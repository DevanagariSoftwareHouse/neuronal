//! Numerical core, independent of Python.

/// Sample instants in milliseconds: t[i] = i * dt_ms.
/// The caller chooses the exact sample count; no endpoint is inferred.
pub fn time_axis(samples: usize, dt_ms: f64) -> Result<Vec<f64>, &'static str> {
    if !dt_ms.is_finite() || dt_ms <= 0.0 {
        return Err("dt_ms must be finite and positive");
    }
    if samples > 0 && !((samples - 1) as f64 * dt_ms).is_finite() {
        return Err("time axis exceeds the finite range");
    }
    let mut times = Vec::new();
    times
        .try_reserve_exact(samples)
        .map_err(|_| "cannot allocate time axis")?;
    times.extend((0..samples).map(|i| i as f64 * dt_ms));
    Ok(times)
}

/// Time between first and last samples, in milliseconds.
pub fn sampled_span(samples: usize, dt_ms: f64) -> Result<f64, &'static str> {
    if !dt_ms.is_finite() || dt_ms <= 0.0 {
        return Err("dt_ms must be finite and positive");
    }
    let span = samples.saturating_sub(1) as f64 * dt_ms;
    if !span.is_finite() {
        return Err("sampled span exceeds the finite range");
    }
    Ok(span)
}
