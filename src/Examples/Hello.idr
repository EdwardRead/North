module Examples.Hello

import IdrisElm
import ApplicationNode.ApplicationNode
import Window

public export
hello : IO ()
hello = node $ MkWindow 
                    (label "Hello, World!") 
                    "Hello App" 
                    700 500
