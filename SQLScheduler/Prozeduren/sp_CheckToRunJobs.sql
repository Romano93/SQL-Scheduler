/*
-----------------------------------------------------------------------------------------------------------
Autor:................Romano Sabbatella
Date:.................2017.04.19
Description:..........This script checks if there's a job which must be scheduled.
......................If there's one it calls another procedure which handels the call of the job
Parameter:............None
Return parameter:.....None
Version:..............2017.04.19 / RS Creat the base structure of the script
......................2017.04.20 / RS Created the script with all functionalities except the parallel call of the sp
......................2017.04.26 / RS Had some issues with the parameters as string. I had to add ' + '
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/
-- exec sp_CheckToRunJobs
/*
-- Drop the procedure
*/
DROP PROCEDURE [dbo].[sp_CheckToRunJobs]
GO

/*
-- Create the procedure
*/
CREATE PROCEDURE [dbo].[sp_CheckToRunJobs]
AS

/*
-- Declarations
*/
DECLARE @JobID int
DECLARE @Now DateTime
DECLARE @ErrorMsg varchar(255)
DECLARE @Database varchar(30)
DECLARE @ScheduleID int
DECLARE @OwnerID int
DECLARE @SpName varchar(50)
DECLARE @Shema varchar(50)
DECLARE @SpPath varchar(100)
DECLARE @RunDateTime datetime
DECLARE @ErrorDateTime datetime
DECLARE @JobName varchar(255)
DECLARE @StatusID int
DECLARE @DependsFromID int
DECLARE @PrevStatusID int
DECLARE @ScheduleStatus varchar(30)
DECLARE @Waiting bit
DECLARE @HistoryID int
DECLARE @ExecString varchar(255)
DECLARE @IntervallType int
DECLARE @Intervall int
DECLARE @NextRunDateTime datetime
DECLARE @Hour int
DECLARE @Minutes int
DECLARE @Daytime varchar(10)
/*
-- Initialisation
*/
SELECT @ScheduleID = 0
SELECT @Now = GETDATE()
SELECT @ErrorMsg = ''
SELECT @OwnerID = 0
/*
-- Declare cursor
*/
DECLARE crsJobs CURSOR LOCAL FOR 
	(SELECT
		JobID, ScheduleID, SchedulestatusID, ScheduleTyp
	FROM 
		Schedules
	WHERE 
		RunDateTime < @Now
		and (SELECT Status FROM Schedulestatus WHERE Schedules.SchedulestatusID = Schedulestatus.SchedulestatusID) <> 'Disabled'
		and ISNULL(ExpireDateTime,GETDATE()+1) > @Now
		and StartDateTime < @Now
	) ORDER BY RunDateTime FOR READ ONLY
