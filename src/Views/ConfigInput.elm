module Views.ConfigInput exposing (Field, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


type alias Field =
    { id : String
    , label : String
    , value : String
    }


view : (String -> msg) -> Field -> Html msg
view msg field =
    div []
        [ label [ for field.id ] [ text field.label ]
        , input [ id field.id, onInput msg, value field.value ] []
        ]
