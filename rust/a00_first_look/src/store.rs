//! Headless little-endian BIN files, mirrored from `neuronal_memmap` /
//! `neuronal_validate_file` / `neuronal_read` (matlab/path).
//!
//! Layout: MATLAB column-major `shape = [rows, cols]`, i.e. samples x channels
//! for LFP, so each column (channel) is contiguous on disk:
//!   byte(k, c) = offset + b * (k + rows * c)        (zero-based k, c)

use std::fs::File;
use std::ops::Range;
use std::path::{Path, PathBuf};

use memmap2::Mmap;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Dtype {
    F64,
    F32,
    I8,
    U8,
    I16,
    U16,
    I32,
    U32,
    I64,
    U64,
}

impl Dtype {
    /// MATLAB class name, as written in `descriptor.dtype`.
    pub fn from_matlab(name: &str) -> Option<Self> {
        Some(match name {
            "double" => Self::F64,
            "single" => Self::F32,
            "int8" => Self::I8,
            "uint8" => Self::U8,
            "int16" => Self::I16,
            "uint16" => Self::U16,
            "int32" => Self::I32,
            "uint32" => Self::U32,
            "int64" => Self::I64,
            "uint64" => Self::U64,
            _ => return None,
        })
    }

    pub fn matlab(self) -> &'static str {
        match self {
            Self::F64 => "double",
            Self::F32 => "single",
            Self::I8 => "int8",
            Self::U8 => "uint8",
            Self::I16 => "int16",
            Self::U16 => "uint16",
            Self::I32 => "int32",
            Self::U32 => "uint32",
            Self::I64 => "int64",
            Self::U64 => "uint64",
        }
    }

    pub fn bytes(self) -> usize {
        match self {
            Self::I8 | Self::U8 => 1,
            Self::I16 | Self::U16 => 2,
            Self::F32 | Self::I32 | Self::U32 => 4,
            Self::F64 | Self::I64 | Self::U64 => 8,
        }
    }

    /// Decode one little-endian value. `b.len() == self.bytes()`.
    #[inline]
    fn decode(self, b: &[u8]) -> f64 {
        match self {
            Self::F64 => f64::from_le_bytes(b.try_into().unwrap()),
            Self::F32 => f32::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::I8 => b[0] as i8 as f64,
            Self::U8 => b[0] as f64,
            Self::I16 => i16::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::U16 => u16::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::I32 => i32::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::U32 => u32::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::I64 => i64::from_le_bytes(b.try_into().unwrap()) as f64,
            Self::U64 => u64::from_le_bytes(b.try_into().unwrap()) as f64,
        }
    }
}

/// What the catalog says about one binary array.
#[derive(Clone, Debug)]
pub struct Descriptor {
    pub name: String,
    pub kind: String,
    pub path: PathBuf,
    pub dtype: Dtype,
    /// `[rows, cols]`, column-major. A vector is `[n, 1]`.
    pub shape: [usize; 2],
    pub offset_bytes: usize,
    pub sampling_rate_hz: Option<f64>,
}

impl Descriptor {
    pub fn expected_bytes(&self) -> Option<usize> {
        self.shape[0]
            .checked_mul(self.shape[1])?
            .checked_mul(self.dtype.bytes())?
            .checked_add(self.offset_bytes)
    }
}

/// Read-only map with the declared shape (`neuronal_memmap`).
pub struct BinMap {
    pub desc: Descriptor,
    map: Mmap,
}

impl BinMap {
    /// Validates like `neuronal_validate_file`: present, exact byte count.
    /// Endianness: files are `ieee-le`; we decode LE explicitly, so the host
    /// order does not matter here (unlike MATLAB memmapfile).
    pub fn open(desc: Descriptor) -> Result<Self, String> {
        let file = File::open(&desc.path)
            .map_err(|e| format!("{}: {e}", desc.path.display()))?;
        let actual = file
            .metadata()
            .map_err(|e| format!("{}: {e}", desc.path.display()))?
            .len() as usize;
        let expected = desc
            .expected_bytes()
            .ok_or_else(|| "shape overflows usize".to_string())?;
        if actual != expected {
            return Err(format!(
                "size mismatch {}: expected {expected} B ({} {} x {} + {}), got {actual} B",
                desc.path.display(),
                desc.dtype.matlab(),
                desc.shape[0],
                desc.shape[1],
                desc.offset_bytes
            ));
        }
        // SAFETY: read-only map; raw files must not be rewritten while open
        // (same contract as the MATLAB side: "raw files must be read-only").
        let map = unsafe { Mmap::map(&file) }
            .map_err(|e| format!("mmap {}: {e}", desc.path.display()))?;
        Ok(Self { desc, map })
    }

    pub fn rows(&self) -> usize {
        self.desc.shape[0]
    }

    pub fn cols(&self) -> usize {
        self.desc.shape[1]
    }

    #[inline]
    fn column_bytes(&self, col: usize) -> &[u8] {
        let b = self.desc.dtype.bytes();
        let start = self.desc.offset_bytes + b * self.rows() * col;
        &self.map[start..start + b * self.rows()]
    }

    /// Zero-based rows of one column, converted to f64 (`neuronal_read`,
    /// 0-based instead of 1-based). Range is clamped to the array.
    pub fn read(&self, rows: Range<usize>, col: usize) -> Vec<f64> {
        assert!(col < self.cols(), "column {col} out of {}", self.cols());
        let b = self.desc.dtype.bytes();
        let rows = rows.start.min(self.rows())..rows.end.min(self.rows());
        let bytes = &self.column_bytes(col)[rows.start * b..rows.end * b];
        bytes.chunks_exact(b).map(|c| self.desc.dtype.decode(c)).collect()
    }

