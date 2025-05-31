use std::{
    env,
    future::Future,
    sync::{LazyLock, Mutex},
};

// A mutex to ensure that the environment variable access is thread-safe
static ENV_MUTEX: LazyLock<Mutex<()>> = LazyLock::new(|| Mutex::new(()));

type Test<T> = fn() -> T;

/// This function can be used to wrap your test functions that
/// modify environment variables.  Since rust runs tests in
/// parallel, changing an environment variable in one test will
/// also mess with the environment that all other tests see,
/// causing flaky tests.
///
/// This function fixes the issue by only allowing one test to
/// use it at a time, and to reset the supplied environment variable
/// value after the test is done.
///
/// To identify flakiness in the test suite, you can run the test suite
/// 1000 times and see how many times it fails with:
/// ```bash
/// for run in {1..1000} ; do
///   cargo test 2>/dev/null 1>&2 || echo "IT FAILED"
/// done | wc -l
/// ```
pub(crate) fn preserving_envvar(key: &str, test: Test<()>) {
    let _lock = ENV_MUTEX.lock().unwrap_or_else(|e| e.into_inner());
    let original = env::var(key).ok();
    test();
    if let Some(value) = original {
        env::set_var(key, value);
    } else {
        env::remove_var(key);
    }
}

pub(crate) async fn preserving_envvar_async<F: Future>(key: &str, test: Test<F>) {
    let _lock = ENV_MUTEX.lock().unwrap_or_else(|e| e.into_inner());
    let original = env::var(key).ok();
    test().await;
    if let Some(value) = original {
        env::set_var(key, value);
    } else {
        env::remove_var(key);
    }
}
