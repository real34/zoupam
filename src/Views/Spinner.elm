module Views.Spinner exposing (view)

import Html exposing (..)
import Html.Attributes exposing (class)


view : Html msg
view =
    div [ class "tc ma5" ] [ i [ class "fa fa-spinner fa-pulse fa-5x" ] [] ]
