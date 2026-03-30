use std::{path::PathBuf, sync::LazyLock};

pub static APPLICATION_ROOT: LazyLock<PathBuf> =
    LazyLock::new(|| PathBuf::from(&format!("{}/../..", env!("CARGO_MANIFEST_DIR"))));
