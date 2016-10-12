module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Events exposing (onClick)
import Configurator exposing (..)
import Http
import RedmineAPI
import TogglAPI
import Projects
import Dict exposing (Dict)
import Debug


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
    , issues : Dict String (List RedmineAPI.Issue)
    }


init : ( Model, Cmd Msg )
init =
    let
        ( initModel, initCmd ) =
            Configurator.init
    in
        Model initModel Projects.init Dict.empty
            ! [ Cmd.map UpdateConfig initCmd ]


type Msg
    = NoOp
    | UpdateConfig Configurator.Msg
    | UpdateProjects Projects.Msg
    | Zou
    | GoIssues
    | FetchSuccess Http.Response
    | FetchFail Http.RawError
    | Fail Http.Error
    | Success (List RedmineAPI.Issue)


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

        GoIssues ->
            model ! [ RedmineAPI.getIssues (Configurator.getRedmineKey model.config) "104" Fail Success ]

        Zou ->
            model ! [ TogglAPI.getDetails FetchFail FetchSuccess ]

        FetchSuccess _ ->
            model ! []

        FetchFail _ ->
            model ! []

        Success issues ->
            let
                filteredIssues =
                    List.foldr issuesToDict Dict.empty issues
            in
                { model | issues = filteredIssues }
                    ! []
                    |> Debug.log "model"

        Fail error ->
            model ! []


issuesToDict : RedmineAPI.Issue -> Dict String (List RedmineAPI.Issue) -> Dict String (List RedmineAPI.Issue)
issuesToDict issue dict =
    let
        version =
            Maybe.withDefault { id = 0, name = "Unknown" } issue.version

        existing =
            Dict.get (version.name) dict
    in
        case existing of
            Nothing ->
                Dict.insert version.name [ issue ] dict

            Just list ->
                Dict.insert version.name (issue :: list) dict


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
        , button [ onClick GoIssues ] [ text "Load Issues" ]
        , button [ onClick Zou ] [ text "Zou" ]
        , div []
            (List.map
                (\( key, issues ) ->
                    div []
                        [ h3 [] [ text key ]
                        , div [] (List.map (\issue -> h4 [] [ text issue.subject ]) issues)
                        ]
                )
                (Dict.toList model.issues)
            )
        ]
