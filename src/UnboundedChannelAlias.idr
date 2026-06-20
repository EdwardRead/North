module UnboundedChannelAlias

import Channel

Channel a = UnboundedChannel a

public export
makeChannel : IO (Channel a)
makeChannel = makeUnboundedChannel

public export
channelGet : Channel a -> IO a
channelGet = unboundedChannelGet

public export
channelPut : Channel a -> a -> IO ()
channelPut = unboundedChannelPut

ClosableChannel a = Channel (ClosableResult a)
