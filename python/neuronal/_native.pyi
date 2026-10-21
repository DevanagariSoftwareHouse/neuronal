import numpy as np
import numpy.typing as npt

__version__: str

def time_axis(samples: int, dt_ms: float) -> npt.NDArray[np.float64]:
    """Return sample instants t[i] = i * dt_ms as a float64 array.

    Raises ValueError if dt_ms is not finite and positive, OverflowError if the
    axis leaves the finite float range, MemoryError if it cannot be allocated.
    """
    ...

def sampled_span(samples: int, dt_ms: float) -> float:
    """Time between first and last samples in milliseconds."""
    ...
