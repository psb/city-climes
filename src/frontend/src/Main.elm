module Main exposing (..)

import Array exposing (Array, get, length, set)
import String exposing (toLower, toInt, left)
import Html
import Html.Styled exposing (..)
import Html.Styled.Attributes
    exposing
        ( css
        , placeholder
        , colspan
        , rowspan
        , scope
        , size
        , href
        , target
        , type_
        , pattern
        , id
        , disabled
        , title
        , maxlength
        , checked
        , value
        )
import Html.Styled.Events exposing (onInput, onClick)
import Html.Styled.Keyed as Keyed
import Http
import Dom.Scroll
import Task
import Date exposing (Date, toTime)
import Time.Date exposing (addDays)
import Time.DateTime as TDT exposing (fromTimestamp)
import Time.Iso8601 exposing (fromDate)
import RemoteData exposing (WebData)
import Data exposing (..)
import Css exposing (Style)
import Styles exposing (..)
import Types exposing (..)
import Analytics exposing (analytics)


-- import Debug


main : Program Never Model Msg
main =
    Html.program
        { init = init
        , update = update
        , view = view >> toUnstyled
        , subscriptions = \_ -> Sub.none
        }



-- MODEL


init : ( Model, Cmd Msg )
init =
    let
        model =
            { allData = RemoteData.Loading
            , pinnedLocations = []
            , unpinnedLocations = []
            , pages = Array.empty
            , pageNoIndex = 0
            , displayData = Celsius
            , temperatureDisplayRow = Both
            , sunshineDisplayRow = All
            , sortedBy = defaultSortedBy
            , monthFilterMaxInputs = defaultMonthFilterInputs
            , monthFilterMinInputs = defaultMonthFilterInputs
            , locationNameFilterInput = defaultLocationNameFilterInput
            , monthsAreLocked = False
            , instructionsModalIsOpen = True
            , resetModalIsOpen = False
            , aboutModalIsOpen = False
            , locationModalIsOpen = False
            , locationModalLocation = Nothing
            , resetSettings = defaultResetSettings
            , goToPageNoIndex = ""
            , checkInDate = ""
            , checkOutDate = ""
            }
    in
        ( model, loadData )



-- UPDATE


