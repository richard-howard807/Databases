SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[UpdateEMPContact]
		@PayrollID AS BIGINT,
	    @prefix AS NVARCHAR(20),
		@firstname AS NVARCHAR(50),
		@surname AS NVARCHAR(50),
		@error INT = 0 OUTPUT, 
		@errormsg VARCHAR(2000) = '' OUTPUT
		

AS
BEGIN
	SET NOCOUNT ON
	SET DATEFORMAT YMD
	SET LOCK_TIMEOUT 5000
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

		DECLARE @clno AS NVARCHAR(100)
		DECLARE @ContID AS BIGINT
	    SET @clno='EMP'+CAST(@PayrollID AS NVARCHAR(50))
		SET @ContID=(SELECT clDefaultContact FROM MS_Prod.config.dbClient WHERE clNo=@clno)


	BEGIN TRY

		SET @errormsg = ''

		------- validation-------------------------------------------------------------
	    IF @clno IS NULL
			SET @errormsg=@errormsg + ', ' + @clno + ' - does not exist' 

	
		IF (@errormsg <> '')
		BEGIN
			SET @errormsg = RIGHT(@errormsg, LEN(@errormsg)-2)
			SET @error = 11
			RETURN @error
		END

	


BEGIN TRANSACTION


UPDATE MS_Prod.dbo.dbContactIndividual
SET contChristianNames=@firstname
,contSurname=@surname
,contTitle=@prefix
WHERE contID=@ContID


UPDATE MS_PROD.config.dbContact 
SET contName= @firstname +' ' + @surname
,contAddressee = @firstname +' ' + @surname
WHERE contID=@ContID

PRINT @ContID

UPDATE MS_Prod.config.dbClient
SET clName=@surname
,clSearch1=@surname
 WHERE clNo=@clno


 PRINT @clno


--SELECT contChristianNames,contSurname FROM MS_Prod.dbo.dbContactIndividual WHERE contID=@ContID

--SELECT clName,clSearch1 FROM MS_Prod.config.dbClient WHERE clNo=@clno
			
			
		IF @@TRANCOUNT > 0
		BEGIN 
			COMMIT TRANSACTION 
		END 
	END TRY
	BEGIN CATCH
		SET @error = @@ERROR
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRANSACTION 
		END
		
		DECLARE @ErrorProcedure AS VARCHAR(8000)
		DECLARE @ErrorMessage AS VARCHAR(8000)

		SELECT @ErrorProcedure = ERROR_PROCEDURE(), @ErrorMessage = ERROR_MESSAGE()
		PRINT @ErrorProcedure
		PRINT @ErrorMessage 

		SET @errormsg = @ErrorMessage
		RAISERROR (50855, 10, 1 , @ErrorProcedure, @ErrorMessage)
	END CATCH

	RETURN @error


END	
GO
