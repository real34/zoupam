module Views.TogglSelector exposing (TogglParams, findReportUrl, fromUrl, emptyParams, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (onInput, onClick)
import Regex


type OnOff
    = On
    | Off


type alias TogglParams =
    { url : String
    , workspaceId : Int
    , projectIds : Maybe (List Int)
    , clientIds : Maybe (List Int)
    , taskIds : Maybe (List Int)
    , since : Maybe String
    , until : Maybe String
    , rounding : OnOff
    }



-- TODO : handle several ids (example: "xxx/projects/123,456/yyy")


idsOfUrlParamName : String -> String -> Maybe (List Int)
idsOfUrlParamName paramName url =
    let
        regex =
            Regex.regex (paramName ++ "/([\\d]+)")
    in
        case Regex.contains regex url of
            True ->
                Regex.find (Regex.AtMost 1) regex url
                    |> List.map
                        (\match ->
                            match.submatches
                                |> List.map
                                    (\submatch ->
                                        case submatch of
                                            Nothing ->
                                                0

                                            Just sm ->
                                                sm |> String.toInt |> (Result.withDefault 0)
                                    )
                        )
                    |> List.head

            False ->
                Nothing


findReportUrl : String -> Maybe String
findReportUrl text =
    let
        -- TODO Support urls with www prefix (Mission for a regexman)
        regex =
            Regex.regex "(https:\\/\\/toggl.com\\/app\\/reports\\/[\\S]+)"
    in
        Regex.find (Regex.AtMost 1) regex text
            |> List.head
            |> Maybe.andThen (\match -> List.head match.submatches)
            |> Maybe.withDefault Nothing


fromUrl : String -> TogglParams
fromUrl url =
    -- Example: https://toggl.com/app/reports/summary/127309/period/thisYear/projects/34394176/tasks/16196934/billable/both
    -- TODO Make me work for real with cleaner code
    -- remove prefix
    -- extract workspace id
    -- split the rest as key values
    let
        projects =
            url |> idsOfUrlParamName "projects"

        tasks =
            url |> idsOfUrlParamName "tasks"
    in
        { url = url
        , workspaceId = 127309
        , projectIds = projects
        , clientIds = Nothing
        , taskIds = tasks
        , since = (Just "2017-01-01")
        , until = Nothing
        , rounding = Off
        }


emptyParams : TogglParams
emptyParams =
    { url = ""
    , workspaceId = 127309
    , projectIds = (Just [ 45022829 ])
    , clientIds = Nothing
    , taskIds = Nothing
    , since = (Just "2017-01-01")
    , until = Nothing
    , rounding = Off
    }


view : (String -> msg) -> TogglParams -> msg -> Html msg
view msg model zou =
    let
        previewLink =
            case model.url of
                "" ->
                    text ""

                url ->
                    a
                        [ href url
                        , target "_blank"
                        , class "link"
                        , title "Ouvrir le rapport dans une autre fenêtre"
                        ]
                        [ i [ class "fa fa-external-link ml2" ] [] ]
    in
        div []
            [ label [] [ i [ class "fa fa-power-off white bg-red pa2 br-100", title "Url du rapport Toggl" ] [] ]
            , input [ onInput msg, value model.url, class "w-30 pa1 ml2" ] []
            , previewLink
            , button
                [ onClick zou
                , class "ml3 ph4 pv2 br-pill outline-0"
                ]
                [ i [ class "fa fa-hand-spock-o mr2" ] [], text "Zou" ]
            ]
