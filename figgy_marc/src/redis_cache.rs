// This module uses Redis as a cache for data from Figgy

use r2d2::Pool;
use redis::{Client, TypedCommands};
use std::{env, sync::LazyLock};

use crate::{config::RedisConfig, error::FiggyMarcError, mms_records_report::FiggyMmsIdCache};

const REDIS_CACHE_KEY: &str = "figgy_marc:mms_id_report:json_string";

static REDIS_CONNECTION_POOL: LazyLock<Pool<redis::Client>> = LazyLock::new(|| {
    let client =
        redis_client(&RedisConfig::from(env::var)).expect("Could not create a new redis client");
    connection_pool(client)
        .expect("Could not create a connection pool")
});

pub fn write(figgy_documents: &FiggyMmsIdCache) {
    let mut connection = REDIS_CONNECTION_POOL
        .get()
        .expect("Could not get a redis connection from the connection pool");
    let documents_as_json = serde_json::to_string(figgy_documents)
        .expect("Could not serialize figgy documents as a JSON string");
    connection.set(REDIS_CACHE_KEY, &documents_as_json).unwrap();
}

pub fn read() -> FiggyMmsIdCache {
    let mut connection = REDIS_CONNECTION_POOL
        .get()
        .expect("Could not get a redis connection from the connection pool");
    serde_json::from_str(&connection.get(REDIS_CACHE_KEY).unwrap().unwrap()).unwrap()
}

fn redis_client(config: &'_ RedisConfig) -> Result<redis::Client, FiggyMarcError<'_>> {
    let connection_url = format!(
        "redis://{}:{}/{}",
        config.redis_url(),
        config.redis_port(),
        config.redis_db()
    );
    redis::Client::open(connection_url.clone())
        .map_err(|e| FiggyMarcError::CouldNotStartRedisClient(e, connection_url))
}

fn connection_pool<'a>(client: Client) -> Result<Pool<Client>, FiggyMarcError<'a>> {
    let connection_addr = client.get_connection_info().addr().clone();
    r2d2::Pool::builder()
        .build(client)
        .map_err(|e| FiggyMarcError::CouldNotCreateRedisConnectionPool(e, connection_addr))
}
