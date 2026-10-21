import math

import numpy as np
import pytest
import neuronal


def test_native_time_axis_returns_float64_array():
    t = neuronal.time_axis(5, 0.1)
    assert isinstance(t, np.ndarray)
    assert t.dtype == np.float64 and t.shape == (5,)
    np.testing.assert_allclose(t, [0, 0.1, 0.2, 0.3, 0.4])
    assert neuronal.time_axis(0, 0.1).shape == (0,)


def test_array_owns_its_buffer():
    t = neuronal.time_axis(3, 1.0)
    t[0] = 42.0  # writable, independent of later calls
    np.testing.assert_array_equal(neuronal.time_axis(3, 1.0), [0.0, 1.0, 2.0])


@pytest.mark.parametrize("dt_ms", [0, -1, math.nan, math.inf])
def test_invalid_step(dt_ms):
    with pytest.raises(ValueError, match="dt_ms must be finite and positive"):
        neuronal.time_axis(5, dt_ms)


def test_overflow():
    with pytest.raises(OverflowError):
        neuronal.time_axis(3, 1.7e308)
    with pytest.raises(OverflowError):
        neuronal.sampled_span(3, 1.7e308)


def test_sampled_span():
    assert neuronal.sampled_span(5, 0.1) == pytest.approx(0.4)
    assert neuronal.sampled_span(0, 0.1) == 0.0
    assert neuronal.sampled_span(1, 0.1) == 0.0


def test_last_instant_matches_span():
    t = neuronal.time_axis(1000, 0.05)
    assert t[-1] == neuronal.sampled_span(1000, 0.05)


@pytest.mark.parametrize("dt_ms", [0, -1, math.nan, math.inf])
def test_invalid_sampled_span(dt_ms):
    with pytest.raises(ValueError):
        neuronal.sampled_span(5, dt_ms)
