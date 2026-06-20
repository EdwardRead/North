use std::ffi::{CStr, c_char};

use glib::object::Cast;
use gtk4::Label;

use crate::statics::widget_map::{insert_widget, with_widget};

#[no_mangle]
pub extern "C" fn make_label(text: *const c_char, label_handle: u64)
{
    let label_str = unsafe { CStr::from_ptr(text).to_str() }.unwrap();
    let label = Label::new(Some(label_str));

    insert_widget(label_handle, label.upcast());
}

#[no_mangle]
pub extern "C" fn set_label(label_handle: u64, label_text: *const c_char) {
    let label_str = unsafe { CStr::from_ptr(label_text).to_str() }.unwrap();

    glib::MainContext::default().invoke(move || {
        let ok = with_widget(label_handle, |w| {
            if let Some(label) = w.downcast_ref::<Label>() {
                label.set_text(label_str);
            } else {
                println!("label_handle does not point to a label");
            }
        });

        if ok.is_none() {
            println!("label_handle not in map");
        }
    });
}
