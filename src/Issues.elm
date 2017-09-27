module Issues exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class)
import Http
import Dict exposing (Dict)
import RedmineAPI exposing (Issue)
import TogglAPI exposing (TimeEntry)
import String
import Views.Versions
import Views.TogglSelector


type alias ZoupamTask =
    { issue : Maybe RedmineAPI.Issue
    , timeEntries : Maybe (List TimeEntry)
    }

type alias Model =
    { tasks: (List ZoupamTask)
    , togglParams: Views.TogglSelector.TogglParams
    , loading : Bool
    }

type Msg
    = GoIssues String Int
    | FetchIssuesEnd (Result Http.Error (List Issue))
    | Zou String Model
    | FetchTogglEnd (Result Http.Error (List TimeEntry))
    | DefineUrl String


init : Model
init =
    Model [] Views.TogglSelector.emptyParams False

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey versionId ->
            { model | loading = True } ! [ RedmineAPI.getIssues redmineKey versionId FetchIssuesEnd ]

        FetchIssuesEnd (Ok issues) ->
            { model |
                loading = False
                , tasks = issues |> List.map(\issue -> ZoupamTask (Just issue) Nothing)
            } ! []

        FetchIssuesEnd (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                { model | loading = False } ! []

        Zou togglKey currModel ->
            model ! [ TogglAPI.getDetails currModel.togglParams togglKey FetchTogglEnd ]

        FetchTogglEnd (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                model ! []

        FetchTogglEnd (Ok toggl) ->
            let
                issues =
                    model.tasks
                        |> List.filterMap issueIfExists
                zoupamTasks =
                    List.map (includeTimeEntries toggl) issues
                        ++ [ ZoupamTask Nothing (notBindedTimeEntries toggl issues) ]
            in
                { model | tasks = zoupamTasks } ! []

        DefineUrl url ->
            { model | togglParams = url |> Views.TogglSelector.fromUrl } ! []

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

view : Model -> String -> Html Msg
view model togglKey =
    let
        result =
            case model.loading of
                False ->
                    div [] [
                        iterationTableView model togglKey
                    ]

                True ->
                    span [] [ text "CHARGEMENT" ]
    in
        result

iterationTableView : Model -> String -> Html Msg
iterationTableView model togglKey =
    let
        versionName = "TODO"

        taskWithIssue =
            model.tasks
            |> List.filter (\task ->
                case task.issue of
                    Nothing -> False
                    Just _ -> True
            )

        unknownTaskIssue =
            model.tasks
            |> List.filter (\task ->
                case task.issue of
                    Nothing -> True
                    Just _ -> False
            )
            |> List.head
    in

    div [ class "pa3 ma3" ]
        [ h2 [ class "bb" ] [ text versionName ]
        , Views.TogglSelector.view DefineUrl model.togglParams (Zou togglKey model)
        , div [ class "overflow-x-auto" ]
            [ table []
                [ Views.Versions.tableHeader
                , (tableBody taskWithIssue)
                ]
            ]
        , (
            let
                result = case unknownTaskIssue of
                    Nothing ->
                        text ""
                    Just taskLine ->
                        div [ class "mt4 bt b--near-white"]
                        [ h3 [ class "f3"] [text "Tickets Toggl non liés à un ticket Redmine"]
                        , div [ class "overflow-x-auto" ]
                            [ table []
                                [ Views.Versions.tableUnknownTaskLineHeader
                                , (tableBodyForUnknownTaskLine taskLine)
                                ]
                            ]
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