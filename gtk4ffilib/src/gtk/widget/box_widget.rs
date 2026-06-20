use std::iter::Successors;

use glib::object::Cast;
use gtk4::{Box as GtkBox, Orientation, Widget, prelude::{BoxExt, WidgetExt}};

use crate::statics::widget_map::{insert_widget, remove_widget, with_widget};

#[no_mangle]
pub extern "C" fn make_box(orientation_int: i32, spacing: i32, box_handle: u64) {
    let orientation = if orientation_int == 0 {
        Orientation::Vertical
    } else {
        Orientation::Horizontal
    };

    let b = GtkBox::new(orientation, spacing);

    insert_widget(box_handle, b.upcast());
}

#[no_mangle]
// Need to expand safety to the rest
pub extern "C" fn append_widget_to_box(box_handle: u64, widget_handle: u64) {
    let child_opt: Option<Widget> = with_widget(widget_handle, |w| w.clone());
    if child_opt.is_none() {
        println!(
            "widget_handle not in map"
        );
        return;
    }
    let child = child_opt.unwrap();

    let ok = with_widget(box_handle, |w| {
        if let Some(b) = w.downcast_ref::<GtkBox>() {
            b.append(&child);
        } else {
            println!("widget_handle not a Box.");
        }
    });

    if ok.is_none() {
        println!("Box widget_handle not in widget map");
    }
}

#[no_mangle]
pub extern "C" fn replace_widget_in_box(parent_key: u64, index: usize, insertion_key: u64)
{
    let parent = with_widget(parent_key, |w| w.clone()).unwrap();
    let insertion = with_widget(insertion_key, |w| w.clone()).unwrap();

    if let Some(b) = parent.downcast_ref::<GtkBox>()
    {
        let old = std::iter::successors(b.first_child(), |w| w.next_sibling()).nth(index);

        b.insert_child_after(&insertion, old.as_ref());

        b.remove(&old.unwrap());
    }
}
