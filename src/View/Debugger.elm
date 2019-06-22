module View.Debugger exposing (view)

import Html exposing (Html, text)
import Model exposing (Model)
import Msg exposing (FrontendMsg)


view : String -> Model -> Html FrontendMsg
view _ _ =
    text "debugger"
