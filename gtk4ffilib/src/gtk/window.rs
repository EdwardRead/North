use std::{cell::RefCell, collections::HashMap, ffi::{CStr, c_char}};

use glib::object::{Cast, ObjectExt};
use gtk4::{Application, ApplicationWindow, Box as GtkBox, Button, Label, Widget, Window, prelude::{ButtonExt, GtkWindowExt}};

use crate::statics::{counter::next_id, widget_map::{WIDGET_MAP, insert_widget, with_widget}};

#[no_mangle]
pub extern "C" fn gtk_new_window(
    title: *const c_char,
    width: i32,
    height: i32,
    app_ptr: *mut Application,
    window_handle: u64
) {
    if app_ptr.is_null() {
        println!("app_ptr is null");
        return;
    }

    let title_str = unsafe { CStr::from_ptr(title).to_str() }.unwrap();
    let app = unsafe { &*app_ptr };

    let window = ApplicationWindow::new(app);
    window.set_title(Some(title_str));
    window.set_default_size(width, height);

    insert_widget(window_handle, window.upcast());
    println!("{}", window_handle);
}

#[no_mangle]
pub extern "C" fn connect_widget_to_window(window_handle: u64, widget_handle: u64) {
    let child_opt: Option<Widget> = with_widget(widget_handle, |w| w.clone());

    if child_opt.is_none() {
        println!("widget_handle not in map");
        return;
    }
    let child = child_opt.unwrap();

    // Set child on ApplicationWindow
    let ok = with_widget(window_handle, |w| 
    {
        if let Some(win) = w.downcast_ref::<ApplicationWindow>() 
        {
            win.set_child(Some(&child));
        } else {
            println!("Handle does not point to ApplicationWindow");
        }
    });

    if ok.is_none() {
        println!("Window handle not in map");
    }
}

#[no_mangle]
pub extern "C" fn present_window(window_handle: u64) {
    let ok = with_widget(window_handle, |w| {
        if let Some(win) = w.downcast_ref::<ApplicationWindow>() {
            win.present();
        } else {
            println!("Handle not an ApplicationWindow");
        }
    });

    if ok.is_none() {
        println!("Window handle not in map");
    }
}

#[no_mangle]
pub extern "C" fn replace_widget_in_window(window_handle: u64, widget_key: u64)
{
    let window = with_widget(window_handle, |w| w.clone()).unwrap();
    let child = with_widget(widget_key, |w| w.clone());

    if let Some(w) = window.downcast_ref::<Window>()
    {
        w.set_child(child.as_ref());
    }
}
