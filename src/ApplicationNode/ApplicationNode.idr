module ApplicationNode.ApplicationNode

import Foreign
import Store
import Data
import Data.IORef
import Decidable.Equality.Core
import Data.List
import Channel

export
data WidgetKey = MkWidgetKey Int

Show WidgetKey where
    show (MkWidgetKey x) = "Widget Key(" ++ show x ++ ")"

public export
getKey : WidgetKey -> Int
getKey (MkWidgetKey x) = x

public export
data DWithHandle a = Handle a WidgetKey

public export
getHandle : DWithHandle _ -> WidgetKey
getHandle (Handle _ h) = h

public export
data KeySupplier = MkKeySupplier (IORef Int)

public export
newKey : KeySupplier -> IO WidgetKey
newKey (MkKeySupplier k) =
    do
        current <- readIORef k
        writeIORef k $ current + 1
        pure (MkWidgetKey current)

mutual
    public export
    record Widget message where
        constructor MkWidget
        nodeType : Type
        node : nodeType
        inNodeType : Type
        { auto isApplicationNode : ApplicationNode nodeType inNodeType message }

    public export
    record InWidget message where
        constructor MkInWidget
        inNodeType : Type
        inNode : inNodeType
        nodeType : Type
        { auto isApplicationNode : ApplicationNode nodeType inNodeType message }

    public export
    interface ApplicationNode nodeType inNodeType message where
        toInNode : KeySupplier -> nodeType -> ClosableUnboundedChannel message -> IO inNodeType
        diff : KeySupplier -> ClosableUnboundedChannel message -> inNodeType -> nodeType -> IO inNodeType
        handle : inNodeType -> WidgetKey
        isNodeTypeSame : (t : Type) -> Maybe (nodeType = t)
        isInNodeTypeSame : (t : Type) -> Maybe (inNodeType = t)

public export
record RLabel where
    constructor Label
    text : String

public export
record RInLabel where
    constructor InLabel
    text : String
    handle : WidgetKey

public export
ApplicationNode RLabel RInLabel msg where
    diff ks _ (InLabel text handle) (Label newText) = 
        do
            primIO $ prim_setLabel (getKey handle) newText
            pure $ InLabel newText handle
    toInNode ks (Label text) _ = 
        do
            labelHandle <- newKey ks
            primIO $ prim_label text $ getKey labelHandle
            pure $ InLabel text labelHandle
    handle (InLabel _ h) = h
    isNodeTypeSame RLabel = Just Refl
    isNodeTypeSame _ = Nothing
    isInNodeTypeSame RInLabel = Just Refl
    isInNodeTypeSame _ = Nothing

public export
record RButton message where
    constructor Button
    label   : String
    onClick : message

public export
record RInButton message where
    constructor InButton
    label : String
    onClick : message
    handle : WidgetKey

public export
ApplicationNode (RButton message) (RInButton message) message where
    diff _ ks (InButton oldLabel oldOnClick handle) (Button newLabel newOnClick) =
        pure $ InButton newLabel newOnClick handle
    toInNode ks (Button label onClick) resultUnboundedChannel = 
        do
            buttonHandle <- newKey ks
            let appendMessageToUnboundedChannel = toPrim $ unboundedChannelPut resultUnboundedChannel $ Result onClick
            primIO $ prim_labelButton label appendMessageToUnboundedChannel (getKey buttonHandle)
            pure $ InButton label onClick buttonHandle
    handle (InButton _ _ h) = h
    isNodeTypeSame (RButton _) = Just (believe_me 0)
    isNodeTypeSame _ = Nothing
    isInNodeTypeSame (RInButton _) = Just (believe_me 0)
    isInNodeTypeSame _ = Nothing

public export
toWidget : {a : Type} -> {b : Type} -> {isApplicationNode : ApplicationNode a b msg} -> (node_ : a) -> Widget msg
toWidget {a} {b} {isApplicationNode} node = MkWidget a node b