-- open cursor
OPEN crsJobs
-- fetch the first row
FETCH NEXT FROM crsJobs INTO @JobID, @ScheduleID, @ScheduleStatus, @IntervallType
-- get thru all the jobs
WHILE @@FETCH_STATUS = 0 BEGIN
	/*
	-- Reset some values
	*/
	SELECT @Intervall = 0
	SELECT @JobName = ''
	SELECT @RunDateTime = GETDATE()
	SELECT @ErrorMsg = ''
	SELECT @Database = ''
	SELECT @SpName = ''
	SELECT @Shema = ''
	SELECT @SpPath = ''
	SELECT @ExecString = ''
	SELECT @OwnerID = 0
	SELECT @StatusID = 0
	SELECT @HistoryID = 0
	SELECT @DependsFromID = 0
	SELECT @Waiting = 0
	SELECT @Hour = 0
	SELECT @Minutes = 0
	SELECT @Daytime = ''
	/*
	-- Check if the interval is day of the week
	*/
	IF @IntervallType = 2 BEGIN
		IF (SELECT [DayOfWeek] FROM Schedules WHERE ScheduleID = @ScheduleID) <> DATEPART(dw, GETDATE()) BEGIN
			SELECT @Waiting = 1
		END
		ELSE BEGIN
			-- get the time string
			SELECT @Daytime = DayTime FROM Schedules WHERE ScheduleID = @ScheduleID
			IF ISNULL(@Daytime, '') = '' BEGIN
				SELECT @ErrorMsg = @ErrorMsg + 'Die Tageszeit ist nicht eingetragen. '
			END
			ELSE BEGIN 
				-- get the hour and minute from the time string
				SELECT @Hour = convert(int,LEFT(@Daytime, 2))
				SELECT @Minutes = convert(int,Right(@Daytime, 2))
				-- check if the hour it should run is already here
				IF @Hour > DATEPART(hh,@Now) BEGIN
					SELECT @Waiting = 1
				END
				-- check if the minute it should run is already here
				IF @Minutes > DATEPART(n,@Now) BEGIN
					SELECT @Waiting = 1
				END
			END
		END
	END
	/*
	-- Check if the job infront is finished
	*/
	SELECT @DependsFromID = PrevScheduleID FROM Schedules WHERE ScheduleID = @ScheduleID
	IF ISNULL(@DependsFromID,0) > 0 BEGIN
		SELECT @PrevStatusID = SchedulestatusID FROM Schedules WHERE ScheduleID = @DependsFromID
		IF (SELECT Status FROM Schedulestatus WHERE SchedulestatusID = @PrevStatusID) = 'Running' BEGIN
			SELECT @Waiting = 1
		END
	END
	/*
	-- Just run the job if there's no previous depending job or the job allredy finished
	*/
	IF @Waiting = 0 BEGIN
		/*
		-- Write an entry into the history
		*/
		--we need a tmp table to save the output
		CREATE TABLE #TmpHistory(
			HistroyID int
		)
		--insert the first details into history
		INSERT INTO Jobhistory
			(JobID, ScheduleID, ErrorYN, StartDateTime)
			OUTPUT inserted.JobhistoryID INTO #TmpHistory
		VALUES
			(@JobID, @ScheduleID, 0, @RunDateTime)
		-- get the historyid
		SELECT @HistoryID = (SELECT TOP 1 HistroyID FROM #TmpHistory)
		-- drop the table
		DROP TABLE #TmpHistory
		/*
		-- Check if all needed informations are there
		*/
		-- Database
		SELECT
			@Database = ISNULL([Databases].[Name],'')
		FROM
			[Databases]
			JOIN Schedules ON [Databases].DatabaseID = Schedules.DatabaseID
		WHERE
			Schedules.ScheduleID = @ScheduleID
		-- check if the name has at least 1 char
		IF NOT EXISTS (SELECT * FROM sys.databases WHERE name = @Database) BEGIN
			SELECT @ErrorDateTime = GETDATE()
			SELECT @ErrorMsg = @ErrorMsg + 'Die gewünschte Datenbank ist nicht vorhanden. '
		END
		--OwnerID
		SELECT @OwnerID = OwnerID FROM Schedules WHERE ScheduleID = @ScheduleID
		-- SP
		SELECT @SpName = ISNULL(SpName,'') FROM Schedules WHERE ScheduleID = @ScheduleID
		-- check if the spname is at least 1 char
		IF LEN(@SpName) = 0 BEGIN
			SELECT @ErrorDateTime = GETDATE()
			SELECT @ErrorMsg = @ErrorMsg + 'Der SP-Namen ist nicht eingetragen. '
		END
		-- shema
		SELECT @Shema = ISNULL(Shema,'') FROM Owners WHERE OwnerID = @OwnerID
		-- check if the shema name is at least 1 char
		IF LEN(@Shema) = 0 BEGIN
			SELECT @ErrorDateTime = GETDATE()
			SELECT @ErrorMsg = @ErrorMsg + 'Der Shema-Namen ist nicht eingetragen. '
		END
		-- concat the string
		SELECT @SpPath = @Database + '.' + @Shema + '.' + @SpName
		-- check if the sp exists
		IF OBJECT_ID(@SpPath) IS NOT NULL BEGIN
			/*
			-- update the status to running
			*/
			UPDATE Schedules SET SchedulestatusID = (SELECT SchedulestatusID FROM Schedulestatus WHERE [Status] = 'Running') WHERE ScheduleID = @ScheduleID
			-- get the exec string
			SELECT @ExecString = 'sp_RunJob ' + convert(varchar(255),@JobID) + ', ' + convert(varchar(255),@ScheduleID) + ', ' + convert(varchar(255),@HistoryID) + ', ' + '''' + @SpPath + ''''
			/*
			-- Execute the next sp
			*/			
			DECLARE @token uniqueidentifier
			BEGIN TRY
				EXEC usp_AsyncExecInvoke @ExecString, @token output
			END TRY
			BEGIN CATCH
				-- Build error msg
				SELECT @ErrorDateTime = GETDATE()
				SELECT @ErrorMsg = @ErrorMsg + 'Die SP wurde nicht in die Queue gestellt. Der ExecString ist: ' + @ExecString + '. '
			END CATCH			
		END
		ELSE BEGIN
			-- build error msg
			SELECT @ErrorDateTime = GETDATE()
			SELECT @ErrorMsg = @ErrorMsg + 'Die gewünschte Sp existiert unter dem Pfad ' + @SpPath + ' nicht. '
		END
		/*
		-- write the error message into the protocol
		*/
		IF LEN(@ErrorMsg) > 0 BEGIN
			-- get the job name for error report
			SELECT @JobName = [Name] FROM Jobs WHERE JobID = @JobID
			/*
			-- write an entry into the protocol table and save it
			*/
			INSERT INTO Exceptionlog 
				(JobID, RunDateTime, ErrorDateTime, ErrorMessage, [Name], SpName, JobName, JobhistoryID)
			VALUES
				(@JobID, @RunDateTime, @ErrorDateTime, @ErrorMsg, @Database, @SpName, @JobName, @HistoryID)
			/*
			-- write the entry into the history table with error flag
			*/
			Update
				Jobhistory
			SET
				ErrorYN = 1, EndDateTime = @ErrorDateTime 
			WHERE
				JobhistoryID = @HistoryID
		END
		/*
		-- set the new interval
		*/
		SELECT @IntervallType = ScheduleTyp FROM Schedules WHERE ScheduleID = @ScheduleID
		-- if the interval is in minutes
		IF @IntervallType = 1 BEGIN
			-- get the interval length
			SELECT @Intervall = Intervall FROM Schedules WHERE ScheduleID = @ScheduleID
			SELECT @NextRunDateTime = DATEADD(mi,@Intervall, (SELECT RunDateTime FROM Schedules WHERE ScheduleID = @ScheduleID))
		END
		IF @IntervallType = 2 BEGIN 
			-- set the rundate in the future and out of today because its weekly
			SELECT @NextRunDateTime = DATEADD(d, 1, @Now)
		END
		-- set the new run date
		UPDATE Schedules SET RunDateTime = @NextRunDateTime WHERE ScheduleID = @ScheduleID
	END
	-- next fetch
	FETCH NEXT FROM crsJobs INTO @JobID, @ScheduleID, @ScheduleStatus, @IntervallType
END
--close the cursor
CLOSE crsJobs
-- get rid of the memory region
DEALLOCATE crsJobs

GO