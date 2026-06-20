use std::{cell::RefCell, collections::HashMap};

use gtk4::Widget;

thread_local! {
    // 
    pub static WIDGET_MAP: RefCell<HashMap<u64, Widget>> = RefCell::new(HashMap::new());
}

pub fn insert_widget(id: u64, widget: Widget) {
    WIDGET_MAP.with(|map| {
        map.borrow_mut().insert(id, widget);
    });
}

pub fn remove_widget(id: u64) -> Option<Widget>
{
    WIDGET_MAP.with(|map| 
    {
        map.borrow_mut().remove(&id)
    })
}

pub fn with_widget<T>(id: u64, f: impl FnOnce(&Widget) -> T) -> Option<T>
{
    WIDGET_MAP.with(|map| map.borrow().get(&id).map(f))
}