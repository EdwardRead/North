module Channel

import System.Concurrency
import Data.IORef
import Data.SnocList

public export
data ClosableResult a = CloseSignal | Result a

ClosableChannel a = Channel (ClosableResult a)

public export
record UnboundedChannel a where
    constructor MkUnboundedChannel
    buffer : IORef (List a)
    mutex : Mutex
    isNotEmpty : Condition

public export
makeUnboundedChannel : IO (UnboundedChannel a)
makeUnboundedChannel =
    do
        buffer <- newIORef Nil
        mutex <- makeMutex
        isNotEmpty <- makeCondition
        pure $ MkUnboundedChannel buffer mutex isNotEmpty

public export
unboundedChannelPut : UnboundedChannel a -> a -> IO ()
unboundedChannelPut (MkUnboundedChannel bufferIORef mutex isNotEmpty) value =
    do
        mutexAcquire mutex
        buffer <- readIORef bufferIORef
        writeIORef bufferIORef $ buffer ++ [value]
        conditionSignal isNotEmpty
        mutexRelease mutex

unboundedChannelGetLoop : UnboundedChannel a -> IO (a, List a)
unboundedChannelGetLoop channel@(MkUnboundedChannel bufferIORef mutex isNotEmpty) =
    do
        buffer <- readIORef bufferIORef
        case buffer of
            [] => 
                conditionWait isNotEmpty mutex >> unboundedChannelGetLoop channel
            (x::xs) => pure (x, xs)

public export
unboundedChannelGet : UnboundedChannel a -> IO a
unboundedChannelGet channel@(MkUnboundedChannel bufferIORef mutex _) =
    do
        mutexAcquire mutex
        (x, xs) <- unboundedChannelGetLoop channel
        writeIORef bufferIORef xs
        mutexRelease mutex
        pure x

ClosableUnboundedChannel a = UnboundedChannel (ClosableResult a)

