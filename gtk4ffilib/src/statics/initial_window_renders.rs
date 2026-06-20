use crossbeam_channel::{Receiver, Sender, unbounded};
use once_cell::sync::Lazy;

static RENDER_HANDLE_QUEUE: Lazy<(Sender<i32>, Receiver<i32>)> = Lazy::new(unbounded);

#[no_mangle]
pub extern "C" fn render_handle_queue_push(v: i32)
{
    let _ = RENDER_HANDLE_QUEUE.0.send(v);
}

#[no_mangle]
pub  extern "C" fn render_handle_queue_pop() -> i32
{
    RENDER_HANDLE_QUEUE.1.recv().unwrap()
}
