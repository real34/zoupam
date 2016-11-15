module Views.Versions exposing (..)

import Html exposing (..)
import Html.Attributes exposing (..)
import TogglAPI exposing (TimeEntry)
import RedmineAPI exposing (Issue)


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
        , th [] [ text "% temps" ]
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
