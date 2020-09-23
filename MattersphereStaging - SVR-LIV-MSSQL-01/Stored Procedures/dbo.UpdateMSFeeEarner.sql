SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[UpdateMSFeeEarner]
		@usrInits NVARCHAR(30),
		@usrADID NVARCHAR(50),
		@usrSQLID NVARCHAR(50),
		@usrFullName NVARCHAR(50),
		@usrEmail NVARCHAR(200),
		@usrWorksFor INT,
		@position NVARCHAR(50),
		@usrDDI NVARCHAR(30),
		@office NVARCHAR(16),
		@feeactive INT,
		@usrID INT OUTPUT,
		@error INT = 0 OUTPUT, 
		@errormsg VARCHAR(2000) = '' OUTPUT
		--,@policyid NVARCHAR(50) OUTPUT

AS
BEGIN
	SET NOCOUNT ON
	SET DATEFORMAT YMD
	SET LOCK_TIMEOUT 5000
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	BEGIN TRY

		SET @errormsg = ''

		------- validation-------------------------------------------------------------
	    IF @usrInits NOT IN (SELECT usrInits FROM [MS_PROD].dbo.dbUser WHERE usrInits = @usrInits)
			SET @errormsg=@errormsg + ', ' + @usrInits + ' - User does not exist' 

		--*****item user validation*****--EW 20170620
		--IF EXISTS (SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
		   -- SET @policyid = (SELECT PolicyID FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
		--	DELETE FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID
		--	--*****item user validation*****--EW 20170620

		--------------------------------------------------------------------------------
		
		IF (@errormsg <> '')
		BEGIN
			SET @errormsg = RIGHT(@errormsg, LEN(@errormsg)-2)
			SET @error = 11
			RETURN @error
		END

		DECLARE @brID NVARCHAR(15), @usrIDUpdating INT 
		SET @brID = (SELECT brID FROM [MS_PROD].[dbo].dbBranch WHERE brCode = @office)
		SET @usrIDUpdating = (SELECT usrID FROM [MS_PROD].[dbo].[dbUser] WHERE usrInits = @usrInits)


BEGIN TRANSACTION


		UPDATE [MS_PROD].[dbo].[dbUser]
		
		SET [usrFullName] = @usrFullName,
		[usrADID] = @usrADID,
		[usrSQLID] = @usrSQLID,
		[usrEmail] = @usrEmail,
		[usrWorksFor] = @usrIDUpdating, -- EW 20161123 - Mandy says this needs to stay as the usrID so removed @usrWorksFor - EW 20161123
		[brID] = @brID,
		[usrDDI] = @usrDDI,
		[usrExtension] = '1'+REPLACE(RIGHT(@usrDDI,6),' ',''),
		[usrJobTitle] = @position,
		[usrActive] = @feeactive
		WHERE usrID = @usrIDUpdating
			

		UPDATE [MS_PROD].[dbo].[dbFeeEarner]
		
		SET feeActive = @feeactive,
		[feeSignOff] = @usrFullName,
		[feeAddSignOff] = @position,
		[feeResponsibleTo] = @usrWorksFor -- EW 20161123 - Mandy says this needs to stay as BCM so left as is - EW 20161123

		WHERE feeusrID = @usrIDUpdating	

		----*****item user security update*****--EW 20170620
		--IF EXISTS	(SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
		--	UPDATE [MS_PROD].[item].[User]
		--	SET PolicyID = @policyid
		--	WHERE NTLogin = @usrADID

		--IF NOT EXISTS (SELECT 1 FROM [MS_PROD].[item].[User] WHERE NTLogin = @usrADID)
				
		--	INSERT [MS_PROD].[item].[User] (NTLogin, Name, Active, PolicyID)
		--	VALUES (@usrADID, @usrFullName, @feeactive, COALESCE(@policyid,'484B971D-3D0A-4FB1-A176-38EC4752B45C'))
		----*****item user security update*****--EW 20170620
			
			
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
