module TogglAPI exposing (..)

import Json.Decode as Json exposing (field)
import Json.Decode.Extra exposing ((|:))
import Http
import String
import Base64


-- import Base64


type alias TimeEntry =
    { id : Int
    , description : String
    , isBillable : Bool
    , duration : Int
    }


type alias Context =
    { workspaceId : Int
    , userAgent : String
    }



-- Source: https://github.com/toggl/toggl_api_docs/blob/master/reports.md#request-parameters
-- NB! Maximum date span (until - since) is one year.


type OnOff
    = On
    | Off


type alias RequestParameters =
    { projectIds : Maybe (List Int)
    , clientIds : Maybe (List Int)
    , since : Maybe String
    , until : Maybe String
    , rounding : Maybe OnOff
    }


durationInMinutes : Int -> Float
durationInMinutes duration =
    toFloat duration / 60 / 60 / 1000


baseUrl : String
baseUrl =
    "https://toggl.com/reports/api/v2"


buildContextParams : Context -> String
buildContextParams context =
    "user_agent="
        ++ context.userAgent
        ++ "&workspace_id="
        ++ toString context.workspaceId


buildIdsListParam : Maybe (List Int) -> String
buildIdsListParam ids =
    (Maybe.withDefault [] ids)
        |> List.map toString
        |> List.intersperse ","
        |> String.concat


buildRequestParams : RequestParameters -> String
buildRequestParams request =
    "project_ids="
        ++ buildIdsListParam request.projectIds
        ++ "&client_ids="
        ++ buildIdsListParam request.clientIds
        ++ "&since="
        ++ Maybe.withDefault "" request.since
        ++ "&until="
        ++ Maybe.withDefault "" request.until
        ++ "&rounding="
        ++ ((Maybe.withDefault Off request.rounding) |> toString)


getDetails : String -> (Result Http.Error (List TimeEntry) -> msg) -> Cmd msg
getDetails key msg =
    let
        context =
            Context 127309 "contact@occitech.fr"

        params =
            RequestParameters
                (Just [ 22791424 ])
                Nothing
                (Just "2016-01-01")
                Nothing
                (Just Off)

        request =
            { method = "GET"
            , headers =
                [ Http.header
                    "Authorization"
                    (key
                        ++ ":api_token"
                        |> Base64.encode
                        |> Result.withDefault ""
                        |> String.append "Basic "
                    )
                ]
            , url =
                baseUrl
                    ++ "/details?"
                    ++ buildContextParams context
                    ++ "&"
                    ++ buildRequestParams params
            , body = Http.emptyBody
            , expect = Http.expectJson detailsDecoder
            , timeout = Nothing
            , withCredentials = False
            }
    in
        Http.send msg <| Http.request request


detailsDecoder : Json.Decoder (List TimeEntry)
detailsDecoder =
    Json.succeed TimeEntry
        |: (field "id" Json.int)
        |: (field "description" Json.string)
        |: (field "is_billable" Json.bool)
        |: (field "dur" Json.int)
        |> Json.list
        |> field "data"