type Msg
    = DataResponse (WebData (List Location))
    | Paginate Bool
    | SetDisplayData DisplayData
    | SetTemperatureDisplayRow TemperatureDisplayRow
    | SetSunshineDisplayRow SunshineDisplayRow
    | ToggleMonthsAreLocked
    | OpenResetModal
    | OpenAboutModal
    | OpenLocationModal Location
    | ToggleLocationIsPinned Int Bool
    | FindSimilar Location
    | CloseAllModals
    | CloseInstructionsModal
    | ToggleResetFilterInputs
    | ToggleResetSorting
    | ToggleResetPinnedLocations
    | ResetData
    | SetSortedBy SortedBy
    | ReverseData
    | SortData
    | SetLocationFilter String
    | SetMonthFilterInputs MonthFilter Int String
    | SetPageNoIndex Int
    | SetGoToPageNoIndex String
    | GoToPage
    | NoOp
    | ScrollToTop
    | GetDate
    | GotDate Date
    | SendAnalytics String


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        DataResponse data ->
            let
                uLocations : List Location
                uLocations =
                    extractRemoteData data
            in
                update GetDate
                    { model
                        | allData = data
                        , unpinnedLocations = uLocations
                    }

        GetDate ->
            ( model, Task.perform GotDate Date.now )

        GotDate date ->
            let
                dateToString : Date -> Int -> String
                dateToString date daysToAdd =
                    date
                        |> toTime
                        |> fromTimestamp
                        |> TDT.date
                        |> addDays daysToAdd
                        |> fromDate

                checkIn : String
                checkIn =
                    dateToString date 2

                checkOut : String
                checkOut =
                    dateToString date 5
            in
                update SortData
                    { model
                        | checkInDate = checkIn
                        , checkOutDate = checkOut
                    }

        Paginate stayOnCurrentPage ->
            let
                pgs : Array (List Location)
                pgs =
                    paginate <| filterData model
            in
                if stayOnCurrentPage then
                    update (SetPageNoIndex model.pageNoIndex) { model | pages = pgs }
                else
                    update (SetPageNoIndex 0) { model | pages = pgs }

        SetDisplayData displayData ->
            ( { model | displayData = displayData }, Cmd.none )

        SetTemperatureDisplayRow displayRow ->
            ( { model | temperatureDisplayRow = displayRow }, Cmd.none )

        SetSunshineDisplayRow displayRow ->
            ( { model | sunshineDisplayRow = displayRow }, Cmd.none )

        ToggleMonthsAreLocked ->
            ( { model | monthsAreLocked = not model.monthsAreLocked }, Cmd.none )

        OpenResetModal ->
            ( { model | resetModalIsOpen = True }, Cmd.none )

        OpenAboutModal ->
            ( { model | aboutModalIsOpen = True }, Cmd.none )

        OpenLocationModal location ->
            ( { model
                | locationModalIsOpen = True
                , locationModalLocation = Just location
              }
            , Cmd.none
            )

        ToggleLocationIsPinned locationID isPinned ->
            let
                ( newPinnedLocations, newUnpinnedLocations ) =
                    toggleLocationPinning model.unpinnedLocations
                        model.pinnedLocations
                        locationID
                        model.sortedBy
            in
                update (Paginate True)
                    { model
                        | pinnedLocations = newPinnedLocations
                        , unpinnedLocations = newUnpinnedLocations
                    }

        FindSimilar location ->
            let
                toSimilar : Float -> Float -> Maybe Float
                toSimilar toAdd val =
                    val
                        + toAdd
                        |> round
                        |> toFloat
                        |> Just

                ( similarFilterMaxInputs, similarFilterMinInputs ) =
                    case model.displayData of
                        Celsius ->
                            ( Array.map (toSimilar 3.0) location.averageHighC
                            , Array.map (toSimilar -3.0) location.averageLowC
                            )

                        Fahrenheit ->
                            ( Array.map (toSimilar 6.0) location.averageHighF
                            , Array.map (toSimilar -6.0) location.averageLowF
                            )

                        SunshineHours ->
                            case location.sunshineHours of
                                Just arr ->
                                    ( Array.map (toSimilar 30.0) arr
                                    , Array.map (toSimilar -30.0) arr
                                    )

                                Nothing ->
                                    ( defaultMonthFilterInputs
                                    , defaultMonthFilterInputs
                                    )
            in
                update (Paginate False)
                    { model
                        | monthFilterMaxInputs = similarFilterMaxInputs
                        , monthFilterMinInputs = similarFilterMinInputs
                        , locationNameFilterInput = defaultLocationNameFilterInput
                    }

        CloseAllModals ->
            ( { model
                | resetModalIsOpen = False
                , aboutModalIsOpen = False
                , locationModalIsOpen = False
                , locationModalLocation = Nothing
              }
            , Cmd.none
            )

        CloseInstructionsModal ->
            ( { model | instructionsModalIsOpen = False }, Cmd.none )

        ToggleResetFilterInputs ->
            let
                oldResetSettings =
                    model.resetSettings

                newResetSettings =
                    { oldResetSettings
                        | resetFilterInputs = not oldResetSettings.resetFilterInputs
                    }
            in
                ( { model | resetSettings = newResetSettings }, Cmd.none )

        ToggleResetSorting ->
            let
                oldResetSettings =
                    model.resetSettings

                newResetSettings =
                    { oldResetSettings
                        | resetSorting = not oldResetSettings.resetSorting
                    }
            in
                ( { model | resetSettings = newResetSettings }, Cmd.none )

        ToggleResetPinnedLocations ->
            let
                oldResetSettings =
                    model.resetSettings

                newResetSettings =
                    { oldResetSettings
                        | resetPinnedLocations = not oldResetSettings.resetPinnedLocations
                    }
            in
                ( { model | resetSettings = newResetSettings }, Cmd.none )

        ResetData ->
            update (Paginate False) (resetData model)

        SetSortedBy newSort ->
            if model.sortedBy == newSort then
                -- Clicked on already sortedBy.col
                let
                    updatedSortedBy =
                        { newSort | order = flipSortOrder newSort.order }
                in
                    update ReverseData { model | sortedBy = updatedSortedBy }
            else
                let
                    updatedSortedBy =
                        case ( model.sortedBy.col, newSort.col ) of
                            -- Default sortedBy.order for month columns
                            ( LocationName, MonthColumn _ ) ->
                                { newSort | order = Descending }

                            ( MonthColumn _, LocationName ) ->
                                -- Default sortedBy.order for locationName column
                                { newSort | order = Ascending }

                            _ ->
                                newSort
                in
                    update SortData { model | sortedBy = updatedSortedBy }

        ReverseData ->
            update (Paginate False)
                { model
                    | pinnedLocations = List.reverse model.pinnedLocations
                    , unpinnedLocations = List.reverse model.unpinnedLocations
                }

        SortData ->
            update (Paginate False)
                { model
                    | pinnedLocations = sortLocations model.sortedBy model.pinnedLocations
                    , unpinnedLocations = sortLocations model.sortedBy model.unpinnedLocations
                }

        SetLocationFilter txt ->
            update (Paginate False) { model | locationNameFilterInput = txt }

        SetMonthFilterInputs monthFilter idx txt ->
            let
                newMonthFilterInputs : Array (Maybe Float) -> Int -> String -> Array (Maybe Float)
                newMonthFilterInputs arr idx txt =
                    case toInt txt of
                        Ok i ->
                            if model.monthsAreLocked then
                                Array.repeat 12 (Just <| toFloat i)
                            else
                                set idx (Just <| toFloat i) arr

                        Err _ ->
                            arr
            in
                case monthFilter of
                    MaxValue ->
                        let
                            updatedInputs : Array (Maybe Float)
                            updatedInputs =
                                newMonthFilterInputs
                                    model.monthFilterMaxInputs
                                    idx
                                    txt
                        in
                            ( { model | monthFilterMaxInputs = updatedInputs }
                            , Cmd.none
                            )

                    MinValue ->
                        let
                            updatedInputs : Array (Maybe Float)
                            updatedInputs =
                                newMonthFilterInputs
                                    model.monthFilterMinInputs
                                    idx
                                    txt
                        in
                            ( { model | monthFilterMinInputs = updatedInputs }
                            , Cmd.none
                            )

        SetPageNoIndex n ->
            let
                pg : Int
                pg =
                    if n >= 0 && n < length model.pages then
                        n
                    else
                        model.pageNoIndex
            in
                update ScrollToTop { model | pageNoIndex = pg }

        ScrollToTop ->
            ( model
            , Task.attempt (\_ -> CloseAllModals) (Dom.Scroll.toTop "cctop")
            )

        SetGoToPageNoIndex txt ->
            ( { model | goToPageNoIndex = txt }, Cmd.none )

        GoToPage ->
            let
                pg : Int
                pg =
                    case toInt model.goToPageNoIndex of
                        Ok i ->
                            if i > 0 && i <= length model.pages then
                                i - 1
                            else
                                model.pageNoIndex

                        Err _ ->
                            model.pageNoIndex
            in
                update (SetPageNoIndex pg) { model | goToPageNoIndex = "" }

        SendAnalytics linkName ->
            ( model, analytics linkName )



-- DATA FETCHING


loadData : Cmd Msg
loadData =
    Http.get dataURL locationsDecoder
        |> RemoteData.sendRequest
        |> Cmd.map DataResponse



