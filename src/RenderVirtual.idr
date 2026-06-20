module RenderVirtual

import Foreign
import MutableCell
import Application
import Window
import Data
import Store
import ApplicationNode.ApplicationNode
import InApplicationNode
import Channel
import System.Concurrency

initNode : KeySupplier -> ClosableUnboundedChannel message -> Widget message -> IO (InWidget message)
initNode = widgetToInWidget

initAppNode : KeySupplier -> ClosableUnboundedChannel message -> Widget message -> WidgetKey -> IO (InWidget message)
initAppNode ks resultUnboundedChannel node windowPtr =
    do
        inNode <- initNode ks resultUnboundedChannel node
        primIO $ prim_connectWidgetToWindow (getKey windowPtr) $ inWidgetHandle inNode
        pure inNode


public export windowToInitUI : KeySupplier -> ClosableUnboundedChannel message -> MutableCell (InWindow message) -> model -> Window message -> VoidPtr -> IO ()
windowToInitUI ks resultUnboundedChannel inViewCell model (MkWindow appNode title width height) appPtr =
    do
        windowHandle <- newKey ks
        primIO $ prim_newWindow title width height appPtr $ getKey windowHandle
        inNode <- initAppNode ks resultUnboundedChannel appNode windowHandle
        putMutableCell inViewCell $ MkInWindow inNode title width height $ getKey windowHandle
        -- inNodeId <- store $ MkInWindow inNode title width height (getKey windowHandle)
        -- primIO $ prim_setCell inNodeId
        primIO $ prim_presentWindow (getKey windowHandle)


-- public export runAppWindow : KeySupplier -> model -> Application -> Window -> IO ()
-- runAppWindow ks model initialView window =
--     do
--         let appPtr = prim_newApp "app.appid"
--         appCol <- onCollect appPtr appFree
--         connectApp appCol $ windowToInitUI ks model initialView window
--         r <- primIO $ prim_appRun appCol
--         print r
--         pure ()


public export runApp : KeySupplier -> ClosableUnboundedChannel message -> MutableCell (InWindow message) -> model -> Application message -> IO () -> IO Int
runApp ks resultUnboundedChannel inViewCell model (MkApplication window id) updateUI = 
    do
        let appPtr = prim_newApp id
        appCol <- onCollect appPtr appFree
        connectApp appCol (windowToInitUI ks resultUnboundedChannel inViewCell model window) updateUI
        primIO $ prim_appRun appCol
