module Commands.Delay

import IdrisElm
import Foreign
import Channel
import System.Clock

public export
delay : Clock Duration -> IO message -> Command message
delay duration f = Cmd $ \c => primIO $ prim_timeoutOnce (cast $ fromInteger $ toNano duration) $ toPrim $
    do
        r <- f
        unboundedChannelPut c $ Result r
