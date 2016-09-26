port module Configurator exposing (..)

import Html exposing (..)
import Views.ConfigInput as ConfigInput


port saveConfig : Config -> Cmd msg


port checkStoredConfig : () -> Cmd msg


port getStoredConfig : (Config -> msg) -> Sub msg


type alias Config =
    { redmineKey : String
    , togglKey : String
    }


init : String -> String -> ( Config, Cmd Msg )
init redmineKey togglKey =
    { redmineKey = redmineKey
    , togglKey = togglKey
    }
        ! [ checkStoredConfig () ]


type Msg
    = UpdateRedmine String
    | UpdateToggl String
    | StoredKeys Config


update : Msg -> Config -> ( Config, Cmd Msg )
update msg config =
    case msg of
        UpdateRedmine str ->
            let
                newConfig =
                    { config | redmineKey = str }
            in
                newConfig ! [ saveConfig newConfig ]

        UpdateToggl str ->
            let
                newConfig =
                    { config | togglKey = str }
            in
                newConfig ! [ saveConfig newConfig ]

        StoredKeys config ->
            config ! []


subscriptions : Sub Msg
subscriptions =
    getStoredConfig StoredKeys


view : Config -> Html Msg
view config =
    div []
        [ ConfigInput.view UpdateRedmine (ConfigInput.Field "redmine" "Redmine" config.redmineKey)
        , ConfigInput.view UpdateToggl (ConfigInput.Field "toggl" "Toggl" config.togglKey)
        ]
