port module ConfigInput exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)


port saveKey : ( String, String ) -> Cmd msg


type alias Config =
    { id : String
    , label : String
    , value : String
    }


init : String -> String -> String -> Config
init id label key =
    Config id label key


type Msg
    = UpdateValue String


update : Msg -> Config -> ( Config, Cmd Msg )
update msg model =
    case msg of
        UpdateValue str ->
            ( { model | value = str }, saveKey ( model.id, str ) )


view : Config -> Html Msg
view model =
    div []
        [ label []
            [ text model.label ]
        , input
            [ onInput UpdateValue
            , value model.value
            ]
            []
        ]
