module Examples.Counter

import Window
import ApplicationNode.ApplicationNode
import IdrisElm
import Data

Model = Int

data Message = Increment | Decrement

initial : Model
initial = 0

update : Message -> Model -> Model
update Increment model = model + 1
update Decrement model = model - 1

viewUI : Model -> Widget Message
viewUI 10 = label "You reached 10!"
viewUI model = box
                    Vertical 
                    60 
                    [
                        button Increment "+", 
                        label (show model), 
                        button Decrement "-"
                    ]

view : Model -> Window Message
view model =
    MkWindow
        (
            viewUI model
        )
        "Click to 10!"
        700 500

public export
counter : IO ()
counter =
    do
        sandbox initial update view
