SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: 28.09.16
-- Description:	Validates Tasks in regards to all data
-- =============================================
CREATE PROCEDURE [dbo].[RunTaskValidation]

AS
BEGIN


UPDATE Tasks
SET [MSfeeusrID]=usrlookup.usrID
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
LEFT OUTER JOIN (SELECT  usrID,usrAlias FROM MSUsers) AS usrlookup
  ON Tasks.feeusrID=usrlookup.usrAlias


UPDATE Tasks
SET [MStskCreatedBy]=usrlookup.usrID
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
LEFT OUTER JOIN (SELECT  usrID,usrAlias FROM MSUsers) AS usrlookup
  ON Tasks.tskCreatedBy=usrlookup.usrAlias
  
UPDATE Tasks
SET [MStskCompletedBy]=usrlookup.usrID
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
INNER JOIN  (SELECT  usrID,usrAlias FROM MSUsers) AS usrlookup
  ON Tasks.tskCompletedBy=usrlookup.usrAlias AND tskCompleted IS NOT NULL

  
     
 --SELECT * FROM [MattersphereStaging].[dbo].[TaskStage] TaskStage
 --INNER JOIN MS_Prod.dbo.dbTasks  AS dbtasks 
 -- ON TaskStage.fileID=dbtasks.fileID 
 -- AND TaskStage.ExttskID=dbtasks.
 


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



UPDATE Tasks
SET StatusID=6
,error=11
,errormsg=ISNULL(errormsg,'') + 'Completed By Doesnt Exist,'
FROM [MattersphereStaging].[dbo].[TaskStage] Tasks
WHERE (MStskCompletedBy IS NULL AND tskCompletedBy IS NOT NULL)

UPDATE [MattersphereStaging].[dbo].[TaskStage] 
SET StatusID=7
WHERE StatusID= 0


END
GO
