SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROC [dbo].[CUR_RunMSMatterZeus]

AS
	 DECLARE @ID INT, 
	 @clNo NVARCHAR (12),
	 @fileNo NVARCHAR (20) ,
	 @extFileID BIGINT,
	 @fileDesc NVARCHAR (255) ,
	 @fileResponsibleID nvarchar (12),
	 @filePrincipleID nvarchar (12),
	 @BusinessLine nvarchar (15) ,
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
	 @Importerror INT, 
	 @Importerrormsg VARCHAR(2000),
	 @MatterNo AS INT

DECLARE @RowID AS INT
SET @RowID = 0


WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM   dbo.FileDetailsStage
                 WHERE  [ID] > @RowID 
                 AND StatusID IN (0,1)
                 ORDER BY [ID]
                 )
BEGIN


		SET @Importerror= 0 
		SET @Importerrormsg = ''
		SET @MatterNo=NULL

		
			
	SELECT TOP 1
     @ID=ID, 
	 @clNo=clNo,
	 @fileNo=fileNo  ,
	 @extFileID=extFileID ,
	 @fileDesc=fileDesc,
	 @fileResponsibleID=fileResponsibleID ,
	 @filePrincipleID=filePrincipleID ,
	 @BusinessLine=BusinessLine,
	 @fileDept=fileDept ,
	 @fileType=fileType ,
	 @fileFundCode=fileFundCode ,
	 @fileCurISOCode=fileCurISOCode,
	 @fileStatus=fileStatus ,
	 @fileCreated=fileCreated,
	 @fileUpdated=fileUpdated,
	 @fileClosed=fileClosed,
	 @fileSource=fileSource,
	 @fileSection=fileSection,
	 @fileSectionGroup=fileSectionGroup,
	 @MattIndex=MattIndex,
	 @Office=Office,
	 @brID=brID ,
	 @Partner=Partner ,
	 @InsertDate=InsertDate ,
	 @Imported=Imported ,
	 @StatusID=StatusID ,
	 @FEDCode=FEDCode ,
	 @Importerror=error, 
	 @Importerrormsg=errormsg
		
	FROM  dbo.FileDetailsStage
    WHERE  ID > @RowID
    AND StatusID  IN(0,1)
    ORDER BY fileNo DESC, ID
                
    PRINT 'Run Matters to Mattersphere: ' + CONVERT(VARCHAR(20),@ID)
        
    EXEC  [dbo].[RunMSMatterZeus]		
	 @ID=@ID, 
	 @clNo=@clNo,
	 @fileNo=@fileNo,
	 @extFileID=@extFileID,
	 @fileDesc=@fileDesc,
	 @fileResponsibleID=@fileResponsibleID ,
	 @filePrincipleID=@filePrincipleID ,
	 @BusinessLine=@BusinessLine ,
	 @fileDept=@fileDept ,
	 @fileType=@fileType ,
	 @fileFundCode=@fileFundCode ,
	 @fileCurISOCode=@fileCurISOCode,
	 @fileStatus=@fileStatus ,
	 @fileCreated=@fileCreated,
	 @fileUpdated=@fileUpdated,
	 @fileClosed=@fileClosed,
	 @fileSource=@fileSource,
	 @fileSection=@fileSection,
	 @fileSectionGroup=@fileSectionGroup,
	 @MattIndex=@MattIndex,
	 @Office=@Office,
	 @brID=@brID ,
	 @Partner=@Partner ,
	 @InsertDate=@InsertDate ,
	 @Imported=@Imported ,
	 @StatusID=@StatusID ,
	 @FEDCode=@FEDCode ,
	 @Importerror=@Importerror OUTPUT, 
	 @Importerrormsg=@Importerrormsg OUTPUT,
	 @MatterNo=@MatterNo OUTPUT
       
     UPDATE    dbo.FileDetailsStage
     SET error = ISNULL(@Importerror,0),
	 errormsg = @Importerrormsg,
	 [NewMatterNumber] = @MatterNo,
	 StatusID = CASE 
					WHEN ISNULL(@Importerror,0) = 0  AND @StatusID=0 THEN 2 -- Success New Matter Insert
					WHEN ISNULL(@Importerror,0) = 0  AND @StatusID=1 THEN 3 -- Sucess Update Matter
					WHEN ISNULL(@Importerror,0) <> 0  AND @StatusID=0 THEN 4 -- Failed New Matter Insert
					WHEN ISNULL(@Importerror,0) <> 0  AND @StatusID=1 THEN 5 -- Failed Update Matter
					ELSE 9
					
				END,
	 Imported=CASE WHEN ISNULL(@Importerror,0) = 0 THEN GETDATE() ELSE NULL END 
     WHERE ID=@ID       