-- VIEW


view : Model -> Html Msg
view model =
    let
        locations : List Location
        locations =
            case get model.pageNoIndex model.pages of
                Just pg ->
                    model.pinnedLocations ++ pg

                Nothing ->
                    model.pinnedLocations
    in
        div [ css [ pageStyle ] ]
            [ instructionsModal model.instructionsModalIsOpen
            , resetModal model.resetModalIsOpen model.resetSettings
            , aboutModal model.aboutModalIsOpen
            , locationModal model.locationModalIsOpen
                model.locationModalLocation
                model.checkInDate
                model.checkOutDate
            , tableOrLoading model locations model.allData
            , pageControls model
            ]


tableOrLoading : Model -> List Location -> WebData (List Location) -> Html Msg
tableOrLoading model locations response =
    let
        defaultTBody : Html Msg -> Html Msg
        defaultTBody txt =
            tbody [] [ tr [] [ td [ colspan 13, css [ loadingStyle, textAlignLeft ] ] [ txt ] ] ]
    in
        case response of
            RemoteData.NotAsked ->
                dataTable model (defaultTBody (text ""))

            RemoteData.Loading ->
                dataTable model (defaultTBody (text "Loading..."))

            RemoteData.Success _ ->
                if length model.pages == 0 then
                    dataTable model (defaultTBody (text "No Locations Match Your Filter Inputs."))
                else
                    dataTable model (Keyed.node "tbody" [] (List.concatMap (locationRow model) locations))

            RemoteData.Failure error ->
                dataTable model (defaultTBody (text (toString error)))


dataTable : Model -> Html Msg -> Html Msg
dataTable model msg =
    table [ css [ tableStyle ] ]
        [ Keyed.node "thead"
            [ css [ theadBorderBottom ] ]
            (List.concat
                [ [ labelRow ]
                , sortRows model
                , filterRows model
                , [ controlsRow model ]
                ]
            )
        , msg
        ]


months : List Month
months =
    [ January
    , February
    , March
    , April
    , May
    , June
    , July
    , August
    , September
    , October
    , November
    , December
    ]


locationRow : Model -> Location -> List ( String, Html Msg )
locationRow model location =
    let
        locationNameCell : Style -> Html Msg
        locationNameCell sty =
            let
                pinnedIcon : String
                pinnedIcon =
                    if location.isPinned then
                        "🍭 "
                    else
                        ""
            in
                th
                    [ css [ locationNameCellStyle, notBoldFont, sty ]
                    , scope "row"
                    , title location.locationNameAndCountry
                    ]
                    [ text (pinnedIcon ++ location.locationNameAndCountry) ]

        rowInfoCell : Html Msg
        rowInfoCell =
            td [ css [ moreInfoCellStyle, borderBottomOnly ] ]
                [ text "(click row for info)" ]

        restOfRow : DisplayData -> Array Float -> List (Html Msg)
        restOfRow displayData arr =
            List.indexedMap
                (\idx _ ->
                    let
                        val =
                            getValue 0 idx arr
                    in
                        td [ css [ tdStyle, (valueCellStyle displayData val) ] ]
                            [ text <| toString val ]
                )
                months
    in
        case model.displayData of
            Celsius ->
                case model.temperatureDisplayRow of
                    High ->
                        [ ( toString location.iD ++ "CH"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell tdStyle
                                    :: restOfRow model.displayData location.averageHighC
                                )
                          )
                        ]

                    Low ->
                        [ ( toString location.iD ++ "CL"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell tdStyle
                                    :: restOfRow model.displayData location.averageLowC
                                )
                          )
                        ]

                    Both ->
                        [ ( toString location.iD ++ "CH"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell borderTopOnly
                                    :: restOfRow model.displayData location.averageHighC
                                )
                          )
                        , ( toString location.iD ++ "CL"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (rowInfoCell
                                    :: restOfRow model.displayData location.averageLowC
                                )
                          )
                        ]

            Fahrenheit ->
                case model.temperatureDisplayRow of
                    High ->
                        [ ( toString location.iD ++ "FH"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell tdStyle
                                    :: restOfRow model.displayData location.averageHighF
                                )
                          )
                        ]

                    Low ->
                        [ ( toString location.iD ++ "FL"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell tdStyle
                                    :: restOfRow model.displayData location.averageLowF
                                )
                          )
                        ]

                    Both ->
                        [ ( toString location.iD ++ "FH"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell borderTopOnly
                                    :: restOfRow model.displayData location.averageHighF
                                )
                          )
                        , ( toString location.iD ++ "FL"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (rowInfoCell
                                    :: restOfRow model.displayData location.averageLowF
                                )
                          )
                        ]

            SunshineHours ->
                case location.sunshineHours of
                    Just arr ->
                        [ ( toString location.iD ++ "SH"
                          , tr
                                [ css [ cursorToPointerOnHover ]
                                , onClick (OpenLocationModal location)
                                ]
                                (locationNameCell tdStyle
                                    :: restOfRow model.displayData arr
                                )
                          )
                        ]

                    Nothing ->
                        case model.sunshineDisplayRow of
                            All ->
                                [ ( toString location.iD ++ "SH"
                                  , tr
                                        [ onClick (OpenLocationModal location)
                                        ]
                                        (locationNameCell tdStyle
                                            :: [ td
                                                    [ css
                                                        [ tdStyle, silverBackground, grayText ]
                                                    , colspan 12
                                                    ]
                                                    [ text "(not available)" ]
                                               ]
                                        )
                                  )
                                ]

                            OnlyJusts ->
                                []


labelRow : ( String, Html Msg )
labelRow =
    ( "labelRow"
    , tr []
        (th
            [ css
                [ locationNameCellStyle, tdStyle, locationNameHeaderWidth ]
            , scope "col"
            ]
            [ text "location name" ]
            :: List.map
                (\month ->
                    th [ css [ tdStyle, monthHeaderWidth ], scope "col" ]
                        [ month |> toString |> toLower |> left 3 |> text ]
                )
                months
        )
    )