public export
widgetEquality : (message : Type) -> (a : Widget message) -> (b : Widget message) -> Maybe (a.nodeType = b.nodeType)
widgetEquality msgType (MkWidget t1 _ inNodeType) (MkWidget t2 _ _) = isNodeTypeSame t2 { nodeType = t1, inNodeType = inNodeType, message = msgType }

inWidgetEquality : (message : Type) -> (a : InWidget message) -> (b : InWidget message) -> Maybe (a.inNodeType = b.inNodeType)
inWidgetEquality msgType (MkInWidget t1 _ nodeType) (MkInWidget t2 _ _) = isInNodeTypeSame t2 { nodeType = nodeType, inNodeType = t1, message = msgType }

public export
inWidgetKey : InWidget message -> WidgetKey
inWidgetKey (MkInWidget nodeType inNode inNodeType {isApplicationNode}) =
    handle @{isApplicationNode} inNode

public export
inWidgetHandle : InWidget message -> Int
inWidgetHandle = getKey . inWidgetKey

public export
record RBox boxMessageType where
    constructor Box
    orientation : Orientation
    spacing : Int
    children : List (Widget boxMessageType)

public export
record RInBox inBoxMessageType where
    constructor InBox
    orientation : Orientation
    spacing : Int
    children : List (InWidget inBoxMessageType)
    handle : WidgetKey

public export
widgetToInWidget : KeySupplier -> ClosableUnboundedChannel msg -> (Widget msg) -> IO (InWidget msg)
widgetToInWidget ks resultUnboundedChannel (MkWidget nodeType node inNodeType {isApplicationNode}) = 
    do
        inNode <- toInNode ks node resultUnboundedChannel
        pure $ MkInWidget inNodeType inNode nodeType

diffNodesHelper :   KeySupplier ->
                    ClosableUnboundedChannel messageType -> 
                    (inNodeType : Type) -> 
                    (inNode : inNodeType) -> 
                    (nodeType : Type) -> 
                    (node : nodeType) -> 
                    ApplicationNode nodeType inNodeType messageType -> 
                    IO (InWidget messageType)
diffNodesHelper ks channel inNodeType inNode nodeType node app =
    do
        newInNode <- diff ks channel inNode node {nodeType = nodeType, inNodeType = inNodeType, message = messageType}
        pure $ MkInWidget inNodeType newInNode nodeType

safeCast : (a : Type) -> a -> a = b -> b
safeCast _ x Refl = x

diffNodes :
  KeySupplier ->
  ClosableUnboundedChannel msg ->
  (inNodeTypeLeft : Type) ->
  (inNode : inNodeTypeLeft) ->
  (nodeTypeLeft : Type) ->
  (isApplicationNodeLeft : ApplicationNode nodeTypeLeft inNodeTypeLeft msg) ->
  (nodeTypeRight : Type) ->
  (node : nodeTypeRight) ->
  (inNodeTypeRight : Type) ->
  inNodeTypeLeft = inNodeTypeRight ->
  nodeTypeLeft = nodeTypeRight ->
  IO (InWidget msg)

diffNodes ks
          channel
          inNodeType
          inNode
          nodeType
          isApplicationNodeLeft
          nodeType
          node
          inNodeType
          left@Refl
          right@Refl =
                            diffNodesHelper
                                ks
                                channel
                                inNodeType
                                inNode
                                nodeType
                                node
                                isApplicationNodeLeft

appendWidgetToBox : WidgetKey -> InWidget msg -> IO ()
appendWidgetToBox boxHandle inWidget = primIO $ prim_appendWidgetToBox (getKey boxHandle) $ inWidgetHandle inWidget

replaceNode : InWidget msg -> Widget msg -> (WidgetKey -> Widget msg -> IO $ InWidget msg) -> IO (InWidget msg)
replaceNode left right replacer = 
    do
        let key = inWidgetKey left
        replacer key right

public export
data DiffResult message = Patch (InWidget message) | Replace (InWidget message)

