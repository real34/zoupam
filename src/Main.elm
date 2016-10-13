module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Events exposing (onClick)
import Configurator exposing (..)
import Http
import RedmineAPI
import TogglAPI
import Projects
import Issues


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
    , issues : Issues.Model
    }


init : ( Model, Cmd Msg )
init =
    let
        ( initModel, initCmd ) =
            Configurator.init
    in
        Model initModel Projects.init Issues.init
            ! [ Cmd.map UpdateConfig initCmd ]


type Msg
    = NoOp
    | UpdateConfig Configurator.Msg
    | UpdateProjects Projects.Msg
    | UpdateIssues Issues.Msg
    | Zou
    | FetchSuccess Http.Response
    | FetchFail Http.RawError


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            model ! []

        UpdateConfig msg ->
            let
                ( subConfig, subCmd ) =
                    Configurator.update msg model.config
            in
                { model | config = subConfig } ! [ Cmd.map UpdateConfig subCmd ]

        UpdateProjects msg ->
            let
                ( subProjects, subCmd ) =
                    Projects.update msg model.projects
            in
                { model | projects = subProjects } ! [ Cmd.map UpdateProjects subCmd ]

        UpdateIssues msg ->
            let
                ( subIssues, subCmd ) =
                    Issues.update msg model.issues
            in
                { model | issues = subIssues } ! [ Cmd.map UpdateIssues subCmd ]

        Zou ->
            model ! [ TogglAPI.getDetails FetchFail FetchSuccess ]

        FetchSuccess _ ->
            model ! []

        FetchFail _ ->
            model ! []


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
        , button [ onClick Zou ] [ text "Zou" ]
        , Issues.view (Configurator.getRedmineKey model.config) "104" model.issues
            |> Html.map UpdateIssues
        ]
