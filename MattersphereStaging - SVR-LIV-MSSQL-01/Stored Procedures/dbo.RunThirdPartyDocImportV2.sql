SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RunThirdPartyDocImportV2]
(
	@FileID [BIGINT],
	@DocumentTitle [NVARCHAR](255),
	@AlternateDocDescription [NVARCHAR](255) ,
	@DocumentExtension [NVARCHAR](15) ,
	@DocWallet [VARCHAR](19) ,
	@CreationDate [DATETIME] ,
	@ModifiedDate [DATETIME] ,
	@DocSent [DATETIME] ,
	@DocReceived [DATETIME] ,
	@DocTo [NVARCHAR](1000),
	@DocFrom [NVARCHAR](255),
	@DocSubject [NVARCHAR](255),
	@ShowOnExtranet NVARCHAR(3)='',
	@MSassocID BIGINT,
    @MSDocFileName NVARCHAR(255)='' OUTPUT,
    @MSDocumentLocation NVARCHAR(255)='' OUTPUT,
    @MSDocID BIGINT OUTPUT,
	@CLIENTID BIGINT OUTPUT,
	@CLNAME NVARCHAR(80)='' OUTPUT,
	@CLNO NVARCHAR(20)='' OUTPUT,
	@FILEDESC NVARCHAR(255)='' OUTPUT,
	@FILENO NVARCHAR(255)='' OUTPUT,
	@Importerror INT = 0 OUTPUT, 
	@Importerrormsg VARCHAR(2000) = '' OUTPUT
)	

AS
BEGIN

	BEGIN TRY

		SET @Importerrormsg=''

DECLARE @DocWalletInsert AS NVARCHAR(15) 

SET @DocWalletInsert=(SELECT cdCode FROM MS_PROD.dbo.dbCodeLookup
WHERE cdType='WALLET' AND  cdDesc=@DocWallet)

DECLARE @clID AS BIGINT
SET @clID=(SELECT clID FROM MS_PROD.config.dbFile WHERE fileID=@FileID)

DECLARE @dirid AS Smallint
SET @dirid=(SELECT dirid FROM  MS_PROD.dbo.dbDirectory WHERE dirCode = 'OMDOCUMENTS')

DECLARE @assocID AS BIGINT

IF @MSassocID IS NOT NULL 
BEGIN 
SET @assocID=@MSassocID
END 

IF @MSassocID IS NULL 
BEGIN 

SET @assocID=(SELECT assocID FROM  (SELECT fileid,[assocID],ROW_NUMBER() OVER (PARTITION BY fileid ORDER BY [assocID] DESC ) AS xOrder
FROM MS_PROD.config.dbAssociates
WHERE assocOrder=0 AND assoctype='CLIENT'
AND fileID=@FileID) as dbAssociates  
WHERE xOrder=1
)
END 

DECLARE @docType AS NVARCHAR(15)

SET @docType=(SELECT CASE WHEN LOWER(@DocumentExtension) = 'msg' THEN 'EMAIL'
--WHEN LOWER(@DocumentExtension) = 'eml'  THEN 'EMAIL'
WHEN LOWER(@DocumentExtension) = 'docx'  THEN 'DOCUMENT'
WHEN  LOWER(@DocumentExtension) = 'doc'  THEN 'DOCUMENT'
WHEN  LOWER(@DocumentExtension) = 'xls'  THEN 'SPREADSHEET'
WHEN  LOWER(@DocumentExtension) = 'xlsx'  THEN 'SPREADSHEET'
WHEN  LOWER(@DocumentExtension) = 'pdf'  THEN 'PDF'
ELSE 'SHELL' END)


DECLARE @docAppID AS smallint
SET @docAppID=(SELECT typeDefaultApp FROM  [MS_PROD].[dbo].[dbDocumentType]
WHERE typeCode=@docType)


DECLARE @PrecID  AS BIGINT
SET @PrecID=(SELECT PrecID FROM MS_PROD.dbo.dbPrecedents 
WHERE PrecTitle='Default' 
AND PrecType='Shell')


IF (@DocWalletInsert IS NULL) 
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: DocWallet = [' + RTRIM(CAST(@DocWallet AS VARCHAR)) + ']'	

IF (@FileID NOT IN (SELECT FileID FROM MS_PROD.config.dbFile WHERE fileID =@FileID))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Matter = [' + RTRIM(CAST(@FileID AS VARCHAR)) + ']'

