SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[CUR_RunThirdPartyDocs]
AS

	 DECLARE 
	 @ID INT,
	 @FileID bigint,
	 @DocumentTitle nvarchar(255),
     @AlternateDocDescription nvarchar(255),
	 @DocumentExtension nvarchar(15),
	 @DocWallet varchar(19),
	 @CreationDate datetime,
	 @ModifiedDate datetime,
	 @ShowOnExtranet NVARCHAR(3),
	 @MSassocID BIGINT,
	 @MSDocFileName nvarchar(255),
	 @MSDocumentLocation nvarchar(255),
	 @MSDocID bigint,
	 @Importerror int,
     @Importerrormsg varchar(2000)

	DECLARE @RowID AS INT
	SET @RowID = 0

	WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM   [dbo].[ThirdPartyDocumentStage]
                 WHERE  [ID] > @RowID 
                 AND Processed=0
                 ORDER BY [ID]
                 )

	BEGIN

		SET @Importerror= 0 
		SET @Importerrormsg = ''
		SET @MSDocFileName =''
		SET @MSDocumentLocation ='' 
		SET @MSDocID = NULL
		SET @FileID = NULL
		SET @DocumentTitle= NULL
		SET @AlternateDocDescription = NULL
		SET @DocumentExtension= NULL
		SET @DocWallet  = NULL
		SET @CreationDate = NULL
		SET @ModifiedDate = NULL
		SET @ShowOnExtranet = NULL
		SET @MSassocID = NULL
	  

	SELECT TOP 1
	 @ID = ID,
	 @FileID =  FileID,
	 @DocumentTitle = DocumentTitle, 
     @AlternateDocDescription =  AlternateDocDescription, 
	 @DocumentExtension = DocumentExtension,
	 @DocWallet = DocWallet,
	 @CreationDate = CreationDate, 
	 @ModifiedDate = ModifiedDate, 
	 @ShowOnExtranet = ShowOnExtranet,
	 @MSassocID = MSassocID,
	 @Importerror = error, 
     @Importerrormsg = errormsg 
	 

	FROM [dbo].[ThirdPartyDocumentStage]
	WHERE ID > @RowID
	AND Processed=0
	ORDER BY ID

	PRINT 'Run Documents to Mattersphere: ' + CONVERT(VARCHAR(20),@ID)
 
	EXEC [dbo].[RunThirdPartyDocImport] 
	 @FileID
	,@DocumentTitle
	,@AlternateDocDescription
	,@DocumentExtension
	,@DocWallet
	,@CreationDate
	,@ModifiedDate
	,@ShowOnExtranet
	,@MSassocID
	,@MSDocFileName OUTPUT
	,@MSDocumentLocation OUTPUT
	,@MSDocID OUTPUT
	,@Importerror OUTPUT
	,@Importerrormsg OUTPUT
	
DECLARE @Processed AS INT
SET @Processed=(CASE 
					WHEN ISNULL(@Importerror,0) = 0 THEN 2 -- Success
					ELSE 1  -- Failed
				END)
				
				PRINT @Processed

	UPDATE [dbo].[ThirdPartyDocumentStage]
	SET error = ISNULL(@Importerror,0),
		errormsg = @Importerrormsg,
	    DocFileName = @MSDocFileName,
		DocumentLocation = @MSDocumentLocation,
	    DocID = @MSDocID,
	    Processed = (CASE 
					WHEN ISNULL(@Importerror,0) = 0 THEN 2 -- Success
					ELSE 1  -- Failed
				END)
		
		WHERE ID=@ID
END 

	
GO
