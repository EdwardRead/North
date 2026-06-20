module MutableCell

import System.Concurrency
import Data.IORef

public export
record MutableCell a where
    constructor MkMutableCell
    mutex   : Mutex
    full    : Condition
    empty   : Condition
    content : IORef (Maybe a)
    
public export
newEmptyMutableCell : IO (MutableCell a)
newEmptyMutableCell = do
  mutex <- makeMutex
  full <- makeCondition
  empty <- makeCondition
  emptyContent <- newIORef Nothing
  pure $ MkMutableCell mutex full empty emptyContent

public export
newMutableCell : a -> IO $ MutableCell a
newMutableCell val = do
    mutex <- makeMutex
    full <- makeCondition
    empty <- makeCondition
    fullContent <- newIORef $ Just val
    pure $ MkMutableCell mutex full empty fullContent


getLoop : MutableCell a -> IO a
getLoop cell@(MkMutableCell mutex full empty content) =
    do
        readContent <- readIORef content
        case readContent of
            Just v =>
                mutexRelease mutex >>
                pure v
            Nothing =>
                conditionWait cell.full cell.mutex >>
                getLoop cell

public export
getMutableCell : MutableCell a -> IO a
getMutableCell cell@(MkMutableCell mutex full empty content) = 
    do
        mutexAcquire cell.mutex
        getLoop cell

takeLoop : MutableCell a -> IO a
takeLoop cell@(MkMutableCell mutex full empty content) =
    do
        readContent <- readIORef content
        case readContent of
            Just v =>
                writeIORef content Nothing >>
                mutexRelease mutex >>
                pure v
            Nothing =>
                conditionWait cell.full cell.mutex >>
                getLoop cell

public export
takeMutableCell : MutableCell a -> IO a
takeMutableCell cell@(MkMutableCell mutex full empty content) =
    do
        mutexAcquire mutex
        takeLoop cell

isJust : Maybe a -> Bool
isJust Nothing = False
isJust _ = True

-- This not fully non-blocking, needs to be altered (LOW priority)
public export
takeMutableCellNonBlocking : MutableCell a -> IO (Maybe a)
takeMutableCellNonBlocking (MkMutableCell mutex full empty content) = do
    mutexAcquire mutex
    read <- readIORef content
    when (isJust read) $ writeIORef content Nothing
    mutexRelease mutex
    pure read

public export
putMutableCell : MutableCell a -> a -> IO ()
putMutableCell (MkMutableCell mutex full empty content) val = do
    mutexAcquire mutex
    writeIORef content $ Just val
    conditionSignal full
    mutexRelease mutex

public export
getMutableCellNonBlocking : MutableCell a -> IO (Maybe a)
getMutableCellNonBlocking (MkMutableCell mutex full empty content) = do
    mutexAcquire mutex
    read <- readIORef content
    mutexRelease mutex
    pure read
