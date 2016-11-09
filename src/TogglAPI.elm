module TogglAPI exposing (..)

import Json.Decode as Json exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task
import String
import Base64


type alias TimeEntry =
    { id : Int
    , description : String
    , isBillable : Bool
    , duration : Int
    }

type alias Context =
    { workspaceId: Int
    , userAgent: String
    }

-- Source: https://github.com/toggl/toggl_api_docs/blob/master/reports.md#request-parameters
-- NB! Maximum date span (until - since) is one year.
type OnOff = On | Off
type alias RequestParameters =
    { projectIds: Maybe (List Int)
    , clientIds: Maybe (List Int)
    , since: Maybe String
    , until: Maybe String
    , rounding: Maybe OnOff
    }

durationInMinutes : Int -> Float
durationInMinutes duration =
  toFloat duration / 60 / 60 / 1000

baseUrl : String
baseUrl =
    "https://toggl.com/reports/api/v2"

buildContextParams : Context -> List (String, String)
buildContextParams context =
    [ ( "user_agent", context.userAgent )
    , ( "workspace_id", toString context.workspaceId )
    ]

buildIdsListParam : Maybe (List Int) -> String
buildIdsListParam ids =
    (Maybe.withDefault [] ids) |> List.map toString |> List.intersperse "," |> String.concat

buildRequestParams : RequestParameters -> List (String, String)
buildRequestParams request =
    [ ( "project_ids", buildIdsListParam request.projectIds )
    , ( "client_ids", buildIdsListParam request.clientIds )
    , ( "since", Maybe.withDefault "" request.since )
    , ( "until", Maybe.withDefault "" request.until )
    , ( "rounding", (Maybe.withDefault Off request.rounding) |> toString )
    ]

getDetails : String -> (Http.Error -> msg) -> (List TimeEntry -> msg) -> Cmd msg
getDetails key errorMsg msg =
    let
        context = Context 127309 "contact@occitech.fr"
        params = RequestParameters
            (Just [22791424])
            Nothing
            (Just "2016-01-01")
            Nothing
            (Just Off)

        request =
            { verb = "GET"
            , headers = [ ( "Authorization", "Basic " ++ (Result.withDefault "bob" (Base64.encode (key ++ ":api_token"))) ) ]
            , url = Http.url (baseUrl ++ "/details") (( buildContextParams context ) ++ ( buildRequestParams params ))
            , body = Http.empty
            }
    in
        Http.send Http.defaultSettings request |> Http.fromJson detailsDecoder |> Task.perform errorMsg msg


detailsDecoder : Json.Decoder (List TimeEntry)
detailsDecoder =
    ("data"
        := Json.list
            (Json.succeed TimeEntry
                |: ("id" := Json.int)
                |: ("description" := Json.string)
                |: ("is_billable" := Json.bool)
                |: ("dur" := Json.int)
            )
    )
