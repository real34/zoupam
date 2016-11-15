module Projects exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (value)
import RedmineAPI
import Http


type alias Model =
    { projects : Maybe (List ( Int, String ))
    , selected : Maybe String
    , loading : Bool
    , redmineKey : String
    }


type Msg
    = ProjectSelect String
    | FetchStart String
    | FetchEnd (Result Http.Error (List ( Int, String )))


init : Model
init =
    { projects = Nothing
    , selected = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyProject : ( Int, String )
emptyProject =
    ( -1, "--- Veuillez sélectionner un projet ---" )


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
            { model | loading = False, projects = Just (emptyProject :: fetchedProjects) } ! []

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
                        [ select [ onInput ProjectSelect ] (List.map (\( projectId, projectName ) -> option [ projectId |> toString |> value ] [ text projectName ]) projects)
                        ]

        True ->
            text "CHARGEMENT"