PRINT  @Importerror

--Insert into success table and delete from stage table
IF ISNULL(@Importerror,0) = 0  
BEGIN

INSERT INTO dbo.ImportSuccess
        ( ID , clNo , fileNo , extFileID ,fileDesc ,fileResponsibleID ,filePrincipleID ,fileDept ,
          fileType ,fileFundCode ,fileCurISOCode ,fileStatus ,fileCreated ,fileUpdated ,fileClosed ,
          fileSource ,fileSection ,fileSectionGroup ,MattIndex ,Office ,brID ,[Partner] ,InsertDate ,
          Imported ,StatusID , FEDCode, error ,errormsg ,NewMatterNumber ,BusinessLine
        )
SELECT 
		  ID , clNo , fileNo , extFileID ,fileDesc ,fileResponsibleID ,filePrincipleID ,fileDept ,
          fileType ,fileFundCode ,fileCurISOCode ,fileStatus ,fileCreated ,fileUpdated ,fileClosed ,
          fileSource ,fileSection ,fileSectionGroup ,MattIndex ,Office ,brID ,[Partner] ,InsertDate ,
          Imported ,StatusID , FEDCode ,error ,errormsg ,NewMatterNumber ,BusinessLine
FROM dbo.FileDetailsStage WHERE ID = @ID

DELETE FROM dbo.FileDetailsStage WHERE ID = @ID
END

--Insert into failure table and leave in stage table so that the value can be fixed and the process call it again
IF ISNULL(@Importerror,0) <> 0  
BEGIN

INSERT INTO dbo.ImportFailure
        ( ID , clNo , fileNo , extFileID ,fileDesc ,fileResponsibleID ,filePrincipleID ,fileDept ,
          fileType ,fileFundCode ,fileCurISOCode ,fileStatus ,fileCreated ,fileUpdated ,fileClosed ,
          fileSource ,fileSection ,fileSectionGroup ,MattIndex ,Office ,brID ,[Partner] ,InsertDate ,
          Imported ,StatusID , FEDCode, error ,errormsg ,NewMatterNumber ,BusinessLine
        )
SELECT 
		  ID , clNo , fileNo , extFileID ,fileDesc ,fileResponsibleID ,filePrincipleID ,fileDept ,
          fileType ,fileFundCode ,fileCurISOCode ,fileStatus ,fileCreated ,fileUpdated ,fileClosed ,
          fileSource ,fileSection ,fileSectionGroup ,MattIndex ,Office ,brID ,[Partner] ,InsertDate ,
          Imported ,StatusID , FEDCode ,error ,errormsg ,NewMatterNumber ,BusinessLine
FROM dbo.FileDetailsStage WHERE ID = @ID

END






END



SET ANSI_NULLS ON
SET QUOTED_IDENTIFIER ON










GO
GRANT EXECUTE ON  [dbo].[CUR_RunMSMatterZeus] TO [lnksvrdatareader_sql02]
GO
GRANT EXECUTE ON  [dbo].[CUR_RunMSMatterZeus] TO [ZurichImportServiceSQL]
GO
