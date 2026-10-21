use neuronal_core::{CoreError, Milliseconds};
use numpy::{IntoPyArray, PyArray1};
use pyo3::exceptions::{PyMemoryError, PyOverflowError, PyValueError};
use pyo3::prelude::*;

/// Map core errors onto the matching Python exception types.
fn to_py(error: CoreError) -> PyErr {
    let message = error.to_string();
    match error {
        CoreError::NonPositive { .. } => PyValueError::new_err(message),
        CoreError::Overflow { .. } => PyOverflowError::new_err(message),
        CoreError::Allocation { .. } => PyMemoryError::new_err(message),
    }
}

fn step(dt_ms: f64) -> PyResult<Milliseconds> {
    Milliseconds::new(dt_ms).map_err(to_py)
}

/// Return sample instants in milliseconds as a NumPy float64 array.
#[pyfunction]
fn time_axis<'py>(
    py: Python<'py>,
    samples: usize,
    dt_ms: f64,
) -> PyResult<Bound<'py, PyArray1<f64>>> {
    let dt = step(dt_ms)?;
    let times = py
        .detach(|| neuronal_core::time_axis(samples, dt))
        .map_err(to_py)?;
    // Hands the Rust buffer to NumPy without copying.
    Ok(times.into_pyarray(py))
}

/// Time between the first and last samples in milliseconds.
#[pyfunction]
fn sampled_span(samples: usize, dt_ms: f64) -> PyResult<f64> {
    neuronal_core::sampled_span(samples, step(dt_ms)?).map_err(to_py)
}

#[pymodule]
fn _native(m: &Bound<'_, PyModule>) -> PyResult<()> {
    m.add("__version__", env!("CARGO_PKG_VERSION"))?;
    m.add_function(wrap_pyfunction!(time_axis, m)?)?;
    m.add_function(wrap_pyfunction!(sampled_span, m)?)?;
    Ok(())
}
