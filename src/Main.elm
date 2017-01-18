module Main exposing (..)

import Html exposing (..)
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

                oldRedmineKey =
                    Configurator.getRedmineKey model.config

                ( subProjects, subCmdProjects ) =
                    case Configurator.getRedmineKey subConfig of
                        "" ->
                            model ! []

                        redmineKey ->
                            if redmineKey == oldRedmineKey then
                                model ! []
                            else
                                update
                                    (redmineKey
                                        |> Projects.FetchStart
                                        |> UpdateProjects
                                    )
                                    model
            in
                { model | config = subConfig, projects = subProjects.projects } ! [ Cmd.map UpdateConfig subCmd, subCmdProjects ]

        UpdateProjects msg ->
            let
                ( subProjects, subCmd ) =
                    Projects.update msg model.projects

                ( subIssues, subCmdIssues ) =
                    case subProjects.selected of
                        Nothing ->
                            ( model, Cmd.none )

                        Just selected ->
                            update
                                (selected
                                    |> Issues.GoIssues (Configurator.getRedmineKey model.config)
                                    |> UpdateIssues
                                )
                                model
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
        , Issues.view model.issues (Configurator.getTogglKey model.config)
            |> Html.map UpdateIssues
        , h2 [] [text "Où trouver vos clé API ?"]
        , div [] [text "Votre clé Redmine est accessible depuis ce lien: http://projets.occitech.fr/my/account pour obtenir votré clé il suffit de cliquer sur 'Afficher' en dessous de 'Clé d'accès API' "]
        , div [] [text "Votre clé Toggl est accessible depuis ce lien: https://toggl.com/app/profile"]
        ]
