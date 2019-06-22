module Component.PPU.GameBoyScreen exposing
    ( GameBoyScreen
    , empty
    , getPixelList
    , pushPixel
    , pushPixels
    , serializePixelBatches
    )

import Array exposing (Array)
import Bitwise
import Component.PPU.Pixel exposing (Pixel)


type GameBoyScreen
    = GameBoyScreen (Array Int) (List Int) Int Int


empty : GameBoyScreen
empty =
    GameBoyScreen Array.empty [] 0 0x00


pushPixel : Pixel -> GameBoyScreen -> GameBoyScreen
pushPixel pixel (GameBoyScreen pxList batchedPixels pixelsInBuffer buffer) =
    GameBoyScreen (Array.push pixel pxList) batchedPixels 0 0x00



{-
   let
       updatedBuffer =
           Bitwise.or pixel (Bitwise.shiftLeftBy 2 buffer)

       updatedPixelsInBuffer =
           pixelsInBuffer + 1
   in
   if updatedPixelsInBuffer == 16 then
       GameBoyScreen (pixel :: pxList) (updatedBuffer :: batchedPixels) 0 0x00

   else
       GameBoyScreen (pixel :: pxList) batchedPixels updatedPixelsInBuffer updatedBuffer
-}


pushPixels : GameBoyScreen -> List Pixel -> GameBoyScreen
pushPixels screen pixels =
    List.foldl pushPixel screen pixels


serializePixelBatches : GameBoyScreen -> List Int
serializePixelBatches (GameBoyScreen pxList batchedPixels pixelsInBuffer buffer) =
    []



{- let
       resultAfterFlushing =
           if pixelsInBuffer /= 0 then
               Bitwise.shiftLeftBy (16 - pixelsInBuffer * 2) buffer :: batchedPixels

           else
               batchedPixels
   in
   List.reverse resultAfterFlushing
-}


getPixelList : GameBoyScreen -> List Pixel
getPixelList (GameBoyScreen pxList _ _ _) =
    let
        chunksOfLeft : Int -> List a -> List (List a)
        chunksOfLeft k xs =
            let
                len =
                    List.length xs
            in
            if len > k then
                List.take k xs :: chunksOfLeft k (List.drop k xs)

            else
                [ xs ]
    in
    Array.toList pxList
