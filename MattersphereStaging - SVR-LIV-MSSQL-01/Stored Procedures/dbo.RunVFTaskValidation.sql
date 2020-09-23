SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RunVFTaskValidation]

AS
BEGIN


UPDATE Tasks
SET [MSfeeusrID]=filePrincipleID
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
INNER JOIN MS_PROD.config.dbFile
 ON dbFile.fileID = Tasks.fileID


UPDATE Tasks
SET [MStskCreatedBy]=filePrincipleID
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
INNER JOIN MS_PROD.config.dbFile
 ON dbFile.fileID = Tasks.fileID
 


UPDATE Tasks
SET StatusID=6
,error=11
,errormsg=ISNULL(errormsg,'') + 'User Doesnt Exist,'
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
WHERE  [MSfeeusrID] IS NULL 


UPDATE Tasks
SET StatusID=6
,error=11
,errormsg=ISNULL(errormsg,'') + 'Created By Doesnt Exist,'
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
WHERE  [MStskCreatedBy] IS NULL




UPDATE [MattersphereStaging].[dbo].[TaskStage] 
SET StatusID=7
WHERE StatusID= 0


UPDATE [MattersphereStaging].[dbo].[TaskStage] 
SET tskType='GENERAL'
WHERE StatusID= 7



END
GO
