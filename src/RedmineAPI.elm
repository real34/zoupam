module RedmineAPI exposing (..)

import Http
import Json.Decode as Json exposing ((:=))
import Task


redmineUrl : String
redmineUrl =
    "http://projets.occitech.fr"


getProjects : String -> (Http.Error -> msg) -> (List ( Int, String ) -> msg) -> Cmd msg
getProjects key errorMsg msg =
    let
        url =
            Http.url (redmineUrl ++ "/projects.json") [ ( "key", key ) ]
    in
        Http.get projectsDecoder url |> Task.perform errorMsg msg


projectsDecoder : Json.Decoder (List ( Int, String ))
projectsDecoder =
    ("projects" := Json.list (Json.object2 (,) ("id" := Json.int) ("name" := Json.string)))
