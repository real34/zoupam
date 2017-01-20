port module Configurator exposing (Config, update, view, init, subscriptions, Msg, getRedmineKey, getTogglKey)

import Html exposing (..)
import Html.Attributes exposing (..)
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

helpRedmineAPI : Html msg
helpRedmineAPI = p [] [text "Votre clé API Redmine est accessible depuis "
       , a [href "http://projets.occitech.fr/my/account"][text "ce lien"]
       , text ", pour obtenir votre clé il suffit de cliquer sur 'Afficher' en dessous de 'Clé d'accès API' (qui se situe à droite de l'écran)."]

helpTogglAPI : Html msg
helpTogglAPI = p [] [text "Votre clé Toggl est accessible depuis "
       , a [href "https://toggl.com/app/profile"][text "ce lien"]]

view : Config -> Html Msg
view config =
    div []
        [ getRedmineKey config
            |> ConfigInput.Field redmineKey "Insérez votre clé API Redmine: "
            |> ConfigInput.view (UpdateConfig redmineKey) (helpRedmineAPI)
        , Dict.get togglKey config
            |> Maybe.withDefault ""
            |> ConfigInput.Field togglKey "Insérez votre clé API Toggl: "
            |> ConfigInput.view (UpdateConfig togglKey) helpTogglAPI
        ]
