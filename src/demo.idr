public export
data Subscription message = Sub (ClosableUnboundedChannel message -> IO ())

public export
data Command message = Cmd (ClosableUnboundedChannel message -> IO ())

httpCommand : ClosableUnboundedChannel message -> IO ()
httpCommand channel = httpGet "example.com" >>= channelPut channel
