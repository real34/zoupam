module Views.TogglSelector exposing (TogglParams, fromUrl, emptyParams, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)

type alias TogglParams =
    { id : String
    , label : String
    , value : String
    , url : String
    }

fromUrl : String -> TogglParams
fromUrl url =
  { id = "", label = "", value = "", url = url}

emptyParams : TogglParams
emptyParams =
  { id = "", label = "", value = "", url = ""}

view : (String -> msg) -> TogglParams -> msg -> Html msg
view msg model zou =
    div []
      [ label [] [ text "Lien Toggl" ]
      , input [ onInput msg, value model.url, class "w-30 pa1" ] []
      , button [
            onClick zou,
            class "ml3 ph4 pv2 br-pill outline-0" ] [ text "Zou" ]
      ]
