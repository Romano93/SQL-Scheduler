/*
-----------------------------------------------------------------------------------------------------------
Autor:................
Date:.................2017.04.21
Description:..........This script is for the asyncron call of sps
Versions:.............2017.04.21 / RS Create the Asynch 
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/
/*
-- Queue
*/

DROP SERVICE [AsyncExecService]
GO
DROP QUEUE [AsyncExecQueue]
GO


CREATE QUEUE [AsyncExecQueue]
GO

/*
-- Service
*/
CREATE SERVICE [AsyncExecService] ON QUEUE [AsyncExecQueue] ([DEFAULT]);
GO

/*
-- Alter the queue after you created the sps
*/
ALTER QUEUE [AsyncExecQueue]
    with activation (
    procedure_name = [usp_AsyncExecActivated]
    , max_queue_readers = 5
    , execute as owner
    , status = on);
GO
