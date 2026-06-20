use std::ffi::{CStr, c_char};

use glib::object::Cast;
use gtk4::{Button, prelude::ButtonExt};

use crate::statics::{event_queue::queue_push, widget_map::insert_widget};

#[no_mangle]
pub extern "C" fn label_button(label: *const c_char, message_function: extern "C" fn(), button_handle: u64)
{
    let label_str = unsafe { CStr::from_ptr(label).to_str() }.unwrap();
    let button = Button::with_label(label_str);

    button.connect_clicked(move |_| {
        // queue_push(message_handle);
        message_function();
    });

    insert_widget(button_handle, button.upcast());
}