noSortChar : String
noSortChar =
    " -"


ascendingArrow : String
ascendingArrow =
    " ▲"


descendingArrow : String
descendingArrow =
    " ▼"


sortRows : Model -> List ( String, Html Msg )
sortRows model =
    let
        firstSortRowCell : Html Msg
        firstSortRowCell =
            let
                ( sortStyle, sortIcon ) =
                    case ( model.sortedBy.col, model.sortedBy.order ) of
                        ( LocationName, Ascending ) ->
                            ( sortActiveStyle, ascendingArrow )

                        ( LocationName, Descending ) ->
                            ( sortActiveStyle, descendingArrow )

                        _ ->
                            ( grayText, noSortChar )
            in
                th
                    [ css
                        [ tdStyle, notBoldFont, sortStyle, cursorToPointerOnHover ]
                    , rowspan 2
                    , onClick
                        (SetSortedBy
                            { col = LocationName
                            , row = Nothing
                            , order = model.sortedBy.order
                            , displayDataType = model.displayData
                            }
                        )
                    , scope "row"
                    ]
                    [ text ("sort" ++ sortIcon) ]

        restOfRow : String -> Maybe SortRow -> List (Html Msg)
        restOfRow cellText sortRow =
            List.map
                (\month ->
                    let
                        ( sortStyle, sortIcon ) =
                            monthSortCellStyle model.sortedBy model.displayData sortRow month
                    in
                        td
                            [ css [ tdStyle, sortStyle, cursorToPointerOnHover ]
                            , onClick
                                (SetSortedBy
                                    { col = MonthColumn month
                                    , row = sortRow
                                    , order = model.sortedBy.order
                                    , displayDataType = model.displayData
                                    }
                                )
                            ]
                            [ text (cellText ++ sortIcon) ]
                )
                months
    in
        case model.displayData of
            Celsius ->
                [ ( "sortRowCelsiusHigh"
                  , tr []
                        (firstSortRowCell
                            :: restOfRow "high" (Just HighTemp)
                        )
                  )
                , ( "sortRowCelsiusLow", tr [] (restOfRow "low" (Just LowTemp)) )
                ]

            Fahrenheit ->
                [ ( "sortRowFahrenheitHigh"
                  , tr []
                        (firstSortRowCell
                            :: restOfRow "high" (Just HighTemp)
                        )
                  )
                , ( "sortRowFahrenheitLow", tr [] (restOfRow "low" (Just LowTemp)) )
                ]

            SunshineHours ->
                [ ( "sortRowSunshineHours"
                  , tr []
                        (firstSortRowCell
                            :: restOfRow "hours" Nothing
                        )
                  )
                , ( "sortRowSunshineFYI"
                  , tr []
                        [ td [ css [ tdStyle, silverBackground ], colspan 12 ]
                            [ text
                                ("FYI: Temperatures are average daily high or low "
                                    ++ "temperatures and sunshine hours are mean monthly "
                                    ++ "sunshine hours (where available)."
                                )
                            ]
                        ]
                  )
                ]


monthSortCellStyle : SortedBy -> DisplayData -> Maybe SortRow -> Month -> ( Style, String )
monthSortCellStyle sortedBy displayData sortRow month =
    case sortedBy.col of
        LocationName ->
            ( grayText, noSortChar )

        MonthColumn mon ->
            if mon == month then
                case ( displayData, sortedBy.row, sortedBy.order, sortRow ) of
                    ( SunshineHours, Nothing, Ascending, _ ) ->
                        ( sortActiveStyle, ascendingArrow )

                    ( SunshineHours, Nothing, Descending, _ ) ->
                        ( sortActiveStyle, descendingArrow )

                    ( _, Just HighTemp, Ascending, Just HighTemp ) ->
                        ( sortActiveStyle, ascendingArrow )

                    ( _, Just HighTemp, Descending, Just HighTemp ) ->
                        ( sortActiveStyle, descendingArrow )

                    ( _, Just LowTemp, Ascending, Just LowTemp ) ->
                        ( sortActiveStyle, ascendingArrow )

                    ( _, Just LowTemp, Descending, Just LowTemp ) ->
                        ( sortActiveStyle, descendingArrow )

                    _ ->
                        ( grayText, noSortChar )
            else
                ( grayText, noSortChar )


filterRows : Model -> List ( String, Html Msg )
filterRows model =
    let
        getMonthFilterValue : Array (Maybe Float) -> Int -> String
        getMonthFilterValue arr idx =
            case get idx arr of
                Just (Just i) ->
                    toString i

                Just Nothing ->
                    ""

                Nothing ->
                    ""
    in
        [ ( "filterRowMax"
          , tr []
                (th [ css [ tdStyle, notBoldFont ], rowspan 2, scope "row" ]
                    [ input
                        [ placeholder "filter names"
                        , css [ inputStyle ]
                        , onInput SetLocationFilter
                        , value model.locationNameFilterInput
                        ]
                        []
                    ]
                    :: List.indexedMap
                        (\monthIdx month ->
                            td [ css [ tdStyle ] ]
                                [ input
                                    [ placeholder "max."
                                    , css [ monthInputStyle ]
                                    , onInput (SetMonthFilterInputs MaxValue monthIdx)
                                    , disabled (model.monthsAreLocked && month /= May)
                                    , pattern "-?\\d+"
                                    , maxlength 4
                                    , value
                                        (getMonthFilterValue
                                            model.monthFilterMaxInputs
                                            monthIdx
                                        )
                                    ]
                                    []
                                ]
                        )
                        months
                )
          )
        , ( "filterRowMin"
          , tr []
                (List.indexedMap
                    (\monthIdx month ->
                        td [ css [ tdStyle ] ]
                            [ input
                                [ placeholder "min."
                                , css [ monthInputStyle ]
                                , onInput (SetMonthFilterInputs MinValue monthIdx)
                                , disabled (model.monthsAreLocked && month /= May)
                                , pattern "-?\\d+"
                                , maxlength 4
                                , value
                                    (getMonthFilterValue
                                        model.monthFilterMinInputs
                                        monthIdx
                                    )
                                ]
                                []
                            ]
                    )
                    months
                )
          )
        ]


