SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[RunMSClient]
--Declare the variables that will be passed in from the cursor to this proc.
(
     @clName			NVARCHAR (80),
	 @clType			NVARCHAR (12),
	 @clNo				NVARCHAR (12),
	 @cbocligrp			NVARCHAR (50),
	 @cbopartner		BIGINT,
	 @addid				BIGINT,
	 @addLine1			NVARCHAR (50),
	 @addLine2			NVARCHAR (50),
	 @addLine3			NVARCHAR (50),
	 @addLine4			NVARCHAR (50),
	 @addLine5			NVARCHAR (50),
	 @addPostCode		NVARCHAR (15),
	 @addCountry		NVARCHAR (50),
	 @addDXCode			NVARCHAR (80),
	 @contSalut			NVARCHAR (50),
	 @contAddressee		NVARCHAR (50),
	 @contTitle			NVARCHAR (10),
	 @contFirstNames	NVARCHAR (50),
	 @contSurname		NVARCHAR (50),
	 @contSex			NCHAR (1),
	 @contEmail			NVARCHAR (200),
	 @contTelHome		NVARCHAR (30),
	 @contTelWork		NVARCHAR (30),
	 @contTelMob		NVARCHAR (30),
	 @contFAX			NVARCHAR (30),
     @brID				INT,
	 @contSubType		NVARCHAR (15),
	 @IsClient			NVARCHAR (15) ,
	 @dbContactID1		BIGINT				OUTPUT,
	 @dbclno			NVARCHAR (12)		OUTPUT,
	 @Importerror		INT = 0				OUTPUT, 
	 @Importerrormsg	VARCHAR(2000) = ''	OUTPUT
	 )
AS

BEGIN

	BEGIN TRY

	SET @Importerrormsg = ''

--VALIDATION
IF (UPPER(@IsClient) = 'YES' AND @cbopartner NOT IN (SELECT usrAlias FROM dbo.MSPartner INNER JOIN dbo.MSUsers ON MSPartner.MSID = MSUsers.usrID WHERE usrAlias=CAST(@cbopartner AS NVARCHAR(15)))) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Partner = [' + RTRIM(CAST(@cbopartner AS VARCHAR)) + ']'		

IF (UPPER(@IsClient) = 'YES' AND @clNo IN (SELECT clno FROM dbo.MSClient WHERE clno=@clno)) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Client Number = [' + RTRIM(CAST(@clno AS VARCHAR)) + '] already exists'		

IF (@brID NOT IN (SELECT brcode FROM MSBranch WHERE brcode=@brID)) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Branch = [' + RTRIM(CAST(@brID AS VARCHAR)) + ']'	

IF (UPPER(@IsClient) NOT IN ('YES', 'NO'))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Client Yes/no not specified = [' + RTRIM(CAST(@IsClient AS VARCHAR)) + ']'

IF (UPPER(@contSex) NOT IN ('M', 'F'))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Sex not valid = [' + RTRIM(CAST(@contSex AS VARCHAR)) + ']'

IF (UPPER(@contSubType) NOT IN ('ORGANISATION','INDIVIDUAL'))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Client Type incorrect = [' + RTRIM(CAST(@contSubType AS VARCHAR)) + ']'

IF (UPPER(@contSubType) = 'ORGANISATION' AND LEN(@clName) < 1) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Organisation Name Not Provided = [' + RTRIM(CAST(@clName AS VARCHAR)) + ']'

IF (UPPER(@contSubType) = 'INDIVIDUAL' AND LEN(@contSurname) < 1) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Individual Surname Not Provided = [' + RTRIM(CAST(@contSurname AS VARCHAR)) + ']'

IF (UPPER(@contSubType) = 'INDIVIDUAL' AND LEN(@contFirstNames) < 1) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Individual First Names Not Provided = [' + RTRIM(CAST(@contFirstNames AS VARCHAR)) + ']'

IF (UPPER(@contSubType) = 'INDIVIDUAL' AND LEN(@contSalut) < 1) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Individual Salutation Names Not Provided = [' + RTRIM(CAST(@contSalut AS VARCHAR)) + ']'
	
--If an error has been reported, set the error number.
IF (@Importerrormsg <> '')
BEGIN
	   SET @Importerrormsg = RIGHT(@Importerrormsg, LEN(@Importerrormsg)-2)
	   SET @Importerror = 11
	   RETURN @Importerror
END	

--Convert the @cboPartner to the MSID
		--Convert payroll id of partner to MS ID
