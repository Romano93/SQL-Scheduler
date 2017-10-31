/*
-----------------------------------------------------------------------------------------------------------
Autor:................Romano Sabbatella
Date:.................2017.04.20
Description:..........This script creates a trigger on the datebase sql scheduler.
......................This trigger handles wrong inputs from User
Versions:.............2017.04.20 / RS Creat script
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/
CREATE TRIGGER [dbo].[Schedules_HandelInserts] ON [dbo].[Schedules] FOR UPDATE, INSERT
AS
------------------------------------------------------------
-- prepare
------------------------------------------------------------
DECLARE @ScheduleID int
DECLARE @Weekday int
DECLARE @ScheduleTyp int
DECLARE @Intervall int
------------------------------------------------------------
-- work
------------------------------------------------------------
DECLARE crsEintraege CURSOR FOR (SELECT ScheduleID, [DayOfWeek], ScheduleTyp, Intervall FROM inserted) FOR READ ONLY
OPEN crsEintraege
FETCH NEXT FROM crsEintraege INTO @ScheduleID, @Weekday, @ScheduleTyp, @Intervall
WHILE @@FETCH_STATUS = 0 BEGIN
	-- weekday can be NULL
	SELECT @Weekday = ISNULL(@Weekday, 0)
	-- check scheduletype
	IF @ScheduleTyp > 2 or @ScheduleTyp < 1 BEGIN
		DELETE Schedules WHERE ScheduleID = @ScheduleID
		RAISERROR (15600,-1,-1, 'The ScheduleTyp is not valid! It has to be 1 or 2')
	END
	-- check intervall
	IF @ScheduleTyp = 1 and @Intervall < 1 BEGIN
		DELETE Schedules WHERE ScheduleID = @ScheduleID
		RAISERROR (15600,-1,-1, 'The interval can not be lower than 1 if the ScheduleTyp is 1 (Intervall)')		
	END
	-- check dayofweek
	IF @Weekday > 7 or @Weekday < 1 and @ScheduleTyp = 2 BEGIN
		DELETE Schedules WHERE ScheduleID = @ScheduleID
		RAISERROR (15600,-1,-1, 'The Weekday is not a valid number between 1-7!')		
	END
   /*
   -- next entry
   */
   FETCH NEXT FROM crsEintraege INTO @ScheduleID, @Weekday, @ScheduleTyp, @Intervall
   CONTINUE
END
CLOSE crsEintraege
DEALLOCATE crsEintraege
GO

ALTER TABLE [dbo].[Schedules] ENABLE TRIGGER [Schedules_HandelInserts]
GO


