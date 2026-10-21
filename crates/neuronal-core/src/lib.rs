//! Numerical core, independent of Python.
//!
//! Conventions shared with the MATLAB reference and the Python API live in
//! `docs/conventions.md`: durations in seconds, frequencies in hertz, and
//! multichannel data laid out as `(channel, time)`. `time_axis` and
//! `sampled_span` predate that decision and still use milliseconds.

pub mod units;

pub use units::{Hertz, Milliseconds, Seconds};

/// Errors produced by the numerical core.
#[derive(Debug, Clone, Copy, PartialEq, Eq, thiserror::Error)]
pub enum CoreError {
    /// A physical quantity was zero, negative, NaN or infinite.
    #[error("{name} must be finite and positive")]
    NonPositive { name: &'static str },
    /// The result would leave the finite range of `f64`.
    #[error("{what} exceeds the finite range")]
    Overflow { what: &'static str },
    /// The output buffer could not be allocated.
    #[error("cannot allocate {what}")]
    Allocation { what: &'static str },
}

pub type Result<T> = std::result::Result<T, CoreError>;

/// Sample instants in milliseconds: `t[i] = i * dt`.
/// The caller chooses the exact sample count; no endpoint is inferred.
pub fn time_axis(samples: usize, dt: Milliseconds) -> Result<Vec<f64>> {
    let dt = dt.get();
    if samples > 0 && !((samples - 1) as f64 * dt).is_finite() {
        return Err(CoreError::Overflow { what: "time axis" });
    }
    let mut times = Vec::new();
    times
        .try_reserve_exact(samples)
        .map_err(|_| CoreError::Allocation { what: "time axis" })?;
    times.extend((0..samples).map(|i| i as f64 * dt));
    Ok(times)
}

/// Time between first and last samples, in milliseconds.
pub fn sampled_span(samples: usize, dt: Milliseconds) -> Result<f64> {
    let span = samples.saturating_sub(1) as f64 * dt.get();
    if !span.is_finite() {
        return Err(CoreError::Overflow {
            what: "sampled span",
        });
    }
    Ok(span)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn ms(value: f64) -> Milliseconds {
        Milliseconds::new(value).unwrap()
    }

    #[test]
    fn empty_and_single_sample() {
        assert_eq!(time_axis(0, ms(0.1)).unwrap(), Vec::<f64>::new());
        assert_eq!(time_axis(1, ms(0.1)).unwrap(), vec![0.0]);
        assert_eq!(sampled_span(0, ms(0.1)).unwrap(), 0.0);
        assert_eq!(sampled_span(1, ms(0.1)).unwrap(), 0.0);
    }

    #[test]
    fn known_values() {
        let t = time_axis(4, ms(0.5)).unwrap();
        assert_eq!(t, vec![0.0, 0.5, 1.0, 1.5]);
    }

    #[test]
    fn rejects_invalid_steps() {
        for bad in [0.0, -1.0, f64::NAN, f64::INFINITY, f64::NEG_INFINITY] {
            assert_eq!(
                Milliseconds::new(bad),
                Err(CoreError::NonPositive { name: "dt_ms" })
            );
        }
    }

    #[test]
    fn overflow_is_reported() {
        let huge = ms(f64::MAX);
        assert_eq!(
            time_axis(3, huge),
            Err(CoreError::Overflow { what: "time axis" })
        );
        assert_eq!(
            sampled_span(3, huge),
            Err(CoreError::Overflow {
                what: "sampled span"
            })
        );
        // Two samples is still finite: span == dt.
        assert_eq!(sampled_span(2, huge).unwrap(), f64::MAX);
    }

    #[test]
    fn error_messages_are_stable() {
        assert_eq!(
            CoreError::NonPositive { name: "dt_ms" }.to_string(),
            "dt_ms must be finite and positive"
        );
    }

    mod properties {
        use super::*;
        use proptest::prelude::*;

        proptest! {
            #[test]
            fn last_instant_equals_span(samples in 1usize..10_000, dt in 1e-6f64..1e3) {
                let t = time_axis(samples, ms(dt)).unwrap();
                prop_assert_eq!(t.len(), samples);
                prop_assert_eq!(*t.last().unwrap(), sampled_span(samples, ms(dt)).unwrap());
            }

            #[test]
            fn axis_is_strictly_increasing(samples in 2usize..2_000, dt in 1e-6f64..1e3) {
                let t = time_axis(samples, ms(dt)).unwrap();
                prop_assert!(t.windows(2).all(|w| w[0] < w[1]));
                prop_assert_eq!(t[0], 0.0);
            }
        }
    }
}
