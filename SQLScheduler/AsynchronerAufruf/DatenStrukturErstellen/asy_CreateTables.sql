/*
-----------------------------------------------------------------------------------------------------------
Autor:................
Date:.................2017.04.21
Description:..........This script is for the asyncron call of sps
Versions:.............2017.04.21 / RS Create the script
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/

/*
-- Result Table
*/
-- select * from AsyncExecQueue


DROP TABLE [AsyncExecResults]
GO
CREATE TABLE [AsyncExecResults] (
	[token] uniqueidentifier primary key
	, [submit_time] datetime not null
	, [start_time] datetime null
	, [finish_time] datetime null
	, [error_number]	int null
	, [error_message] nvarchar(2048) null);
GO
