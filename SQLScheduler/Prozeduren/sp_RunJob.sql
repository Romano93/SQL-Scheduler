/*
-----------------------------------------------------------------------------------------------------------
Autor:................Romano Sabbatella
Date:.................2017.04.20
Description:..........This script runs the job with help of the SQL Broker
......................
Parameter:............@ScheduleID	the ID of the schedule which has to run
......................@HistoryID	the ID of the History entry
......................@SpPath		Contains the path of the sp which it has to run
Return parameter:.....None
Version:..............2017.04.20 / RS Creat the base structure of the script
......................2017.04.21 / RS Corrected some mistakes
......................2017.04.24 / RS surrounded inserts and updates with try / catch because of the queue so it runs,
......................                 otherwise the queue will crash and stop working
......................xxxx.xx.xx / xx xxxxxx
-----------------------------------------------------------------------------------------------------------
*/
/*
-- Drop the procedure
*/
DROP PROCEDURE [dbo].[sp_RunJob]
GO

/*
-- Create the procedure
*/
CREATE PROCEDURE [dbo].[sp_RunJob]
	(
	@i_JobID int,
   	@i_ScheduleID int,
   	@i_HitoryID int,
	@i_SpPath varchar(100)
	)
AS
/*
-- Declarations
*/
DECLARE @JobID int
DECLARE @JobhistoryID int
DECLARE @ScheduleID int
DECLARE @SpPath varchar(100)
DECLARE @Error bit
DECLARE @ErrorMsg varchar(max)
DECLARE @Description varchar(100)
DECLARE @ExceptionlogID int
DECLARE @JobName varchar(255)
DECLARE @RunDateTime datetime
DECLARE @DateTime datetime
DECLARE @DatabaseName varchar(30)
DECLARE @SpName varchar(50)
/*
-- Initialisation
*/
--to values i got
SELECT @JobID = @i_JobID
SELECT @JobhistoryID = @i_HitoryID
SELECT @ScheduleID = @i_ScheduleID
SELECT @SpPath = @i_SpPath
-- new values
SELECT @DatabaseName = ''
SELECT @SpName = ''
SELECT @ErrorMsg = ''
SELECT @Description = ''
SELECT @Error = 0
SELECT @JobName = ''
/*
-- execute the sp
*/
BEGIN TRY
	exec @SpPath
	SELECT @DateTime = GETDATE()
END TRY
/*
-- Error handling if something went wrong
*/
BEGIN CATCH
	BEGIN TRY
	SELECT @ErrorMsg = ERROR_MESSAGE()
	SELECT @DateTime = GETDATE()
	-- get the job name
	SELECT @JobName = [Name] FROM SQLScheduler.dbo.Jobs WHERE JobID = @JobID
	-- get the databasename
	SELECT
		@DatabaseName = [Databases].[Name]
	FROM
		SQLScheduler.dbo.Schedules 
		JOIN [Databases] ON SQLScheduler.dbo.Schedules.DatabaseID = [Databases].DatabaseID
	-- get the runtime
	SELECT @RunDateTime = StartDateTime FROM SQLScheduler.dbo.Jobhistory WHERE JobhistoryID = @JobhistoryID
	-- get the sp name
	SELECT @SpName = SpName FROM SQLScheduler.dbo.Schedules WHERE ScheduleID = @ScheduleID
	-- get the jobname
	SELECT @JobName = Name FROM SQLScheduler.dbo.Jobs WHERE JobID = @JobID
	/*
	-- Create tmptable for output
	*/
	-- insert error into protocoll
	INSERT INTO SQLScheduler.dbo.Exceptionlog
		(JobID, JobName, RunDateTime, ErrorDateTime, ErrorMessage, [Name], SpName, JobhistoryID)
	VALUES
		(@JobID, @JobName, @RunDateTime, @DateTime, @ErrorMsg, @DatabaseName, @SpName, @JobhistoryID)	
	-- set Error
	SELECT @Error = 1
	END TRY
	BEGIN CATCH
		-- if everthing goes wrong nothing happens here
		-- otherwise the queue will crash
	END CATCH
END CATCH
/*
-- Update the History
*/
BEGIN TRY
	UPDATE
		SQLScheduler.dbo.Jobhistory
	SET
		ErrorYN = @Error, [Description] = @Description, EndDateTime = @DateTime
	WHERE
		JobhistoryID = @JobhistoryID
END TRY
BEGIN CATCH
	-- if everthing goes wrong nothing happens here
	-- otherwise the queue will crash
END CATCH
/*
-- Update the schedule status
*/
BEGIN TRY
	UPDATE SQLScheduler.dbo.Schedules SET SchedulestatusID = (SELECT SchedulestatusID FROM Schedulestatus WHERE [Status] = 'Ready') WHERE ScheduleID = @ScheduleID
END TRY
BEGIN CATCH
	-- if everthing goes wrong nothing happens here
	-- otherwise the queue will crash
END CATCH

GO