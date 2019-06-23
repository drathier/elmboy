module Backend exposing (Model, app, init, update, updateFromFrontend)

import Dict exposing (Dict)
import Lamdera.Backend
import Lamdera.Types exposing (ClientId)
import Model exposing (GameBoy)
import Msg exposing (..)


type alias Model =
    { savestates : Dict String GameBoy
    }


init : ( Model, Cmd BackendMsg )
init =
    ( { savestates = Dict.empty }, Cmd.none )


update : BackendMsg -> Model -> ( Model, Cmd BackendMsg )
update msg model =
    case msg of
        SendSavestateToClientFeedback _ ->
            -- we don't care if the save state arrived at the client; they'll ask for it again if the game didn't load
            ( model, Cmd.none )


updateFromFrontend : ClientId -> ToBackend -> Model -> ( Model, Cmd BackendMsg )
updateFromFrontend clientId msg model =
    case msg of
        SaveMyGameState url gameboy ->
            ( { model | savestates = Dict.insert url gameboy model.savestates }
            , Cmd.none
            )

        LoadSavestate url ->
            ( model
            , Msg.sendToFrontend 30000 clientId SendSavestateToClientFeedback (FetchedSaveState (Dict.get url model.savestates))
            )


app =
    Lamdera.Backend.application
        { init = init
        , update = update
        , subscriptions = \m -> Sub.none
        , updateFromFrontend = updateFromFrontend
        }
