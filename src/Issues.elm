module Issues exposing (..)

import Html exposing (..)
import Html.Attributes exposing (class, href, target)
import Http
import RedmineAPI exposing (Issue, Version, urlOf)
import TogglAPI exposing (TimeEntry)
import String
import Views.Versions
import Views.TogglSelector
import Views.Spinner


type alias ZoupamTask =
    { issue : Maybe RedmineAPI.Issue
    , timeEntries : Maybe (List TimeEntry)
    }


type alias Model =
    { tasks : List ZoupamTask
    , togglParams : Views.TogglSelector.TogglParams
    , loading : Bool
    }


type Msg
    = GoIssues String Version
    | FetchIssuesEnd (Result Http.Error (List Issue))
    | Zou String Model
    | FetchTogglEnd String Int (Result Http.Error (List TimeEntry))
    | DefineUrl String


init : Model
init =
    Model [] Views.TogglSelector.emptyParams False


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey version ->
            let
                togglParams =
                    version.description
                        |> Views.TogglSelector.findReportUrl
                        |> Maybe.withDefault ""
                        |> Views.TogglSelector.fromUrl
            in
                { model
                    | loading = True
                    , togglParams = togglParams
                }
                    ! [ RedmineAPI.getIssues redmineKey version.id FetchIssuesEnd ]

        FetchIssuesEnd (Ok issues) ->
            { model
                | loading = False
                , tasks = issues |> List.map (\issue -> ZoupamTask (Just issue) Nothing)
            }
                ! []

        FetchIssuesEnd (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                { model | loading = False } ! []

        Zou togglKey currModel ->
            { model
                | tasks = model.tasks |> List.map resetTimeEntries
            }
                ! [ TogglAPI.getDetails currModel.togglParams 1 togglKey (FetchTogglEnd togglKey 1) ]

        FetchTogglEnd _ _ (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                model ! []

        FetchTogglEnd togglKey page (Ok togglTimeEntries) ->
            let
                tasksWithIssue =
                    model.tasks |> List.filter (\task -> task.issue /= Nothing)

                firstTaskWithoutIssue =
                    model.tasks
                        |> List.filter (\task -> task.issue == Nothing)
                        |> List.head
                        |> Maybe.withDefault (ZoupamTask Nothing (Just []))

                unbindedTimeEntries =
                    notBindedTimeEntries togglTimeEntries tasksWithIssue

                zoupamTasks =
                    (tasksWithIssue |> List.map (appendTimeEntries togglTimeEntries))
                        ++ [ { firstTaskWithoutIssue
                                | timeEntries =
                                    case firstTaskWithoutIssue.timeEntries of
                                        Nothing ->
                                            Just unbindedTimeEntries

                                        Just timeEntries ->
                                            Just (timeEntries ++ unbindedTimeEntries)
                             }
                           ]

                -- Keep fetching new pages for other time entries while we won!
                nextPage =
                    page + 1

                nextPageMsg =
                    case List.isEmpty togglTimeEntries of
                        True ->
                            []

                        False ->
                            [ TogglAPI.getDetails model.togglParams nextPage togglKey (FetchTogglEnd togglKey nextPage) ]
            in
                { model | tasks = zoupamTasks } ! nextPageMsg

        DefineUrl url ->
            { model | togglParams = url |> Views.TogglSelector.fromUrl } ! []


resetTimeEntries : ZoupamTask -> ZoupamTask
resetTimeEntries task =
    { task | timeEntries = Nothing }


notBindedTimeEntries : List TimeEntry -> List ZoupamTask -> List TimeEntry
notBindedTimeEntries timeEntries tasks =
    timeEntries
        |> List.filter
            (\entry ->
                List.foldr
                    (\task acc -> acc && not (isReferencing task.issue entry))
                    True
                    tasks
            )


isReferencing : Maybe Issue -> TimeEntry -> Bool
isReferencing issue entry =
    case issue of
        Nothing ->
            False

        Just issue ->
            entry.description |> String.contains (issue.id |> toString)


appendTimeEntries : List TimeEntry -> ZoupamTask -> ZoupamTask
appendTimeEntries newTimeEntries task =
    let
        currentEntries =
            task.timeEntries |> Maybe.withDefault []

        relatedNewEntries =
            newTimeEntries
                |> List.filter (isReferencing task.issue)
    in
        { task | timeEntries = Just (currentEntries ++ relatedNewEntries) }


view : Version -> Model -> String -> Html Msg
view version model togglKey =
    let
        result =
            case model.loading of
                False ->
                    div [] [ iterationTableView version model togglKey ]

                True ->
                    Views.Spinner.view
    in
        result


iterationTableView : Version -> Model -> String -> Html Msg
iterationTableView version model togglKey =
    let
        taskWithIssue =
            model.tasks
                |> List.filter
                    (\task ->
                        case task.issue of
                            Nothing ->
                                False

                            Just _ ->
                                True
                    )

        unknownTaskIssue =
            model.tasks
                |> List.filter
                    (\task ->
                        case task.issue of
                            Nothing ->
                                True

                            Just _ ->
                                False
                    )
                |> List.head
    in
        div [ class "mt5 mb3" ]
            [ h2 [ class "bb" ]
                [ a [ href (urlOf version), target "_blank", class "link hide-child" ]
                    [ text version.name
                    , i [ class "fa fa-external-link ml2 child" ] []
                    ]
                ]
            , Views.TogglSelector.view DefineUrl model.togglParams (Zou togglKey model)
            , div [ class "overflow-x-auto" ]
                [ table []
                    [ Views.Versions.tableHeader
                    , (tableBody taskWithIssue)
                    ]
                ]
            , (let
                result =
                    case unknownTaskIssue of
                        Nothing ->
                            text ""

                        Just taskLine ->
                            div [ class "mt4 bt b--near-white" ]
                                [ h3 [ class "f3" ] [ text "Tickets Toggl non liés à un ticket Redmine" ]
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
