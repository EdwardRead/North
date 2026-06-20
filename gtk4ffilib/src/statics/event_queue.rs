use crossbeam::select;
use crossbeam_channel::{Receiver, Sender, unbounded};
use once_cell::sync::Lazy;

// Can probably remove this now
pub const QUEUE_CANCEL: i64 = -1;

static QUEUE: Lazy<(Sender<i64>, Receiver<i64>)> = Lazy::new(unbounded);
// Maybe use a different channel system for this oneshot queue
static SHUTDOWN: Lazy<(Sender<()>, Receiver<()>)> = Lazy::new(unbounded);

#[no_mangle]
// Kills all the queues so the program can close. 
pub extern "C" fn queue_cancel_waiters() {
    let _ = SHUTDOWN.0.send(());
}

#[unsafe(no_mangle)]
pub extern "C" fn queue_push(v: i64) {
    println!("PUSHING!");
    let _ = QUEUE.0.send(v);
}

#[unsafe(no_mangle)]
pub extern "C" fn queue_pop() -> i64 {

    select! {
        recv(QUEUE.1) -> msg =>
        {
            msg.unwrap_or(QUEUE_CANCEL)
        }
        recv(SHUTDOWN.1) -> _ => {
            QUEUE_CANCEL
        }
    }
}