module Foreign

import Data

link : String -> String
link s = "C:" ++ s ++ ",libgtk4ffilib"

-- Anything using integers for widgets in here will be using widget keys which are then mapped using the WIDGET_MAP structure into their actual widget forms. 
-- Done since widget references and widget pointers cannot be sent across threads safely. 

%foreign link "gtk_app_new"
export prim_newApp : String -> Ptr ()

%foreign link "connect_app"
export prim_connectApp : GCPtr () -> (Ptr () -> PrimIO ()) -> PrimIO () -> PrimIO ()

%foreign link "gtk_app_run"
export prim_appRun : GCPtr () -> PrimIO Int

%foreign link "gtk_app_free"
export prim_appFree : Ptr () -> PrimIO ()

%foreign link "default_build_ui"
export prim_buildUI : Ptr () -> String -> PrimIO ()

%foreign link "gtk_new_window"
export prim_newWindow : String -> Int -> Int -> Ptr () -> Int -> PrimIO ()

%foreign link "label_button"
export prim_labelButton : String -> PrimIO () -> Int -> PrimIO ()

%foreign link "make_label"
export prim_label : String -> Int -> PrimIO ()

%foreign link "connect_widget_to_window"
export prim_connectWidgetToWindow : Int -> Int -> PrimIO ()

%foreign link "append_widget_to_box"
export prim_appendWidgetToBox : Int -> Int -> PrimIO ()

%foreign link "make_box"
export prim_box : Int -> Int -> Int -> PrimIO ()

%foreign link "present_window"
export prim_presentWindow : Int -> PrimIO ()

-- Currently unused so can be deleted but I am going to keep it in for the submission since it is handy to show previous stages

%foreign link "queue_push"
export prim_queuePush : Int -> PrimIO ()

%foreign link "queue_pop"
export prim_queuePop : PrimIO Int

%foreign link "queue_cancel_waiters"
export prim_queueClose : PrimIO ()

%foreign link "set_cell"
export prim_setCell : Int -> PrimIO ()

%foreign link "get_cell"
export prim_getCell : PrimIO Int

%foreign link "set_label"
export prim_setLabel : Int -> String -> PrimIO ()

-- Runs a function on the main thread, similar to the schedule_... code below but involves no scheduling. 

%foreign link "glib_main_context"
export prim_mainThread : PrimIO () -> PrimIO ()

%foreign link "render_handle_queue_push"
export prim_renderHandleQueuePush : Int -> PrimIO ()

%foreign link "render_handle_queue_pop"
export prim_renderHandleQueuePop : PrimIO Int


%foreign link "sleep_nanos"
export prim_sleepNanos : Bits64 -> PrimIO ()


-- Code for scheduling operations using GLib and GTK
-- schedule_... is scheduled on the main thread, otherwise is run from the current thread

%foreign link "schedule_idle_once"
export prim_scheduleIdleOnce : PrimIO () -> PrimIO ()

%foreign link "idle_once"
export prim_idleOnce : PrimIO () -> PrimIO ()

%foreign link "timeout_once"
export prim_timeoutOnce : Bits64 -> PrimIO () -> PrimIO ()

%foreign link "schedule_timeout_once"
export prim_scheduleTimeoutOnce : Bits64 -> PrimIO () -> PrimIO ()

%foreign link "schedule_timeout_repeating"
export prim_scheduleTimeoutRepeating : Bits64 -> PrimIO () -> PrimIO ()

%foreign link "timeout_repeating"
export prim_timeoutRepeating : Bits64 -> PrimIO () -> PrimIO ()

%foreign link "replace_widget_in_box"
export prim_replaceWidgetInBox : Int -> Int -> Int -> PrimIO ()

-- Clears a widget from the widget map by its key
%foreign link "delete_widget"
export prim_deleteWidget : Int -> PrimIO ()

-- Given a window handle and a widget key, replace the window's child with the new key, does not delete from the widget map. That must be done separately. 
%foreign link "replace_widget_in_window"
export prim_replaceWidgetInWindow : Int -> Int -> PrimIO ()
