module Grid (Grid, fromList, map, make, rotate, stamp, collide, mapToList, clearLines, centerOfMass, width, height) where
import Array exposing (Array)


type alias Grid a = Array (Array (Maybe a))


fromList : List (List (Maybe a)) -> Grid a
fromList listOfLists =
  List.map Array.fromList listOfLists |> Array.fromList


map : (a -> b) -> Grid a -> Grid b
map fun grid =
  Array.map (\row -> Array.map (Maybe.map fun) row) grid


make : Int -> Int -> (Int -> Int -> Maybe a) -> Grid a
make w h f =
  Array.initialize h (\y -> Array.initialize w (\x -> f x y))


get : Int -> Int -> Grid a -> Maybe a
get x y grid =
  let
    row = Maybe.withDefault Array.empty (Array.get y grid)
  in
    Maybe.withDefault Nothing (Array.get x row)


height : Grid a -> Int
height =
  Array.length


width : Grid a -> Int
width grid =
  Maybe.map Array.length (Array.get 0 grid)
  |> Maybe.withDefault 0


rotate : Bool -> Grid a -> Grid a
rotate clockwise grid =
  let
    wid = width grid
    hei = height grid
    fn x y =
      if clockwise then
        get y (hei - x - 1) grid
      else
        get (wid - y - 1) x grid
  in
    make hei wid fn


stamp : Int -> Int -> Grid a -> Grid a -> Grid a
stamp x y sample grid =
  let
    fn x' y' =
      Maybe.oneOf
        [ get (x' - x) (y' - y) sample
        , get x' y' grid
        ]
  in
    make (width grid) (height grid) fn


-- collides a positioned sample with a grid and its bounds
collide : Int -> Int -> Grid a -> Grid a -> Bool
collide x y sample grid =
  let
    wid = width grid
    hei = height grid
    collideCell x' y' _ =
      if (x' + x >= wid) || (x' + x < 0) || (y + y' >= hei) then
        True
      else
        case get (x' + x) (y' + y) grid of
          Just value -> True
          Nothing -> False
  in
    mapToList collideCell sample |> List.any identity


mapToList : (Int -> Int -> a -> b) -> Grid a -> List b
mapToList fun grid =
  let
    processCell y (x, cell) =
      Maybe.map (fun x y) cell
    processRow y row =
      List.filterMap (processCell y) (Array.toIndexedList row)
  in
    Array.indexedMap processRow grid
    |> Array.toList
    |> List.concat


clearLines : Grid a -> (Grid a, Int)
clearLines grid =
  let
    keep row = List.any ((==) Nothing) (Array.toList row)
    grid' = Array.filter keep grid
    lines = height grid - height grid'
    add = make (width grid) lines (\_ _ -> Nothing)
  in
    (Array.append add grid', lines)


centerOfMass : Grid a -> (Int, Int)
centerOfMass grid =
  let
    boxes = mapToList (\x y _ -> (toFloat x, toFloat y)) grid
    len = toFloat (List.length boxes)
    (x, y) = List.unzip boxes
  in
    (round (List.sum x / len), round (List.sum y / len))
