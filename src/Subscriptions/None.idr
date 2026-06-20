module Subscriptions.None

import IdrisElm
import Channel

public export
none : Subscription message
none = Sub $ \_ => pure ()
