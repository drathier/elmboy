module Frontend exposing (app)

import Bootstrap.Modal as Modal
import Browser.Events
import Browser.Navigation
import Bytes
import Bytes.Decode
import Component.Cartridge as Cartridge
import Component.PPU.GameBoyScreen as GameBoyScreen
import Constants
import Emulator
import File
import File.Select
import GameBoy
import Html exposing (Html, div)
import Html.Attributes exposing (href, rel)
import Json.Decode as Decode exposing (Error(..))
import Lamdera.Frontend as Frontend
import Model exposing (Model, SaveAttemptStatus(..))
import Msg exposing (FrontendMsg(..), ToBackend(..), ToFrontend(..))
import Task
import UI.KeyDecoder
import Url
import Util
import View.Debugger
import View.Emulator


app =
    Frontend.application
        { init = init
        , onUrlRequest = \_ -> NoOp
        , onUrlChange = \_ -> NoOp
        , update = update
        , updateFromBackend = updateFromBackend
        , subscriptions = subscriptions
        , view =
            \model ->
                { title = "Lamdera Collaborative Markdown"
                , body =
                    [ div []
                        [ Html.node "link" [ rel "stylesheet", href "src.f8b043ed.css" ] []
                        , view model
                        ]
                    ]
                }
        }


updateFromBackend : Msg.ToFrontend -> Model -> ( Model, Cmd FrontendMsg )
updateFromBackend toFrontend model =
    case toFrontend of
        FetchedSaveState (Just gameboy) ->
            ( { model | gameBoy = Just gameboy }, Cmd.none )

        FetchedSaveState Nothing ->
            -- TODO: tell user savestate fetch failed
            -- don't overwrite the gameBoy state with Nothing
            ( model, Cmd.none )


view : Model -> Html FrontendMsg
view model =
    if model.debuggerEnabled then
        View.Debugger.view canvasId model

    else
        View.Emulator.view canvasId model


init : Url.Url -> Browser.Navigation.Key -> ( Model, Cmd FrontendMsg )
init { fragment } _ =
    case fragment of
        Just v ->
            ( { initModel | currentSaveGameName = v }
            , Msg.sendToBackend 5000 SendSaveStateToBackendFeedback (Msg.LoadSavestate v)
            )

        Nothing ->
            ( initModel, Cmd.none )


initModel =
    { gameBoy = Nothing
    , gameBoyScreen = GameBoyScreen.empty
    , emulateOnAnimationFrame = False
    , frameTimes = []
    , errorModal = Nothing
    , debuggerEnabled = False
    , skipNextFrame = False
    , lastSaveAttempt = SaveIdle
    , currentSaveGameName = ""
    }


update : FrontendMsg -> Model -> ( Model, Cmd FrontendMsg )
update msg model =
    case msg of
        AnimationFrameDelta time ->
            case model.gameBoy of
                Just gameBoy ->
                    let
                        timeToEmulate =
                            min time 1000

                        cyclesToEmulate =
                            ceiling ((timeToEmulate / 1000) * toFloat Constants.cyclesPerSecond)

                        ( emulatedGameBoy, audioSamples, screen ) =
                            gameBoy
                                |> Emulator.emulateCycles cyclesToEmulate
                                |> GameBoy.drainBuffers

                        ( shouldSkipNextFrame, gbScreen ) =
                            case screen of
                                Just newScreen ->
                                    if model.skipNextFrame then
                                        ( False, model.gameBoyScreen )

                                    else
                                        ( True, newScreen )

                                Nothing ->
                                    ( False, model.gameBoyScreen )
                    in
                    ( { model | skipNextFrame = shouldSkipNextFrame, gameBoy = Just emulatedGameBoy, gameBoyScreen = gbScreen, frameTimes = time :: List.take 30 model.frameTimes }
                    , Cmd.none
                    )

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
            ( initModel, Cmd.none )

        Pause ->
            ( { model | emulateOnAnimationFrame = False }, Cmd.none )

        Resume ->
            ( { model | emulateOnAnimationFrame = True }, Cmd.none )

        EnableAPU ->
            ( { model | gameBoy = model.gameBoy |> Maybe.map (GameBoy.setAPUEnabled True) }, Cmd.none )

        DisableAPU ->
            ( { model | gameBoy = model.gameBoy |> Maybe.map (GameBoy.setAPUEnabled False) }, Cmd.none )

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
                    ( { model | gameBoy = Just (GameBoy.init cartridge True), emulateOnAnimationFrame = True }, Cmd.none )

                Nothing ->
                    let
                        errorModal =
                            { visibility = Modal.shown
                            , title = "Unsupported ROM"
                            , body =
                                "Your selected ROM is not yet supported by Elmboy. This is usually the case due to an unsupported memory bank controller"
                                    ++ " required by the ROM you're trying to run. Please select another game and report the issue in the GitHub issue tracker."
                            }
                    in
                    ( { model | errorModal = Just errorModal }, Cmd.none )

        CloseErrorModal ->
            ( { model | errorModal = Nothing }, Cmd.none )

        NoOp ->
            ( model, Cmd.none )

        SendSaveStateToBackendFeedback (Ok ()) ->
            ( { model | lastSaveAttempt = SaveSuccess }, Cmd.none )

        SendSaveStateToBackendFeedback (Err _) ->
            ( { model | lastSaveAttempt = SaveFailure }, Cmd.none )

        SaveTheGame ->
            case model.gameBoy of
                Nothing ->
                    -- how did you save a game without a cartridge in?
                    ( model, Cmd.none )

                Just gb ->
                    ( { model | lastSaveAttempt = SaveInProgress }
                    , Msg.sendToBackend 5000 SendSaveStateToBackendFeedback (SaveMyGameState model.currentSaveGameName gb)
                    )


subscriptions : Model -> Sub FrontendMsg
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
