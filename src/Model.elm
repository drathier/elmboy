module Model exposing (..)

import Array exposing (Array)
import Bootstrap.Modal as Modal
import Component.APU.NoiseChannel exposing (NoiseChannel)
import Component.APU.PulseChannel exposing (PulseChannel)
import Component.CPU exposing (CPU)
import Component.Joypad exposing (Joypad)
import Component.PPU.GameBoyScreen exposing (GameBoyScreen)
import Component.Timer exposing (Timer)


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


type alias GameBoy =
    { cpu : CPU
    , ppu : PPU
    , timer : Timer
    , apu : APU
    , workRamBank0 : RAM
    , workRamBank1 : RAM
    , hram : RAM
    , bootRomDisabled : Bool
    , cartridge : Cartridge
    , joypad : Joypad
    , lastInstructionCycles : Int
    }


type RAM
    = RAM (Array Int)


type alias Cartridge =
    { bytes : Array Int
    , ram : RAM
    , selectedRomBank : Int
    , selectedRamBank : Int
    , ramEnabled : Bool
    , mbc1BankingMode : MBC1BankingMode
    , memoryBankController : MemoryBankController
    }


type MemoryBankController
    = ROM
    | MBC1
    | MBC3
    | MBC5


type MBC1BankingMode
    = ROMBanking
    | RAMBanking


type alias Sprite =
    { y : Int
    , x : Int
    , tileId : Int
    , flags : Int
    }


type alias PPU =
    { mode : Mode
    , vram : RAM
    , line : Int
    , lineCompare : Int
    , scrollX : Int
    , scrollY : Int
    , windowX : Int
    , windowY : Int
    , lcdc : Int
    , sprites : Array Sprite
    , screen : GameBoyScreen
    , lastCompleteFrame : Maybe GameBoyScreen
    , cyclesSinceLastCompleteFrame : Int
    , backgroundPalette : Int
    , objectPalette0 : Int
    , objectPalette1 : Int
    , triggeredInterrupt : PPUInterrupt
    , lcdStatus : Int

    {-
       We omit every other frame to increase emulation performance. Omitted frames are still emulated, but no pixels will be
       produced - speeding up the emulation at the cost of halved refresh rate (30fps). Omitted frames will use the same pixels as the
       previous frame.
    -}
    , omitFrame : Bool
    }


type Mode
    = OamSearch
    | PixelTransfer
    | HBlank
    | VBlank


type PPUInterrupt
    = VBlankInterrupt
    | HBlankInterrupt
    | LineCompareInterrupt
    | OamInterrupt
    | NoInterrupt


type alias APU =
    { channel1 : PulseChannel
    , channel2 : PulseChannel
    , channel3 : WaveChannel
    , channel4 : NoiseChannel
    , sampleBuffer : List ( Float, Float )
    , cycleAccumulator : Int
    , frameSequencerCounter : Int
    , frameSequence : Int
    , enabled : Bool
    , powerOn : Bool
    , leftVolume : Int
    , rightVolume : Int
    , vinLeftEnable : Bool
    , vinRightEnable : Bool
    , enabledChannels :
        { channel1Left : Bool
        , channel2Left : Bool
        , channel3Left : Bool
        , channel4Left : Bool
        , channel1Right : Bool
        , channel2Right : Bool
        , channel3Right : Bool
        , channel4Right : Bool
        }
    }

type alias WaveChannel =
    { waveRam : RAM
    , frequency : Int
    , wavePosition : Int
    , timerValue : Int
    , dacPower : Bool
    , enabled : Bool
    , volume : Int

    -- Length
    , lengthCounter : Int
    , lengthEnabled : Bool
    }
