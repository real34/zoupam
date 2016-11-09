module Issues exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick)
import Html.Attributes exposing (href, target)
import Http
import Dict exposing (Dict)
import RedmineAPI
import TogglAPI
import String


type alias ZoupamTask =
    { issue : Maybe (RedmineAPI.Issue)
    , timeEntries : Maybe (List TogglAPI.TimeEntry)
    }


type alias Model =
    { issues : Dict String (List ZoupamTask)
    , loading : Bool
    }


type Msg
    = GoIssues String String
    | FetchIssuesFail Http.Error
    | FetchIssuesSuccess (List RedmineAPI.Issue)
    | Zou String String
    | FetchTogglFail Http.Error
    | FetchTogglSuccess String (List TogglAPI.TimeEntry)


init : Model
init =
    Model Dict.empty False


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GoIssues redmineKey projectId ->
            { model | loading = True } ! [ RedmineAPI.getIssues redmineKey projectId FetchIssuesFail FetchIssuesSuccess ]

        FetchIssuesSuccess issues ->
            { model | loading = False, issues = List.foldr issuesToDict Dict.empty issues } ! []

        FetchIssuesFail error ->
            { model | loading = False } ! []

        Zou togglKey version ->
            model ! [ TogglAPI.getDetails togglKey FetchTogglFail (FetchTogglSuccess version) ]

        FetchTogglFail error ->
            let
                pouet =
                    error |> Debug.log "error"
            in
                model ! []

        FetchTogglSuccess version toggl ->
            let
                issues = (Maybe.withDefault [] (Dict.get version model.issues))
                  |> List.filterMap (\task -> case task.issue of
                    Nothing -> Nothing
                    Just issue -> Just issue)

                zoupamTasks =
                    List.map (includeTimeEntries toggl) issues
                    ++ [ ZoupamTask Nothing (Just (List.filter (\entry -> List.foldr
                      (\issue acc -> acc && not (isReferencing issue entry))
                      True
                      issues
                    ) toggl)) ]
            in
                { model | issues = Dict.insert version zoupamTasks model.issues } ! []

isReferencing : RedmineAPI.Issue -> TogglAPI.TimeEntry -> Bool
isReferencing issue entry =
    String.contains (toString issue.id) entry.description

includeTimeEntries : List TogglAPI.TimeEntry -> RedmineAPI.Issue -> ZoupamTask
includeTimeEntries toggl issue =
    let
        entries = Just (List.filter (isReferencing issue) toggl)
    in
        ZoupamTask (Just issue) entries

issuesToDict : RedmineAPI.Issue -> Dict String (List ZoupamTask) -> Dict String (List ZoupamTask)
issuesToDict issue dict =
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
                            (Dict.toList model.issues)
                        )

                True ->
                    span [] [ text "CHARGEMENT" ]
    in
        result


iterationTableView : List ZoupamTask -> String -> String -> Html Msg
iterationTableView tasks version togglKey =
    div []
        [ h2 [] [ text version ]
        , button [ onClick (Zou togglKey version) ] [ text "Zou" ]
        , table []
            [ tableHeader
            , (tableBody tasks)
            ]
        ]


tableHeader : Html Msg
tableHeader =
    thead []
        [ th [] [ text "#Id" ]
        , th [] [ text "Description" ]
        , th [] [ text "Estimé" ]
        , th [] [ text "% Réalisé" ]
        , th [] [ text "État" ]
        , th [] [ text "Temps consommé" ]
        , th [] [ text "Temps facturable" ]
        , th [] [ text "% temps" ]
        , th [] [ text "Capital" ]
        ]


tableBody : List ZoupamTask -> Html Msg
tableBody tasks =
    tbody []
        (List.filterMap
            (\task ->
                let
                    result =
                        case task.issue of
                            Nothing ->
                                Just (unknownTaskLine task.timeEntries)

                            Just issue ->
                                Just (taskLine issue task.timeEntries)
                in
                    result
            )
            tasks
        )

unknownTaskLine : Maybe (List TogglAPI.TimeEntry) -> Html Msg
unknownTaskLine timeEntries =
    let
        entries = case timeEntries of
          Nothing -> []
          Just entries -> entries

        used = toString (List.foldr (\timeEntry acc -> acc + (TogglAPI.durationInMinutes timeEntry.duration)) 0 entries)
    in
        tr []
            [ td [] [ text "Le reste" ]
            , td [] [ ul [] (List.map (\entry -> li [] [ text ((toString (TogglAPI.durationInMinutes entry.duration)) ++ " - " ++ entry.description) ]) entries) ]
            , td [] [ ]
            , td [] [ ]
            , td [] [ ]
            , td [] [ text used ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            ]


taskLine : RedmineAPI.Issue -> Maybe (List TogglAPI.TimeEntry) -> Html Msg
taskLine issue timeEntries =
    let
        issueId =
            "#" ++ (toString issue.id)

        estimated =
            case issue.estimated of
                Nothing ->
                    0

                Just hour ->
                    hour

        used =
            case timeEntries of
                Nothing ->
                    "TBD"

                Just entries ->
                    toString (List.foldr (\timeEntry acc -> acc + (toFloat (timeEntry.duration) / 60 / 60 / 1000)) 0 entries)
    in
        tr []
            [ td [] [ a [ target "_blank", href ("http://projets.occitech.fr/issues/" ++ issueId) ] [ text issueId ] ]
            , td [] [ text issue.subject ]
            , td [] [ text (toString estimated) ]
            , td [] [ text (toString issue.doneRatio) ]
            , td [] [ text issue.status ]
            , td [] [ text used ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            ]
