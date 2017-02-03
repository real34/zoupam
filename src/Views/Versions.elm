module Views.Versions exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import TogglAPI exposing (TimeEntry)
import RedmineAPI exposing (Issue)
import Round

tableHeader : Html msg
tableHeader =
    thead []
        [ th [] [ text "#Id" ]
        , th [] [ text "Description" ]
        , th [] [ text "Estimé" ]
        , th [] [ text "% Réalisé" ]
        , th [] [ text "État" ]
        , th [] [ text "Temps consommé" ]
        , th [] [ text "Temps facturable" ]
        , th [] [ text "Temps restant" ]
        , th [] [ text "Capital" ]
        , th [] [ text "Priorité" ]
        ]


unknownTaskLine : Maybe (List TimeEntry) -> Html msg
unknownTaskLine timeEntries =
    let
        entries =
            case timeEntries of
                Nothing ->
                    []

                Just entries ->
                    entries

        used =
            toString (List.foldr (\timeEntry acc -> acc + (TogglAPI.durationInMinutes timeEntry.duration)) 0 entries)
    in
        tr []
            [ td [] [ text "Le reste" ]
            , td [] [ ul [] (List.map otherTimeEntryView entries) ]
            , td [] []
            , td [] []
            , td [] []
            , td [] [ text used ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            , td [] [ text "TODO" ]
            ]


otherTimeEntryView : TimeEntry -> Html msg
otherTimeEntryView entry =
    li []
        [ entry.duration
            |> TogglAPI.durationInMinutes
            |> toString
            |> (++) " - "
            |> (++) entry.description
            |> text
        ]


taskLine : Issue -> Maybe (List TimeEntry) -> Html msg
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
                    0

                Just entries ->
                    List.foldr (\timeEntry acc -> acc + toFloat timeEntry.duration) 0 entries

        billableTime =
            case timeEntries of
                Nothing ->
                    0

                Just entries ->
                    List.foldr billableAccumulator 0 entries

        capital =
            case capitalCalculator estimated issue.doneRatio billableTime of
                Nothing ->
                    "Erreur, calcul impossible"

                Just capital ->
                    capital |> formatTime

    in
        tr []
            [ td [] [ a [ target "_blank", href ("http://projets.occitech.fr/issues/" ++ issueId) ] [ text issueId ] ]
            , td [] [ issue.subject |> toString |> text]
            , td [] [ estimated |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ issue.doneRatio |> toString |> text ]
            , td [] [ text issue.status ]
            , td [] [ used |> formatTime |> text ]
            , td [] [ billableTime |> formatTime |> text ]
            , td [] [ (timeLeftCalculator estimated billableTime) |> formatTime |> text ]
            , td [] [ capital |> text ]
            , td [] [ issue.priority |> text ]
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
    Round.round 2 ((ms / 60 / 60 / 1000) / 6)

capitalCalculator : Float -> Int -> Float -> Maybe Float
capitalCalculator estimated realised billableTime =
    if realised == 0 then
     Nothing
      else
       (estimated  |> daysToMs) - ((100 * (billableTime)) / toFloat (realised)) |> Just