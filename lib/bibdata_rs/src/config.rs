use std::env;

pub fn rails_env() -> String {
    env::var("RAILS_ENV").unwrap_or("development".to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::testing_support::preserving_envvar;

    #[test]
    fn it_determines_the_rails_env() {
        preserving_envvar("RAILS_ENV", || {
            env::set_var("RAILS_ENV", "production");
            assert_eq!(rails_env(), "production");
        });
    }

    #[test]
    fn it_defaults_the_rails_env_to_development() {
        preserving_envvar("RAILS_ENV", || {
            env::remove_var("RAILS_ENV");
            assert_eq!(rails_env(), "development");
        });
    }
}
