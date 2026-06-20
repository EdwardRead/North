module IdrisElm

import System
import Foreign
import Data.List
import Data.IORef
import System.File
import Data.String
import Store
import ApplicationNode.ApplicationNode
import InApplicationNode
import Window
import Data
import Application
import RenderVirtual
import System.Clock
import Channel
import MutableCell
import System.Concurrency

public export
data Command message = Cmd (ClosableUnboundedChannel message -> IO ())

mainThread : IO () -> IO ()
mainThread f = primIO $ prim_mainThread (toPrim f)

public export singleWindowApplication : Window message -> String -> Application message
singleWindowApplication x id = MkApplication x id

public export
data Subscription message = Sub (ClosableUnboundedChannel message -> IO ())

runSubscription : Subscription message -> ClosableUnboundedChannel message -> IO ()
runSubscription (Sub f) c = f c

sendNTimes : Integer -> message -> ClosableUnboundedChannel message -> IO ()
sendNTimes 0 _ _ = pure()
sendNTimes n message unboundedChannel = unboundedChannelPut unboundedChannel (Result message) >> sendNTimes (n - 1) message unboundedChannel

periodicTimerSubscriptionHelper : Clock Monotonic -> Clock Duration -> (Clock Monotonic -> message) -> ClosableUnboundedChannel message -> IO ()
periodicTimerSubscriptionHelper origin duration messageFunction unboundedChannel =
    do
        primIO $ prim_sleepNanos (fromInteger $ toNano duration)
        current <- clockTime Monotonic
        let difference = toNano $ timeDifference current origin
        let nanoDuration = toNano duration
        let divided = difference `div` nanoDuration
        -- printLn divided
        let newOrigin = addDuration origin (fromNano $ nanoDuration * divided)
        let message = messageFunction newOrigin
        sendNTimes divided message unboundedChannel
        periodicTimerSubscriptionHelper newOrigin duration messageFunction unboundedChannel

public export
periodicTimerSubscription : Clock Duration -> (Clock Monotonic -> message) -> Subscription message
periodicTimerSubscription duration messageFunction = Sub $ \unboundedChannel =>
    do
        origin <- clockTime Monotonic
        _ <- fork $ periodicTimerSubscriptionHelper origin duration messageFunction unboundedChannel
        pure ()

timerSubscriptionHelper : Clock Monotonic -> Clock Duration -> (Clock Duration -> message) -> ClosableUnboundedChannel message -> IO ()
timerSubscriptionHelper origin duration messageFunction unboundedChannel =
    do
        primIO $ prim_sleepNanos (fromInteger $ toNano duration)
        current <- clockTime Monotonic
        let clockDifference = timeDifference current origin
        newOrigin <- clockTime Monotonic--addDuration origin (fromNano $ nanoDuration * divided)
        let message = messageFunction clockDifference
        unboundedChannelPut unboundedChannel $ Result message
        timerSubscriptionHelper newOrigin duration messageFunction unboundedChannel

public export
timerSubscription : Clock Duration -> (Clock Duration -> message) -> Subscription message
timerSubscription duration messageFunction = Sub $ \unboundedChannel =>
    do
        origin <- clockTime Monotonic
        originIO <- newIORef origin
        primIO $ prim_scheduleTimeoutRepeating (fromInteger $ toNano duration) $ toPrim $
            do
                previous <- readIORef originIO
                current <- clockTime Monotonic
                writeIORef originIO current

                unboundedChannelPut unboundedChannel $ Result $ messageFunction $ timeDifference current previous
        pure ()

unboundedChannelFold : (a -> b -> b) -> ClosableUnboundedChannel a -> b -> IO b
unboundedChannelFold f unboundedChannel initial =
    do
        unboundedChannelGetResult <- unboundedChannelGet unboundedChannel
        case unboundedChannelGetResult of
            Result r  => unboundedChannelFold f unboundedChannel $ f r initial
            CloseSignal => pure initial

unboundedChannelProcess : (a -> IO ()) -> ClosableUnboundedChannel a -> IO ()
unboundedChannelProcess f unboundedChannel =
    do
        unboundedChannelGetResult <- unboundedChannelGet unboundedChannel
        case unboundedChannelGetResult of
            Result r => 
                do
                    f r
                    unboundedChannelProcess f unboundedChannel
            CloseSignal =>
                pure ()

commandLoop : ClosableUnboundedChannel (Command message) -> ClosableUnboundedChannel message -> IO ()
commandLoop taskUnboundedChannel resultUnboundedChannel =
    do
        taskOrClose <- unboundedChannelGet taskUnboundedChannel
        case taskOrClose of
            CloseSignal => pure ()
            Result (Cmd task) =>
                do
                    task resultUnboundedChannel
                    commandLoop taskUnboundedChannel resultUnboundedChannel

collectThreadIds : ClosableUnboundedChannel ThreadID -> List ThreadID -> IO (List ThreadID)
collectThreadIds unboundedChannel xs =
    do
        m <- unboundedChannelGet unboundedChannel
        case m of
            CloseSignal => pure xs
            Result x => collectThreadIds unboundedChannel $ x::xs

awaitThreadIds : List ThreadID -> IO ()
awaitThreadIds [] = pure ()
awaitThreadIds (x::xs) =
    do
        threadWait x
        awaitThreadIds xs

