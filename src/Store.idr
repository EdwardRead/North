module Store

import System
import Foreign
import Data.List
import Data.IORef
import System.File
import Data.String

-- Dodgy way of transmitting the data around. Not sure how else to do it. 

nextHandle : IORef Int
nextHandle = unsafePerformIO (newIORef 0)

-- Need to make this actually a table as the name implies and not just a list. 
handleTable : IORef (List (Int, t))
handleTable = unsafePerformIO (newIORef [])

-- Locking?
newHandle : IO Int
newHandle = do
  h <- readIORef nextHandle
  writeIORef nextHandle (h + 1)
  pure h

public export store : t -> IO Int
store obj = do
  h <- newHandle
  modifyIORef handleTable ((h, obj) ::)
  pure h

public export lookupHandleT : (t : Type) -> Int -> IO (Maybe t)
lookupHandleT _ h =
    do
        tbl <- readIORef handleTable
        pure (search h tbl)
        where
            search : Int -> List (Int, a) -> Maybe a
            search _ [] = Nothing
            search k ((k2, v) :: rest) =
                if k == k2 then Just v else search k rest

lookupHandle : Int -> IO (Maybe t)
lookupHandle h = do
  tbl <- readIORef handleTable
  pure (search h tbl)
  where
    search : Int -> List (Int, a) -> Maybe a
    search _ [] = Nothing
    search k ((k2, v) :: rest) =
      if k == k2 then Just v else search k rest

queuePushObj : t -> IO ()
queuePushObj x = do
  h <- store x
  primIO $ prim_queuePush h

public export queuePopObjT : (t : Type) -> IO (Maybe t)
queuePopObjT _ = do
    h <- primIO $ prim_queuePop
    lookupHandle h