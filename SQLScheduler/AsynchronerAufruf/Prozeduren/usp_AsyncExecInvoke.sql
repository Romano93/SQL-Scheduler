/*
-----------------------------------------------------------------------------------------------------------
Autor:................http://rusanu.com/2009/08/05/asynchronous-procedure-execution/
Date:.................2017.04.21
Description:..........This script is a stored procedure for the asyncron call of sps
Versions:.............2017.04.21 / RS copy pasted it
......................xxxx.xx.xx / xx
-----------------------------------------------------------------------------------------------------------
*/
DROP PROCEDURE [usp_AsyncExecInvoke]
GO

CREATE PROCEDURE [usp_AsyncExecInvoke]
    @procedureName sysname
    , @token uniqueidentifier output
as
begin
    declare @h uniqueidentifier
	    , @xmlBody xml
        , @trancount int;
    set nocount on;

	--set @trancount = @@trancount;
 --   if @trancount = 0
 --       begin transaction
 --   else
        --save transaction usp_AsyncExecInvoke;
    begin try
        begin dialog conversation @h
            from service [AsyncExecService]
            to service N'AsyncExecService', 'current database'
            with encryption = off;
        select @token = [conversation_id]
            from sys.conversation_endpoints
            where [conversation_handle] = @h;
        select @xmlBody = (
            select @procedureName as [name]
            for xml path('procedure'), type);
		-- insert into SQLScheduler.dbo.result ([description]) values(convert(varchar(8000),@xmlBody));
        send on conversation @h (@xmlBody);
		/*
		-- Muss kontrolliert werden wann auf einem anderen Server
		*/
        insert into SQLScheduler.dbo.AsyncExecResults
            ([token], [submit_time])
            values
            (@token, getdate());
    --if @trancount = 0
    --    commit;
    end try
    begin catch
        declare @error int
            , @message nvarchar(2048)
            , @xactState smallint;
        select @error = ERROR_NUMBER()
            , @message = ERROR_MESSAGE()
            , @xactState = XACT_STATE();
        --if @xactState = -1
        --    rollback;
        --if @xactState = 1 and @trancount = 0
        --    rollback
        --if @xactState = 1 and @trancount > 0
        --    rollback transaction usp_my_procedure_name;

        raiserror(N'Error: %i, %s', 16, 1, @error, @message);
    end catch
end
GO