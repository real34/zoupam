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


init : Model
init =
    { projects = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyProject : String
emptyProject =
    "--- Veuillez sélectionner un projet ---"


view : msg -> Model -> Html msg
view msg model =
    case model.loading of
        False ->
            case model.projects of
                Nothing ->
                    div []
                        [ button [ onClick msg ] [ text "Go!" ]
                        ]

                Just projects ->
                    div []
                        [ select [] (List.map (\project -> option [] [ text project ]) projects)
                        , button [ onClick msg ] [ text "Go!" ]
                        ]

        True ->
            text "CHARGEMENT"
