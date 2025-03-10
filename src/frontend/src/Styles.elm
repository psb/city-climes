module Styles exposing (..)

import Css exposing (..)
import Css.Colors exposing (..)
import Css.Transitions exposing (transition, easeOut, easeIn, easeInOut)
import Types exposing (DisplayData)
import Array exposing (Array, fromList, get)


backgroundImageGradient : Style
backgroundImageGradient =
    backgroundImage <| linearGradient2 toRight (stop orange) (stop yellow) [ stop aqua, stop white, stop blue ]


pageStyle : Style
pageStyle =
    batch
        [ fontFamilies
            [ "Office Code Pro"
            , "Source Code Pro"
            , "Consolas"
            , "Inconsolata"
            , "Menlo"
            , "Monaco"
            , "Courier Next"
            , "Courier New"
            , "Courier"
            , .value monospace
            ]
        , fontWeight normal
        , fontSize (Css.rem 0.8)
        , lineHeight (Css.rem 1.5)
        , overflowX scroll
        , width (pct 100)
        , backgroundImageGradient
        ]


tableStyle : Style
tableStyle =
    batch
        [ tableLayout fixed
        , borderCollapse collapse
        , width (pct 100)
        , minWidth (px 1280)
        , maxWidth (px 1280)
        , textAlign center
        , margin2 (px 0) auto
        , backgroundColor white
        , border3 (px 10) solid white
        ]


locationNameHeaderWidth : Style
locationNameHeaderWidth =
    width (pct 19)


monthHeaderWidth : Style
monthHeaderWidth =
    width (pct 6.75)


tdPadding : Style
tdPadding =
    padding2 (Css.rem 0.25) (Css.rem 0.2)


tdStyle : Style
tdStyle =
    batch
        [ border3 (px 1) solid black
        , tdPadding
        ]


notBoldFont : Style
notBoldFont =
    fontWeight normal


borderTopOnly : Style
borderTopOnly =
    batch
        [ borderTop3 (px 1) solid black
        , tdPadding
        ]


borderBottomOnly : Style
borderBottomOnly =
    batch
        [ borderBottom3 (px 1) solid black
        , tdPadding
        ]


theadBorderBottom : Style
theadBorderBottom =
    borderBottom3 (px 3) solid black


borderTopAndBottomOnly : Style
borderTopAndBottomOnly =
    batch
        [ borderTop3 (px 1) solid black
        , borderBottom3 (px 1) solid black
        , tdPadding
        ]


inputStyle : Style
inputStyle =
    batch
        [ borderStyle none
        , textAlign center
        , width (pct 90)
        ]


monthInputStyle : Style
monthInputStyle =
    batch
        [ inputStyle
        , disabled
            [ lightPurpleBackground
            , border3 (px 1) solid (hex "E9BAF1")
            ]
        ]


grayText : Style
grayText =
    color gray


whiteText : Style
whiteText =
    color white


blackText : Style
blackText =
    color black


purpleText : Style
purpleText =
    color purple


lightPurpleText : Style
lightPurpleText =
    color (hex "E9BAF1")


sortArrowPadding : Style
sortArrowPadding =
    padding2 (Css.rem 0) (Css.rem 0.25)


sortActiveStyle : Style
sortActiveStyle =
    batch
        [ color black
        , fontWeight bold
        , textDecoration underline
        ]


textAlignLeft : Style
textAlignLeft =
    textAlign left


textAlignRight : Style
textAlignRight =
    textAlign right


locationNameCellStyle : Style
locationNameCellStyle =
    batch
        [ textAlignLeft
        , textOverflow ellipsis
        , whiteSpace noWrap
        , overflow hidden
        ]


moreInfoCellStyle : Style
moreInfoCellStyle =
    batch
        [ locationNameCellStyle
        , grayText
        , fontSize (em 0.9)
        ]


loadingStyle : Style
loadingStyle =
    batch
        [ fontSize (Css.rem 1)
        , padding (Css.rem 0.5)
        ]


logoStyle : Style
logoStyle =
    batch
        [ fontWeight bold
        , fontStyle italic
        , backgroundImageGradient
        ]


