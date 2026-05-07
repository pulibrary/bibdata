//! Utilities related to slices

/// See if a slice (e.g. &vec![1, 2, 3]) contains a subslice (e.g. &vec![2, 3])
/// in order.
pub fn contains_subslice<T: PartialEq>(slice: &[T], subslice: &[T]) -> bool {
    if subslice.is_empty() {
        return true;
    }
    if subslice.len() > slice.len() {
        return false;
    }
    slice.windows(subslice.len()).any(|w| w == subslice)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_determine_if_slice_contains_subslice() {
        assert!(contains_subslice(&[1, 2, 3], &[]));
        assert!(contains_subslice(&[1, 2, 3], &[1]));
        assert!(contains_subslice(&[1, 2, 3], &[1, 2]));
        assert!(contains_subslice(&[1, 2, 3], &[1, 2, 3]));
        assert!(contains_subslice(&[1, 2, 3], &[2, 3]));
        assert!(contains_subslice(&[1, 2, 3], &[2]));
        assert!(contains_subslice(&[1, 2, 3], &[3]));

        assert!(!contains_subslice(&[1, 2, 3], &[3, 2, 1]));
        assert!(!contains_subslice(&[1, 2, 3], &[1, 1]));
        assert!(!contains_subslice(&[1, 2, 3], &[1, 2, 3, 4]));
    }
}
