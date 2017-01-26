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
        ]

testHeader : Html msg
testHeader =
    thead []
        [ th [] [ text "Pas de ticket" ]
        , th [] [ text "Description" ]
        , th [] [ text "Temps consommé" ]
        , th [] [ text "   Temps facturable" ]
        , th [] [ text "Temps consommé total" ]
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
            List.foldr (\timeEntry acc -> acc + (TogglAPI.durationInMinutes timeEntry.duration)) 0 entries

        billableTime =
            case timeEntries of
                Nothing ->
                    0

                Just entries ->
                    List.foldr billableAccumulator 0 entries

    in
        tr []
            [ td [] [ text "..." ]
            , td [] [ ul [] (List.map otherTimeEntryDescription entries) ] --- Une liste qui représente enfaite une ligne
            , td [] [ ul [] (List.map otherTimeEntryTogglTime entries) ]
            , td [] [ billableTime |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ used |> roundedAtTwoDigitAfterComma |> text ]
            ]
--        tr[]
--            [ td [] [text "test"]
--             ]


otherTimeEntryDescription : TimeEntry -> Html msg
otherTimeEntryDescription entry =
    li []
        [ entry.description
            |> text
        ]

otherTimeEntryTogglTime : TimeEntry -> Html msg
otherTimeEntryTogglTime entry  =
    li []
        [ entry.duration
            |> TogglAPI.durationInMinutes
            |> roundedAtTwoDigitAfterComma
            |> text
        ]

testBillable : Float -> Html msg
testBillable billableTime =
    li []
        [  billableTime |> toString |> text
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

    in
        tr []
            [ td [] [ a [ target "_blank", href ("http://projets.occitech.fr/issues/" ++ issueId) ] [ text issueId ] ]
            , td [] [ issue.subject |> toString |> text]
            , td [] [ estimated |> toString |> text ]
            , td [] [ issue.doneRatio |> toString |> text]
            , td [] [ text issue.status ]
            , td [] [ used |> msToDays |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ billableTime |> roundedAtTwoDigitAfterComma |> text ]
            , td [] [ text (roundedAtTwoDigitAfterComma (timeLeftCalculator estimated billableTime)) ]
            , td [] [ text (toString (capitalCalculator estimated issue.doneRatio billableTime)) ]
            ]

billableAccumulator : TimeEntry -> Float -> Float
billableAccumulator timeEntry acc =
    case timeEntry.isBillable of
        False ->
            acc
        True ->
            acc + toFloat timeEntry.duration |> msToDays

timeLeftCalculator : Float -> Float -> Float
timeLeftCalculator estimated billableTime =
    estimated - billableTime |> msToDays

msToDays : Float -> Float
msToDays ms =
    (ms / 60 / 60 / 1000) / 6

roundedAtTwoDigitAfterComma : Float -> String
roundedAtTwoDigitAfterComma =
    Round.round 2

capitalCalculator : Float -> Int -> Float -> Float
capitalCalculator estimated realised billableTime =
    estimated - ((100 * (billableTime)) / toFloat (realised))
