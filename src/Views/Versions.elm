module Views.Versions exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import TogglAPI exposing (TimeEntry)
import RedmineAPI exposing (Issue)
import Round
import Debug

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
                    List.foldr (\timeEntry acc -> acc + (toFloat (timeEntry.duration) / 60 / 60 / 1000)) 0 entries

        billableTime =
            case timeEntries of
                Nothing ->
                    0

                Just entries ->
                    List.foldr billableAccumulator 0 entries

    in
        tr []
            [ td [] [ a [ target "_blank", href ("http://projets.occitech.fr/issues/" ++ issueId) ] [ text issueId ] ]
            , td [] [ issue.subject |> toString |> text]
            , td [] [ estimated |> toString |> text ]
            , td [] [ issue.doneRatio |> Debug.log "ratio" |> toString |> text]
            , td [] [ text issue.status ]
            , td [] [ used |> convertIntoDay |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ billableTime |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ text (roundedAtTwoDigitAfterComma (timeLeftCalculator estimated billableTime)) ]
            , td [] [ text (toString (capitalCalculator estimated issue.doneRatio billableTime)) ]
            ]

billableAccumulator : TimeEntry -> Float -> Float
billableAccumulator timeEntry acc =
    case timeEntry.isBillable of
        False ->
            acc + 0
        True ->
            acc + (toFloat (timeEntry.duration) / 60 / 60 / 1000) |> convertIntoDay

timeLeftCalculator : Float -> Float -> Float
timeLeftCalculator estimated billableTime =
    estimated - billableTime |> convertIntoDay

convertIntoDay : Float -> Float
convertIntoDay decTime =
    decTime / 6

roundedAtTwoDigitAfterComma : Float -> String
roundedAtTwoDigitAfterComma =
    Round.round 2

capitalCalculator : Float -> Int -> Float -> Float
capitalCalculator estimated realisated billableTime =
    estimated - ((100 * (billableTime)) / toFloat (realisated))
