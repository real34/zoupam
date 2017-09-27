module RedmineAPI exposing (..)

import Http
import Json.Decode as Json exposing (field)
import Json.Decode.Extra exposing ((|:), withDefault)
import Date exposing (Date)

type alias Issue =
    { id : Int
    , description : String
    , subject : String
    , priority : String
    , doneRatio : Int
    , status : String
    , estimated : Maybe Float
    }


type alias Version =
    { id : Int
    , name : String
    , dueOn : Maybe Date
    }
type alias Versions =
    List Version

type alias Project =
    { id : Int
    , name : String
    , status : Int
    }

type alias Projects =
    List Project

urlOf : Version -> String
urlOf version =
    redmineUrl ++ "/versions/" ++ (version.id |> toString)

redmineUrl : String
redmineUrl =
    "https://projets.occitech.fr"

isActiveProject : Project -> Bool
isActiveProject project =
    project.status == 1

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

getVersions : String -> String -> (Result Http.Error (List Version) -> msg) -> Cmd msg
getVersions key projectId msg =
    let
        url =
            redmineUrl
                ++ "/projects/"
                ++ projectId
                ++ "/versions.json?key="
                ++ key
    in
        Http.send msg <| Http.get url versionsDecoder

getIssues : String -> Int -> (Result Http.Error (List Issue) -> msg) -> Cmd msg
getIssues key versionId msg =
    let
        url =
            redmineUrl
                ++ "/issues.json?key="
                ++ key
                ++ "&fixed_version_id="
                ++ (versionId |> toString)
                ++ "&status_id=*&limit=1000&sort=priority:desc"
    in
        Http.send msg <| Http.get url issuesDecoder


projectsDecoder : Json.Decoder Projects
projectsDecoder =
    Json.succeed Project
        |: (field "id" Json.int)
        |: (field "name" Json.string)
        |: (field "status" Json.int)
        |> Json.list
        |> field "projects"

versionsDecoder : Json.Decoder (List Version)
versionsDecoder =
    Json.succeed Version
        |: (field "id" Json.int)
        |: (field "name" Json.string)
        |: (Json.maybe <| field "due_date" Json.Decode.Extra.date)
        |> Json.list
        |> field "versions"

issuesDecoder : Json.Decoder (List Issue)
issuesDecoder =
    Json.succeed Issue
        |: (field "id" Json.int)
        |: (field "description" Json.string)
        |: (field "subject" Json.string)
        |: (field "priority" <| field "name" <| Json.string)
        |: (field "done_ratio" Json.int)
        |: (field "status" <| field "name" Json.string)
        |: (Json.maybe <| field "estimated_hours" Json.float)
        |> Json.list
        |> field "issues"