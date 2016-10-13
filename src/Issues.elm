module Issues exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Http
import Dict exposing (Dict)
import RedmineAPI


type alias Model =
    { issues : Dict String (List RedmineAPI.Issue)
    , loading : Bool
    }


type Msg
    = GoIssues String String
    | Fail Http.Error
    | Success (List RedmineAPI.Issue)


init : Model
init =
    Model Dict.empty False


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey projectId ->
            { model | loading = True } ! [ RedmineAPI.getIssues redmineKey projectId Fail Success ]

        Success issues ->
            { model | loading = False, issues = List.foldr issuesToDict Dict.empty issues } ! []

        Fail error ->
            { model | loading = False } ! []


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
        loadButton =
            case projectId of
                Nothing ->
                    span [] []

                Just project ->
                    button [ onClick (GoIssues redmineKey project) ]
                        [ text "Load Issues" ]

        result =
            case model.loading of
                False ->
                    div []
                        (List.map
                            (\( key, issues ) ->
                                div []
                                    [ h3 [] [ text key ]
                                    , div [] (List.map (\issue -> h4 [] [ text issue.subject ]) issues)
                                    ]
                            )
                            (Dict.toList model.issues)
                        )

                True ->
                    span [] [ text "LOADING" ]
    in
        div []
            [ loadButton
            , result
            ]
