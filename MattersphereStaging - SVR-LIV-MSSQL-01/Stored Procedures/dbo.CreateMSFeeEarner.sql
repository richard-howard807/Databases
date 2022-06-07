SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[CreateMSFeeEarner]
		@usrInits NVARCHAR(30),
		@usrAlias NVARCHAR(36),
		@usrADID NVARCHAR(50),
		@usrSQLID NVARCHAR(50),
		@usrFullName NVARCHAR(50),
		@usrEmail NVARCHAR(200),
		@usrWorksFor INT,
		@position NVARCHAR(50),
		@usrDDI NVARCHAR(30),
		@usrExtID INT,
		@feeExtID INT,
		@office NVARCHAR(16),
		@usrID INT OUTPUT,
		@error INT = 0 OUTPUT, 
		@errormsg VARCHAR(2000) = '' OUTPUT

AS
BEGIN
	SET NOCOUNT ON
	SET DATEFORMAT YMD
	SET LOCK_TIMEOUT 5000
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @original_policyid NVARCHAR(50)
DECLARE @policyid NVARCHAR(50)

-----ROLES----------
DECLARE @NonPartnerXML AS NVARCHAR(MAX)
SET @NonPartnerXML='<config><settings><property name="usrEmailProfileLevel" value="M" /><property name="usrEmailProfileOnClose" value="False" /><property name="usrEmailProfileOnNew" value="True" /><property name="usrEmailProfileOnReply" value="True" /><property name="usrEmailProfileOnForward" value="True" /><property name="usrEmailProfileOnDelete" value="False" /><property name="usrEmailProfileOnMove" value="True" /><property name="usrEmailProfileAllowEdit" value="False" /><property name="Roles" value="TASKADDMANUAL,TASKDELATEALL,TASKDELETETEAM,TASKUPDATEALL,TASKUPDATETEAM,PHASE2,DOCDELETE,PAYOR,SHWINFPNL" /><property name="usrShowDocumentMarkup" value="False" /><property name="usrPrecLangOpt" value="False" /><property name="usrPrecLibOpt" value="False" /><property name="RemmberLastClientNFile" value="True" /><property name="WorksForMatterHandler" value="False" /><property name="usrAutoPrint" value="Null" /><property name="usrDisplayCommandCentreAtLogon" value="False" /><property name="usrUseDefaultAssociate" value="Null" /><property name="usrAutoWriteLetter" value="False" /><property name="usrEnableTrackChangesWarning" value="Null" /><property name="usrShowMRIList" value="False" /><property name="DisableStopCodeCheck" value="False" /><property name="usrAutoSaveAttachments" value="Null" /><property name="usrEmailResolveAddress" value="Null" /><property name="usrEmailQuickSave" value="Null" /><property name="usrSavedEmailOption" value="" /><property name="usrSavedSentEmailOption" value="" /><property name="usrSavedEmailFolderLocation" value="" /><property name="usrContinueEditingAfterSave" value="True" /><property name="AutoCheckInUnchangedDocuments" value="Null" /><property name="usrPromptDocAlreadyOpen" value="Null" /><property name="usrPromptDocAlreadyOpenTime" value="0" /><property name="MinimiseWindowOnOpen" value="Null" /><property name="usrHideAllWelcomeWizardPages" value="Null" /><property name="InformationPanelDockLocation" value="DOCK2LFT" /></settings></config>'

