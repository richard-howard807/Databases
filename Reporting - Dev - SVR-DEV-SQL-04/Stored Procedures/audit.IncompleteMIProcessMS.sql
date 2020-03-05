SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[IncompleteMIProcessMS]--'Family','5122'
(
@Team AS NVARCHAR(MAX)

)
AS
BEGIN
SELECT 
clNo +'.' + fileNo AS [MS Ref]
,clName AS [Client Name]
,FEDCode AS [Fed Ref]
,fileDesc AS [Matter Description]
,dbFile.Created AS [Date File Opened]
,dbUser.usrFullName
,dbUser.usrInits
,dbFile.fileID
,tskDue
,tskComplete
,tskDesc
,DATEDIFF(DAY,tskDue,getdate()) AS DaysIncomplete 
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,AlreadyCompleted.fileID
FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
INNER JOIN  MS_Prod.dbo.dbTasks
 ON dbFile.fileID=dbTasks.fileID
LEFT OUTER JOIN MS_PROD.dbo.dbUser ON filePrincipleID=dbUser.usrID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON dbFile.fileID=udExtFile.fileID
LEFT OUTER JOIN (SELECT * FROM red_dw.dbo.dim_fed_hierarchy_history WHERE dss_current_flag='Y') AS Structure
 ON dbUser.usrInits=fed_code collate database_default
LEFT OUTER JOIN 
(
SELECT dbFile.fileID 
FROM MS_Prod.config.dbFile
INNER JOIN  MS_Prod.dbo.dbTasks
 ON dbFile.fileID=dbTasks.fileID
WHERE tskDesc='ADM: Commence MI Process'
AND tskComplete=1
) AS AlreadyCompleted
 ON dbFile.fileID=AlreadyCompleted.fileID
 
WHERE tskDesc='ADM: Commence MI Process'
AND tskComplete=0
AND fileStatus='LIVE'
AND clNo <>'30645'
AND hierarchylevel4hist IS NOT NULL
AND activeud=1
AND fed_code <> 'Unknown'
AND display_name NOT LIKE '%Budget%'
AND hierarchylevel4hist=@Team
AND AlreadyCompleted.fileID IS NULL


END 

GO
