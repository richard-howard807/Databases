SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[CDDProcedure]--'Family','5122'
(
@Team AS NVARCHAR(MAX)
,@FeeEarner AS NVARCHAR(10)
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
,[Date Last Ran]
,DATEDIFF(DAY,tskDue,getdate()) AS DaysIncomplete 
,DATEDIFF(DAY,tskDue,[Date Last Ran])*-1 AS DaysSinceLastRan 
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
LEFT OUTER JOIN MS_PROD.dbo.dbUser ON filePrincipleID=dbUser.usrID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON dbFile.fileID=udExtFile.fileID
LEFT OUTER JOIN (SELECT * FROM red_dw.dbo.dim_fed_hierarchy_history WHERE dss_current_flag='Y') AS Structure
 ON dbUser.usrInits=fed_code collate database_default
LEFT OUTER JOIN (SELECT dbTasks.fileID,tskDue,[Date Last Ran] FROM MS_PROD.dbo.dbTasks
LEFT OUTER JOIN (SELECT a.fileID as fileID,MAX(evWhen) AS [Date Last Ran]
FROM MS_PROD.dbo.dbFileEvents  AS a
WHERE  evDesc='CDD form completed'
GROUP BY a.fileID

) AS LastRan
  ON dbTasks.fileID=LastRan.fileID
WHERE tskDesc IN ('Complete CDD procedure','Complete CDD form procedure')
) AS CDD  ON dbFile.fileID=CDD.fileID
 WHERE fileStatus='LIVE'
 AND (hierarchylevel3hist='Real Estate' OR hierarchylevel4hist='Family' OR hierarchylevel4hist='Glasgow')
 AND hierarchylevel4hist=@Team
 AND fed_code=@FeeEarner
 AND clNo <>'30645'
END
GO
