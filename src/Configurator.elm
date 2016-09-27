port module Configurator exposing (..)

import Html exposing (..)
import Views.ConfigInput as ConfigInput
import Dict exposing (Dict)
import Debug


port saveConfig : List ( String, String ) -> Cmd msg


port checkStoredConfig : () -> Cmd msg


port getStoredConfig : (List ( String, String ) -> msg) -> Sub msg


type alias Config =
    Dict String String


emptyConfig =
    Dict.fromList []


init : Config -> ( Config, Cmd Msg )
init config =
    config ! [ checkStoredConfig () ]


type Msg
    = UpdateConfig String String
    | StoredKeys (List ( String, String ))


update : Msg -> Config -> ( Config, Cmd Msg )
update msg config =
    case msg of
        UpdateConfig configType str ->
            let
                newConfig =
                    Dict.insert configType str config
            in
                newConfig ! [ saveConfig (Dict.toList newConfig) ]

        StoredKeys storedConfig ->
            Dict.fromList storedConfig
                ! []


subscriptions : Sub Msg
subscriptions =
    getStoredConfig StoredKeys


view : Config -> Html Msg
view config =
    div []
        [ ConfigInput.view (UpdateConfig "redmine") (ConfigInput.Field "redmine" "Redmine" (Maybe.withDefault "" (Dict.get "redmine" config)))
        , ConfigInput.view (UpdateConfig "toggl") (ConfigInput.Field "toggl" "Toggl" (Maybe.withDefault "" (Dict.get "toggl" config)))
        ]
