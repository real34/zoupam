module Projects exposing (..)

import Html exposing (..)
import Http
import Html.Events exposing (onClick)
import Json.Decode as Json exposing ((:=))
import Task


type alias Model =
    { projects : Maybe (List String)
    , loading : Bool
    }


type Msg
    = FetchSuccess (List String)
    | FetchFail Http.Error
    | Go


init : Model
init =
    { projects = Nothing
    , loading = False
    }


redmineUrl : String
redmineUrl =
    "http://projets.occitech.fr"


emptyProject : String
emptyProject =
    "--- Veuillez sélectionner un projet ---"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Go ->
            { model | loading = True } ! [ getProjects "2df7fd0acd7d7f09966a746458aa78ab3fdc6ebc" ]

        FetchSuccess projects ->
            { model | loading = False, projects = Just projects } ! []

        FetchFail error ->
            { model | loading = False } ! []


view : Model -> Html Msg
view model =
    case model.loading of
        False ->
            case model.projects of
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


getProjects : String -> Cmd Msg
getProjects key =
    let
        url =
            Http.url (redmineUrl ++ "/projects.json") [ ( "key", key ) ]
    in
        Http.get projectsDecoder url |> Task.perform FetchFail FetchSuccess


projectsDecoder : Json.Decoder (List String)
projectsDecoder =
    ("projects" := Json.list ("name" := Json.string))
