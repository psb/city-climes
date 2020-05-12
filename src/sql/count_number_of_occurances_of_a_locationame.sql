select 
	LocationName,
	WikipediaURL,
	count(LocationName) as thecount
from FetchAndParseResults 
where AverageHighC is not null
group by LocationName
having count(LocationName) > 1