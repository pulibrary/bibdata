//! This module defines errors that may happen while working with Theses

use magnus::Ruby;
use std::fmt;

#[derive(Debug)]
pub enum ThesesError {
    CouldNotOpenFileForWriting,
    CouldNotWriteToFile,
}

impl fmt::Display for ThesesError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{self:?}")
    }
}

impl std::error::Error for ThesesError {}

impl ThesesError {
    pub fn to_magnus(&self, ruby: &Ruby) -> magnus::Error {
        magnus::Error::new(ruby.exception_runtime_error(), format!("{self:?}"))
    }
}
