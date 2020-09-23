SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[RunMSMatter]
(
	 @ID INT, 
	 @clNo NVARCHAR (12),
	 @fileNo NVARCHAR (20) ,
	 @extFileID BIGINT,
	 @fileDesc NVARCHAR (255) ,
	 @fileResponsibleID NVARCHAR (12),
	 @filePrincipleID NVARCHAR (12),
	 @BusinessLine NVARCHAR (15) ,
	 @fileDept NVARCHAR (15) ,
	 @fileType NVARCHAR (15) ,
	 @fileFundCode NVARCHAR (15) ,
	 @fileCurISOCode NCHAR (3) ,
	 @fileStatus NVARCHAR (15) ,
	 @fileCreated DATETIME,
	 @fileUpdated DATETIME,
	 @fileClosed DATETIME,
	 @fileSource NVARCHAR (15) ,
	 @fileSection NVARCHAR (15) ,
	 @fileSectionGroup NVARCHAR (15) ,
	 @MattIndex INT,
	 @Office INT,
	 @brID NVARCHAR (15) ,
	 @Partner BIGINT,
	 @InsertDate DATETIME,
	 @Imported DATETIME,
	 @StatusID TINYINT,
	 @FEDCode NVARCHAR(50),
	 @Importerror INT = 0 OUTPUT, 
	 @Importerrormsg VARCHAR(2000) = '' OUTPUT,
	 @MatterNo INT OUTPUT
)	

AS
BEGIN

	BEGIN TRY

		SET @Importerrormsg = ''
		
		DECLARE @clID AS INT
		SET @clID=(SELECT clID FROM MSClient  WHERE clno=@clno) 

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

IF (@clNo NOT IN (SELECT clno FROM MSClient  WHERE clno=@clno ))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: clno = [' + RTRIM(CAST(@clNo AS VARCHAR)) + ']'
--Validate the payrollID exists and is valid.
IF (@fileResponsibleID NOT IN (SELECT usrAlias FROM MSUsers WHERE usrAlias=CAST(@fileResponsibleID AS NVARCHAR(15)))) -- Does this use payroll number or usrid
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: ResponsibleID No Payroll Number = [' + RTRIM(CAST(@fileResponsibleID AS VARCHAR)) + ']'
	
IF (@filePrincipleID NOT IN (SELECT usrAlias FROM MSUsers WHERE usrAlias=CAST(@filePrincipleID AS NVARCHAR(15)) )) -- Does this use payroll number or usrid
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: PrincipleID = [' + RTRIM(CAST(@filePrincipleID AS VARCHAR)) + ']'		
		
IF (@brID NOT IN (SELECT brcode FROM MSBranch WHERE brcode=@brID)) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Branch = [' + RTRIM(CAST(@brID AS VARCHAR)) + ']'		
	
IF (@fileType NOT IN (SELECT typecode FROM MSFileType WHERE typecode=@fileType)) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: FileType = [' + RTRIM(CAST(@fileType AS VARCHAR)) + ']'		
	
IF (@fileDept NOT IN (SELECT code FROM MSDepartment WHERE code=@fileDept)) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Department = [' + RTRIM(CAST(@fileDept AS VARCHAR)) + ']'		
--Validate the partner exists.
IF (@Partner NOT IN (SELECT usrAlias FROM dbo.MSPartner INNER JOIN dbo.MSUsers ON MSPartner.MSID = MSUsers.usrID WHERE usrAlias=CAST(@Partner AS NVARCHAR(15)))) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Partner = [' + RTRIM(CAST(@Partner AS VARCHAR)) + ']'		

IF (@StatusID=0 AND @fileNo IS NOT NULL AND @fileNo IN (SELECT fileno FROM MSClient INNER JOIN MSFile AS Matters ON MSClient.clID=Matters.clID
WHERE MSClient.clNo=@clNo AND fileNo=RTRIM(CAST(@fileNo AS VARCHAR)))) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Matter Already Exists = [' + RTRIM(CAST(@fileNo AS VARCHAR)) + ']'

IF (@StatusID=1 AND @fileNo IS NOT NULL AND @fileNo NOT IN (SELECT fileno FROM MSClient INNER JOIN MSFile AS Matters ON MSClient.clID=Matters.clID
WHERE MSClient.clNo=@clNo AND fileNo=RTRIM(CAST(@fileNo AS VARCHAR)))) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Matter Does not Exists = [' + RTRIM(CAST(@fileNo AS VARCHAR)) + ']'

---------------------------------------------------------------------------------------------------------------------------------------------------				
			
