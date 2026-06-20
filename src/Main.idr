module Main

import Examples.DelayedButton
import Examples.Counter
import Examples.Timer

main : IO ()
main = do
    counter
    delayedButton
    timer
