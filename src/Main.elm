module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Events exposing (onClick)
import Configurator exposing (..)
import Http
import RedmineAPI


main =
    Html.program
        { init = init
        , subscriptions = subscriptions
        , update = update
        , view = view
        }


type alias Model =
    { config : Configurator.Config
    , projects :
        { projects : Maybe (List String)
        , loading : Bool
        , redmineKey : String
        }
    }


initProjects =
    { projects = Nothing
    , loading = False
    , redmineKey = ""
    }


init : ( Model, Cmd Msg )
init =
    let
        ( initModel, initCmd ) =
            Configurator.init
    in
        Model initModel initProjects
            ! [ Cmd.map UpdateConfig initCmd ]


type Msg
    = NoOp
    | UpdateConfig Configurator.Msg
    | FetchSuccess (List String)
    | FetchFail Http.Error
    | Go


emptyProject : String
emptyProject =
    "--- Veuillez sélectionner un projet ---"


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

        Go ->
            let
                projects =
                    model.projects
            in
                { model | projects = { projects | loading = True } } ! [ RedmineAPI.getProjects (Configurator.getRedmineKey model.config) FetchFail FetchSuccess ]

        FetchSuccess fetchedProjects ->
            let
                projects =
                    model.projects
            in
                { model | projects = { projects | loading = False, projects = Just (emptyProject :: fetchedProjects) } } ! []

        FetchFail error ->
            let
                projects =
                    model.projects
            in
                { model | projects = { projects | loading = False } } ! []


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
        , case model.projects.loading of
            False ->
                case model.projects.projects of
                    Nothing ->
                        div []
                            [ button [ onClick Go ] [ text "Go!" ]
                            ]

                    Just projects ->
                        div []
                            [ select [] (List.map (\project -> option [] [ text project ]) projects)
                            , button [ onClick Go ] [ text "Go!" ]
                            ]

            True ->
                text "CHARGEMENT"
        ]
