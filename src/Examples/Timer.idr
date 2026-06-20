module Examples.Timer

import System.Clock
import IdrisElm
import Window
import ApplicationNode.ApplicationNode
import Commands.Async
import Commands.None

data Model = AwaitingClick | Clicked (Clock Duration)

data Message = Click | Update (Clock Duration)

update : Message -> Model -> (Model, Command Message)
update Click _ = (Clicked $ makeDuration 0 0, none)
update (Update duration) (Clicked current) = (Clicked $ addDuration current duration, none)
update _ AwaitingClick = (AwaitingClick, none)

view : Model -> Window Message
view AwaitingClick =
    MkWindow
        (
            button Click "Click me!"
        )
        "Timer App"
        700 500
view (Clicked clock) =
    MkWindow
        (
            label $ show $ (toNano clock) `div` 1000000000
        )
        "Timer App"
        700 500

subscriptions : Subscription Message
subscriptions = timerSubscription (fromNano $ 1000000000 `div` 20) Update

public export
timer : IO ()
timer =
    do 
        element AwaitingClick update view subscriptions