controlsRow : Model -> ( String, Html Msg )
controlsRow model =
    let
        displayDataStyle : DisplayData -> DisplayData -> Style
        displayDataStyle modelDisplayData labelDisplayData =
            if modelDisplayData == labelDisplayData then
                activeDisplayDataStyle
            else
                lightYellowBackground

        monthsArelockedCellText : String
        monthsArelockedCellText =
            if model.monthsAreLocked then
                "unlock"
            else
                "lock"

        monthsArelockedCellStyle : Style
        monthsArelockedCellStyle =
            if model.monthsAreLocked then
                activeMonthsAreLockedStyle
            else
                lightPurpleBackground

        temperatureDisplayRowStyle : TemperatureDisplayRow -> TemperatureDisplayRow -> Style
        temperatureDisplayRowStyle modelDisplayRow labelDisplayRow =
            case ( modelDisplayRow, labelDisplayRow ) of
                ( Both, Both ) ->
                    activeDisplayRowStyle

                ( High, High ) ->
                    activeDisplayRowStyle

                ( Low, Low ) ->
                    activeDisplayRowStyle

                _ ->
                    lightAquaBackground

        sunshineDisplayRowStyle : SunshineDisplayRow -> SunshineDisplayRow -> Style
        sunshineDisplayRowStyle modelDisplayRow labelDisplayRow =
            case ( modelDisplayRow, labelDisplayRow ) of
                ( All, All ) ->
                    activeDisplayRowStyle

                ( OnlyJusts, OnlyJusts ) ->
                    activeDisplayRowStyle

                _ ->
                    lightAquaBackground

        displayRowCells : DisplayData -> List (Html Msg)
        displayRowCells displayData =
            case displayData of
                SunshineHours ->
                    [ td
                        [ css
                            [ borderTopAndBottomOnly
                            , (sunshineDisplayRowStyle model.sunshineDisplayRow All)
                            , cursorToPointerOnHover
                            ]
                        , onClick (SetSunshineDisplayRow All)
                        ]
                        [ text "show all" ]
                    , td
                        [ css
                            [ borderTopAndBottomOnly
                            , (sunshineDisplayRowStyle model.sunshineDisplayRow OnlyJusts)
                            , cursorToPointerOnHover
                            ]
                        , onClick (SetSunshineDisplayRow OnlyJusts)
                        ]
                        [ text "hide n/a" ]
                    , td
                        [ css
                            [ borderTopAndBottomOnly
                            ]
                        ]
                        [ text "🌈🌈🌈" ]
                    ]

                _ ->
                    [ td
                        [ css
                            [ borderTopAndBottomOnly
                            , (temperatureDisplayRowStyle model.temperatureDisplayRow Both)
                            , cursorToPointerOnHover
                            ]
                        , onClick (SetTemperatureDisplayRow Both)
                        ]
                        [ text "show all" ]
                    , td
                        [ css
                            [ borderTopAndBottomOnly
                            , (temperatureDisplayRowStyle model.temperatureDisplayRow High)
                            , cursorToPointerOnHover
                            ]
                        , onClick (SetTemperatureDisplayRow High)
                        ]
                        [ text "only high" ]
                    , td
                        [ css
                            [ borderTopAndBottomOnly
                            , (temperatureDisplayRowStyle model.temperatureDisplayRow Low)
                            , cursorToPointerOnHover
                            ]
                        , onClick (SetTemperatureDisplayRow Low)
                        ]
                        [ text "only low" ]
                    ]
    in
        ( "controlsRow"
        , tr []
            ([ td
                [ css [ tdStyle, logoStyle ] ]
                [ text "city climes" ]
             , td
                [ css [ tdPadding, veryLightYellowBackground ] ]
                [ text "display:" ]
             , td
                [ css
                    [ tdPadding
                    , (displayDataStyle model.displayData Celsius)
                    , cursorToPointerOnHover
                    ]
                , onClick (SetDisplayData Celsius)
                , title "Average daily high and low temperatures in degrees Celsius."
                ]
                [ text "°C" ]
             , td
                [ css
                    [ tdPadding
                    , (displayDataStyle model.displayData Fahrenheit)
                    , cursorToPointerOnHover
                    ]
                , onClick (SetDisplayData Fahrenheit)
                , title "Average daily high and low temperatures in degrees Fahrenheit."
                ]
                [ text "°F" ]
             , td
                [ css
                    [ tdPadding
                    , largerFont
                    , (displayDataStyle model.displayData SunshineHours)
                    , cursorToPointerOnHover
                    ]
                , onClick (SetDisplayData SunshineHours)
                , title "Mean monthly sunshine hours."
                ]
                [ text "☀" ]
             , td
                [ css
                    [ tdStyle, monthsArelockedCellStyle, cursorToPointerOnHover ]
                , onClick ToggleMonthsAreLocked
                , title "When locked, the values inputted for May will be applied to all months."
                ]
                [ text monthsArelockedCellText

                -- , span [ css [ Css.float Css.right ] ] [ text "(?)" ]
                , sup [] [ text "?" ]
                ]
             , td
                [ css
                    [ tdStyle, blackBackground, whiteText, cursorToPointerOnHover ]
                , colspan 2
                , onClick (Paginate False)
                , title
                    ("Click me to filter the data based the max. and min. values you inputted. "
                        ++ "Names are filtered in real-time."
                    )
                ]
                [ text "filter months" ]
             ]
                ++ displayRowCells model.displayData
                ++ [ td
                        [ css [ tdStyle, redBackground, whiteText, cursorToPointerOnHover ]
                        , onClick OpenResetModal
                        , title "Reset data sorting, filtering and/or pinning."
                        ]
                        [ text "reset" ]
                   , td
                        [ css [ tdStyle, silverBackground, cursorToPointerOnHover ]
                        , onClick OpenAboutModal
                        ]
                        [ text "about" ]
                   ]
            )
        )


