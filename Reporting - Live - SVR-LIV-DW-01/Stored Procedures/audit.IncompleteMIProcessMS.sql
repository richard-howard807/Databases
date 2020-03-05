SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[IncompleteMIProcessMS]--'Family','5122'
(
@Div AS NVARCHAR(MAX),
@Dep AS NVARCHAR(MAX), 
@Team1 AS NVARCHAR(MAX)


)
AS
BEGIN
SELECT ListValue  INTO #Div  FROM Reporting.dbo.[udt_TallySplit]('|', @Div)
SELECT ListValue  INTO #Dep  FROM Reporting.dbo.[udt_TallySplit]('|', @Dep)
SELECT ListValue  INTO #Team1 FROM Reporting.dbo.[udt_TallySplit]('|', @Team1)





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
 
 	INNER JOIN #Div AS Div ON Div.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel2hist COLLATE DATABASE_DEFAULT	
	INNER JOIN #Dep AS Dep ON Dep.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT	
INNER JOIN #Team1 AS Team1 ON Team1.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
		

WHERE tskDesc='ADM: Commence MI Process'
AND tskComplete=0
AND fileStatus='LIVE'
AND clNo <>'30645'
AND hierarchylevel4hist IS NOT NULL
AND activeud=1
AND fed_code <> 'Unknown'
AND display_name NOT LIKE '%Budget%'
--AND hierarchylevel4hist=@Team
AND AlreadyCompleted.fileID IS NULL


END 

GO
