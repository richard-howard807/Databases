SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE proc [SBC\6237].[update_ms_udMIMatterExceptions]

as


-- ************************************************************************************
-- RH 25/05/2021 Created script
-- MattersphereStaging.dbo.staging_exceptions is updated by DWH Red job
-- This script then updates udMIMatterExceptions with latest file exceptions
-- ************************************************************************************

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

begin try

	begin transaction
	
		-- Delete exceptions that are no longer in stage table	

	MERGE MS_DEV.dbo.udMIMatterExceptions as Target
	using (select distinct staging_exceptions.ms_fileid
                          , staging_exceptions.exceptionruleid
                          , staging_exceptions.fieldname
                          , staging_exceptions.narrative
                          , staging_exceptions.update_time from  staging_exceptions where ms_fileid is not null)	AS Source
		on Source.ms_fileid = Target.ms_fileid and Source.exceptionruleid  = Target.exceptionruleid

		when NOT MATCHED BY Target THEN
			INSERT (ms_fileid, exceptionruleid, fieldname, narrative, update_time)
			values (Source.ms_fileid, Source.exceptionruleid, Source.fieldname, Source.narrative, getdate())
		
		WHEN MATCHED THEN UPDATE SET
			Target.narrative	= Source.narrative,
			Target.fieldname		= Source.fieldname,
			Target.update_time = getdate()

	
		WHEN NOT MATCHED BY Source THEN
			 DELETE;
	
	   	  

	commit transaction					

end try

begin catch
	
	DECLARE @ErrorProcedure AS VARCHAR(8000)
	DECLARE @ErrorMessage AS VARCHAR(8000)


		rollback transaction
	

		SELECT @ErrorProcedure = ERROR_PROCEDURE(), @ErrorMessage = ERROR_MESSAGE()
		PRINT @ErrorProcedure
		PRINT @ErrorMessage 

		RAISERROR (50855, 10, 1 , @ErrorProcedure, @ErrorMessage)

end catch
GO
