CREATE TABLE "FetchAndParseResults" (
    `ID` INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
    `PageName` TEXT NOT NULL,
    `FetchResult` TEXT NOT NULL,
    `ResponseURL` TEXT,
    `StatusCode` INTEGER,
    `ContentLocationURL` TEXT,
    `WikipediaURL` TEXT,
    `LocationName` TEXT,
    `TableHTML` TEXT,
    `TemperatureTableType` TEXT,
    `AverageHighC` TEXT,
    `AverageLowC` TEXT,
    `AverageHighF` TEXT,
    `AverageLowF` TEXT,
    `SunshineHours` TEXT,
    `ParseResult` TEXT,
    `DateAddedToDB` NUMERIC NOT NULL DEFAULT CURRENT_TIMESTAMP
)