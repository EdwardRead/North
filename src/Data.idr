module Data

VoidPtr = Ptr ()

-- WidgetKey = Int

public export data Orientation = Vertical | Horizontal

-- For the rust code because transmitting enums is impossible (I think)
public export orientationToInt : Orientation -> Int
orientationToInt Vertical = 0
orientationToInt Horizontal = 1
