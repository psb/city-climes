module Data exposing (..)

import Array exposing (Array, get)
import List exposing (..)
import Json.Decode exposing (int, string, float, Decoder, array, nullable, list)
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded, resolve)
import String
import RemoteData exposing (WebData)
import Types exposing (..)


-- DATA FETCHING


dataURL : String
dataURL =
    "/static/CityClimesCountries.json"



-- DATA PARSING


locationsDecoder : Decoder (List Location)
locationsDecoder =
    list locationDecoder


locationDecoder : Decoder Location
locationDecoder =
    let
        toDecoder :
            Int
            -> String
            -> String
            -> String
            -> Array Float
            -> Array Float
            -> Array Float
            -> Array Float
            -> Maybe (Array Float)
            -> Bool
            -> Decoder Location
        toDecoder locationID wikipediaURL locationName country averageHighC averageLowC averageHighF averageLowF sunshineHours isPinned =
            if String.contains country locationName then
                Json.Decode.succeed
                    (Location locationID
                        wikipediaURL
                        locationName
                        country
                        averageHighC
                        averageLowC
                        averageHighF
                        averageLowF
                        sunshineHours
                        isPinned
                        locationName
                    )
            else
                Json.Decode.succeed
                    (Location locationID
                        wikipediaURL
                        locationName
                        country
                        averageHighC
                        averageLowC
                        averageHighF
                        averageLowF
                        sunshineHours
                        isPinned
                        (locationName ++ ", " ++ country)
                    )
    in
        decode toDecoder
            |> required "ID" int
            |> required "WikipediaURL" string
            |> required "LocationName" string
            |> required "Country" string
            |> required "AverageHighC" (array float)
            |> required "AverageLowC" (array float)
            |> required "AverageHighF" (array float)
            |> required "AverageLowF" (array float)
            |> required "SunshineHours" (nullable (array float))
            |> hardcoded False
            |> resolve



-- FUNCTIONS ON DATA ON MODEL


extractRemoteData : WebData (List Location) -> List Location
extractRemoteData data =
    case data of
        RemoteData.Success locations ->
            locations

        _ ->
            []


paginate : List Location -> Array (List Location)
paginate unpinned =
    let
        chunkinate : Int -> List a -> List (List a)
        chunkinate i xs =
            if List.isEmpty xs then
                []
            else if i == 0 then
                [ xs ]
            else
                take i xs :: chunkinate i (drop i xs)
    in
        unpinned
            |> chunkinate 50
            |> Array.fromList


defaultMonthFilterInputs : Array (Maybe Float)
defaultMonthFilterInputs =
    Array.repeat 12 Nothing


defaultLocationNameFilterInput : String
defaultLocationNameFilterInput =
    ""


defaultSortedBy : SortedBy
defaultSortedBy =
    { col = LocationName
    , row = Nothing
    , order = Ascending
    , displayDataType = Celsius
    }


defaultResetSettings : ResetSettings
defaultResetSettings =
    { resetFilterInputs = False
    , resetSorting = False
    , resetPinnedLocations = False
    }


resetData : Model -> Model
resetData model =
    let
        resetFilterInputs : Bool -> Model -> Model
        resetFilterInputs bool model =
            if bool then
                { model
                    | locationNameFilterInput = defaultLocationNameFilterInput
                    , monthFilterMaxInputs = defaultMonthFilterInputs
                    , monthFilterMinInputs = defaultMonthFilterInputs
                }
            else
                model

        resetSorting : Bool -> Model -> Model
        resetSorting bool model =
            if bool then
                { model | sortedBy = defaultSortedBy }
            else
                model

        resetPinnedLocations : Bool -> Model -> Model
        resetPinnedLocations bool model =
            if bool then
                { model
                    | pinnedLocations = []
                    , unpinnedLocations = extractRemoteData model.allData
                }
            else
                model

        resetResetSettings : Model -> Model
        resetResetSettings model =
            { model | resetSettings = defaultResetSettings }
    in
        model
            |> resetFilterInputs model.resetSettings.resetFilterInputs
            |> resetSorting model.resetSettings.resetSorting
            |> resetPinnedLocations model.resetSettings.resetPinnedLocations
            |> resetResetSettings


flipSortOrder : SortOrder -> SortOrder
flipSortOrder sortOrder =
    case sortOrder of
        Ascending ->
            Descending

        Descending ->
            Ascending


getValue : Float -> Int -> Array Float -> Float
getValue default idx arr =
    Maybe.withDefault default (get idx arr)


