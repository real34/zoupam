module TogglAPI exposing (..)

import Json.Decode as Json exposing ((:=))
import Json.Decode.Extra exposing ((|:))
import Http
import Task
import Base64


type alias TimeEntry =
    { id : Int
    , description : String
    , isBillable : Bool
    , duration : Int
    }

durationInMinutes : Int -> Float
durationInMinutes duration =
  toFloat duration / 60 / 60 / 1000

baseUrl : String
baseUrl =
    "https://toggl.com/reports/api/v2"


getDetails : String -> (Http.Error -> msg) -> (List TimeEntry -> msg) -> Cmd msg
getDetails key errorMsg msg =
    let
        request =
            { verb = "GET"
            , headers = [ ( "Authorization", "Basic " ++ (Result.withDefault "bob" (Base64.encode (key ++ ":api_token"))) ) ]
            , url =
                Http.url (baseUrl ++ "/details")
                    [ ( "user_agent", "adrien@occitech.fr" )
                    , ( "workspace_id", "127309" )
                    , ( "project_ids", "22791424" )
                    , ( "since", "2016-01-01" )
                    ]
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
