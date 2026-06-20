module Examples.DelayedButton

import IdrisElm
import ApplicationNode.ApplicationNode
import Commands.Delay
import Commands.None
import Window
import System.Clock
import Subscriptions.None as Sub

data Model = Idle | Loading | Loaded

data Message = Started | Finished

fiveSeconds : Clock Duration
fiveSeconds = makeDuration 5 0

update : Message -> Model -> (Model, Command Message)
update Started _  = (Loading, delay fiveSeconds $ pure Finished)
update Finished _ = (Loaded, none)

view : Model -> Window Message
view model =
    MkWindow
        (
            case model of
                Idle    => button Started "Click me to start loading!"
                Loading => label "Loading........"
                Loaded  => label "Finished loading!!"
        )
        "Delayed Button"
        700 500

public export
delayedButton : IO ()
delayedButton = element Idle update view Sub.none