DECLARE @PartnerXML AS NVARCHAR(MAX)
SET @PartnerXML='<config><settings><property name="usrShowDocumentMarkup" value="False" /><property name="usrPrecLangOpt" value="False" /><property name="usrPrecLibOpt" value="False" /><property name="RemmberLastClientNFile" value="False" /><property name="WorksForMatterHandler" value="False" /><property name="Roles" value="CLPART,KIPS,FE,PAYOR,DOCDELETE,PHASE2,TASKDELETEALL,TASKADDMANUAL,TASKDELATEALL,TASKDELETETEAM,TASKUPDATEALL,TASKUPDATETEAM,SHWINFPNL" /><property name="usrAutoPrint" value="Null" /><property name="usrDisplayCommandCentreAtLogon" value="False" /><property name="usrUseDefaultAssociate" value="Null" /><property name="usrEnableTrackChanges" value="Null" /><property name="usrAutoWriteLetter" value="False" /><property name="usrEnableTrackChangesWarning" value="Null" /><property name="usrShowMRIList" value="False" /><property name="DisableStopCodeCheck" value="False" /><property name="usrAutoSaveAttachments" value="Null" /><property name="usrEmailResolveAddress" value="Null" /><property name="usrEmailQuickSave" value="Null" /><property name="usrSavedEmailOption" value="" /><property name="usrSavedSentEmailOption" value="" /><property name="usrSavedEmailFolderLocation" value="" /><property name="usrEmailProfileOnClose" value="False" /><property name="usrEmailProfileOnNew" value="True" /><property name="usrEmailProfileOnReply" value="True" /><property name="usrEmailProfileOnForward" value="True" /><property name="usrEmailProfileOnDelete" value="False" /><property name="usrEmailProfileOnMove" value="True" /><property name="usrEmailProfileAllowEdit" value="False" /><property name="usrContinueEditingAfterSave" value="True" /><property name="AutoCheckInUnchangedDocuments" value="Null" /><property name="usrPromptDocAlreadyOpen" value="Null" /><property name="MinimiseWindowOnOpen" value="Null" /><property name="usrPromptDocAlreadyOpenTime" value="0" /><property name="usrHideAllWelcomeWizardPages" value="Null" /><property name="RTAUSRNAME" value="" /><property name="usrEmailProfileLevel" value="M" /><property name="InformationPanelDockLocation" value="DOCK2LFT" /></settings></config>'
--------------------


	BEGIN TRY

		SET @errormsg = ''

		------- validation-------------------------------------------------------------
	    IF @usrInits IN (SELECT usrInits FROM [MS_PROD].dbo.dbUser WHERE usrInits = @usrInits)
			SET @errormsg=@errormsg + ', ' + @usrInits + ' - User already exists' 

		--*****item user validation*****--EW 20170620
		IF EXISTS (SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
		    SET @original_policyid = (SELECT PolicyID FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
			DELETE FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID
			--*****item user validation*****--EW 20170620

		--------------------------------------------------------------------------------
		
		IF (@errormsg <> '')
		BEGIN
			SET @errormsg = RIGHT(@errormsg, LEN(@errormsg)-2)
			SET @error = 11
			RETURN @error
		END

		DECLARE @brID NVARCHAR(15)
		SET @brID = (SELECT brID FROM [MS_PROD].[dbo].dbBranch WHERE brCode = @office)

BEGIN TRANSACTION

		INSERT INTO [MS_PROD].[dbo].[dbUser]
				   ([usrInits]	--PayrollID
					,[usrAlias]	--PayrollID
					,[usrADID]	--Network Name
					,[usrSQLID]	--Network Name
					,[usrFullName]	--User Name
					,[usrEmail]	-- Email
					,[usrWorksFor]	--UserID
					,[usrDDI]		--Phone Number
					,[usrExtID]  	--Entity
					,[brID]
					,[usrprintID]
					,[usrcurISOCode]
					,usrXML
					,usrExchangeSync -- RH Added 04/09/2020 after request from Jake to fix exchange calendar sync issues 
					)
			 VALUES
				   (@usrInits,
					@usrAlias,
					@usrADID,
					@usrSQLID,
					@usrFullName,
					@usrEmail,
					@usrWorksFor,
					@usrDDI,
					@usrExtID,
					@brID,
					2,
					'GBP'
					,CASE WHEN UPPER(@position) LIKE '%PARTNER%' THEN @PartnerXML ELSE @NonPartnerXML END 
					, 1
				   )

		
		DECLARE @feeusrID INT
		SET @feeusrID = @@IDENTITY
		PRINT @feeusrID

		DECLARE	@extension NVARCHAR(16)
		SET @extension = '1'+REPLACE(RIGHT(@usrDDI,6),' ','')

		/*Don't need this now as the BCM is being pulled in via Integration Builder -EW 20161123 - Mandy wants this back in as it's breaking Mattersphere - EW 20161123 */

		UPDATE [MS_PROD].[dbo].[dbUser]
		SET [usrWorksFor]=@feeusrID,
			[usrExtension]=@extension,
			[usrJobTitle]=@position
		WHERE usrInits=@usrInits

		PRINT @feeusrID 
		PRINT @feeExtID
		PRINT @usrFullName
		PRINT @position
		PRINT @usrWorksFor

		INSERT INTO [MS_PROD].[dbo].[dbFeeEarner]
					([feeusrID]	--User ID
					,[feeExtID]	--TkprIndex
					,[feeSignOff] --User Name
					,[feeAddSignOff] -- Position
					,[feeResponsibleTo]
					,[feeResponsible]
					,feeActive
					,feeAddRef)
			VALUES
					(@feeusrID,
					 @feeExtID,
					 @usrFullName,
					 @position,
					 @usrWorksFor,  --EW 20161123 - Mandy says BCM is still required here - EW 20161123
					 1,
					 1,
					 left(@usrFullName, 1) + SUBSTRING( @usrFullName, CHARINDEX(' ', @usrFullName, 0) + 1 , 4 ) --added request by Jake for letter reference
					 )

		INSERT INTO [MS_PROD].[dbo].[udExtUser] 
					(usrID
					,bitMSOnlyUser
					,rowguid)
		
		VALUES
					(@feeusrID,
					1,
					NEWID())

				--*****item user security update*****--EW 20170620
		IF EXISTS	(SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
			
			BEGIN 
			
			SET @policyid = (SELECT ISNULL(PolicyID,'484B971D-3D0A-4FB1-A176-38EC4752B45C') FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
			
			
			UPDATE [MS_PROD].[item].[User]
			SET PolicyID = COALESCE(@original_policyid,@policyid)
			WHERE NTLogin = @usrADID
			
			END 

		IF NOT EXISTS (SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
				
			INSERT [MS_PROD].[item].[User] (NTLogin, Name, Active, PolicyID)
			VALUES (@usrADID, @usrFullName, 1, COALESCE(@policyid,'484B971D-3D0A-4FB1-A176-38EC4752B45C'))
		--*****item user security update*****--EW 20170620


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
