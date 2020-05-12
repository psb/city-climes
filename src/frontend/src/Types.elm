module Types exposing (..)

import Array exposing (Array)
import RemoteData exposing (WebData)


type alias Model =
    { allData : WebData (List Location)
    , pinnedLocations : List Location
    , unpinnedLocations : List Location
    , pages : Array (List Location)
    , pageNoIndex : Int
    , displayData : DisplayData
    , temperatureDisplayRow : TemperatureDisplayRow
    , sunshineDisplayRow : SunshineDisplayRow
    , sortedBy : SortedBy
    , monthFilterMaxInputs : Array (Maybe Float)
    , monthFilterMinInputs : Array (Maybe Float)
    , locationNameFilterInput : String
    , monthsAreLocked : Bool
    , instructionsModalIsOpen : Bool
    , resetModalIsOpen : Bool
    , aboutModalIsOpen : Bool
    , locationModalIsOpen : Bool
    , locationModalLocation : Maybe Location
    , resetSettings : ResetSettings
    , goToPageNoIndex : String
    , checkInDate : String
    , checkOutDate : String
    }


type alias Location =
    { iD : Int
    , wikipediaURL : String
    , locationName : String
    , country : String
    , averageHighC : Array Float
    , averageLowC : Array Float
    , averageHighF : Array Float
    , averageLowF : Array Float
    , sunshineHours : Maybe (Array Float)
    , isPinned : Bool
    , locationNameAndCountry : String
    }


type Month
    = January
    | February
    | March
    | April
    | May
    | June
    | July
    | August
    | September
    | October
    | November
    | December


type DisplayData
    = Celsius
    | Fahrenheit
    | SunshineHours


type TemperatureDisplayRow
    = High
    | Low
    | Both


type SunshineDisplayRow
    = All
    | OnlyJusts


type SortColumn
    = LocationName
    | MonthColumn Month


type SortRow
    = HighTemp
    | LowTemp


type SortOrder
    = Ascending
    | Descending


type alias SortedBy =
    { col : SortColumn
    , row : Maybe SortRow
    , order : SortOrder
    , displayDataType : DisplayData
    }


type alias ResetSettings =
    { resetFilterInputs : Bool
    , resetSorting : Bool
    , resetPinnedLocations : Bool
    }


type MonthFilter
    = MaxValue
    | MinValue
