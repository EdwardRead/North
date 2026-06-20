use crossbeam::channel::{bounded, Receiver, Sender};
use once_cell::sync::Lazy;

// Single-producer, single-consumer channel of size 1
static CHANNEL: Lazy<(Sender<i32>, Receiver<i32>)> = Lazy::new(|| bounded(1));

#[no_mangle]
pub extern "C" fn set_cell(value: i32) {
    let (sender, _receiver) = &*CHANNEL;
    // If the value was already sent, we replace it by removing the old one first
    let _ = sender.try_send(value); // ignores error if full
}

#[no_mangle]
pub extern "C" fn get_cell() -> i32 {
    let (_sender, receiver) = &*CHANNEL;
    // Blocks until a value is available
    receiver.recv().unwrap()
}