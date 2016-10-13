module Issues exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Dict exposing (Dict)
import RedmineAPI


type alias Model =
    Dict String (List RedmineAPI.Issue)


type Msg
    = GoIssues String String
    | Fail Http.Error
    | Success (List RedmineAPI.Issue)


init : Dict a b
init =
    Dict.empty


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey projectId ->
            model ! [ RedmineAPI.getIssues redmineKey projectId Fail Success ]

        Success issues ->
            List.foldr issuesToDict Dict.empty issues ! []

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


view : String -> Maybe String -> Model -> Html Msg
view redmineKey projectId model =
    let
        load =
            case projectId of
                Nothing ->
                    span [] [ text "Please select a project" ]

                Just project ->
                    button [ onClick (GoIssues redmineKey project) ]
                        [ text "Load Issues" ]
    in
        div []
            [ load
            , div []
                (List.map
                    (\( key, issues ) ->
                        div []
                            [ h3 [] [ text key ]
                            , div [] (List.map (\issue -> h4 [] [ text issue.subject ]) issues)
                            ]
                    )
                    (Dict.toList model)
                )
            ]
