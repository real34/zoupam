module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Configurator exposing (..)


main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { config : Configurator.Config }


init : ( Model, Cmd Msg )
init =
    let
        ( initModel, initCmd ) =
            Configurator.init
    in
        Model initModel
            ! [ Cmd.map UpdateConfig initCmd ]


type Msg
    = NoOp
    | UpdateConfig Configurator.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UpdateConfig msg ->
            let
                ( subConfig, subMsg ) =
                    Configurator.update msg model.config
            in
                { model | config = subConfig }
                    ! [ Cmd.map UpdateConfig subMsg ]


subscriptions : Model -> Sub Msg
subscriptions model =
    Configurator.subscriptions
        |> Sub.map UpdateConfig


view : Model -> Html Msg
view model =
    div []
        [ h1 [] [ text "Zoupam v3" ]
        , Configurator.view model.config
            |> Html.map UpdateConfig
        ]
