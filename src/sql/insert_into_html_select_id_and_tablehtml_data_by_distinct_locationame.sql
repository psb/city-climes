insert into Html
select 
	ID,
	TableHTML
from FetchAndParseResults 
where AverageHighC is not null
group by LocationName
order by 
	TemperatureTableType desc, 
	LocationName asc,
	SunshineHours desc