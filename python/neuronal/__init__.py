"""Electrophysiology analysis backed by a Rust numerical core.

Units follow docs/conventions.md: durations in seconds, frequencies in hertz,
multichannel arrays shaped (channel, time). time_axis/sampled_span still take
milliseconds (dt_ms), as named.
"""
from ._native import __version__, sampled_span, time_axis

__all__ = ["__version__", "sampled_span", "time_axis"]
