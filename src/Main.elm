module Main exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Html.App as Html
import ConfigInput exposing (..)


main =
    Html.programWithFlags
        { init = init
        , subscriptions = \_ -> Sub.none
        , update = update
        , view = view
        }


type alias Model =
    { redmineConfig : ConfigInput.Config
    , togglConfig : ConfigInput.Config
    }


type alias Stored =
    { redmineKey : String, togglKey : String }


init : Stored -> ( Model, Cmd Msg )
init { redmineKey, togglKey } =
    ( Model (ConfigInput.init "redmine" "Redmine" redmineKey) (ConfigInput.init "toggl" "Toggl" togglKey)
    , Cmd.none
    )


type Msg
    = NoOp
    | UpdateConfig ConfigInput.Config ConfigInput.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        UpdateConfig model msg ->
            let
                ( subModel, subCmd ) =
                    ConfigInput.update msg model
            in
                ( { model | redmineConfig = subModel }, Cmd.map UpdateConfig subCmd )


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Zoupam v3" ]
        , Html.map (UpdateConfig model.redmineConfig) (ConfigInput.view model.redmineConfig)
        , Html.map (UpdateConfig model.togglConfig) (ConfigInput.view model.togglConfig)
        ]
