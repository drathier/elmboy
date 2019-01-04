module Main exposing (main)

import Bootstrap.Modal as Modal
import Browser
import Browser.Events
import Bytes
import Bytes.Decode
import Component.Cartridge as Cartridge
import Component.Joypad exposing (GameBoyButton(..))
import Component.PPU as PPU
import Component.PPU.GameBoyScreen as GameBoyScreen
import Constants
import Emulator
import File
import File.Select
import GameBoy
import Html exposing (Html)
import Json.Decode as Decode
import Model exposing (Model)
import Msg exposing (Msg(..))
import Ports
import Task
import UI.KeyDecoder
import Util
import View.Debugger
import View.Emulator


main : Program () Model Msg
main =
    Browser.element
        { view = view
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


view : Model -> Html Msg
view model =
    if model.debuggerEnabled then
        View.Debugger.view canvasId model

    else
        View.Emulator.view canvasId model


init : () -> ( Model, Cmd Msg )
init _ =
    ( { gameBoy = Nothing
      , emulateOnAnimationFrame = False
      , frameTimes = []
      , errorModal = Nothing
      , debuggerEnabled = False
      , apuEnabled = False
      }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        AnimationFrameDelta time ->
            case model.gameBoy of
                Just gameBoy ->
                    let
                        ( emulatedGameBoy, audioSamples ) =
                            gameBoy
                                |> Emulator.emulateCycles (Constants.cyclesPerSecond // 60)
                                |> GameBoy.drainAudioBuffer (44100 // 10)

                        cmds =
                            Cmd.batch
                                [ Ports.setPixelsFromBatches { canvasId = canvasId, pixelBatches = GameBoyScreen.serializePixelBatches (PPU.getLastCompleteFrame emulatedGameBoy.ppu) }
                                , Ports.queueAudioSamples audioSamples
                                ]
                    in
                    ( { model | gameBoy = Just emulatedGameBoy, frameTimes = time :: List.take 30 model.frameTimes }, cmds )

                Nothing ->
                    ( model, Cmd.none )

        ButtonDown button ->
            ( { model | gameBoy = model.gameBoy |> Maybe.map (GameBoy.setButtonStatus button True) }
            , Cmd.none
            )

        ButtonUp button ->
            ( { model | gameBoy = model.gameBoy |> Maybe.map (GameBoy.setButtonStatus button False) }
            , Cmd.none
            )

        Reset ->
            init ()

        Pause ->
            ( { model | emulateOnAnimationFrame = False }, Cmd.none )

        Resume ->
            ( { model | emulateOnAnimationFrame = True }, Cmd.none )

        OpenFileSelect ->
            ( model, File.Select.file [] FileSelected )

        FileSelected file ->
            file
                |> File.toBytes
                |> Task.map (\bytes -> Bytes.Decode.decode (Util.uint8ArrayDecoder (Bytes.width bytes)) bytes |> Maybe.andThen Cartridge.fromBytes)
                |> Task.perform CartridgeSelected
                |> Tuple.pair model

        CartridgeSelected maybeCartridge ->
            case maybeCartridge of
                Just cartridge ->
                    ( { model | gameBoy = Just (GameBoy.init cartridge model.apuEnabled), emulateOnAnimationFrame = True }, Cmd.none )

                Nothing ->
                    let
                        errorModal =
                            { visibility = Modal.shown
                            , title = "Unsupported ROM"
                            , body = "Your selected ROM is not yet supported by Elmboy. This is usually the case due to an unsupported memory bank controller required by the ROM you're trying to run. Please select another game and report the issue in the GitHub issue tracker."
                            }
                    in
                    ( { model | errorModal = Just errorModal }, Cmd.none )

        CloseErrorModal ->
            ( { model | errorModal = Nothing }, Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions model =
    let
        animationFrameSubscription =
            if model.emulateOnAnimationFrame then
                Browser.Events.onAnimationFrameDelta AnimationFrameDelta

            else
                Sub.none
    in
    Sub.batch
        [ animationFrameSubscription
        , Browser.Events.onKeyDown (Decode.map ButtonDown UI.KeyDecoder.decodeKey)
        , Browser.Events.onKeyUp (Decode.map ButtonUp UI.KeyDecoder.decodeKey)
        ]


canvasId : String
canvasId =
    "screen"
