select 
	ID,
	ContentLocationURL,
	LocationName,
	TemperatureTableType, 
	AverageHighC,
    AverageLowC,
    AverageHighF,
    AverageLowF,
	SunshineHours,
	case
	when TableHTML is not null then
		1
	else 
		0
	end HasTableHTML
from FetchAndParseResults 
where AverageHighC is not null
group by LocationName
order by 
	TemperatureTableType desc, 
	LocationName asc,
	SunshineHours desc