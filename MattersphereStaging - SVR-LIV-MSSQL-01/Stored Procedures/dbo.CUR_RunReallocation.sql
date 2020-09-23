SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[CUR_RunReallocation]

AS
	 DECLARE @ID INT, 
	 @clNo NVARCHAR (12),
	 @fileNo NVARCHAR (20) ,
	 @fileResponsibleID nvarchar (12),
	 @filePrincipleID nvarchar (12),
	 @Partner BIGINT,
	 @StatusID TINYINT,
	 @Importerror INT, 
	 @Importerrormsg VARCHAR(2000),
	 @FedClient AS CHAR(8),
	 @FedMatter AS CHAR(8),
	 @PreviousFE nvarchar (12),
	 @NewAssistant nvarchar (12) 
	 

DECLARE @RowID AS INT
SET @RowID = 0


WHILE	EXISTS ( 
				 SELECT TOP 1
                        1
                 FROM   dbo.MatterReallocation
                 WHERE  [ID] > @RowID 
                 AND StatusID =0
                 ORDER BY [ID]
                 )
BEGIN


		SET @Importerror= 0 
		SET @Importerrormsg = ''


		
			
	SELECT TOP 1
	 @ID=[ID]
     ,@clNo=[clNo]
     ,@fileNo=[fileNo]
     ,@FedClient=[FedClient]
     ,@FEDMatter=[FEDMatter]
     ,@PreviousFE=[PreviousFE]
     ,@filePrincipleID=[filePrincipleID]
     ,@NewAssistant=[NewAssistant]
     ,@fileResponsibleID=[fileResponsibleID]
     ,@Partner=[Partner]
     ,@StatusID=[StatusID]
     ,@Importerror=[error]
     ,@Importerrormsg=[errormsg]
     FROM [dbo].[MatterReallocation]
      WHERE  ID > @RowID
    AND StatusID =0
    ORDER BY ID
  
                
    PRINT 'Run Matters to Mattersphere: ' + CONVERT(VARCHAR(20),@ID)
        
    EXEC  [dbo].[RunReallocation]		
	    @ID
  ,@clNo=@clNo
  ,@fileNo=@fileNo
  ,@fileResponsibleID=@fileResponsibleID
  ,@filePrincipleID=@filePrincipleID
  ,@Partner=@Partner
  ,@Importerror=@Importerror OUTPUT
  ,@Importerrormsg=@Importerrormsg OUTPUT

       
     UPDATE    dbo.MatterReallocation
     SET error = ISNULL(@Importerror,0),
	 errormsg = @Importerrormsg,
	 StatusID = CASE 
					WHEN ISNULL(@Importerror,0) = 0  AND @StatusID=0 THEN 2 -- Success Update
					WHEN ISNULL(@Importerror,0) <> 0  AND @StatusID=0 THEN 1 -- Failed Update
					ELSE 9
					
				END
     WHERE ID=@ID       


PRINT @FedClient 
PRINT @FedMatter 
PRINT @PreviousFE
PRINT @fileResponsibleID
PRINT @NewAssistant 
PRINT @filePrincipleID



IF ISNULL(@Importerror,0) = 0  
BEGIN

INSERT INTO dbo.ReallocationSuccess
(
[ID] ,[clNo],[fileNo],[FedClient],[FEDMatter]
,[PreviousFE],[filePrincipleID],[NewAssistant]
,[fileResponsibleID],[Partner],[StatusID],[InsertDate] ,[error],[errormsg]
)
SELECT [ID] ,[clNo],[fileNo],[FedClient],[FEDMatter]
,[PreviousFE],[filePrincipleID],[NewAssistant]
,[fileResponsibleID],[Partner],[StatusID],[InsertDate] ,[error],[errormsg]
FROM dbo.MatterReallocation
WHERE ID = @ID

DELETE FROM dbo.MatterReallocation WHERE ID = @ID
END

IF ISNULL(@Importerror,0) <> 0  
BEGIN

INSERT INTO dbo.ReallocationFailure
(
[ID] ,[clNo],[fileNo],[FedClient],[FEDMatter]
,[PreviousFE],[filePrincipleID],[NewAssistant]
,[fileResponsibleID],[Partner],[StatusID],[InsertDate] ,[error],[errormsg]
)
SELECT [ID] ,[clNo],[fileNo],[FedClient],[FEDMatter]
,[PreviousFE],[filePrincipleID],[NewAssistant]
,[fileResponsibleID],[Partner],[StatusID],[InsertDate] ,[error],[errormsg]
FROM dbo.MatterReallocation
WHERE ID = @ID

END 


END


set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON









GO
