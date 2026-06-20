use std::sync::atomic::{AtomicU64, Ordering};

pub static COUNTER: AtomicU64 = AtomicU64::new(0);

pub fn next_id() -> u64 {
    COUNTER.fetch_add(1, Ordering::Relaxed) + 1
}
