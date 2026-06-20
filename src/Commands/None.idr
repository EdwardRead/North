module Commands.None

import IdrisElm
import Channel

public export
none : Command message
none = Cmd $ \_ => pure ()
