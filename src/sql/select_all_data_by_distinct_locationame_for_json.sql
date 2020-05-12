select
	ID,
	WikipediaURL,
	LocationName,
	AverageHighC,
    AverageLowC,
    AverageHighF,
    AverageLowF,
	SunshineHours
from FetchAndParseResults
where AverageHighC is not null
group by LocationName
order by
	TemperatureTableType desc,
	LocationName asc,
	SunshineHours desc