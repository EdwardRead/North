use std::ffi::{CStr, c_char};

use gtk4::{Application, Window, prelude::*};
use once_cell::sync::OnceCell;

pub type BuildUICallback = extern "C" fn(app: *mut Application);

#[no_mangle]
pub extern "C" fn gtk_app_new(app_id: *const c_char) -> *mut Application {
    let app_id_str = unsafe { CStr::from_ptr(app_id).to_str().unwrap() };

    let app = Application::new(Some(app_id_str), gio::ApplicationFlags::FLAGS_NONE);

    Box::into_raw(Box::new(app))
}

#[no_mangle]
pub extern "C" fn connect_app(app_ptr: *mut Application, build_ui: BuildUICallback, update_ui: extern "C" fn()) {
    let app = unsafe { &*app_ptr };

    app.connect_activate(move |gtk_app| 
    {
        let gtk_app_ptr = gtk_app as *const Application as *mut Application;

        glib::timeout_add_local(std::time::Duration::from_millis(32),
            move ||
        {
            update_ui();

            glib::ControlFlow::Continue
        });

        build_ui(gtk_app_ptr);
    });
}

#[no_mangle]
pub extern "C" fn gtk_app_run(app_ptr: *mut Application) -> i32 {
    if app_ptr.is_null() {
        println!("app_ptr is null");
        return -1;
    }
    let app = unsafe { &*app_ptr };
    app.run_with_args(&["App"]);
    0
}

#[no_mangle]
pub extern "C" fn gtk_app_free(app_ptr: *mut Application) {
    if app_ptr.is_null() {
        println!("app_ptr is null");
        return;
    }
    unsafe {
        let _ = Box::from_raw(app_ptr);
    }
}