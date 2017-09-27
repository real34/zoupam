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

type alias Versions =
    Dict String Version

type alias Version =
    { name: String
    , togglParams: Views.TogglSelector.TogglParams
    , tasks: (List ZoupamTask)
    }


type alias Model =
    { versions : Versions
    , loading : Bool
    }


type Msg
    = GoIssues String String
    | FetchIssuesEnd (Result Http.Error (List Issue))
    | Zou String Version
    | FetchTogglEnd Version (Result Http.Error (List TimeEntry))
    | DefineUrl Version String


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
            model ! [ TogglAPI.getDetails version.togglParams togglKey (FetchTogglEnd version) ]

        FetchTogglEnd _ (Err error) ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                model ! []

        FetchTogglEnd version (Ok toggl) ->
            { model | versions = Dict.update version.name
                (\version ->
                    case version of
                        Nothing -> Nothing
                        Just version ->
                            let
                                issues =
                                    version.tasks
                                        |> List.filterMap issueIfExists
                                zoupamTasks =
                                    List.map (includeTimeEntries toggl) issues
                                        ++ [ ZoupamTask Nothing (notBindedTimeEntries toggl issues) ]
                            in
                                Just { version | tasks = zoupamTasks }
                )
                model.versions } ! []

        DefineUrl version url ->
            { model | versions = Dict.update version.name
                (\version ->
                    case version of
                        Nothing -> Nothing
                        Just version -> Just { version | togglParams = url |> Views.TogglSelector.fromUrl }
                )
                model.versions } ! []

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
                dict
                |> Dict.insert version.name {
                    name = version.name,
                    togglParams = Views.TogglSelector.emptyParams,
                    tasks = [ ZoupamTask (Just issue) Nothing ]
                }

            Just list ->
                dict
                |> Dict.insert version.name {
                    list
                    | tasks = (ZoupamTask (Just issue) Nothing) :: list.tasks
                }


view : Model -> String -> Html Msg
view model togglKey =
    let
        result =
            case model.loading of
                False ->
                    div []
                        ( model.versions
                            |> Dict.toList
                            |> List.map (\(_, version) -> iterationTableView version togglKey)
                        )

                True ->
                    span [] [ text "CHARGEMENT" ]
    in
        result

iterationTableView : Version -> String -> Html Msg
iterationTableView version togglKey =
    let
        taskWithIssue =
            version.tasks
            |> List.filter (\task ->
                case task.issue of
                    Nothing -> False
                    Just _ -> True
            )

        unknownTaskIssue =
            version.tasks
            |> List.filter (\task ->
                case task.issue of
                    Nothing -> True
                    Just _ -> False
            )
            |> List.head
    in

    div [ class "pa3 ma3 o-40 glow" ]
        [ h2 [ class "bb" ] [ text version.name ]
        , Views.TogglSelector.view (DefineUrl version) version.togglParams (Zou togglKey version)
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