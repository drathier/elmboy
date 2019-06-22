module Model exposing (ErrorModal, Model, SaveAttemptStatus(..))

import Bootstrap.Modal as Modal
import Component.PPU.GameBoyScreen exposing (GameBoyScreen)
import GameBoy exposing (GameBoy)


type alias Model =
    { gameBoy : Maybe GameBoy
    , gameBoyScreen : GameBoyScreen
    , frameTimes : List Float
    , errorModal : Maybe ErrorModal
    , debuggerEnabled : Bool
    , emulateOnAnimationFrame : Bool
    , skipNextFrame : Bool
    , lastSaveAttempt : SaveAttemptStatus
    , currentSaveGameName : String
    }


type alias ErrorModal =
    { visibility : Modal.Visibility
    , title : String
    , body : String
    }


type SaveAttemptStatus
    = SaveFailure
    | SaveSuccess
    | SaveInProgress
    | SaveIdle
