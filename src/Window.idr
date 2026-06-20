module Window

import ApplicationNode.ApplicationNode
import Data
import Channel
import Foreign

public export data Window message = MkWindow (Widget message) String Int Int

public export data InWindow message = MkInWindow (InWidget message) String Int Int Int

replaceChildInWindow : KeySupplier -> ClosableUnboundedChannel msg -> Int -> WidgetKey -> (parentKey : WidgetKey) -> (replacement : Widget msg) -> IO $ InWidget msg
replaceChildInWindow ks channel windowHandle key parent replacement =
    do
        inWidget <- widgetToInWidget ks channel replacement
        let widgetKey = inWidgetKey inWidget

        primIO $ prim_replaceWidgetInWindow windowHandle $ getKey widgetKey
        primIO $ prim_deleteWidget $ getKey key

        pure $ inWidget

public export
diffWindow : KeySupplier -> ClosableUnboundedChannel message -> (InWindow message) -> (Window message) -> IO (InWindow message)
diffWindow ks channel (MkInWindow inWidget inTitle inWidth inHeight windowHandle) (MkWindow widget title width height) =
    do
        updatedWidget <- diffWidget ks channel inWidget widget $ replaceChildInWindow ks channel windowHandle $ inWidgetKey inWidget
        -- Need to also chuck in diffing for title, width, height. Not needed for examples so low priority. 
        pure $ MkInWindow updatedWidget title width height windowHandle
