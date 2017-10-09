port module Configurator exposing (Config, update, view, init, isComplete, subscriptions, Msg, getRedmineKey, getTogglKey)

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


isComplete : Config -> Bool
isComplete config =
    Maybe.map2
        (\cfgRedmine -> \cfgToggl -> cfgRedmine /= "" && cfgToggl /= "")
        (Dict.get redmineKey config)
        (Dict.get togglKey config)
        |> Maybe.withDefault False


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
helpRedmineAPI =
    p [ class "lh-copy bg-near-white f6 pa2" ]
        [ text "Votre clé API Redmine est accessible depuis "
        , a [ href "http://projets.occitech.fr/my/account", class "link" ] [ text "votre compte Redmine" ]
        , text ", pour obtenir votre clé il suffit de cliquer sur 'Afficher' en dessous de 'Clé d'accès API' (qui se situe à droite de l'écran)."
        ]


helpTogglAPI : Html msg
helpTogglAPI =
    p [ class "lh-copy bg-near-white f6 pa2" ]
        [ text "Votre clé API Toggl est accessible depuis "
        , a [ href "https://toggl.com/app/profile", class "link" ] [ text "votre profil Toggl." ]
        ]


view : Config -> Html Msg
view config =
    div [ class "mb5" ]
        [ h2 [] [ text "Configurez l'application" ]
        , div [ class "mb4" ]
            [ getRedmineKey config
                |> ConfigInput.Field redmineKey "Insérez votre clé API Redmine: "
                |> ConfigInput.view (UpdateConfig redmineKey) (helpRedmineAPI)
            ]
        , div [ class "mb4" ]
            [ getTogglKey config
                |> ConfigInput.Field togglKey "Insérez votre clé API Toggl: "
                |> ConfigInput.view (UpdateConfig togglKey) helpTogglAPI
            ]
        ]