greenBackground : Style
greenBackground =
    backgroundColor green


activeDisplayDataStyle : Style
activeDisplayDataStyle =
    batch
        [ backgroundColor (hex "FFDC00")
        , textDecoration underline
        , border3 (px 1) solid (hex "FFDC00")
        ]


lightYellowBackground : Style
lightYellowBackground =
    backgroundColor (hex "FFF4B1")


veryLightYellowBackground : Style
veryLightYellowBackground =
    backgroundColor (hex "FFFAD8")


purpleBackground : Style
purpleBackground =
    backgroundColor purple


lightPurpleBackground : Style
lightPurpleBackground =
    backgroundColor (hex "E9BAF1")


activeMonthsAreLockedStyle : Style
activeMonthsAreLockedStyle =
    batch
        [ lightPurpleBackground
        , textDecoration underline
        ]


activeDisplayRowStyle : Style
activeDisplayRowStyle =
    batch
        [ backgroundColor (hex "66D4FF")
        , textDecoration underline
        , border3 (px 1) solid (hex "66D4FF")
        ]


lightAquaBackground : Style
lightAquaBackground =
    backgroundColor (hex "CDF7FF")


silverBackground : Style
silverBackground =
    backgroundColor silver


redBackground : Style
redBackground =
    backgroundColor red


grayBackground : Style
grayBackground =
    backgroundColor gray


blackBackground : Style
blackBackground =
    backgroundColor black


cursorToPointerOnHover : Style
cursorToPointerOnHover =
    hover
        [ cursor pointer
        ]


largerFont : Style
largerFont =
    fontSize (Css.rem 0.9)


modalBackdropStyle : Style
modalBackdropStyle =
    batch
        [ position fixed
        , height (pct 100.0)
        , width (pct 100.0)
        , top (px 0)
        , left (px 0)
        , zIndex (int 100)
        ]


modalClosedBackdropStyle : Style
modalClosedBackdropStyle =
    batch
        [ backgroundColor (rgba 0 0 0 0.0)
        , display none
        ]


modalOpenBackdropStyle : Style
modalOpenBackdropStyle =
    batch
        [ backgroundColor (rgba 0 0 0 0.8)
        , display block
        ]


modalContainerStyle : Style
modalContainerStyle =
    batch
        [ padding (em 1)
        , backgroundColor white
        , position fixed
        , transition
            [ Css.Transitions.transform3 200 0 easeOut
            ]
        , zIndex (int 200)
        , marginTop (px 75)
        ]


modalClosedContainerStyle : Style
modalClosedContainerStyle =
    transform (translate2 (pct 0.0) (pct -500.0))


modalOpenContainerStyle : Style
modalOpenContainerStyle =
    transform (translate2 (pct 0.0) (pct 0.0))


resetModalStyle : Style
resetModalStyle =
    batch
        [ border3 (px 10) solid red
        , width (px 500)
        ]


aboutModalStyle : Style
aboutModalStyle =
    batch
        [ border3 (px 10) solid silver
        , width (px 500)
        ]


instructionsModalStyle : Style
instructionsModalStyle =
    batch
        [ borderLeft3 (px 10) solid orange
        , borderTop3 (px 10) solid yellow
        , borderBottom3 (px 10) solid aqua
        , borderRight3 (px 10) solid blue
        , width (px 500)
        ]


locationModalStyle : Style
locationModalStyle =
    batch
        [ borderLeft3 (px 10) solid orange
        , borderTop3 (px 10) solid yellow
        , borderBottom3 (px 10) solid aqua
        , borderRight3 (px 10) solid blue
        ]


noMarginTop : Style
noMarginTop =
    marginTop (px 0)


modalTitleStyle : Style
modalTitleStyle =
    batch
        [ marginBottom (Css.rem 0.8)
        , textDecoration underline
        , fontSize (Css.rem 1)
        , fontWeight normal
        ]


noUnderline : Style
noUnderline =
    textDecoration none


