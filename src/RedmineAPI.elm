module RedmineAPI exposing (..)

import Http
import Json.Decode as Json exposing (field)
import Json.Decode.Extra exposing ((|:))


type alias Issue =
    { id : Int
    , description : String
    , subject : String
    , priority : String
    , doneRatio : Int
    , version : Maybe Version
    , status : String
    , estimated : Maybe Int
    }


type alias Version =
    { id : Int
    , name : String
    }


type alias Projects =
    List ( Int, String )


redmineUrl : String
redmineUrl =
    "https://projets.occitech.fr"


getProjects : String -> (Result Http.Error Projects -> msg) -> Cmd msg
getProjects key msg =
    let
        url =
            redmineUrl
                ++ "/projects.json?key="
                ++ key
                ++ "&limit=1000"
    in
        Http.send msg <| Http.get url projectsDecoder


getIssues : String -> String -> (Result Http.Error (List Issue) -> msg) -> Cmd msg
getIssues key projectId msg =
    let
        url =
            redmineUrl
                ++ "/issues.json?key="
                ++ key
                ++ "&project_id="
                ++ projectId
                ++ "&status_id=*&limit=1000"
    in
        Http.send msg <| Http.get url issuesDecoder


projectsDecoder : Json.Decoder Projects
projectsDecoder =
    Json.map2 (,) (field "id" Json.int) (field "name" Json.string)
        |> Json.list
        |> field "projects"


issuesDecoder : Json.Decoder (List Issue)
issuesDecoder =
    Json.succeed Issue
        |: (field "id" Json.int)
        |: (field "description" Json.string)
        |: (field "subject" Json.string)
        |: (field "priority" <| field "name" <| Json.string)
        |: (field "done_ratio" Json.int)
        |: (Json.maybe <| field "fixed_version" <| Json.map2 Version (field "id" Json.int) (field "name" Json.string))
        |: (field "status" <| field "name" Json.string)
        |: (Json.maybe <| field "estimated_hours" Json.int)
        |> Json.list
        |> field "issues"