DECLARE @PartnerMSID  nvarchar (36)
SET @PartnerMSID = (SELECT TOP 1 MSID FROM dbo.MSPartner 
							INNER JOIN dbo.MSUsers ON MSPartner.MSID = MSUsers.usrID
							WHERE usrAlias = CAST(@cbopartner AS NVARCHAR(15)))
/*Moved the @PartnerMSID to here so it was set early enough in the query to be used by subsequent inserts. D.Abram - 20170418*/
BEGIN TRANSACTION

--Begin the inserts

INSERT MS_Prod.[config].[dbContact]
		(
		[contTypeCode] ,
		[contName] ,
		[contDefaultAddress] ,
		[contSalut] ,
		[contAddressee],
		[contNotes] ,
		[Created] , 
		[CreatedBy] --INT
		)
		SELECT 
		@contSubType,
		LEFT((Coalesce ( ltrim ( Coalesce ( @contTitle , '' ) + ' ' + rtrim ( ( @contFirstNames + ' ' + Coalesce ( @contSurname , '' )) )) , @clName ))  ,80),
		1 AS [contDefaultAddress], --DEFAULT ADDRESS
		@contSalut,
		@contAddressee,
		'',
		GETUTCDATE(),
		-200 AS CreatedBy--DEFAULT

DECLARE @dbContactID BIGINT 	

--Charge the outputID		
SET @dbContactID = @@IDENTITY --Get the new ID from the DBContact Table.

INSERT INTO MS_Prod.dbo.udExtContact
(
contID
)
SELECT @dbContactID

IF UPPER(@IsClient) = 'YES' 

BEGIN --For when a client number is not provided
IF @clNo  IS NULL
BEGIN
-------------------GET NEXT SEED/ClientNo--------------------------
--Insert into the dbClient Table and dbExtClient if this is a client.
--This is the proc that gets the new seed number.
DECLARE @number NVARCHAR(12)
DECLARE @branch INT
DECLARE @usrid INT
--SELECT @clid = clid , @number = clno, @cltype = cltypecode, @usrid = createdby , @branch = brID FROM inserted 
-- If the branchID is specifically set i.e. the value is not 0 or -1 set the branchID to equal that value
-- =========================================================
IF (SELECT TOP 1 regBranchConfig FROM MS_Prod..dbRegInfo)  > 0
	SET @branch = ( SELECT TOP 1 regBranchConfig FROM MS_Prod..dbRegInfo R JOIN MS_Prod..dbBranch B ON B.brID = R.regBranchConfig )
-- If using site specfic database (value 0)
-- ======================
IF (SELECT TOP 1 regBranchConfig FROM MS_Prod..dbRegInfo) = 0 OR @branch IS NULL
	SET @branch = (SELECT TOP 1 brid FROM MS_Prod..dbreginfo)
IF @number IS NULL OR @number = ''

PRINT CAST(@branch AS VARCHAR(10)) + ' Branch'
BEGIN
-- DECLARE @clNo   NVARCHAR (12)
 DECLARE @newnum NVARCHAR(12)
 DECLARE @seed NVARCHAR(15) --This is the data type of the user defined code uCodeLookup

 SET @seed = ISNULL((SELECT typeseed FROM MS_Prod..dbclienttype WHERE typecode = @cltype), 'CL')

 EXECUTE  MS_Prod..sprGetNextSeedNo @branch, @seed, NULL, @newnum OUTPUT
 SELECT @clNo = @newnum --Set CLno to the value assigned by the proc.
END
END
-------------------------------------------------------------------------------------------------------------------------


	INSERT MS_Prod.[config].[dbClient]
		(
		[clNo] ,
		[clAccCode] ,
		[brid] ,		 -- 3E OFFICE
		[clTypeCode] ,	
		[clName] ,
		[feeusrId] ,	-- 3E OPEN TIMEKEEPER
		[createdBy] ,
		[clDefaultContact] ,
		[clSource] ,
		[clUICultureInfo] ,
		[clSearch1] ,
		[clSearch2] ,
		[clSearch3] ,
		[clSearch4] ,
		[clSearch5] ,
		[clextID]		-- 3E CLIENTINDEX
		)

/*Changed the feeusrId to use the @PartnerMSID instead of -200 beacuse it was breaking the user import process. D.Abram - 20170418*/

	SELECT @clNo,NULL,@brID,@clType,@clName,@PartnerMSID,-200, @dbContactID ,'IMPORT','en-gb'
	,MS_Prod.[dbo].[GetSearchField] ( rtrim ( @clName ) , 1 ) as [search1] 
	,MS_Prod.[dbo].[GetSearchField] ( rtrim ( @clName ) , 2 ) as [search2] 
	,MS_Prod.[dbo].[GetSearchField] ( rtrim ( @clName ) , 3 ) as [search3] 
	,MS_Prod.[dbo].[GetSearchField] ( rtrim ( @clName ) , 4 ) as [search4] 
	,MS_Prod.[dbo].[GetSearchField] ( rtrim ( @clName ) , 5 ) as [search5]
	,NULL


