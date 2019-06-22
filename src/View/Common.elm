module View.Common exposing (errorModalView, romSelector, screen)

import Bootstrap.Button as Button
import Bootstrap.Modal as Modal
import Component.PPU.GameBoyScreen as GameBoyScreen exposing (GameBoyScreen)
import Html exposing (Html, br, canvas, div, node, p, pre, text)
import Html.Attributes exposing (class, height, id, style, value, width)
import Html.Events exposing (onClick)
import Html.Keyed as K
import Html.Lazy
import Model exposing (ErrorModal)
import Msg exposing (FrontendMsg(..))


errorModalView : ErrorModal -> Html FrontendMsg
errorModalView errorModal =
    Modal.config CloseErrorModal
        |> Modal.large
        |> Modal.hideOnBackdropClick True
        |> Modal.h3 [] [ text errorModal.title ]
        |> Modal.body [] [ p [] [ text errorModal.body ] ]
        |> Modal.footer []
            [ Button.button
                [ Button.outlinePrimary
                , Button.attrs [ onClick CloseErrorModal ]
                ]
                [ text "Close" ]
            ]
        |> Modal.view errorModal.visibility


romSelector : Html FrontendMsg
romSelector =
    div [ class "screen-wrapper" ] [ div [ class "rom-selector", onClick OpenFileSelect ] [] ]


screen : GameBoyScreen -> String -> Html FrontendMsg
screen gbs canvasId =
    div [ class "screen-wrapper" ]
        [ textScreenLines gbs
        -- , textScreen gbs
        -- , textAreaScreen gbs
        ]


textScreenLines : GameBoyScreen -> Html FrontendMsg
textScreenLines gbs =
    div []
        [ pre
            [ style "font-family" "Consolas, Liberation Mono, Menlo, SFMono-Regular, monospace"
            , style "font-size" "1px"
            , style "margin-left" "193px"
            --, style "transform" "scale(5,3.75)"
            --, style "margin-top" "158px"
            , style "transform" "scale(5,3)"
            , style "margin-top" "144px"
            , style "width" "96.3px"
            , style "background-color" "rgb(155, 188, 15)"
            ]
            (gbs
                |> GameBoyScreen.getPixelList
                -- |> (\v -> v ++ List.concatMap (List.repeat (10 * 160)) (List.range 0 3)) -- uncomment to add think lines of solid color to the end of the screen, so you can see the colors used
                |> (\pxs -> chunk 0 pxs [] [])
                |> List.map (Html.Lazy.lazy text)
            )
        ]


chunk : Int -> List Int -> List String -> List String -> List String
chunk col pixels curr res =
    if col == 160 then
        chunk 0 pixels [] (String.concat (List.reverse ("\n" :: curr)) :: res)

    else
        case pixels of
            [] ->
                List.reverse res

            px :: pxRest ->
                chunk (col + 1) pxRest (colorChar px :: curr) res


textScreen : GameBoyScreen -> Html FrontendMsg
textScreen gbs =
    node "pre"
        [ style "font-family" "Consolas, Liberation Mono, Menlo, SFMono-Regular, monospace"
        , style "font-size" "1px"
        , style "transform" "scale(5,3.5)"
        , style "padding-left" "190px"
        , style "padding-top" "120px"
        ]
        [ text <|
            String.concat <|
                (gbs
                    |> GameBoyScreen.getPixelList
                    |> (\v -> v ++ List.concatMap (List.repeat (10 * 160)) (List.range 0 3))
                    |> List.indexedMap
                        (\idx px ->
                            colorChar px
                                ++ (if (idx |> modBy 160) == 159 then
                                        "|\n"

                                    else
                                        ""
                                   )
                        )
                )
        ]


textAreaScreen : GameBoyScreen -> Html FrontendMsg
textAreaScreen gbs =
    node "textarea"
        [ style "font-family" "Consolas, Liberation Mono, Menlo, SFMono-Regular, monospace"
        , style "font-size" "1px"
        , style "transform" "scale(5,3.5)"
        , style "margin-left" "190px"
        , style "margin-top" "120px"
        , width 200
        , height 200
        , value
            (String.concat <|
                (gbs
                    |> GameBoyScreen.getPixelList
                    |> (\v -> v ++ List.concatMap (List.repeat (10 * 160)) (List.range 0 3))
                    |> List.indexedMap
                        (\idx px ->
                            colorChar px
                                ++ (if (idx |> modBy 160) == 159 then
                                        "|\n"

                                    else
                                        ""
                                   )
                        )
                )
            )
        ]
        []



--K.node "div"
--    []
--    (mgbs
--        |> Maybe.map GameBoyScreen.getPixelList
--        |> Maybe.withDefault (List.repeat (160 * 144) 0)
--        |> List.indexedMap
--            (\idx px ->
--                [ ( "key-" ++ String.fromInt idx
--                  , div
--                        [ id ("key-" ++ String.fromInt idx)
--                        , style "background-color" (color px)
--                        , style "width" "5px"
--                        , style "height" "5px"
--                        ]
--                        []
--                  )
--                ]
--                    ++ (if (idx |> modBy 160) == 159 then
--                            [ ( "key-br-" ++ String.fromInt idx, br [ id ("key-br-" ++ String.fromInt idx) ] [] ) ]
--
--                        else
--                            []
--                       )
--            )
--        |> List.concat
--    )


color px =
    case px of
        0 ->
            "rgb(155, 188, 15)"

        1 ->
            "rgb(139, 172, 15)"

        2 ->
            "rgb(48, 98, 48)"

        _ ->
            "rgb(15, 56, 15)"


colorChar px =
    case px of
        0 ->
            -- em-space (fixed-width space, same width as a capital M character)
            "\u{2003}"

        1 ->
            "░"

        2 ->
            "▒"

        _ ->
            "▓"
