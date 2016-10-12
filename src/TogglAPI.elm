module TogglAPI exposing (..)

import Json.Decode as Json exposing ((:=))
import Http
import Task
import Base64


baseUrl : String
baseUrl =
    "https://toggl.com/reports/api/v2"


getDetails : (Http.RawError -> msg) -> (Http.Response -> msg) -> Cmd msg
getDetails errorMsg msg =
    let
        request =
            { verb = "GET"
            , headers = [ ( "Authorization", "Basic " ++ (Result.withDefault "bob" (Base64.encode "c75854d75609916a2b807d5737796328:api_token")) ) ]
            , url = Http.url (baseUrl ++ "/details") [ ( "user_agent", "adrien@occitech.fr" ), ( "workspace_id", "127309" ) ]
            , body = Http.empty
            }
    in
        Http.send Http.defaultSettings request |> Task.perform errorMsg msg


detailsDecoder : Json.Decoder (List Int)
detailsDecoder =
    ("projects" := Json.list ("id" := Json.int))
