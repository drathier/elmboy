module Msg exposing (BackendMsg(..), FrontendMsg(..), ToBackend(..), ToFrontend(..))

import Component.Joypad exposing (GameBoyButton)
import File exposing (File)
import Lamdera.Types exposing (ClientId, Milliseconds, WsError)
import Model exposing (Cartridge, GameBoy)


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
