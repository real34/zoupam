module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Configurator exposing (..)
import Http
import RedmineAPI
import Projects


main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { config : Configurator.Config
    , projects : Projects.Model
    }


init : ( Model, Cmd Msg )
init =
    let
        ( initModel, initCmd ) =
            Configurator.init
    in
        Model initModel Projects.init
            ! [ Cmd.map UpdateConfig initCmd ]


type Msg
    = NoOp
    | UpdateConfig Configurator.Msg
    | UpdateProjects Projects.Msg


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

        UpdateProjects msg ->
            let
                ( subProjects, subMsg ) =
                    Projects.update msg model.projects
            in
                { model | projects = subProjects }
                    ! [ Cmd.map UpdateProjects subMsg ]


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
        , Projects.view (Configurator.getRedmineKey model.config) model.projects
            |> Html.map UpdateProjects
        ]