-- commandLoop : ClosableUnboundedChannel (Command message) -> ClosableUnboundedChannel message -> IO ()
-- commandLoop taskUnboundedChannel resultUnboundedChannel =
--         commandLoopHelper taskUnboundedChannel resultUnboundedChannel


makeTaskUnboundedChannel : (message : Type) -> IO (ClosableUnboundedChannel (Command message), ClosableUnboundedChannel message)
makeTaskUnboundedChannel msgType =
    do
        leftUnboundedChannel <- makeUnboundedChannel
        rightUnboundedChannel <- makeUnboundedChannel
        pure (leftUnboundedChannel, rightUnboundedChannel)

inputCommandToTaskUnboundedChannel : ClosableUnboundedChannel (Command message) -> Command message -> IO ()
inputCommandToTaskUnboundedChannel channel command = unboundedChannelPut channel $ Result command
-- inputCommandToTaskUnboundedChannel _ None = pure ()
-- inputCommandToTaskUnboundedChannel taskUnboundedChannel (Of task) = unboundedChannelPut taskUnboundedChannel $ Result task
-- inputCommandToTaskUnboundedChannel taskUnboundedChannel (Batch tasks) = traverse_ (inputCommandToTaskUnboundedChannel taskUnboundedChannel) (map Of tasks)

-- Batch updates, only view once per batch. 

integerToInt : Integer -> Int
integerToInt = cast

refreshInterval : Integer
refreshInterval = 1000000000 `div` 30

-- renderLoop : Eq model => KeySupplier -> InWindow message -> (model -> Window message) -> ClosableChannel model -> IO ()
-- renderLoop ks inView view stateCell =
--     do
--         start <- clockTime Monotonic
        
--         printLn "Waiting1..."
--         retrieved <- channelGet stateCell
--         printLn "Done waiting!"
--         case retrieved of
--             CloseSignal => pure ()
--             Result result =>
--                 do
--                     let updatedView = view result
--                     printLn "Pre-diffing..."
--                     inView' <- diffWindow ks inView updatedView
--                     printLn "Post-diffing!"
--                     end <- clockTime Monotonic
--                     let elapsed = toNano (timeDifference end start)
--                     let sleepTime = integerToInt $ refreshInterval - elapsed
--                     when (sleepTime > 0) $ primIO $ prim_sleepNanos sleepTime
--                     renderLoop ks inView' view stateCell

updateUI : KeySupplier -> ClosableUnboundedChannel message -> (model -> Window message) -> MutableCell model -> MutableCell (InWindow message) -> IO ()
updateUI ks channel view stateCell inViewCell =
    do
        maybeState <- takeMutableCellNonBlocking stateCell
        case maybeState of
            Nothing => pure ()
            Just retrieved =>
                do
                    let updatedView = view retrieved
                    inView <- getMutableCell inViewCell
                    inView' <- diffWindow ks channel inView updatedView
                    putMutableCell inViewCell inView'

public export
element : {message : Type} ->
                       model ->
                       (message -> model -> (model, Command message)) ->
                       (model -> Window message) ->
                       Subscription message ->
                       IO ()
element {message} mdl update view subscriptions =
    do
        (taskUnboundedChannel, resultUnboundedChannel) <- makeTaskUnboundedChannel message
        s <- newIORef 0
        let ks = MkKeySupplier s
        let initialView = view mdl
        stateCell  <- newMutableCell mdl
        inViewCell <- newEmptyMutableCell
        tid <- fork $ eventLoop ks mdl taskUnboundedChannel resultUnboundedChannel stateCell
        tid2 <- fork $ commandLoop taskUnboundedChannel resultUnboundedChannel
        runSubscription subscriptions resultUnboundedChannel
        r <- runApp ks resultUnboundedChannel inViewCell mdl (MkApplication initialView "app.appid") $ updateUI ks resultUnboundedChannel view stateCell inViewCell
        unboundedChannelPut taskUnboundedChannel CloseSignal
        unboundedChannelPut resultUnboundedChannel CloseSignal
        threadWait tid
        threadWait tid2
        printLn r
    where
        eventLoop : KeySupplier -> model -> ClosableUnboundedChannel (Command message) -> ClosableUnboundedChannel message -> MutableCell model -> IO ()
        eventLoop ks model taskUnboundedChannel resultUnboundedChannel stateCell =
            do
                closeOrResult <- unboundedChannelGet resultUnboundedChannel
                case closeOrResult of
                    CloseSignal => pure ()
                    Result r =>
                        do
                            let (updatedModel, command) = update r model
                            putMutableCell stateCell updatedModel
                            inputCommandToTaskUnboundedChannel taskUnboundedChannel command
                            eventLoop ks updatedModel taskUnboundedChannel resultUnboundedChannel stateCell

public export
node : Window () -> IO ()
node virtual = element () (\x => \y => (x, Cmd $ \_ => pure ())) (\x => virtual) $ Sub $ \_ => pure ()

public export
sandbox :   {message : Type} ->
            model ->
            (message -> model -> model) ->
            (model -> Window message) ->
            IO ()
sandbox initial update view =
    do
        let cmdUpdate = \x => \y => (update x y, Cmd $ \_ => pure ())
        element initial cmdUpdate view $ Sub $ \_ => pure ()
