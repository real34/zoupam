module Issues exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (href, target)
import Http
import Dict exposing (Dict)
import RedmineAPI exposing (Issue)
import TogglAPI exposing (TimeEntry)
import String
import Views.Versions


type alias ZoupamTask =
    { issue : Maybe RedmineAPI.Issue
    , timeEntries : Maybe (List TimeEntry)
    }


type alias Versions =
    Dict String (List ZoupamTask)


type alias Model =
    { versions : Versions
    , loading : Bool
    }


type Msg
    = GoIssues String String
    | FetchIssuesEnd (Result Http.Error (List Issue))
    | Zou String String
    | FetchTogglEnd String (Result Http.Error (List TimeEntry))


init : Model
init =
    Model Dict.empty False


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey projectId ->
            { model | loading = True } ! [ RedmineAPI.getIssues redmineKey projectId FetchIssuesEnd ]

        FetchIssuesEnd (Ok issues) ->
            { model | loading = False, versions = List.foldr issuesToVersions Dict.empty issues } ! []

        FetchIssuesEnd (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                { model | loading = False } ! []

        Zou togglKey version ->
            model ! [ TogglAPI.getDetails togglKey (FetchTogglEnd version) ]

        FetchTogglEnd _ (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                model ! []

        FetchTogglEnd version (Ok toggl) ->
            let
                issues =
                    (Maybe.withDefault [] (Dict.get version model.versions))
                        |> List.filterMap issueIfExists

                zoupamTasks =
                    List.map (includeTimeEntries toggl) issues
                        ++ [ ZoupamTask Nothing (notBindedTimeEntries toggl issues) ]
            in
                { model | versions = Dict.insert version zoupamTasks model.versions } ! []


notBindedTimeEntries : List TimeEntry -> List Issue -> Maybe (List TimeEntry)
notBindedTimeEntries timeEntries issues =
    (Just
        (List.filter
            (\entry ->
                List.foldr
                    (\issue acc -> acc && not (isReferencing issue entry))
                    True
                    issues
            )
            timeEntries
        )
    )


issueIfExists : ZoupamTask -> Maybe Issue
issueIfExists task =
    case task.issue of
        Nothing ->
            Nothing

        Just issue ->
            Just issue


isReferencing : Issue -> TimeEntry -> Bool
isReferencing issue entry =
    String.contains (toString issue.id) entry.description


includeTimeEntries : List TimeEntry -> Issue -> ZoupamTask
includeTimeEntries toggl issue =
    let
        entries =
            Just (List.filter (isReferencing issue) toggl)
    in
        ZoupamTask (Just issue) entries


issuesToVersions : Issue -> Versions -> Versions
issuesToVersions issue dict =
    let
        version =
            Maybe.withDefault { id = 0, name = "Version non renseignée" } issue.version

        existing =
            Dict.get (version.name) dict
    in
        case existing of
            Nothing ->
                Dict.insert version.name [ ZoupamTask (Just issue) Nothing ] dict

            Just list ->
                Dict.insert version.name ((ZoupamTask (Just issue) Nothing) :: list) dict


view : Model -> String -> Html Msg
view model togglKey =
    let
        result =
            case model.loading of
                False ->
                    div []
                        (List.map
                            (\( version, issues ) ->
                                iterationTableView issues version togglKey
                            )
                            (Dict.toList model.versions)
                        )

                True ->
                    span [] [ text "CHARGEMENT" ]
    in
        result


iterationTableView : List ZoupamTask -> String -> String -> Html Msg
iterationTableView tasks version togglKey =
    let
        taskWithIssue =
            List.filter (\task ->
                case task.issue of
                    Nothing -> False
                    Just _ -> True
            ) tasks

        unknownTaskIssue =
            List.head (List.filter (\task ->
                case task.issue of
                    Nothing -> True
                    Just _ -> False
            ) tasks)
    in

    div []
        [ h2 [] [ text version ]
        , button [ onClick (Zou togglKey version) ] [ text "Zou" ]
        , table []
            [ Views.Versions.tableHeader
            , (tableBody taskWithIssue)
            ]
        , (
            let
                result = case unknownTaskIssue of
                    Nothing ->
                        text ""
                    Just taskLine ->
                        table []
                            [ Views.Versions.tableUnknownTaskLineHeader
                            , (tableBodyForUnknownTaskLine taskLine)
                            ]
            in
                result
        )
        ]


tableBody : List ZoupamTask -> Html Msg
tableBody tasks =
    tbody []
        (List.map
            (\task ->
                let
                    result =
                        case task.issue of
                            Nothing ->
                                text "Erreur, impossible de trouver une entrée Redmine"

                            Just issue ->
                                Views.Versions.taskLine issue task.timeEntries
                in
                    result
            )
            tasks
        )

tableBodyForUnknownTaskLine : ZoupamTask -> Html Msg
tableBodyForUnknownTaskLine task =
    let
        result =
            case task.timeEntries of
                Nothing ->
                    text "Aucune entrée Toggl n'est pas associé à un ticket Redmine"
                Just timeEntries ->
                    tbody []
                        (List.map
                            (\timeEntry -> Views.Versions.unknownTaskLine timeEntry)
                            timeEntries
                        )
    in
        result