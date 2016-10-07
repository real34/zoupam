module Projects exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import RedmineAPI
import Http


type alias Model =
    { projects : Maybe (List String)
    , loading : Bool
    , redmineKey : String
    }


type Msg
    = FetchSuccess (List String)
    | FetchFail Http.Error
    | Go


init : Model
init =
    { projects = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyProject : String
emptyProject =
    "--- Veuillez sélectionner un projet ---"


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Go ->
            { model | loading = True } ! [ RedmineAPI.getProjects model.redmineKey FetchFail FetchSuccess ]

        FetchSuccess projects ->
            { model | loading = False, projects = Just (emptyProject :: projects) } ! []

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
