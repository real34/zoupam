module Views.Versions exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import TogglAPI exposing (TimeEntry)
import RedmineAPI exposing (Issue)
import Round

tableUnknownTaskLineHeader : Html msg
tableUnknownTaskLineHeader =
    thead []
        [ th [ class "pv2 ph3" ] [ text "Description" ]
        , th [ class "pv2 ph3 tr" ] [ text "Temps consommé" ]
        , th [ class "pv2 ph3 tr" ] [ text "Temps facturable" ]
        ]


unknownTaskLine : TimeEntry -> Html msg
unknownTaskLine entry =
        tr [ class "striped--near-white" ]
            [ td [ class "pv2 ph3" ] [ entry.description |> text ]
            , td [ class "pv2 ph3 tr" ] [ otherTimeEntryTogglTime entry ]
            , td [ class "pv2 ph3 tr" ] [ billableAccumulator entry 0 |> formatTime |> text ]
            ]

otherTimeEntryTogglTime : TimeEntry -> Html msg
otherTimeEntryTogglTime entry  =
 entry.duration
            |> TogglAPI.durationInMinutes
            |> roundedAtTwoDigitAfterComma
            |> text

tableHeader : Html msg
tableHeader =
    thead []
        [ th [ class "pv2 ph3"] [ text "#Id" ]
        , th [ class "pv2 ph3"] [ text "Description" ]
        , th [ class "pv2 ph3 tr"] [ text "Estimé" ]
        , th [ class "pv2 ph3 tr"] [ text "% Réalisé" ]
        , th [ class "pv2 ph3"] [ text "État" ]
        , th [ class "pv2 ph3 tr"] [ text "Temps consommé" ]
        , th [ class "pv2 ph3 tr"] [ text "Temps facturable" ]
        , th [ class "pv2 ph3 tr"] [ text "Temps restant" ]
        , th [ class "pv2 ph3 tr"] [ text "Capital" ]
        , th [ class "pv2 ph3"] [ text "Priorité" ]
        ]

taskLine : Issue -> Maybe (List TimeEntry) -> Html msg
taskLine issue timeEntries =
    let
        issueId =
            (toString issue.id)

        estimated =
            case issue.estimated of
                Nothing ->
                    0 -- TODO Display " - " when no estimation provided to highlight the fact that it is out of the game

                Just hour ->
                    hour

        used =
            case timeEntries of
                Nothing ->
                    0

                Just entries ->
                    List.foldr (\timeEntry acc -> acc + toFloat timeEntry.duration) 0 entries

        billableTime =
            case timeEntries of
                Nothing ->
                    0
                Just entries ->
                    List.foldr billableAccumulator 0 entries

        capitalValue = capitalCalculator estimated issue.doneRatio billableTime
        capital =
            case capitalValue of
                Nothing ->
                    " - "
                Just capital ->
                    capital |> formatTime

        cssPriorityClass =
            case issue.priority of
                "Immediate" -> "bg-washed-red"
                "Urgente" -> "bg-washed-red"
                "Haute" -> "bg-light-yellow"
                "Basse" -> "bg-light-blue"
                _ -> "striped--near-white"
        cssCapitalClass =
            case capitalValue of
                Nothing -> ""
                Just capital ->
                    if capital >= 0 then "bg-green" else "bg-red"

    in
        tr [ class cssPriorityClass ]
            [ td [ class "pv2 ph3" ] [ a [ target "_blank", href ("https://projets.occitech.fr/issues/" ++ issueId), class "link" ] [ text ("#" ++ issueId) ] ]
            , td [ class "pv2 ph3" ] [ issue.subject |> toString |> text]
            , td [ class "pv2 ph3 tr" ] [ estimated |> roundedAtTwoDigitAfterComma |> text ]
            , td [ class "pv2 ph3 tr" ] [ issue.doneRatio |> toString |> text ]
            , td [ class "pv2 ph3" ] [ text issue.status ]
            , td [ class "pv2 ph3 tr" ] [ used |> formatTime |> text ]
            , td [ class "pv2 ph3 tr" ] [ billableTime |> formatTime |> text ]
            , td [ class "pv2 ph3 tr" ] [ (timeLeftCalculator estimated billableTime) |> formatTime |> text ]
            , td [ class ("pv2 ph3 tr " ++ cssCapitalClass) ] [ capital |> text ]
            , td [ class "pv2 ph3" ] [ issue.priority |> text ]
            ]

billableAccumulator : TimeEntry -> Float -> Float
billableAccumulator timeEntry acc =
    case timeEntry.isBillable of
        False ->
            acc
        True ->
            acc + toFloat timeEntry.duration

timeLeftCalculator : Float -> Float -> Float
timeLeftCalculator estimated billableTime =
    (estimated |> daysToMs) - billableTime

msToDays : Float -> Float
msToDays ms =
    (ms / 60 / 60 / 1000) / 6

daysToMs : Float -> Float
daysToMs days =
    days * 6 * 60 * 60 * 1000

roundedAtTwoDigitAfterComma : Float -> String
roundedAtTwoDigitAfterComma =
    Round.round 2

formatTime : Float -> String
formatTime ms =
    ms |> msToDays |> roundedAtTwoDigitAfterComma

capitalCalculator : Float -> Int -> Float -> Maybe Float
capitalCalculator estimated realised billableTime =
    if realised == 0 then
        Nothing
    else
        (estimated  |> daysToMs) - ((100 * (billableTime)) / toFloat (realised)) |> Just