    /// Whole column (for spike vectors etc.).
    pub fn column(&self, col: usize) -> Vec<f64> {
        self.read(0..self.rows(), col)
    }

    /// Min/max envelope of `rows` in `buckets` bins, without materialising
    /// the window. Returns `(row_index, value)` pairs, two per bucket,
    /// ordered so a line through them draws the envelope.
    pub fn envelope(&self, rows: Range<usize>, col: usize, buckets: usize) -> Vec<(usize, f64)> {
        let rows = rows.start.min(self.rows())..rows.end.min(self.rows());
        let n = rows.len();
        if n == 0 || buckets == 0 {
            return Vec::new();
        }
        let b = self.desc.dtype.bytes();
        let col_bytes = self.column_bytes(col);
        let at = |k: usize| self.desc.dtype.decode(&col_bytes[k * b..(k + 1) * b]);
        if n <= 2 * buckets {
            return rows.map(|k| (k, at(k))).collect();
        }
        let mut out = Vec::with_capacity(2 * buckets);
        for i in 0..buckets {
            let lo = rows.start + n * i / buckets;
            let hi = rows.start + n * (i + 1) / buckets;
            let (mut kmin, mut vmin, mut kmax, mut vmax) = (lo, f64::INFINITY, lo, f64::NEG_INFINITY);
            for k in lo..hi {
                let v = at(k);
                if v < vmin {
                    vmin = v;
                    kmin = k;
                }
                if v > vmax {
                    vmax = v;
                    kmax = k;
                }
            }
            if kmin <= kmax {
                out.push((kmin, vmin));
                out.push((kmax, vmax));
            } else {
                out.push((kmax, vmax));
                out.push((kmin, vmin));
            }
        }
        out
    }
}

/// Resolve a catalog path: absolute as-is, relative against the repo root
/// (`neuronal_file_path` default).
pub fn resolve(root: &Path, p: &str) -> PathBuf {
    let p = PathBuf::from(p.replace('\\', "/"));
    if p.is_absolute() {
        p
    } else {
        root.join(p)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Write;

    fn write_tmp(name: &str, bytes: &[u8]) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("a00_first_look_{}", std::process::id()));
        std::fs::create_dir_all(&dir).unwrap();
        let p = dir.join(name);
        std::fs::File::create(&p).unwrap().write_all(bytes).unwrap();
        p
    }

    fn desc(path: PathBuf, dtype: Dtype, shape: [usize; 2]) -> Descriptor {
        Descriptor {
            name: "t".into(),
            kind: "lfp".into(),
            path,
            dtype,
            shape,
            offset_bytes: 0,
            sampling_rate_hz: Some(500.0),
        }
    }

    /// Same toy as 01_STORAGE.md: channels x samples [11 12 13 14; 21 22 23 24]
    /// stored as samples x channels; second channel reads 21..24.
    #[test]
    fn column_major_roundtrip() {
        let stored: Vec<f32> = vec![11., 12., 13., 14., 21., 22., 23., 24.];
        let bytes: Vec<u8> = stored.iter().flat_map(|v| v.to_le_bytes()).collect();
        let m = BinMap::open(desc(write_tmp("toy.bin", &bytes), Dtype::F32, [4, 2])).unwrap();
        assert_eq!(m.column(1), vec![21., 22., 23., 24.]);
        assert_eq!(m.read(1..3, 0), vec![12., 13.]);
        assert_eq!(m.read(3..99, 1), vec![24.]);
    }

    #[test]
    fn transposed_shape_fails_only_semantically() {
        // Correct byte length does not catch a swapped shape (the exercise in
        // 01_STORAGE.md) - but a wrong total does get caught.
        let bytes = vec![0u8; 8 * 4];
        assert!(BinMap::open(desc(write_tmp("a.bin", &bytes), Dtype::F32, [2, 4])).is_ok());
        assert!(BinMap::open(desc(write_tmp("b.bin", &bytes), Dtype::F32, [3, 4])).is_err());
    }

    #[test]
    fn envelope_keeps_extremes() {
        let mut v: Vec<f64> = (0..10_000).map(|k| (k as f64 * 0.01).sin()).collect();
        v[4321] = 9.0;
        v[777] = -9.0;
        let bytes: Vec<u8> = v.iter().flat_map(|x| x.to_le_bytes()).collect();
        let m = BinMap::open(desc(write_tmp("env.bin", &bytes), Dtype::F64, [10_000, 1])).unwrap();
        let e = m.envelope(0..10_000, 0, 100);
        assert_eq!(e.len(), 200);
        assert!(e.contains(&(4321, 9.0)));
        assert!(e.contains(&(777, -9.0)));
        assert!(e.windows(2).all(|w| w[0].0 <= w[1].0));
    }

    #[test]
    fn int32_clusters() {
        let ids: Vec<i32> = vec![3, -1, 7];
        let bytes: Vec<u8> = ids.iter().flat_map(|v| v.to_le_bytes()).collect();
        let m = BinMap::open(desc(write_tmp("c.bin", &bytes), Dtype::I32, [3, 1])).unwrap();
        assert_eq!(m.column(0), vec![3., -1., 7.]);
    }
}
