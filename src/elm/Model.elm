module Model exposing (ErrorModal, Model)

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
    }


type alias ErrorModal =
    { visibility : Modal.Visibility
    , title : String
    , body : String
    }