createModal : Style -> List (Html Msg) -> Bool -> Html Msg
createModal sty msg isOpen =
    let
        ( backdropStyle, containerStyle ) =
            if isOpen then
                ( modalOpenBackdropStyle, modalOpenContainerStyle )
            else
                ( modalClosedBackdropStyle, modalClosedContainerStyle )
    in
        div [ css [ columnButtonContainerStyle ] ]
            [ div
                [ css [ modalBackdropStyle, backdropStyle ]
                , onClick CloseAllModals
                ]
                []
            , div [ css [ sty, modalContainerStyle, containerStyle ] ]
                msg
            ]


resetModal : Bool -> ResetSettings -> Html Msg
resetModal isOpen resetSettings =
    let
        checkbox : msg -> String -> Bool -> Html msg
        checkbox msg name isChecked =
            label []
                [ input
                    [ css [ modalCheckboxStyle ]
                    , type_ "checkbox"
                    , onClick msg
                    , checked isChecked
                    ]
                    []
                , text name
                ]

        msg : List (Html Msg)
        msg =
            [ p [ css [ modalTitleStyle, noMarginTop ] ] [ text "Reset" ]
            , fieldset []
                [ p []
                    [ checkbox ToggleResetFilterInputs
                        "Clear Filter Inputs"
                        resetSettings.resetFilterInputs
                    ]
                , p []
                    [ checkbox ToggleResetSorting
                        "Clear Sorting"
                        resetSettings.resetSorting
                    ]
                , p []
                    [ checkbox ToggleResetPinnedLocations
                        "Unpin All Locations"
                        resetSettings.resetPinnedLocations
                    ]
                ]
            , div [ css [ modalButtonContainerStyle ] ]
                [ button
                    [ css [ fixedWidthButton 100, redButtonStyle ]
                    , onClick ResetData
                    ]
                    [ text "Reset" ]
                , button
                    [ css [ fixedWidthButton 100, whiteButtonStyle ]
                    , onClick CloseAllModals
                    ]
                    [ text "Cancel" ]
                ]
            ]
    in
        createModal resetModalStyle msg isOpen


aboutModal : Bool -> Html Msg
aboutModal isOpen =
    let
        msg : List (Html Msg)
        msg =
            [ p [ css [ modalTitleStyle, noMarginTop ] ] [ text "About" ]
            , p [ css [ noMarginTop ] ]
                [ text "City Climes was created to help "
                , a [ href "https://paulbacchus.com/", target "_blank" ] [ text "me" ]
                , text
                    """ find warm places to live and visit.
                        Average daily high and low temperatures for each month and
                        mean monthly sunshine hours (where available)
                        are listed for over 6000 locations,
                        so I hope you find somewhere to your tastes.
                    """
                ]
            , p [ css [ noMarginTop ] ]
                [ text "This website uses data from "
                , a
                    [ href "https://en.wikipedia.org/wiki/Main_Page"
                    , target "_blank"
                    ]
                    [ text "Wikipedia" ]
                , text ", which is released under the "
                , a
                    [ href "https://creativecommons.org/licenses/by-sa/3.0/"
                    , target "_blank"
                    ]
                    [ text "Creative Commons Attribution-Share-Alike License 3.0" ]

                -- , text ". 10% of any profit from this site is donated to Wikipedia."
                ]
            , p [ css [ noMarginTop ] ]
                [ text "City Climes was built using "
                , a
                    [ href "https://www.rust-lang.org/en-US/"
                    , target "_blank"
                    ]
                    [ text "Rust" ]
                , text " and "
                , a
                    [ href "http://elm-lang.org/"
                    , target "_blank"
                    ]
                    [ text "Elm" ]
                , text ", with a little JavaScript as an intermediary. Desktop first design."
                ]
            , p [ css [ noMarginTop ] ]
                [ text "salutations@cityclimes.com" ]
            , p [ css [ noMarginTop ] ]
                [ a
                    [ href "https://twitter.com/cityclimes"
                    , target "_blank"
                    ]
                    [ text "Twitter" ]
                ]
            , div [ css [ modalButtonContainerStyle, flexEndStyle ] ]
                [ button
                    [ css [ fixedWidthButton 100, whiteButtonStyle ]
                    , onClick CloseAllModals
                    ]
                    [ text "Close" ]
                ]
            ]
    in
        createModal aboutModalStyle msg isOpen


instructionsModal : Bool -> Html Msg
instructionsModal isOpen =
    let
        msg : List (Html Msg)
        msg =
            [ p [ css [ modalTitleStyle, noMarginTop, noUnderline ] ] [ text "\x1F984 While the data is loading..." ]
            , p [ css [ noMarginTop ] ]
                [ text
                    """ \x1F984 ... I just thought I'd let you know that you can
                        sort the data by clicking on the appropriate cell
                        in each column ('high' sorts by the high temperature
                        and 'low' sorts by the low temperature for that month).
                    """
                ]
            , p [ css [ noMarginTop ] ]
                [ text
                    """ \x1F984 You can also filter the data by name, maximum temperature
                        ('max.') and/or minimum temperature ('min.'). Location names
                        are filtered in real time, but you need to click the 'filter months'
                        button in the controls row to filter by temperature.
                    """
                ]
            , p [ css [ noMarginTop ] ]
                [ text
                    """ \x1F984 There are also other controls in the controls row to play with.
                    """
                ]
            , p [ css [ noMarginTop ] ]
                [ text
                    """ \x1F984 A cookie is used for analytics.
                    """
                ]
            , div [ css [ modalButtonContainerStyle, flexEndStyle ] ]
                [ button
                    [ css [ fixedWidthButton 100, whiteButtonStyle ]
                    , onClick CloseInstructionsModal
                    ]
                    [ text "Okay" ]
                ]
            ]
    in
        createModal instructionsModalStyle msg isOpen