public export
diffWidget : KeySupplier -> ClosableUnboundedChannel msg -> InWidget msg -> Widget msg -> ((parentKey : WidgetKey) -> (replacement : Widget msg) -> IO $ InWidget msg) -> IO $ InWidget msg
diffWidget  ks
            channel
            left@(MkInWidget inNodeTypeLeft inNode nodeTypeLeft    @{isApplicationNodeLeft}) 
            right@(MkWidget   nodeTypeRight  node   inNodeTypeRight @{isApplicationNodeRight})
            replacer = 
            case isNodeTypeSame {nodeType = nodeTypeLeft} {inNodeType = inNodeTypeLeft} {message = msg} nodeTypeRight of
                Just prf1 =>
                    case isInNodeTypeSame {nodeType = nodeTypeLeft} {inNodeType = inNodeTypeLeft} {message = msg} inNodeTypeRight of
                        Just prf2 => diffNodes ks channel inNodeTypeLeft inNode nodeTypeLeft isApplicationNodeLeft nodeTypeRight node inNodeTypeRight prf2 prf1
                        Nothing => replaceNode left right replacer
                Nothing => replaceNode left right replacer

traverseZip : (Traversable t, Zippable t, Applicative f) => (a -> b -> f c) -> t a -> t b -> f (t c)
traverseZip f left right = traverse (\(x, y) => f x y) $ zip left right

itraverseHelper : Monad f => Applicative f => (a -> Int -> f b) -> List a -> List b -> Int -> f (List b)
itraverseHelper f [] results _ = pure $ results
itraverseHelper f (x::xs) results i =
    do
        x' <- f x i
        itraverseHelper f xs (x'::results) $ i + 1

itraverse : Monad f => Applicative f => (a -> Int -> f b) -> List a -> f (List b)
itraverse f traversable = itraverseHelper f traversable [] 0

replaceChildInBox : KeySupplier -> ClosableUnboundedChannel message -> WidgetKey -> Int -> WidgetKey -> Widget message -> IO $ InWidget message
replaceChildInBox ks channel parentKey i key widget =
    do
        inWidget <- widgetToInWidget ks channel widget
        primIO $ prim_replaceWidgetInBox (getKey parentKey) i $ getKey $ inWidgetKey inWidget
        primIO $ prim_deleteWidget $ getKey key
        pure $ inWidget

public export
ApplicationNode (RBox msg) (RInBox msg) msg where
    diff ks channel (InBox orientation spacing inChildren key) (Box newOrientation newSpacing newChildren) =
        do
                diffedChildren <- itraverse (\(x, y) => \i => diffWidget ks channel x y $ replaceChildInBox ks channel key i) $ zip inChildren newChildren
                pure $ InBox newOrientation newSpacing diffedChildren key
    toInNode ks (Box orientation spacing children) resultUnboundedChannel =
        do
            boxHandle <- newKey ks
            primIO $ prim_box (orientationToInt orientation) spacing $ getKey boxHandle
            inChildren <- traverse (widgetToInWidget ks resultUnboundedChannel) children
            _ <- traverse (appendWidgetToBox boxHandle) inChildren
            pure $ InBox orientation spacing inChildren boxHandle
    handle (InBox _ _ _ h) = h
    isNodeTypeSame (RBox msg) = Just $ believe_me 0
    isNodeTypeSame _ = Nothing
    isInNodeTypeSame (RInBox msg) = Just $ believe_me 0
    isInNodeTypeSame _ = Nothing

Spacing = Int

public export
box : {msg : Type} -> Orientation -> Spacing -> List (Widget msg) -> Widget msg
box orientation spacing children = MkWidget (RBox msg) (Box orientation spacing children) (RInBox msg)

public export
label : String -> Widget msg
label text = MkWidget RLabel (Label text) RInLabel

public export
button : {msg : Type} -> (message : msg) -> String -> Widget msg
button {msg} message text = MkWidget (RButton msg) (Button text message) (RInButton msg)
