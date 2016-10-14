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
            Http.url (redmineUrl ++ "/projects.json") [ ( "key", key ), ( "limit", "1000" ) ]
    in
        Http.get projectsDecoder url |> Task.perform errorMsg msg


projectsDecoder : Json.Decoder (List ( Int, String ))
projectsDecoder =
    ("projects" := Json.list (Json.object2 (,) ("id" := Json.int) ("name" := Json.string)))


type alias Issue =
    { id : Int
    , description : String
    , subject : String
    , priority : String
    , doneRatio : Int
    , version : Maybe Version
    }


type alias Version =
    { id : Int
    , name : String
    }


getIssues : String -> String -> (Http.Error -> msg) -> (List Issue -> msg) -> Cmd msg
getIssues key projectId errorMsg msg =
    let
        url =
            Http.url (redmineUrl ++ "/issues.json") [ ( "key", key ), ( "project_id", projectId ), ( "limit", "1000" ) ]
    in
        Http.get issuesDecoder url
            |> Task.perform errorMsg msg


issuesDecoder : Json.Decoder (List Issue)
issuesDecoder =
    ("issues"
        := Json.list
            (Json.object6 Issue
                ("id" := Json.int)
                ("description" := Json.string)
                ("subject" := Json.string)
                ("priority" := ("name" := Json.string))
                ("done_ratio" := Json.int)
                (Json.maybe ("fixed_version" := (Json.object2 Version ("id" := Json.int) ("name" := Json.string))))
            )
    )