locationModal : Bool -> Maybe Location -> String -> String -> Html Msg
locationModal isOpen maybeLocation checkInDate checkOutDate =
    let
        msg : List (Html Msg)
        msg =
            case maybeLocation of
                Just location ->
                    if location.locationName == "Mars" then
                        [ h1 [ css [ modalTitleStyle, noMarginTop ] ]
                            [ text location.locationName ]
                        , div [ css [ locationModalButtonContainerStyle ] ]
                            [ div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Actions" ]
                                , button
                                    [ css
                                        [ fixedWidthButton 153
                                        , (if location.isPinned then
                                            inverseBlackButtonStyle
                                           else
                                            blackButtonStyle
                                          )
                                        , noMarginTop
                                        ]
                                    , onClick
                                        (ToggleLocationIsPinned location.iD
                                            location.isPinned
                                        )
                                    , title "Pin location to the top of the page for comparisons. Unpin to remove."
                                    ]
                                    [ text
                                        (if location.isPinned then
                                            "Unpin"
                                         else
                                            "Pin"
                                        )
                                    ]
                                , button
                                    [ css
                                        [ fixedWidthButton 153
                                        , blackButtonStyle
                                        , lessMarginTop
                                        ]
                                    , onClick (FindSimilar location)
                                    , title "Find similar locations to this one."
                                    ]
                                    [ text "Find Similar" ]
                                ]
                            , div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Information" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , purpleButtonStyle
                                        , linkButtonStyle
                                        , noMarginTop
                                        ]
                                    , href location.wikipediaURL
                                    , target "_blank"
                                    , title "View more information at Wikipedia."
                                    ]
                                    [ text "Wikipedia" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , greenButtonStyle
                                        , linkButtonStyle
                                        , lessMarginTop
                                        ]
                                    , href "https://www.google.com/mars/"
                                    , target "_blank"
                                    , title "View location on a map."
                                    ]
                                    [ text "Map" ]
                                ]
                            , div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Digital Nomadism" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , orangeButtonStyle
                                        , linkButtonStyle
                                        , noMarginTop
                                        ]
                                    , href "https://nomadlist.com/mars"
                                    , target "_blank"
                                    , title "Maybe some nomads have been here?"
                                    ]
                                    [ text "Nomad List" ]
                                ]
                            ]
                        , h2 [ css [ modalH2Style, padLeft20 ] ] [ text "Travel & Accommodation" ]
                        , div [ css [ locationModalButtonContainerStyle, flexWrapStyle ] ]
                            [ a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href "https://www.spacex.com/mars"
                                , target "_blank"
                                , title "SpaceX."
                                ]
                                [ text "SpaceX" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href "https://mars.nasa.gov/"
                                , target "_blank"
                                , title "NASA."
                                ]
                                [ text "NASA" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href "http://www.esa.int/Our_Activities/Space_Science/Mars_Express"
                                , target "_blank"
                                , title "ESA."
                                ]
                                [ text "ESA" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href "https://en.wikipedia.org/wiki/Colonization_of_Mars"
                                , target "_blank"
                                , title "Colonization."
                                ]
                                [ text "Colonization" ]
                            ]
                        , div [ css [ modalButtonContainerStyle, flexEndStyle ] ]
                            [ button
                                [ css [ fixedWidthButton 100, whiteButtonStyle ]
                                , onClick CloseAllModals
                                ]
                                [ text "Close" ]
                            ]
                        ]
                    else
                        [ h1 [ css [ modalTitleStyle, noMarginTop ] ]
                            [ text location.locationNameAndCountry ]
                        , div [ css [ locationModalButtonContainerStyle ] ]
                            [ div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Actions" ]
                                , button
                                    [ css
                                        [ fixedWidthButton 153
                                        , (if location.isPinned then
                                            inverseBlackButtonStyle
                                           else
                                            blackButtonStyle
                                          )
                                        , noMarginTop
                                        ]
                                    , onClick
                                        (ToggleLocationIsPinned location.iD
                                            location.isPinned
                                        )
                                    , title "Pin location to the top of the page for comparisons. Unpin to remove."
                                    ]
                                    [ text
                                        (if location.isPinned then
                                            "Unpin"
                                         else
                                            "Pin"
                                        )
                                    ]
                                , button
                                    [ css
                                        [ fixedWidthButton 153
                                        , blackButtonStyle
                                        , lessMarginTop
                                        ]
                                    , onClick (FindSimilar location)
                                    , title "Find similar locations to this one."
                                    ]
                                    [ text "Find Similar" ]
                                ]
                            , div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Information" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , purpleButtonStyle
                                        , linkButtonStyle
                                        , noMarginTop
                                        ]
                                    , href location.wikipediaURL
                                    , target "_blank"
                                    , title "View more information at Wikipedia."
                                    , onClick (SendAnalytics "Wikipedia")
                                    ]
                                    [ text "Wikipedia" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , greenButtonStyle
                                        , linkButtonStyle
                                        , lessMarginTop
                                        ]
                                    , href
                                        -- ("https://duckduckgo.com/?q="
                                        --     ++ Http.encodeUri location.locationName
                                        --     ++ "&t=ffab&ia=news&iaxm=about"
                                        -- )
                                        ("https://www.google.com/maps?hl=en&q="
                                            ++ Http.encodeUri location.locationName
                                        )
                                    , target "_blank"
                                    , title "View location on a map."
                                    , onClick (SendAnalytics "Map")
                                    ]
                                    [ text "Map" ]
                                ]
                            , div [ css [ columnButtonContainerStyle ] ]
                                [ h2 [ css [ modalH2Style ] ] [ text "Digital Nomadism" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , orangeButtonStyle
                                        , linkButtonStyle
                                        , noMarginTop
                                        ]
                                    , href
                                        ("https://nomadlist.com/"
                                            ++ Http.encodeUri
                                                (location.locationName
                                                    |> toLower
                                                    |> String.split " "
                                                    |> String.join "-"
                                                )
                                        )
                                    , target "_blank"
                                    , title "Maybe some nomads have been here?"
                                    , onClick (SendAnalytics "NomadList")
                                    ]
                                    [ text "Nomad List" ]
                                , a
                                    [ css
                                        [ fixedWidthButton 125
                                        , orangeButtonStyle
                                        , linkButtonStyle
                                        , lessMarginTop
                                        ]
                                    , href
                                        ("https://www.reddit.com/r/digitalnomad/search?q="
                                            ++ Http.encodeUri location.locationName
                                            ++ "&restrict_sr=1"
                                        )
                                    , target "_blank"
                                    , title "Maybe some nomads have been here?"
                                    , onClick (SendAnalytics "Reddit")
                                    ]
                                    [ text "Reddit" ]
                                ]
                            ]
                        , h2 [ css [ modalH2Style, padLeft20 ] ] [ text "Travel & Accommodation" ]
                        , div [ css [ locationModalButtonContainerStyle, flexWrapStyle ] ]
                            [ a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href
                                    ("https://www.booking.com/searchresults.html?ss="
                                        ++ Http.encodeUri
                                            (location.locationName
                                                |> String.split " "
                                                |> String.join "+"
                                            )
                                    )
                                , target "_blank"
                                , title "Booking.com."
                                , onClick (SendAnalytics "Booking.com")
                                ]
                                [ text "Booking.com" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href
                                    ("https://www.airbnb.com/s/"
                                        ++ Http.encodeUri
                                            (location.locationName
                                                |> String.split " "
                                                |> String.join "-"
                                            )
                                    )
                                , target "_blank"
                                , title "Airbnb."
                                , onClick (SendAnalytics "Airbnb")
                                ]
                                [ text "Airbnb" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href
                                    ("https://www.hipmunk.com/hotels#w="
                                        ++ Http.encodeUri
                                            (location.locationName
                                                |> String.split " "
                                                |> String.join "+"
                                            )
                                        ++ ";i="
                                        ++ checkInDate
                                        ++ ";o="
                                        ++ checkOutDate
                                        ++ ";is_search_for_business=false"
                                    )
                                , target "_blank"
                                , title "Hipmunk."
                                , onClick (SendAnalytics "Hipmunk")
                                ]
                                [ text "Hipmunk" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href
                                    ("https://www.couchsurfing.com/place?location_text="
                                        ++ Http.encodeUri
                                            (location.locationName
                                                |> String.split " "
                                                |> String.join "+"
                                            )
                                    )
                                , target "_blank"
                                , title "Couchsurfing."
                                , onClick (SendAnalytics "Couchsurfing")
                                ]
                                [ text "Couchsurfing" ]
                            , a
                                [ css
                                    [ fixedWidthButton 125
                                    , aquaButtonStyle
                                    , linkButtonStyle
                                    , lessMarginTop
                                    ]
                                , href
                                    ("https://www.tripadvisor.com/SearchForums?q="
                                        ++ Http.encodeUri location.locationName
                                    )
                                , target "_blank"
                                , title "TripAdvisor Forums."
                                , onClick (SendAnalytics "TripAdvisor")
                                ]
                                [ text "TripAdvisor" ]
                            ]
                        , div [ css [ modalButtonContainerStyle, flexEndStyle ] ]
                            [ button
                                [ css [ fixedWidthButton 100, whiteButtonStyle ]
                                , onClick CloseAllModals
                                ]
                                [ text "Close" ]
                            ]
                        ]

                Nothing ->
                    [ text "No location information found." ]
    in
        createModal locationModalStyle msg isOpen


