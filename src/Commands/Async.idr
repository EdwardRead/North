module Commands.Async

import IdrisElm
import Channel
import Foreign

public export
async : IO message -> Command message
async f = Cmd $ \c => primIO $ prim_mainThread $ toPrim $
    do
        r <- f
        unboundedChannelPut c $ Result r
