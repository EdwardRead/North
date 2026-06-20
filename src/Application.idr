module Application

import Window
import Foreign
import Data

public export
data Application msg = MkApplication (Window msg) String

public export
data InApplication msg = MkInApplication (InWindow msg) String

buildUIPrimIO : (VoidPtr -> IO ()) -> VoidPtr -> PrimIO ()
buildUIPrimIO buildUIIOFunction appPtr = toPrim $ buildUIIOFunction appPtr

public export appFree : VoidPtr -> IO ()
appFree = primIO . prim_appFree

public export connectApp : GCPtr () -> (VoidPtr -> IO ()) -> IO () -> IO ()
connectApp appPtr callback updateUI = primIO $ prim_connectApp appPtr (buildUIPrimIO callback) $ toPrim updateUI