pageControls : Model -> Html Msg
pageControls model =
    nav [ css [ pageControlsNavContainerStyle ] ]
        [ div [ css [ pageControlsContainerStyle ] ]
            [ button
                [ css [ fixedWidthButton 100, blueButtonStyle ]
                , onClick (SetPageNoIndex <| model.pageNoIndex - 1)
                , disabled (model.pageNoIndex == 0)
                ]
                [ text "< Prev" ]
            , div [ css [ pageControlsPageInfoStyle ] ]
                [ div [ css [ tdPadding ] ] [ text "Page " ]
                , div [ css [ tdPadding ] ] [ text <| toString <| model.pageNoIndex + 1 ]
                , div [ css [ tdPadding, borderTopOnly ] ] [ text <| toString <| Array.length model.pages ]
                ]
            , button
                [ css [ fixedWidthButton 100, blueButtonStyle ]
                , onClick (SetPageNoIndex <| model.pageNoIndex + 1)
                , disabled (model.pageNoIndex == length model.pages - 1)
                ]
                [ text "Next >" ]
            ]
        , div []
            [ text "Go to Page: "
            , input
                [ css [ goToPageInputStyle ]
                , pattern "[0-9]"
                , maxlength 4
                , onInput SetGoToPageNoIndex
                , value model.goToPageNoIndex
                ]
                []
            , button
                [ css [ fixedWidthButton 50, blueButtonStyle ]
                , onClick GoToPage
                ]
                [ text "Go" ]
            ]
        ]
