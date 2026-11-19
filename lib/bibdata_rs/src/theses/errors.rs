//! This module defines errors that may happen while working with Theses

use magnus::Ruby;

#[derive(Debug)]
pub enum ThesesError {
    CouldNotOpenFileForWriting,
}

impl ThesesError {
    pub fn to_magnus(&self, ruby: &Ruby) -> magnus::Error {
        magnus::Error::new(ruby.exception_runtime_error(), format!("{self:?}"))
    }
}
