//! Validated physical quantities.
//!
//! Each newtype guarantees a finite, strictly positive value, so functions that
//! receive one never re-check it. Units follow `docs/conventions.md`.

use crate::{CoreError, Result};

macro_rules! positive_quantity {
    ($(#[$doc:meta])* $name:ident, $label:literal) => {
        $(#[$doc])*
        #[derive(Debug, Clone, Copy, PartialEq, PartialOrd)]
        pub struct $name(f64);

        impl $name {
            /// Accepts finite, strictly positive values only.
            pub fn new(value: f64) -> Result<Self> {
                if value.is_finite() && value > 0.0 {
                    Ok(Self(value))
                } else {
                    Err(CoreError::NonPositive { name: $label })
                }
            }

            pub fn get(self) -> f64 {
                self.0
            }
        }

        impl TryFrom<f64> for $name {
            type Error = CoreError;
            fn try_from(value: f64) -> Result<Self> {
                Self::new(value)
            }
        }
    };
}

positive_quantity!(
    /// A duration in milliseconds, such as a sampling step.
    Milliseconds,
    "dt_ms"
);

positive_quantity!(
    /// A duration in seconds, the canonical time unit shared with MATLAB.
    Seconds,
    "duration_s"
);

positive_quantity!(
    /// A frequency in hertz, such as a sampling rate.
    Hertz,
    "fs_hz"
);

impl Milliseconds {
    /// Sampling step corresponding to a sampling rate: `dt = 1000 / fs`.
    pub fn from_rate(rate: Hertz) -> Result<Self> {
        Self::new(1000.0 / rate.get())
    }

    /// Fails if the product overflows; never saturates.
    pub fn from_seconds(value: Seconds) -> Result<Self> {
        Self::new(value.get() * 1000.0)
    }
}

impl Seconds {
    /// Fails if the quotient underflows to zero; never saturates.
    pub fn from_millis(value: Milliseconds) -> Result<Self> {
        Self::new(value.get() / 1000.0)
    }
}

impl Hertz {
    /// Sampling rate corresponding to a sampling step: `fs = 1000 / dt`.
    pub fn from_step(step: Milliseconds) -> Result<Self> {
        Self::new(1000.0 / step.get())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn rate_and_step_round_trip() {
        let fs = Hertz::new(1000.0).unwrap();
        let dt = Milliseconds::from_rate(fs).unwrap();
        assert_eq!(dt.get(), 1.0);
        assert_eq!(Hertz::from_step(dt).unwrap(), fs);
    }

    #[test]
    fn seconds_and_milliseconds_convert() {
        let s = Seconds::new(0.25).unwrap();
        assert_eq!(Milliseconds::from_seconds(s).unwrap().get(), 250.0);
        assert_eq!(
            Seconds::from_millis(Milliseconds::new(250.0).unwrap()).unwrap(),
            s
        );
    }

    #[test]
    fn conversions_fail_instead_of_saturating() {
        assert!(Milliseconds::from_seconds(Seconds::new(f64::MAX).unwrap()).is_err());
        let smallest = Milliseconds::new(f64::from_bits(1)).unwrap();
        assert!(Seconds::from_millis(smallest).is_err());
    }

    #[test]
    fn subnormal_conversion_is_rejected() {
        // 1000 / tiny overflows to infinity.
        let tiny = Milliseconds::new(f64::MIN_POSITIVE / 1e10).unwrap();
        assert!(Hertz::from_step(tiny).is_err());
    }
}
