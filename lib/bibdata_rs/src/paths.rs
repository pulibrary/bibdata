use std::{path::Path, sync::LazyLock};

pub static APPLICATION_ROOT: LazyLock<&Path> = LazyLock::new(|| {
    let current_path = Path::new(file!());
    current_path
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .parent()
        .unwrap()
        .parent()
        .unwrap()
});
