//! This module contains tools for managing data through a pipeline

/// Compose two functions, starting with the one on the left
/// based on https://stackoverflow.com/a/45792463
///
/// Note: it cannot compose a left-hand function that returns an owned value
/// with a right-hand function that accepts a borrowed value.
pub fn compose_two<A, B, C, R, L>(left: L, right: R) -> impl Fn(A) -> C
where
    L: Fn(A) -> B,
    R: Fn(B) -> C,
{
    move |x| {
        let step_one = left(x);
        right(step_one)
    }
}

macro_rules! pipe {
    ( $last:expr ) => { $last };
    ( $head:expr, $($tail:expr), +) => {
        crate::data_pipeline::compose_two($head, pipe!($($tail),+))
    };
}

pub(crate) use pipe;