DECLARE @clID AS bigint
--Charge the outputID		
SELECT @clID =  @@IDENTITY --Get the new ID from the dbclient Table.


INSERT MS_Prod.[dbo].[dbClientContacts]
		(
		[ClID] ,
		[contID] 
		)
SELECT @clID,@dbContactID



INSERT INTO MS_Prod.dbo.udExtClient
(
clID
,cboPartner
,cboClientGroup
)
SELECT @clID,@PartnerMSID,@cbocligrp

END

--Now need to see if address exists.
IF @addid NOT IN (SELECT addID  FROM MS_Prod..dbaddress WHERE addID = @addid)
BEGIN

INSERT INTO MS_Prod.dbo.dbAddress
           ([addLine1]
           ,[addLine2]
           ,[addLine3]
           ,[addLine4]
           ,[addLine5]
           ,[addPostcode]
           ,[addCountry]
           ,[addDXCode]
           ,[CreatedBy]
           ,[UpdatedBy]
		   )
SELECT
           @addLine1		AS addLine1 
           ,@addLine2		AS addLine2
           ,@addLine3		AS addLine3 
           ,@addLine4		AS addLine4 
           ,@addLine5		AS addLine5 
           ,@addPostCode	AS addPostcode
           ,@addCountry		AS addCountry
           ,@addDXCode		AS addDXCode
           ,-200			AS [Createdby]				--Default used by MS
           ,-200			AS UpdatedBy	
          -- ,@<addExtTxtID, nvarchar(20),>
           --,<ROWGUID, uniqueidentifier,>
           --,<addCountryOld, nvarchar(50),> 

DECLARE @NewAddressId bigint			--Get the seed number of the new address ID and store it in a variable
SELECT @NewAddressId = @@IDENTITY	

UPDATE MS_Prod.config.dbContact
SET [contDefaultAddress]=@NewAddressId
WHERE contID=@dbContactID

END 

IF COALESCE(@NewAddressId,@addid) IN (SELECT addID  FROM MS_Prod..dbaddress WITH (NOLOCK) WHERE addID = COALESCE(@NewAddressId,@addid))
BEGIN

INSERT INTO  MS_Prod.[dbo].[dbContactAddresses]
           ([contID]
           ,[contaddID]
           ,[contCode]
		   )
SELECT		@dbContactID	AS [contID]
           ,COALESCE(@NewAddressId,@addid)			AS [contaddID]
           ,'Main'				AS [contCode]				--Not sure which variable to use here.
END


IF UPPER(@contSubType)='INDIVIDUAL'
BEGIN

INSERT MS_Prod.[dbo].[dbContactIndividual]
		(
		[contID] ,
		[contTitle] ,
		[contChristianNames] ,
		[contSurname] ,
		[contSex]
		)
SELECT  @dbContactID
		,@contTitle
		,@contFirstNames
		,@contSurname
		,@contSex

END 

IF UPPER(@contSubType)='ORGANISATION'

BEGIN
INSERT  MS_Prod.dbo.dbContactCompany 
		(
		[contID] ,
		[contRegCoName]
		)
		SELECT @dbContactID AS [contID]
		,@clName AS [contRegCoName]

END


IF LEN(@contEmail)>0 

BEGIN 
	INSERT MS_Prod.[dbo].[dbContactEmails]
		(
		[contID] ,
		[contEmail] ,
		[contCode]
		)
	SELECT 
		@dbContactID, @contEmail, 'MAIN'
		
END 


	INSERT MS_Prod.[dbo].[dbContactNumbers]
		(
		[contID] ,
		[contNumber] ,
		[contCode] ,
		[contExtraCode] 
		)
		SELECT 	ContactID ,
		[contNumber] ,
		[contCode] ,
		[contExtraCode]  
		FROM 
		(
		SELECT @dbContactID AS ContactID, @contTelHome AS [contNumber] , 'TELEPHONE' AS [contCode] , 'HOME'  AS [contExtraCode] UNION
		SELECT @dbContactID, @contTelWork, 'TELEPHONE' , 'WORK' UNION
		SELECT @dbContactID , @contFAX, 'FAX' , 'MAIN'
		) AS ContactNo
		WHERE LEN([contNumber])> 3


SET @dbContactID1 = @dbContactID
SET @dbclno = @clNo

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
