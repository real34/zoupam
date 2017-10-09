module Versions exposing (..)

import Html exposing (..)
import Html.Events exposing (onClick, onInput)
import Html.Attributes exposing (value, class)
import RedmineAPI exposing (Versions, Version)
import Http
import Date
import Date.Extra
import Views.Spinner


type alias Model =
    { versions : Maybe Versions
    , selected : Maybe Version
    , loading : Bool
    , redmineKey : String
    }


type Msg
    = SelectVersion String
    | FetchStart String String
    | FetchEnd (Result Http.Error Versions)


init : Model
init =
    { versions = Nothing
    , selected = Nothing
    , loading = False
    , redmineKey = ""
    }


emptyVersion : Version
emptyVersion =
    { id = -1
    , name = "--- Veuillez sélectionner une version ---"
    , dueOn = Nothing
    , description = ""
    }


compareVersions : Version -> Version -> Order
compareVersions v1 v2 =
    let
        withOldDefault =
            Maybe.withDefault (Date.Extra.fromCalendarDate 1942 Date.Jan 1)
    in
        Date.Extra.compare (v1.dueOn |> withOldDefault) (v2.dueOn |> withOldDefault)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        FetchStart redmineKey projectId ->
            { model | loading = True, selected = Nothing } ! [ RedmineAPI.getVersions redmineKey projectId FetchEnd ]

        SelectVersion versionValue ->
            let
                versionId =
                    versionValue |> String.toInt |> Result.withDefault -1
            in
                case versionId of
                    (-1) ->
                        { model | selected = Nothing } ! []

                    _ ->
                        let
                            isVersion : Version -> Bool
                            isVersion version =
                                version.id == versionId
                        in
                            { model
                                | selected =
                                    case model.versions of
                                        Nothing ->
                                            Nothing

                                        Just versions ->
                                            versions
                                                |> List.filter isVersion
                                                |> List.head
                            }
                                ! []

        FetchEnd (Ok fetchedVersions) ->
            let
                versions =
                    fetchedVersions
                        |> List.sortWith compareVersions
                        |> List.reverse
            in
                { model | loading = False, versions = Just (emptyVersion :: versions) } ! []

        FetchEnd (Err _) ->
            { model | loading = False } ! []


view : Model -> Html Msg
view model =
    case model.loading of
        True ->
            Views.Spinner.view

        False ->
            case model.versions of
                Nothing ->
                    div [] []

                Just versions ->
                    div [ class "tc mt2" ]
                        [ select [ onInput SelectVersion, class "pa2" ]
                            (List.map
                                (\version -> option [ version.id |> toString |> value ] [ text version.name ])
                                versions
                            )
                        ]
