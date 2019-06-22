module Msg exposing (BackendMsg(..), FrontendMsg(..), ToBackend(..), ToFrontend(..), sendToBackend, sendToFrontend)

import Component.Cartridge exposing (Cartridge)
import Component.Joypad exposing (GameBoyButton)
import File exposing (File)
import GameBoy exposing (GameBoy)
import Lamdera.Backend
import Lamdera.Frontend
import Lamdera.Types exposing (ClientId, Milliseconds, WsError)


type FrontendMsg
    = OpenFileSelect
    | FileSelected File
    | CartridgeSelected (Maybe Cartridge)
    | AnimationFrameDelta Float
    | ButtonDown GameBoyButton
    | ButtonUp GameBoyButton
    | Reset
    | Pause
    | Resume
    | CloseErrorModal
    | EnableAPU
    | DisableAPU
    | NoOp
    | SaveTheGame
    | SendSaveStateToBackendFeedback (Result WsError ())


type BackendMsg
    = SendSavestateToClientFeedback (Result WsError ())


type ToFrontend
    = FetchedSaveState (Maybe GameBoy)


type ToBackend
    = SaveMyGameState String GameBoy
    | LoadSavestate String


sendToBackend :
    Milliseconds
    -> (Result WsError () -> FrontendMsg)
    -> ToBackend
    -> Cmd FrontendMsg
sendToBackend =
    Lamdera.Frontend.sendToBackend


sendToFrontend :
    Milliseconds
    -> ClientId
    -> (Result WsError () -> BackendMsg)
    -> ToFrontend
    -> Cmd BackendMsg
sendToFrontend =
    Lamdera.Backend.sendToFrontend
