module Projects exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (value)
import RedmineAPI
import Http


type alias Model =
    { projects : Maybe (List ( Int, String ))
    , loading : Bool
    , redmineKey : String
    }


type Msg
    = ProjectSelect String
    | Go String
    | FetchSuccess (List ( Int, String ))
    | FetchFail Http.Error


init : Model
init =
    { projects = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyProject : ( Int, String )
emptyProject =
    ( -1, "--- Veuillez sélectionner un projet ---" )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Go redmineKey ->
            let
                projects =
                    model.projects
            in
                { model | loading = True } ! [ RedmineAPI.getProjects redmineKey FetchFail FetchSuccess ]

        ProjectSelect projectId ->
            model ! []

        FetchSuccess fetchedProjects ->
            { model | loading = False, projects = Just (emptyProject :: fetchedProjects) } ! []

        FetchFail error ->
            { model | loading = False } ! []


view : String -> Model -> Html Msg
view redmineKey model =
    case model.loading of
        False ->
            case model.projects of
                Nothing ->
                    div []
                        [ button [ onClick (Go redmineKey) ] [ text "Go!" ]
                        ]

                Just projects ->
                    div []
                        [ select [ onInput ProjectSelect ] (List.map (\( projectId, projectName ) -> option [ projectId |> toString |> value ] [ text projectName ]) projects)
                        , button [ onClick (Go redmineKey) ] [ text "Go!" ]
                        ]

        True ->
            text "CHARGEMENT"
