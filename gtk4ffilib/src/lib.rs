use std::{thread::{self, JoinHandle}, time::Duration};

use crate::statics::widget_map::remove_widget;

mod statics;
mod debug;
mod gtk;

type CVoidFunc = extern "C" fn();
// Not sure where to put this so it can stay here for now. 
#[no_mangle]
pub extern "C" fn glib_main_context(func: CVoidFunc) 
{
    glib::MainContext::default().invoke(move || {
        func();
    });
}

#[no_mangle]
pub extern "C" fn sleep_nanos(nanos: u64) {
    let duration = Duration::from_nanos(nanos);
    thread::sleep(duration);
}

pub struct ThreadId
{
    handle: Option<JoinHandle<()>>
}

#[no_mangle]
pub extern "C" fn thread_spawn(f: CVoidFunc) -> *mut ThreadId
{
    let handle = thread::spawn(move | | { f(); });
    
    let boxed = Box::new(ThreadId
    {
        handle: Some(handle)
    });

    Box::into_raw(boxed)
}

#[no_mangle]
pub extern "C" fn thread_wait(tid: *mut ThreadId)
{
    if tid.is_null() { return; }

    unsafe 
    {
        let mut boxed = Box::from_raw(tid);
        if let Some(join) = boxed.handle.take()
        {
            let _ = join.join();
        }
    }
}

#[no_mangle]
pub extern "C" fn schedule_idle_once(f: extern "C" fn())
{
    glib::MainContext::default().invoke(move || 
    {
        glib::idle_add_local_once(move ||
        {
            f();
        });
    });
}

#[no_mangle]
pub extern "C" fn idle_once(f: extern "C" fn())
{
    glib::idle_add_once(move ||
    {
        f();
    });
}

#[no_mangle]
pub extern "C" fn timeout_once(nanos: u64, f: extern "C" fn())
{
    glib::timeout_add_once(Duration::from_nanos(nanos), move || 
    {
        f();
    });
}

#[no_mangle]
pub extern "C" fn schedule_timeout_once(nanos: u64, f: extern "C" fn())
{
    glib::MainContext::default().invoke(move || 
    {
        glib::timeout_add_local_once(Duration::from_nanos(nanos), move || f());
    });
}

#[no_mangle]
pub extern "C" fn schedule_timeout_repeating(nanos: u64, f: extern "C" fn())
{
    glib::MainContext::default().invoke(move ||
    {
        glib::timeout_add_local(Duration::from_nanos(nanos), move ||
        {
            f();

           glib::ControlFlow::Continue 
        });
    });
}

#[no_mangle]
pub extern "C" fn timeout_repeating(nanos: u64, f: extern "C" fn())
{
    glib::MainContext::default().invoke(move ||
    {
        glib::timeout_add(Duration::from_nanos(nanos), move ||
        {
            f();

           glib::ControlFlow::Continue 
        });
    });
}

#[no_mangle]
pub extern "C" fn delete_widget(id: u64)
{
    remove_widget(id);
}