modalH2Style : Style
modalH2Style =
    batch
        [ fontSize (Css.rem 0.85)
        , fontWeight normal
        ]


padLeft20 : Style
padLeft20 =
    paddingLeft (px 20)


modalCheckboxStyle : Style
modalCheckboxStyle =
    batch
        [ largerFont
        , margin2 (px 0) (px 15)
        ]


modalButtonContainerStyle : Style
modalButtonContainerStyle =
    batch
        [ displayFlex
        , justifyContent spaceBetween
        ]


flexEndStyle : Style
flexEndStyle =
    justifyContent flexEnd


flexWrapStyle : Style
flexWrapStyle =
    flexWrap wrap


locationModalButtonContainerStyle : Style
locationModalButtonContainerStyle =
    batch
        [ displayFlex
        , justifyContent spaceAround
        , width (px 550)
        ]


columnButtonContainerStyle : Style
columnButtonContainerStyle =
    batch
        [ displayFlex
        , flexDirection column
        , alignItems center
        , padding2 (px 0) (px 5)
        ]


fixedWidthButton : Float -> Style
fixedWidthButton w =
    width (px w)


whiteButtonStyle : Style
whiteButtonStyle =
    batch
        [ margin2 (px 20) (px 10)
        , backgroundColor white
        , border3 (px 4) solid silver
        , padding (px 10)
        , textTransform uppercase
        , overflow hidden
        , outline zero
        , boxShadow4 (px 1) (px 1) (px 1) gray
        , lineHeight (Css.rem 1.5)
        , transition
            [ Css.Transitions.backgroundColor3 150 0 easeIn
            , Css.Transitions.boxShadow3 150 0 easeIn
            , Css.Transitions.border3 150 0 easeIn
            , Css.Transitions.opacity3 150 0 easeIn
            ]
        , hover
            [ backgroundColor silver
            , cursor pointer
            , boxShadow4 (px 1) (px 1) (px 1) black
            ]
        , active
            [ boxShadow5 inset (px 1) (px 1) (px 1) black
            ]
        , disabled
            [ boxShadow none
            , backgroundColor silver
            , border3 (px 4) solid silver
            , opacity (num 0.6)
            ]
        ]


lessMarginTop : Style
lessMarginTop =
    marginTop (px 10)


redButtonStyle : Style
redButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid red
        , hover
            [ color white
            , backgroundColor red
            ]
        ]


blueButtonStyle : Style
blueButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid blue
        , hover
            [ enabled
                [ color white
                , backgroundColor blue
                ]
            ]
        ]


purpleButtonStyle : Style
purpleButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid purple
        , hover
            [ color white
            , backgroundColor purple
            ]
        ]


blackButtonStyle : Style
blackButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid black
        , hover
            [ color white
            , backgroundColor black
            ]
        ]


inverseBlackButtonStyle : Style
inverseBlackButtonStyle =
    batch
        [ blackButtonStyle
        , backgroundColor black
        , color white
        , border3 (px 4) solid black
        , hover
            [ color black
            , backgroundColor white
            ]
        ]


aquaButtonStyle : Style
aquaButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid aqua
        , hover
            [ backgroundColor aqua
            , color white
            ]
        ]


greenButtonStyle : Style
greenButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid green
        , hover
            [ color white
            , backgroundColor green
            ]
        ]


orangeButtonStyle : Style
orangeButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid orange
        , hover
            [ color white
            , backgroundColor orange
            ]
        ]


yellowButtonStyle : Style
yellowButtonStyle =
    batch
        [ whiteButtonStyle
        , backgroundColor white
        , border3 (px 4) solid yellow
        , hover
            [ color black
            , backgroundColor yellow
            ]
        ]


linkButtonStyle : Style
linkButtonStyle =
    batch
        [ textDecoration none
        , color initial
        , textAlign center
        ]


pageControlsNavContainerStyle : Style
pageControlsNavContainerStyle =
    batch
        [ displayFlex
        , alignItems center
        , margin2 (px 10) auto
        , width (px 1280)
        ]