IF (@Importerrormsg <> '')
BEGIN
	   SET @Importerrormsg = RIGHT(@Importerrormsg, LEN(@Importerrormsg)-2)
	   SET @Importerror = 11
	   RETURN @Importerror
END	


BEGIN TRANSACTION

IF @StatusID=0

BEGIN

	--DECLARE @MatterNo AS INT 
	IF @fileNo IS NULL 

	BEGIN

	SET @MatterNo=(SELECT COALESCE(MAX(Cast(ISNULL(fileno,0) as int)),0) +1
					   FROM MSClient INNER JOIN MSFile AS Matters 
					   ON MSClient.clID=Matters.clID 
					   WHERE MSClient.clNo=@clNo
					   AND ISNUMERIC(fileno)=1)
	END

	IF @fileNo IS NOT NULL BEGIN SET @MatterNo=@fileNo END
	
	---INSERT INTO DBFILE
	INSERT INTO  MS_PROD.[config].[dbFile]
		(
		[clID] ,[fileNo] ,[fileDesc] ,[fileResponsibleID],
		[filePrincipleID],[fileDepartment],[fileType],
		[fileFundCode],[fileCurISoCode],[fileStatus],
		[Created],[CreatedBy],[Updated],[fileClosed],
		[fileSource],[brID] ,FILEEXTLINKID	-- FOR 3E MATTINDEX ??
		)
		SELECT
		@clID ,@MatterNo ,@fileDesc ,@fileResponsibleMSID,
		@filePrincipleMSID,'DEFDEPT',@fileType,
		@fileFundCode,@fileCurISoCode,@fileStatus,
		@FileCreated,-200,@FileUpdated,@fileClosed,
		@fileSource,@brID ,@MattIndex	 

--- Get FILEID
	DECLARE @FileID AS INT
	SET @FileID=(SELECT fileID FROM MSFile WITH (NOLOCK) WHERE clID=@clID AND fileNo=RTRIM(CAST(@MatterNo AS VARCHAR)))

	 --INSERT INTO dbAssociates
	 INSERT INTO MS_PROD.[config].[dbAssociates] 
	 ( [fileID], [contID], [assocOrder], [assocType],
	   [assocHeading], [assocdefaultaddID], [assocSalut] )
 	 SELECT 
	 @FileID, C.[contID] , 0 , 'CLIENT' , @fileDesc , NULL , 
	 coalesce ( C.[contSalut] , 'Sir/Madam' )
	 FROM MSFile F 
	 INNER JOIN MSClient CL ON F.[clID] = CL.[clID]
	 INNER JOIN MSContact C ON C.[contID] = CL.[cldefaultContact]
	 WHERE F.clid = @clID AND F.fileNo = RTRIM(CAST(@MatterNo AS VARCHAR))
	 
	 DECLARE @cboCategory NVARCHAR(50)
SET @cboCategory=(SELECT TOP 1 matterCategory FROM MS_PROD.dbo.udMatterCategory WHERE matterType=@fileType)

	 --INSERT INTO udExtFile
	 INSERT INTO MS_PROD.[dbo].[udExtFile]
     ([fileID],[cboPracticeArea],[cboTeam],[cboBusinessLine],[cboDepartment],cboPartner,FEDCode,bitMSOnlyMM,cboCategory)
	 SELECT @FileID, @fileSectionGroup, @fileSection, @BusinessLine, @fileDept,@PartnerMSID,@FEDCode,1,@cboCategory
		 
END

IF @StatusID=1

BEGIN
	DECLARE @UpdateFileID AS INT
	SET @UpdateFileID=(SELECT fileID FROM MSClient 
					   INNER JOIN MSFile AS Matters 
					   ON MSClient.clID=Matters.clID
					   WHERE MSClient.clNo=@clNo 
					   AND fileNo=RTRIM(CAST(@fileNo AS VARCHAR)) )
PRINT 'Starting Extfileupdate' 
print @UpdateFileID
UPDATE MS_PROD.[dbo].[udExtFile]
SET [cboPracticeArea]=@fileSectionGroup
,[cboTeam]=@fileSection
,[cboBusinessLine]=@BusinessLine
,cboDepartment=@fileDept
WHERE fileID=@UpdateFileID

UPDATE MS_PROD.[config].[dbFile]
SET [fileDesc]=@fileDesc 
,[fileResponsibleID]=@fileResponsibleMSID
,[filePrincipleID]=@filePrincipleMSID
,[fileDepartment]='DEFDEPT'
,[fileType]=@fileType
,[fileStatus]=@fileStatus
,[Updated]=GETDATE()
,[fileClosed]=@fileClosed
,[brID]=@brID
WHERE fileID=@UpdateFileID


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
