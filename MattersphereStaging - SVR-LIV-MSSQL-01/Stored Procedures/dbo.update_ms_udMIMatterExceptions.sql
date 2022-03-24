SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROC [dbo].[update_ms_udMIMatterExceptions]

AS


-- ************************************************************************************
-- RH 25/05/2021 Created script
-- MattersphereStaging.dbo.staging_exceptions is updated by DWH Red job
-- This script then updates udMIMatterExceptions with latest file exceptions
-- ************************************************************************************

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

BEGIN TRY

	BEGIN TRANSACTION
	
		-- Delete exceptions that are no longer in stage table	

	MERGE MS_PROD.dbo.udMIMatterExceptions AS Target
	USING (SELECT DISTINCT staging_exceptions.ms_fileid
                          , staging_exceptions.exceptionruleid
                          , staging_exceptions.fieldname
                          , staging_exceptions.narrative
                          , staging_exceptions.update_time FROM  staging_exceptions WHERE ms_fileid IS NOT NULL)	AS Source
		ON Source.ms_fileid = Target.ms_fileid AND Source.exceptionruleid  = Target.exceptionruleid

		WHEN NOT MATCHED BY TARGET THEN
			INSERT (ms_fileid, exceptionruleid, fieldname, narrative, update_time)
			VALUES (Source.ms_fileid, Source.exceptionruleid, Source.fieldname, Source.narrative, GETDATE())
		
		WHEN MATCHED THEN UPDATE SET
			Target.narrative	= Source.narrative,
			Target.fieldname		= Source.fieldname,
			Target.update_time = GETDATE()

	
		WHEN NOT MATCHED BY SOURCE THEN
			 DELETE;
	
	   	  

	COMMIT TRANSACTION					

END TRY

BEGIN CATCH
	
	DECLARE @ErrorProcedure AS VARCHAR(8000)
	DECLARE @ErrorMessage AS VARCHAR(8000)


		ROLLBACK TRANSACTION
	

		SELECT @ErrorProcedure = ERROR_PROCEDURE(), @ErrorMessage = ERROR_MESSAGE()
		PRINT @ErrorProcedure
		PRINT @ErrorMessage 

		RAISERROR (50855, 10, 1 , @ErrorProcedure, @ErrorMessage)

END CATCH
GO