pageControlsContainerStyle : Style
pageControlsContainerStyle =
    batch
        [ displayFlex
        , alignItems center
        , marginLeft (px 10)
        , marginRight (px 20)
        ]


pageControlsPageInfoStyle : Style
pageControlsPageInfoStyle =
    batch
        [ displayFlex
        , flexDirection column
        , alignItems center
        ]


goToPageInputStyle : Style
goToPageInputStyle =
    width (px 75)


valueCellStyle : DisplayData -> Float -> Style
valueCellStyle displayData val =
    let
        calcColorIndex : Int -> Int -> Int -> Float -> Int
        calcColorIndex noOfCategories minMaxDiff maxVal vdv =
            (toFloat maxVal - vdv)
                / (toFloat minMaxDiff / toFloat noOfCategories)
                |> Basics.round

        getColors : Array ( String, Color ) -> Int -> ( String, Color )
        getColors ls idx =
            if idx > 30 then
                Maybe.withDefault ( "111111", white ) (get 30 ls)
            else
                Maybe.withDefault ( "111111", white ) (get idx ls)

        ( hexColor, textColor ) =
            case displayData of
                Types.Celsius ->
                    calcColorIndex 31 122 55 val
                        |> getColors temperatureColors

                Types.Fahrenheit ->
                    calcColorIndex 31 219 131 val
                        |> getColors temperatureColors

                Types.SunshineHours ->
                    if val > 450 then
                        getColors sunshineColors 0
                    else
                        calcColorIndex 30 460 460 val
                            |> getColors sunshineColors
    in
        batch
            [ backgroundColor (hex hexColor)
            , color textColor
            ]


temperatureColors : Array ( String, Color )
temperatureColors =
    -- http://www.perbang.dk/rgbgradient/
    fromList
        [ ( "720000", white ) -- darker red; future hotter
        , ( "8B0000", white ) -- dark red; hottest
        , ( "9B0F00", white )
        , ( "AC1E00", white )
        , ( "BC2D00", white )
        , ( "CD3D00", white )
        , ( "DD4C00", white )
        , ( "EE5B00", white )
        , ( "FF6A00", black )
        , ( "FFE01C", black )
        , ( "C0FF39", black )
        , ( "7EFF56", black )
        , ( "73FF90", black )
        , ( "90FFD9", black )
        , ( "ADF6FF", black )
        , ( "CAE1FF", black )
        , ( "E7E7FF", black ) -- light blue; 0
        , ( "CBCBF1", black )
        , ( "B1B1E4", black )
        , ( "9898D6", black )
        , ( "8282C9", black )
        , ( "6D6DBC", white )
        , ( "5A5AAE", white )
        , ( "4949A1", white )
        , ( "393994", white )
        , ( "2B2B86", white )
        , ( "1F1F79", white )
        , ( "14146C", white )
        , ( "0C0C5E", white )
        , ( "050551", white )
        , ( "000044", white ) -- navy/black; coldest
        ]


sunshineColors : Array ( String, Color )
sunshineColors =
    -- http://www.perbang.dk/rgbgradient/
    fromList
        [ ( "FFF5B8", black )
        , ( "FFEE7F", black )
        , ( "FCEA73", black )
        , ( "FAE667", black )
        , ( "F7E35C", black )
        , ( "F5DF50", black )
        , ( "F2DB45", black )
        , ( "F0D839", black )
        , ( "EDD42E", black )
        , ( "EBD022", black )
        , ( "E8CD17", black )
        , ( "E6C90B", black )
        , ( "E4C600", black )
        , ( "D8B30C", black )
        , ( "CCA316", black )
        , ( "C09420", black )
        , ( "B58728", black )
        , ( "A97B2F", white )
        , ( "9D7134", white )
        , ( "916838", white )
        , ( "865F3B", white )
        , ( "7A573D", white )
        , ( "6E503D", white )
        , ( "63493C", white )
        , ( "57423A", white )
        , ( "4B3B36", white )
        , ( "3F3431", white )
        , ( "342C2B", white )
        , ( "282423", white )
        , ( "1C1B1B", white )
        , ( "111111", white )
        ]
