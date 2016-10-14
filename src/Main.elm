module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Configurator exposing (..)
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
    = UpdateConfig Configurator.Msg
    | UpdateProjects Projects.Msg
    | UpdateIssues Issues.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        UpdateConfig msg ->
            let
                ( subConfig, subCmd ) =
                    Configurator.update msg model.config

                ( subProjects, subCmdProjects ) = case Configurator.getRedmineKey subConfig of
                  "" -> model ! []
                  redmineKey -> update (UpdateProjects (redmineKey |> Projects.FetchStart)) model
            in
                { model | config = subConfig , projects = subProjects.projects } ! [ Cmd.map UpdateConfig subCmd, subCmdProjects ]

        UpdateProjects msg ->
            let
                ( subProjects, subCmd ) =
                    Projects.update msg model.projects

                (subIssues, subCmdIssues) = case subProjects.selected of
                  Nothing -> (model, Cmd.none)
                  Just selected -> update (UpdateIssues (Issues.GoIssues (Configurator.getRedmineKey model.config) selected)) model
            in
                { model | projects = subProjects, issues = subIssues.issues } ! [ Cmd.map UpdateProjects subCmd, subCmdIssues ]

        UpdateIssues msg ->
            let
                ( subIssues, subCmd ) =
                    Issues.update msg model.issues
            in
                { model | issues = subIssues } ! [ Cmd.map UpdateIssues subCmd ]

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
        , Projects.view model.projects
            |> Html.map UpdateProjects
        , Issues.view model.issues
            |> Html.map UpdateIssues
        ]