IF (@clID NOT IN (SELECT clID FROM MS_PROD.config.dbClient WHERE clID =@clID) )
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Client = [' + RTRIM(CAST(@FileID AS VARCHAR)) + ']'		

IF (@dirid IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: DocDirectory'

--IF (@assocID IS NULL)
--SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: AssociateID'

IF (@clID IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Client'


IF(@DocumentExtension IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Missing Doc Extension'

IF(@docType IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: DocType'

IF(@docAppID IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: AppID'

IF(@DocumentTitle IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Missing Document Title'

IF(@AlternateDocDescription IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Missing AlternateDocDescription'

IF(@DocumentExtension IS NULL)
SET @Importerrormsg = @Importerrormsg + ', ' + 'Missing Doc Extension'

IF (@assocID IS NOT NULL AND @assocID NOT IN (SELECT assocID FROM MS_PROD.config.dbAssociates WHERE fileID =@FileID AND assocID=@assocID))
SET @Importerrormsg = @Importerrormsg + ', ' + 'Invalid: Associate ID = [' + RTRIM(CAST(@assocID AS VARCHAR)) + ']'

--If an error has been reported, set the error number.
IF (@Importerrormsg <> '')
BEGIN
	   SET @Importerrormsg = RIGHT(@Importerrormsg, LEN(@Importerrormsg)-2)
	   SET @Importerror = 11
	   RETURN @Importerror
END	

BEGIN TRANSACTION

--Begin the inserts


INSERT INTO MS_PROD.config.dbDocument
(
[clID]	,[fileID] 	,[assocID] 	,[docbrID]	,[docType] 	,[docbaseprecID] 	,[docChecksum] 	,[docDesc] 	,[docStyleDesc] 	,[docWallet]
,[docFileName]	,[docLocation]	,[docdirID] 	,[docPassword] 	,[docDirection] 	,[docArchived] 	,[docArchiveLocation] 	,[docArchiveDirID]
,[docAppID],[docPasswordHint] ,[docExtension],[docAuthored] ,[Createdby] ,[Created] ,[UpdatedBy],[Updated] ,[docParent],[docDeleted],[docRetain] 
,[docFlags] ,[phID],[docIDOld] ,[docAuthoredBy] ,[docCheckedOut] ,[docCheckedOutBy] ,[docCheckedOutlocation] ,[docCurrentVersion] ,[docLastAccessed] 
,[docLastAccessedBy] ,[docLastEdited] ,[docLastEditedBy] ,[docIDExt] ,[SecurityOptions],docprecID )

SELECT 
	@clID AS [clID] 
	,@FileID AS [fileID] 
	,@assocID [assocID] 
	,1 AS [docbrID]
	,@docType AS [docType] 
	,NULL AS [docbaseprecID] 
	,NULL AS [docChecksum] 
	,LEFT(@DocumentTitle,150) AS [docDesc] 
	,@AlternateDocDescription [docStyleDesc] 
	,@DocWalletInsert AS [docWallet]
	,'Awaiting' [docFileName] 
	,0 AS [docLocation]
	,@dirid AS [docdirID] 
	,NULL AS [docPassword] 
	,1 AS [docDirection] 
	,0 AS [docArchived] 
	,0 AS [docArchiveLocation] 
	,NULL AS [docArchiveDirID]
	,@docAppID AS [docAppID]
	,NULL AS [docPasswordHint] 
	,RTRIM(@DocumentExtension) AS [docExtension]
	,@CreationDate AS [docAuthored] 
	,-200 AS [Createdby] 
	,@CreationDate AS [Created] 
	,-200 AS [UpdatedBy]
	,@ModifiedDate AS [Updated] 
	,NULL AS [docParent]
	,0 AS [docDeleted]
	,NULL AS [docRetain] 
	,0 AS [docFlags] 
	,NULL AS [phID]
	,NULL AS [docIDOld] 
	,-200 AS [docAuthoredBy] 
	,NULL AS [docCheckedOut] 
	,NULL AS [docCheckedOutBy] 
	,NULL AS [docCheckedOutlocation] 
	,NULL AS [docCurrentVersion] 
	,NULL AS [docLastAccessed] 
	,NULL AS [docLastAccessedBy] 
	,NULL AS [docLastEdited] 
	,NULL AS [docLastEditedBy] 
	,NULL AS [docIDExt] 
	,CASE WHEN @ShowOnExtranet='Yes' THEN 2 ELSE 0 END  AS [SecurityOptions] 
	,@PrecID AS PrecID
	
	
	--DECLARE @MSDocID BIGINT 	

--Charge the outputID		
SET @MSDocID = @@IDENTITY --Get the new ID from the dbDocumentID Table.

UPDATE MS_PROD.config.dbDocument
SET [docFileName]=(SELECT CAST(@clID AS VARCHAR(50)) +'\' + CAST(@FileID AS VARCHAR(50)) +'\In\' + CAST(@MSDocID AS VARCHAR(50)) + '.1.'+ @DocumentExtension)
WHERE fileID=@FileID AND docID=@MSDocID


INSERT INTO MS_PROD.dbo.dbDocumentVersion
([docID],[verNumber],[verParent],[verDepth]
,[verLabel],[verComments],[verToken]
,[verAuthoredBy],[verAuthored],[CreatedBy],[Created])

SELECT @MSDocID AS [docID]
           ,1 AS [verNumber]
           ,NULL[verParent]
           ,0 AS [verDepth]
           ,1 AS [verLabel]
           ,NULL AS [verComments]
           ,(SELECT CAST(@clID AS VARCHAR(50)) +'\' + CAST(@FileID AS VARCHAR(50)) +'\In\' + CAST(@MSDocID AS VARCHAR(50)) + '.1.'+ @DocumentExtension) AS [verToken]
           ,-200 AS [verAuthoredBy]
           ,@CreationDate AS [verAuthored]
           ,-200 AS [CreatedBy]
           ,@CreationDate AS [Created]


UPDATE a
SET DocCurrentVersion=b.verID
FROM MS_PROD.config.dbDocument AS a
INNER JOIN MS_PROD.dbo.dbDocumentVersion AS b
 ON a.docID=b.docID AND b.[verNumber]=1
 WHERE a.docID=@MSDocID

SET @MSDocFileName=(SELECT CAST(@clID AS VARCHAR(50)) +'\' + CAST(@FileID AS VARCHAR(50)) +'\In\' + CAST(@MSDocID AS VARCHAR(50)) + '.1.'+ @DocumentExtension)
SET @MSDocumentLocation=(SELECT dirPath FROM  MS_PROD.dbo.dbDirectory WHERE dirCode = 'OMDOCUMENTS') + '\' + @MSDocFileName

SET	@CLIENTID =(SELECT dbClient.clID FROM MS_PROD.config.dbClient INNER JOIN MS_PROD.config.dbFile ON dbFile.clID = dbClient.clID WHERE fileID=@FileID)
SET	@CLNAME =(SELECT clName FROM MS_PROD.config.dbClient INNER JOIN MS_PROD.config.dbFile ON dbFile.clID = dbClient.clID WHERE fileID=@FileID) 
SET	@CLNO  =(SELECT clNo FROM MS_PROD.config.dbClient INNER JOIN MS_PROD.config.dbFile ON dbFile.clID = dbClient.clID WHERE fileID=@FileID) 
SET	@FILEDESC =(SELECT fileDesc FROM MS_PROD.config.dbClient INNER JOIN MS_PROD.config.dbFile ON dbFile.clID = dbClient.clID WHERE fileID=@FileID) 
SET	@FILENO =(SELECT fileNo FROM MS_PROD.config.dbClient INNER JOIN MS_PROD.config.dbFile ON dbFile.clID = dbClient.clID WHERE fileID=@FileID) 

IF LOWER(@DocumentExtension) = 'msg'
BEGIN

INSERT INTO MS_PROD.dbo.dbdocumentemail
([docID],[docSent],[DocReceived],[docTo]
,[docFrom],docConversationTopic)

SELECT @MSDocID AS [docID]
           ,@DocSent AS [docSent]
           ,@DocReceived AS [DocReceived]
           ,@DocTo AS [docTo]
           ,@DocFrom AS [docFrom]
		   ,@DocSubject AS docConversationTopic
END



IF @@TRANCOUNT > 0
		BEGIN 
			COMMIT TRANSACTION 
			
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
GRANT EXECUTE ON  [dbo].[RunThirdPartyDocImportV2] TO [SBC\SQL - XpertRule access SVR-LIV-MSSQ-01]
GO
