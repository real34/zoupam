module Projects exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (value)
import RedmineAPI exposing (Projects, Project)
import Http


type alias Model =
    { projects : Maybe ( Projects )
    , selected : Maybe String
    , loading : Bool
    , redmineKey : String
    }


type Msg
    = ProjectSelect String
    | FetchStart String
    | FetchEnd (Result Http.Error (Projects))


init : Model
init =
    { projects = Nothing
    , selected = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyProject : Project
emptyProject =
    {
        id = -1
        , name = "--- Veuillez sélectionner un projet ---"
        , status = 1
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchStart redmineKey ->
            let
                projects =
                    model.projects
            in
                { model | loading = True } ! [ RedmineAPI.getProjects redmineKey FetchEnd ]

        ProjectSelect projectId ->
            case projectId of
                "-1" ->
                    { model | selected = Nothing } ! []

                _ ->
                    { model | selected = Just projectId } ! []

        FetchEnd (Ok fetchedProjects) ->
            { model | loading = False, projects = Just (emptyProject :: fetchedProjects |> List.filter RedmineAPI.isActiveProject) } ! []

        FetchEnd (Err _) ->
            { model | loading = False } ! []


view : Model -> Html Msg
view model =
    case model.loading of
        False ->
            case model.projects of
                Nothing ->
                    div [] []

                Just projects ->
                    div []
                        [ select [ onInput ProjectSelect ] (List.map (
                            \( project ) -> option [ project.id |> toString |> value ] [ text project.name ]) projects
                        )
                        ]

        True ->
            text "CHARGEMENT"