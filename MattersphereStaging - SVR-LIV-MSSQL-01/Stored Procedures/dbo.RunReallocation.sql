SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[RunReallocation]
(
	 @ID int, 
	 @clNo nvarchar (12),
	 @fileNo nvarchar (20) ,
	 @fileResponsibleID nvarchar (12),
	 @filePrincipleID nvarchar (12),
	 @Partner BIGINT,
	 @Importerror int = 0 OUTPUT, 
	 @Importerrormsg varchar(2000) = '' OUTPUT
)	

AS
BEGIN

	BEGIN TRY

		SET @Importerrormsg = ''
		
		--Convert payroll id to MS ID
		DECLARE @fileResponsibleMSID  nvarchar (36)
		SET @fileResponsibleMSID = (SELECT TOP 1 usrID FROM MSUsers WHERE usrAlias = CAST(@fileResponsibleID AS NVARCHAR(15)))
		--Convert payroll id to MS ID
		DECLARE @filePrincipleMSID  nvarchar (36)
		SET @filePrincipleMSID = (SELECT TOP 1 usrID FROM MSUsers WHERE usrAlias = CAST(@filePrincipleID AS NVARCHAR(15)))
		--Convert payroll id of partner to MS ID
		DECLARE @PartnerMSID  nvarchar (36)
		SET @PartnerMSID = (SELECT TOP 1 MSID FROM dbo.MSPartner 
							INNER JOIN dbo.MSUsers ON MSPartner.MSID = MSUsers.usrID
							WHERE usrAlias = CAST(@Partner AS NVARCHAR(15)))
		
-----------------VALIDATION---------------------------------------------------------------------------------------------------------------------

--Validate the payrollID exists and is valid.
IF (@fileResponsibleID NOT IN (SELECT usrAlias FROM MSUsers WHERE usrAlias=CAST(@fileResponsibleID AS NVARCHAR(15)))) -- Does this use payroll number or usrid
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: ResponsibleID No Payroll Number = [' + RTRIM(CAST(@fileResponsibleID AS VARCHAR)) + ']'
	
IF (@filePrincipleID NOT IN (SELECT usrAlias FROM MSUsers WHERE usrAlias=CAST(@filePrincipleID AS NVARCHAR(15)) )) -- Does this use payroll number or usrid
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: PrincipleID = [' + RTRIM(CAST(@filePrincipleID AS VARCHAR)) + ']'		
		
IF (@Partner NOT IN (SELECT usrAlias FROM dbo.MSPartner INNER JOIN dbo.MSUsers ON MSPartner.MSID = MSUsers.usrID WHERE usrAlias=CAST(@Partner AS NVARCHAR(15)))) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Partner = [' + RTRIM(CAST(@Partner AS VARCHAR)) + ']'		


---------------------------------------------------------------------------------------------------------------------------------------------------				
			
IF (@Importerrormsg <> '')
BEGIN
	   SET @Importerrormsg = RIGHT(@Importerrormsg, LEN(@Importerrormsg)-2)
	   SET @Importerror = 11
	   RETURN @Importerror
END	


BEGIN TRANSACTION


BEGIN
	DECLARE @UpdateFileID AS INT
	SET @UpdateFileID=(SELECT fileID FROM MSClient 
					   INNER JOIN MSFile AS Matters 
					   ON MSClient.clID=Matters.clID
					   WHERE MSClient.clNo=@clNo 
					   AND fileNo=RTRIM(CAST(@fileNo AS VARCHAR)) )

UPDATE MS_Prod.[config].[dbFile]
SET [fileResponsibleID]=@fileResponsibleMSID
,[filePrincipleID]=@filePrincipleMSID
,[Updated]=GETUTCDATE()
WHERE fileID=@UpdateFileID

UPDATE MS_Prod.[dbo].[udExtFile]
SET cboPartner=@PartnerMSID
WHERE fileID=@UpdateFileID

UPDATE MS_PROD.dbo.dbTasks
SET feeusrID=@filePrincipleMSID
WHERE fileID=@UpdateFileID
AND tskComplete=0
--Above Reallocates Outstanding Tasks


END 


IF @@TRANCOUNT > 0
		BEGIN 
			COMMIT TRANSACTION 
			PRINT 'COMMIT Transaction'
			
		END 
	END TRY
	BEGIN CATCH
		SET @Importerror = @@ERROR
		IF @@TRANCOUNT > 0
		BEGIN 
			ROLLBACK TRANSACTION 
		END
		
		DECLARE @ErrorProcedure AS VARCHAR(8000)
		DECLARE @ErrorMessage AS VARCHAR(8000)

		SELECT @ErrorProcedure = ERROR_PROCEDURE(), @ErrorMessage = ERROR_MESSAGE()
		PRINT @ErrorProcedure
		PRINT @ErrorMessage 

		SET @Importerrormsg = @ErrorMessage
		RAISERROR (50855, 10, 1 , @ErrorProcedure, @ErrorMessage)
	END CATCH

    RETURN @Importerror

END


GO
