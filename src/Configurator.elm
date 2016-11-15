port module Configurator exposing (Config, update, view, init, subscriptions, Msg, getRedmineKey, getTogglKey)

import Html exposing (..)
import Views.ConfigInput as ConfigInput
import Dict exposing (Dict)


port saveConfig : StoredConfig -> Cmd msg


port checkStoredConfig : () -> Cmd msg


port getStoredConfig : (StoredConfig -> msg) -> Sub msg


type alias StoredConfig =
    List ( String, String )


type alias Config =
    Dict String String


redmineKey : String
redmineKey =
    "redmine"


togglKey : String
togglKey =
    "toggl"


emptyConfig : Config
emptyConfig =
    Dict.fromList []


init : ( Config, Cmd Msg )
init =
    emptyConfig ! [ checkStoredConfig () ]


getRedmineKey : Config -> String
getRedmineKey config =
    Dict.get redmineKey config
        |> Maybe.withDefault ""


getTogglKey : Config -> String
getTogglKey config =
    Dict.get togglKey config
        |> Maybe.withDefault ""


type Msg
    = UpdateConfig String String
    | StoredKeys StoredConfig


update : Msg -> Config -> ( Config, Cmd Msg )
update msg config =
    case msg of
        UpdateConfig configType str ->
            let
                newConfig =
                    config |> Dict.insert configType str
            in
                newConfig ! [ Dict.toList newConfig |> saveConfig ]

        StoredKeys storedConfig ->
            Dict.fromList storedConfig
                ! []


subscriptions : Sub Msg
subscriptions =
    getStoredConfig StoredKeys


view : Config -> Html Msg
view config =
    div []
        [ getRedmineKey config
            |> ConfigInput.Field redmineKey "Redmine"
            |> ConfigInput.view (UpdateConfig redmineKey)
        , Dict.get togglKey config
            |> Maybe.withDefault ""
            |> ConfigInput.Field togglKey "Toggl"
            |> ConfigInput.view (UpdateConfig togglKey)
        ]
