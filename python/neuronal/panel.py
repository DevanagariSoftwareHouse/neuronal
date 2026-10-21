"""Reusable NiceGUI panel and an async, same-kernel notebook presenter."""
import asyncio
import socket
from uuid import uuid4

import numpy as np

try:
    from fastapi import FastAPI
    from nicegui import ui
    import uvicorn
except ImportError as error:  # pragma: no cover - depends on installed extras
    raise ImportError(
        "neuronal.panel needs the optional NiceGUI stack: "
        "pip install 'neuronal-rs[panel]'"
    ) from error

from . import time_axis


class TimeAxisPanel:
    """Controls and results shared by a notebook and its embedded web UI.

    One object represents one experiment; browser clients share its state.
    """

    def __init__(self, samples=1000, dt_ms=0.1):
        self.parameters = {"samples": samples, "dt_ms": dt_ms}
        self.result = np.empty(0)
        self.closed = False
        self.path = f"/panel/{uuid4().hex}"
        self.url = None
        self.compute()
        self._view = ui.refreshable(self._build)
        ui.page(self.path)(self.build)

    def compute(self):
        if self.closed:
            raise RuntimeError("This panel is closed; create a new panel.")
        self.result = time_axis(**self.parameters)
        return self.result

    def _build(self):
        if self.closed:
            ui.label("Panel closed")
            return
        ui.label("neuronal · time axis").classes("text-h5")
        with ui.row():
            samples = ui.number("Samples", value=self.parameters["samples"],
                                min=0, max=100000, step=1, precision=0)
            dt = ui.number("dt (ms)", value=self.parameters["dt_ms"], min=0.000001)

            def calculate():
                try:
                    if samples.value is None or dt.value is None:
                        raise ValueError("Fill both parameters")
                    if samples.value != int(samples.value) or not 0 <= samples.value <= 100000:
                        raise ValueError("Samples must be an integer between 0 and 100000")
                    candidate = {"samples": int(samples.value), "dt_ms": float(dt.value)}
                    result = time_axis(**candidate)
                except (ValueError, TypeError, OverflowError) as error:
                    ui.notify(str(error), type="negative")
                    return
                self.parameters = candidate
                self.result = result
                self._view.refresh()

            ui.button("Calculate", on_click=calculate)
        ui.label(f"{len(self.result)} samples; last instant: "
                 f"{self.result[-1] if len(self.result) else None} ms")
        # Bound the displayed points, while retaining the complete numerical result.
        stride = max(1, (len(self.result) + 1999) // 2000)
        ui.echart({"xAxis": {"type": "value", "name": "sample"},
                   "yAxis": {"type": "value", "name": "time (ms)"},
                   "series": [{"type": "line", "showSymbol": False,
                               "data": [[i, float(self.result[i])]
                                        for i in range(0, len(self.result), stride)]}]}).classes("w-full h-64")

    def build(self):
        """Render into the current NiceGUI page (also usable outside notebooks)."""
        self._view()

    async def show(self, *, height=460):
        """Display an iframe; Jupyter and NiceGUI must run on the same computer."""
        if self.closed:
            raise RuntimeError("This panel is closed; create a new panel.")
        from IPython.display import IFrame, display
        runtime = await _start_runtime()
        self.url = f"http://127.0.0.1:{runtime.port}{self.path}"
        display(IFrame(self.url, width="100%", height=height))
        return self

    def close(self):
        """Disable this panel, including existing browser views."""
        self.closed = True
        self._view.refresh()


class _Runtime:
    def __init__(self):
        self.socket = socket.socket()
        self.socket.bind(("127.0.0.1", 0))
        self.port = self.socket.getsockname()[1]
        application = FastAPI()
        ui.run_with(application, show_welcome_message=False)
        self.server = uvicorn.Server(uvicorn.Config(
            application, host="127.0.0.1", port=self.port,
            loop="asyncio", log_level="warning"))
        self.task = asyncio.create_task(self.server.serve(sockets=[self.socket]))


_runtime = None


async def _start_runtime():
    global _runtime
    if _runtime is None:
        _runtime = _Runtime()
    for _ in range(200):
        if _runtime.task.done():
            await _runtime.task
            raise RuntimeError("Panel server stopped; restart the kernel")
        if _runtime.server.started:
            return _runtime
        await asyncio.sleep(0.05)
    raise TimeoutError("NiceGUI server did not start in 10 seconds")


async def shutdown_panels():
    """Stop the shared notebook server. Restart the kernel before using it again."""
    if _runtime is not None:
        _runtime.server.should_exit = True
        await _runtime.task
        _runtime.socket.close()
