module TogglAPI exposing (..)

import Json.Decode as Json exposing (field)
import Json.Decode.Extra exposing ((|:))
import Http
import String
import Base64
import Views.TogglSelector exposing (TogglParams)


-- import Base64


type alias TimeEntry =
    { id : Int
    , description : String
    , isBillable : Bool
    , duration : Int
    }


type alias Context =
    { userAgent : String
    }



-- Source: https://github.com/toggl/toggl_api_docs/blob/master/reports.md#request-parameters
-- NB! Maximum date span (until - since) is one year.


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


buildIdsListParam : Maybe (List Int) -> String
buildIdsListParam ids =
    (Maybe.withDefault [] ids)
        |> List.map toString
        |> List.intersperse ","
        |> String.concat


buildRequestParams : TogglParams -> String
buildRequestParams request =
    "workspace_id="
        ++ toString request.workspaceId
        ++ "&project_ids="
        ++ buildIdsListParam request.projectIds
        ++ "&task_ids="
        ++ buildIdsListParam request.taskIds
        ++ "&client_ids="
        ++ buildIdsListParam request.clientIds
        ++ "&since="
        ++ Maybe.withDefault "" request.since
        ++ "&until="
        ++ Maybe.withDefault "" request.until
        ++ "&rounding="
        ++ (request.rounding |> toString)


getDetails : TogglParams -> Int -> String -> (Result Http.Error (List TimeEntry) -> msg) -> Cmd msg
getDetails params page key msg =
    let
        context =
            Context "contact@occitech.fr"

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
                    ++ "&page="
                    ++ (page |> toString)
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
