SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*

LD 09/11/2017 Created this view to enable reports to report on keydates over both FED and Mattersphere

*/

CREATE VIEW [dbo].[tasks_union] 
AS
-- Mattersphere key dates

  SELECT CASE WHEN ISNUMERIC(dbClient.clNo) = 1  THEN  RIGHT('00000000' + CAST(dbClient.clNo AS VARCHAR),8) ELSE clNo END  [client_code]
		,RIGHT('00000000' + CAST(dbFile.fileNo AS VARCHAR),8) [matter_number]
		,clNo master_client_code
		,fileNo  master_matter_number	
		,dbTasks.tskID [task_id]
		,dbTasks.tskDue [task_due_date]
		,dbKeyDates.kdType [task_code]
		,dbUser.usrFullName [task_owner]
		,dbUser.usrAlias AS [tast_owner_code]
		,dbTasks.tskDesc [task_desc]	

  FROM [MS_Prod].[dbo].[dbTasks] dbTasks
  INNER JOIN [MS_Prod].config.dbFile dbFile ON dbFile.fileID = dbTasks.fileID
  INNER JOIN [MS_Prod].dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
  INNER JOIN [MS_Prod].config.dbClient dbClient ON dbClient.clID = dbFile.clID
  INNER JOIN [MS_Prod].dbo.dbKeyDates dbKeyDates ON dbTasks.tskRelatedID = dbKeyDates.kdRelatedID
  LEFT JOIN [MS_Prod].dbo.dbUser dbUser ON dbUser.usrID = dbTasks.feeusrID
  LEFT JOIN [MS_PROD].dbo.dbTaskBridge dbTasksBridge ON dbTasksBridge.tskID = dbTasks.tskID

  WHERE tskType = 'KEYDATE' 
  AND tskRelatedID IS NOT NULL -- exclude the manual tasks
  AND udExtFile.bitMSOnlyMM = 1 -- files are on MS only
  AND dbTasksBridge.tskID IS NULL -- exclude converted tasks
  AND dbFile.fileClosed IS NULL -- only open file tasks
  AND dbTasks.tskActive = 1 -- exclude inactive tasks

UNION 

  -- Converted activities
SELECT  CASE WHEN ISNUMERIC(dbClient.clNo) = 1  THEN  RIGHT('00000000' + CAST(dbClient.clNo AS VARCHAR),8) ELSE clNo END  [client_code]
		,RIGHT('00000000' + CAST(dbFile.fileNo AS VARCHAR),8) [matter_number]
		,clNo master_client_code
		,fileNo  master_matter_number	
		,dbTasks.tskID [task_id]
		,dbTasks.tskDue [task_due_date]
		,ISNULL(a.activity_code,'KEYDATE') [task_code]
		,dbUser.usrFullName [task_owner]
		,dbUser.usrAlias AS [tast_owner_code]
		,dbTasks.tskDesc [task_desc]	
FROM MS_PROD.dbo.dbTasks dbTasks
INNER JOIN MS_PROD.config.dbFile dbFile ON dbFile.fileID = dbTasks.fileID
INNER JOIN MS_PROD.dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
INNER JOIN MS_PROD.config.dbClient dbClient ON dbFile.clID = dbClient.clID
INNER JOIN MS_PROD.dbo.dbTaskBridge dbTaskBridge ON dbTaskBridge.tskID = dbTasks.tskID -- links to list of converted tasks
LEFT JOIN [MS_Prod].dbo.dbUser dbUser ON dbUser.usrID = dbTasks.feeusrID
LEFT JOIN axxia01.dbo.casact a ON dbTaskBridge.OriginatingSystemID = a.case_id AND dbTaskBridge.OriginatingSequenceID = a.activity_seq

WHERE dbTasks.tskManual = 1-- all converted tasks are manual tasks
AND  tskType = 'KEYDATE' 
AND dbTasks.tskCompleted IS NULL 
AND dbTasks.tskComplete = 0
--AND clno IN ('787558','787559','787560','787561')
AND dbFile.fileClosed IS NULL -- open files only
AND dbTasks.tskActive = 1 -- exclude inactive tasks



UNION

-- Fed activities


SELECT 
		header.client_code COLLATE Latin1_General_CI_AS
		,header.matter_number COLLATE Latin1_General_CI_AS
		,header.master_client_code COLLATE Latin1_General_CI_AS
		,header.master_matter_number COLLATE Latin1_General_CI_AS
		,-1 [task_id]
		,casact.plan_date [task_due_date]
		,casact.activity_code COLLATE Latin1_General_CI_AS [task_code] 
		,task_owner.name COLLATE Latin1_General_CI_AS [task_owner] 
		,initiating_entity COLLATE Latin1_General_CI_AS [tast_owner_code] 
		,casact.activity_desc COLLATE Latin1_General_CI_AS [task_desc] 

FROM axxia01.dbo.cashdr cashdr
INNER JOIN axxia01.dbo.casact casact  ON casact.case_id = cashdr.case_id
LEFT JOIN red_dw.dbo.dim_matter_header_current header ON header.case_id = cashdr.case_id
INNER JOIN red_dw.dbo.dim_fed_hierarchy_current task_owner ON casact.initiating_entity = task_owner.fed_code
WHERE  casact.tran_done IS NULL -- not actioned
AND casact.p_a_marker = 'p' -- planned activities
AND cashdr.date_closed IS NULL  -- exclude closed files (which will exclude those going over to mattersphere)
AND casact.activity_desc NOT LIKE '%TM%' -- exclude TM reminders
AND cashdr.matter <> 'ML'
AND cashdr.client NOT IN ('00030645','95000C','00453737')















GO