sortLocations : SortedBy -> List Location -> List Location
sortLocations newSort locations =
    let
        descendingComparison : (a -> comparable) -> a -> a -> Order
        descendingComparison fn a b =
            case compare (fn a) (fn b) of
                LT ->
                    GT

                EQ ->
                    EQ

                GT ->
                    LT

        compareByMonth : Int -> List Location
        compareByMonth idx =
            case newSort.displayDataType of
                Celsius ->
                    case newSort.row of
                        Just HighTemp ->
                            case newSort.order of
                                Ascending ->
                                    sortBy (\l -> getValue 0 idx l.averageHighC)
                                        locations

                                Descending ->
                                    sortWith
                                        (descendingComparison
                                            (\l -> getValue 0 idx l.averageHighC)
                                        )
                                        locations

                        _ ->
                            case newSort.order of
                                Ascending ->
                                    sortBy (\l -> getValue 0 idx l.averageLowC)
                                        locations

                                Descending ->
                                    sortWith
                                        (descendingComparison
                                            (\l -> getValue 0 idx l.averageLowC)
                                        )
                                        locations

                Fahrenheit ->
                    case newSort.row of
                        Just HighTemp ->
                            case newSort.order of
                                Ascending ->
                                    sortBy (\l -> getValue 0 idx l.averageHighF)
                                        locations

                                Descending ->
                                    sortWith
                                        (descendingComparison
                                            (\l -> getValue 0 idx l.averageHighF)
                                        )
                                        locations

                        _ ->
                            case newSort.order of
                                Ascending ->
                                    sortBy (\l -> getValue 0 idx l.averageLowF)
                                        locations

                                Descending ->
                                    sortWith
                                        (descendingComparison
                                            (\l -> getValue 0 idx l.averageLowF)
                                        )
                                        locations

                SunshineHours ->
                    case newSort.order of
                        Ascending ->
                            sortBy
                                (\l ->
                                    case l.sunshineHours of
                                        Just arr ->
                                            getValue 0 idx arr

                                        Nothing ->
                                            -1
                                )
                                locations

                        Descending ->
                            sortWith
                                (descendingComparison
                                    (\l ->
                                        case l.sunshineHours of
                                            Just arr ->
                                                getValue 0 idx arr

                                            Nothing ->
                                                -1
                                    )
                                )
                                locations
    in
        case newSort.col of
            LocationName ->
                case newSort.order of
                    Ascending ->
                        sortBy .locationNameAndCountry locations

                    Descending ->
                        sortWith (descendingComparison .locationNameAndCountry) locations

            MonthColumn month ->
                case month of
                    January ->
                        compareByMonth 0

                    February ->
                        compareByMonth 1

                    March ->
                        compareByMonth 2

                    April ->
                        compareByMonth 3

                    May ->
                        compareByMonth 4

                    June ->
                        compareByMonth 5

                    July ->
                        compareByMonth 6

                    August ->
                        compareByMonth 7

                    September ->
                        compareByMonth 8

                    October ->
                        compareByMonth 9

                    November ->
                        compareByMonth 10

                    December ->
                        compareByMonth 11


filterData : Model -> List Location
filterData model =
    let
        acceptableLocationName : String -> String -> Bool
        acceptableLocationName nameFilter locationNameAndCountry =
            String.contains (String.toLower nameFilter) (String.toLower locationNameAndCountry)

        acceptableMonth : Float -> Float -> Float -> Float -> Bool
        acceptableMonth filterMinValue filterMaxValue dataMinValue dataMaxValue =
            filterMinValue <= dataMinValue && dataMaxValue <= filterMaxValue

        absoluteMax : Float
        absoluteMax =
            10000.0

        absoluteMin : Float
        absoluteMin =
            -10000.0

        valOrAbsoluteDefault : Float -> Maybe Float -> Float
        valOrAbsoluteDefault absoluteDefault inputVal =
            case inputVal of
                Just f ->
                    f

                Nothing ->
                    absoluteDefault

        absoluteMaxFilters : List Float
        absoluteMaxFilters =
            map (valOrAbsoluteDefault absoluteMax)
                (Array.toList model.monthFilterMaxInputs)

        absoluteMinFilters : List Float
        absoluteMinFilters =
            map (valOrAbsoluteDefault absoluteMin)
                (Array.toList model.monthFilterMinInputs)

        locationDataValues : DisplayData -> Location -> ( List Float, List Float )
        locationDataValues displayData location =
            case displayData of
                Celsius ->
                    ( Array.toList location.averageLowC
                    , Array.toList location.averageHighC
                    )

                Fahrenheit ->
                    ( Array.toList location.averageLowF
                    , Array.toList location.averageHighF
                    )

                SunshineHours ->
                    case location.sunshineHours of
                        Just arr ->
                            ( Array.toList arr, Array.toList arr )

                        Nothing ->
                            ( repeat 12 -11000.0, repeat 12 11000.0 )
    in
        if
            model.locationNameFilterInput
                == defaultLocationNameFilterInput
                && model.monthFilterMaxInputs
                == defaultMonthFilterInputs
                && model.monthFilterMinInputs
                == defaultMonthFilterInputs
        then
            model.unpinnedLocations
        else if
            model.monthFilterMaxInputs
                == defaultMonthFilterInputs
                && model.monthFilterMinInputs
                == defaultMonthFilterInputs
        then
            filter
                (\location ->
                    acceptableLocationName
                        model.locationNameFilterInput
                        location.locationNameAndCountry
                )
                model.unpinnedLocations
        else
            filter
                (\location ->
                    let
                        ( dataMinValues, dataMaxValues ) =
                            locationDataValues model.displayData location

                        locationNameIsAcceptable : Bool
                        locationNameIsAcceptable =
                            acceptableLocationName model.locationNameFilterInput
                                location.locationNameAndCountry

                        monthsAreAcceptable : List Bool
                        monthsAreAcceptable =
                            map4 acceptableMonth
                                absoluteMinFilters
                                absoluteMaxFilters
                                dataMinValues
                                dataMaxValues
                    in
                        all identity (locationNameIsAcceptable :: monthsAreAcceptable)
                )
                model.unpinnedLocations


toggleLocationPinning : List Location -> List Location -> Int -> SortedBy -> ( List Location, List Location )
toggleLocationPinning pinnedLocations unpinnedLocations locationID sortedBy =
    let
        allLocationsSorted : List Location
        allLocationsSorted =
            sortLocations
                sortedBy
                (pinnedLocations ++ unpinnedLocations)
    in
        foldr
            (\location ( newPinned, newUnpinned ) ->
                if location.iD == locationID then
                    case location.isPinned of
                        True ->
                            ( newPinned, { location | isPinned = False } :: newUnpinned )

                        False ->
                            ( { location | isPinned = True } :: newPinned, newUnpinned )
                else
                    case location.isPinned of
                        True ->
                            ( location :: newPinned, newUnpinned )

                        False ->
                            ( newPinned, location :: newUnpinned )
            )
            ( [], [] )
            allLocationsSorted
