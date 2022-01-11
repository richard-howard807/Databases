SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
	Created by: Max Taylor
	Created Date: 09/03/2021
	Report: Business Services/Business Change/Physical Item Request Report
	Ticket: 90991

*/



CREATE PROCEDURE [dbo].[PhysicalItemRequestReport] 
(
   @Start AS DATETIME,
    @End AS DATETIME,
	@Status AS INT
)

AS
BEGIN
 
 
 IF @Status = 0

BEGIN
 
 -- Test 
 --DECLARE @Start AS DATE = '2021-12-30'--GETDATE() - 100
 --      , @End AS DATE =  '2022-01-06'  --  GETDATE()
	--   ,@Status AS int = 0
SELECT * FROM 

(

 SELECT DISTINCT
		Final.job_id,
        Final.[Requesting User],
        Final.[Date Requested],
        Final.scan_datetime,
        Final.Comment,
        Final.[Processing User],
        Final.[Date Processed],
        Final.Result,
        Final.[Days Old],
        Final.document_link,
        Final.SourceSystem,
        Final.OriginalStatus
		,RN = ROW_NUMBER() OVER (PARTITION BY Final.job_id ORDER BY CASE WHEN Final.Result = 'COMPLETED' THEN 1 ELSE 0 END DESC)

 FROM 

 (
 
 SELECT 

  x.job_id,
  x.[Requesting User],
  x.[Date Requested],
  x.Comment,
  x.[Processing User],
  x.[Date Processed],
  CASE WHEN x.Result ='No Original' THEN 'NO ORIGINAL' ELSE x.Result END AS Result,
  x.[Days Old],
  x.scan_datetime,
  x.document_link,
  'FlowMatrix' AS SourceSystem
  ,x.OriginalStatus AS [OriginalStatus]
 

  FROM
 ( 

 SELECT DISTINCT 
  [job_id] =  T1.[job_id],
  [Requesting User] = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT  +' (' +T1.[username] +')'  , --T1.[username] 
  [Date Requested] = T1.[event_time],
  [Comment] = T1.[comment],
  [Processing User] = ProUser.name COLLATE DATABASE_DEFAULT  + ' (' + T2.[username] + ')' , -- T2.[username] 
  [Date Processed] =  T2.[event_time] , 
  [Result]= COALESCE(NULLIF(T2.[filter2],''), 'COMPLETED') ,
  [Days Old] = CASE WHEN COALESCE(NULLIF(T2.[filter2],''), 'COMPLETED') <> 'COMPLETED' THEN DATEDIFF( day , CAST(T1.[event_time] AS DATE)  , GETDATE() ) ELSE NULL  END,
  [scan_datetime] = T1.scan_datetime,
  [document_link] = '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(j.guid, 2) 
		+ '\' + RIGHT(LEFT(j.guid, 4), 2) + '\' + RIGHT(LEFT(j.guid, 6), 2) 
		+ '\' + RIGHT(j.guid, LEN(j.guid)-6) + '\' + j.label + '.TIF' ,		
  [OriginalStatus] = COALESCE(NULLIF(T2.[filter2],''), 'done') 

	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)

LEFT JOIN [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]  T2 WITH(NOLOCK)
		ON  T1.job_id = T2.job_id 

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j
		ON j.job_id = T1.job_id

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 
	    ON windowsusername COLLATE DATABASE_DEFAULT = T1.[username] 
		AND dss_current_flag = 'Y' AND activeud = 1

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ProUser
	    ON ProUser.windowsusername COLLATE DATABASE_DEFAULT = T2.[username] 
		AND ProUser.dss_current_flag = 'Y' AND ProUser.activeud = 1

WHERE  T1.event = 'Physical Document' AND
(T2.event = 'IndexingDelete' OR T2.event = 'QADelete') 
AND T1.event_time > @Start 
AND T1.event_time < @End 

UNION 

SELECT DISTINCT 
  [job_id] = T3.[job_id],
  [Requesting User] = dim_fed_hierarchy_history.name, --  T3.[username]
  [Date Requested]= T3.[event_time] ,
  [Comment] = T3.[comment],
  [Processing User]=  '' ,
  [Date Processed] =  '' ,
  [Result] = 'PENDING' ,
  [Days Old] = DATEDIFF( day , CAST(T3.[event_time] AS DATE)  , GETDATE() ) ,
  [scan_datetime] = T3.scan_datetime,
  [document_link] = '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(j.guid, 2) 
		+ '\' + RIGHT(LEFT(j.guid, 4), 2) + '\' + RIGHT(LEFT(j.guid, 6), 2) 
		+ '\' + RIGHT(j.guid, LEN(j.guid)-6) + '\' + j.label + '.TIF' 	,	
  [OriginalStatus] ='PENDING'
FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T3 WITH(NOLOCK)

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j
		ON j.job_id = T3.job_id

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 
	    ON windowsusername COLLATE DATABASE_DEFAULT = T3.[username]
		AND dss_current_flag = 'Y' AND activeud = 1


WHERE T3.event = 'Physical Document' 
AND T3.job_id NOT IN (SELECT job_id FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]  WITH(NOLOCK)
WHERE (event = 'IndexingDelete' OR event = 'QADelete') 
AND event_time > @Start 
AND event_time < @End) 
AND T3.event_time > @Start 
AND T3.event_time < @End

) x 



 UNION 

SELECT 
	 [job_id] =  wo.WORKORDERID	, 
	 [Requesting User] = aau.FIRST_NAME, 
	 [Date Requested] = CAST(Dateadd(second, Cast(wo.CREATEDTIME AS BIGINT) / 1000,  '1-1-1970 00:00:00')  AS DATETIME) ,
	 [Comment] = wo.TITLE	,		 
	 [Processing User]=  aau2.FIRST_NAME,	
	 [Date Processed] = CASE WHEN wo.RESOLVEDTIME =0 THEN NULL ELSE CAST(Dateadd(second, Cast(wo.RESOLVEDTIME  AS BIGINT) / 1000, '1-1-1970 00:00:00')  AS DATETIME) END ,
     [Result] = CASE WHEN sta.STATUSDESCRIPTION = 'Request Pending' THEN 'PENDING'
        WHEN sta.STATUSDESCRIPTION = 'Request Resolved, waiting for approval by Requester' THEN 'COMPLETED'
		WHEN sta.STATUSDESCRIPTION = 'Request action in progress' THEN 'PENDING'
		WHEN sta.STATUSDESCRIPTION = 'Request Completed' THEN 'COMPLETE'
		ELSE 'ALL' END ,
    [Days Old] = CASE WHEN sta.STATUSDESCRIPTION NOT IN ( 'Request Completed' , 'Request Resolved, waiting for approval by Requester')
		THEN DATEDIFF( day , CAST( DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00'))AS DATE)  , GETDATE() ) 
			ELSE NULL END ,
	[scan_datetime] = NULL,
    [document_link] = CASE WHEN sta.STATUSNAME = 'Open' 
			THEN 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID=' + CAST(wo.WORKORDERID AS VARCHAR(20))
		  WHEN sta.STATUSNAME = 'In Progress' 
			THEN 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID='+ CAST(wo.WORKORDERID AS VARCHAR(20)) +'&&fromListView=true'
			ELSE 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID=' + CAST(wo.WORKORDERID AS VARCHAR(20))
			END ,
     [SourceSystem] = 'Service Desk' ,    
	 [OriginalStatus] = sta.STATUSDESCRIPTION

	 FROM [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[WorkOrder] wo 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[ModeDefinition] mdd 
	ON wo.MODEID=mdd.MODEID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[SDUser] sdu 
	ON wo.REQUESTERID =sdu.USERID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[SDUser] sdu2 
	ON wo.CREATEDBYID =sdu2.USERID
	

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[AaaUser] aau 
	ON sdu.USERID=aau.USER_ID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[AaaUser] aau2 
	ON sdu2.USERID=aau2.USER_ID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[DepartmentDefinition] dpt
	ON wo.DEPTID=dpt.DEPTID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[WorkOrderStates] wos
	ON wo.WORKORDERID=wos.WORKORDERID 
	
LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[StatusDefinition] sta
	ON sta.STATUSID = wos.STATUSID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].CategoryDefinition cd
	ON wos.CATEGORYID=cd.CATEGORYID
	
	WHERE 1= 1
	
	AND wo.CREATEDTIME != 0 
	AND wo.CREATEDTIME IS NOT NULL 
	AND wo.CREATEDTIME != -1   
	AND wo.ISPARENT='1'  
	AND cd.[CATEGORYID]	= 100000602 --Document retrieval
	AND DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00')) > @Start 
    AND DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00'))  < @End 

) Final 

--WHERE Final.job_id = 200431
) f
WHERE RN =1 
ORDER BY f.[Date Requested] DESC


END 

 IF @Status = 1

  SELECT Final.*

 FROM 

 (
 
 SELECT 

  x.job_id,
  x.[Requesting User],
  x.[Date Requested],
  x.Comment,
  x.[Processing User],
  x.[Date Processed],
  CASE WHEN x.Result ='No Original' THEN 'NO ORIGINAL' ELSE x.Result END AS Result,
  x.[Days Old],
  x.scan_datetime,
  x.document_link,
  'FlowMatrix' AS SourceSystem
  ,x.OriginalStatus AS [OriginalStatus]



  FROM
 ( 

 SELECT DISTINCT 
   [job_id] = T1.[job_id],
   [Requesting User] = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT  +' (' +T1.[username] +')'  , --T1.[username] 
   [Date Requested] = T1.[event_time] ,
   [Comment] = T1.[comment]    ,
   [Processing User] = ProUser.name COLLATE DATABASE_DEFAULT  + ' (' + T2.[username] + ')'  , -- T2.[username] 
   [Date Processed] = T2.[event_time] , 
   [Result] = COALESCE(NULLIF(T2.[filter2],''), 'COMPLETED')  ,
   [Days Old] = CASE WHEN COALESCE(NULLIF(T2.[filter2],''), 'COMPLETED') <> 'COMPLETED' THEN DATEDIFF( day , CAST(T1.[event_time] AS DATE)  , GETDATE() ) ELSE NULL  END ,
   [scan_datetime] = T1.scan_datetime,
   [document_link] = '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(j.guid, 2) 
		+ '\' + RIGHT(LEFT(j.guid, 4), 2) + '\' + RIGHT(LEFT(j.guid, 6), 2) 
		+ '\' + RIGHT(j.guid, LEN(j.guid)-6) + '\' + j.label + '.TIF' ,		 
   [OriginalStatus] = COALESCE(NULLIF(T2.[filter2],''), 'done')  
	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)

LEFT JOIN [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]  T2 WITH(NOLOCK)
		ON  T1.job_id = T2.job_id 

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j
		ON j.job_id = T1.job_id

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 
	    ON windowsusername COLLATE DATABASE_DEFAULT = T1.[username] 
		AND dss_current_flag = 'Y' AND activeud = 1

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ProUser
	    ON ProUser.windowsusername COLLATE DATABASE_DEFAULT = T2.[username] 
		AND ProUser.dss_current_flag = 'Y' AND ProUser.activeud = 1

WHERE  T1.event = 'Physical Document' AND
(T2.event = 'IndexingDelete' OR T2.event = 'QADelete') 
AND T1.event_time > @Start 
AND T1.event_time < @End 

UNION 

SELECT DISTINCT 
   [job_id] = T3.[job_id],
   [Requesting User] = dim_fed_hierarchy_history.name , --  T3.[username]
   [Date Requested] = T3.[event_time] ,
   [Comment] = T3.[comment], 
   [Processing User] = '',
   [Date Processed] = '',
   [Result] = 'PENDING'  ,
   [Days Old] = DATEDIFF( day , CAST(T3.[event_time] AS DATE)  , GETDATE() ),
   [scan_datetime] = T3.scan_datetime,
   [document_link] = '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(j.guid, 2) 
		+ '\' + RIGHT(LEFT(j.guid, 4), 2) + '\' + RIGHT(LEFT(j.guid, 6), 2) 
		+ '\' + RIGHT(j.guid, LEN(j.guid)-6) + '\' + j.label + '.TIF' ,		
   [OriginalStatus] = 'PENDING'
FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T3 WITH(NOLOCK)

LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j
		ON j.job_id = T3.job_id

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 
	    ON windowsusername COLLATE DATABASE_DEFAULT = T3.[username]
		AND dss_current_flag = 'Y' AND activeud = 1


WHERE T3.event = 'Physical Document' 
AND T3.job_id NOT IN (SELECT job_id FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]  WITH(NOLOCK)
WHERE (event = 'IndexingDelete' OR event = 'QADelete') 
AND event_time > @Start 
AND event_time < @End) 
AND T3.event_time > @Start 
AND T3.event_time < @End

) x 



 UNION 

SELECT 
	 [job_id] = wo.WORKORDERID, 
	 [Requesting User] = aau.FIRST_NAME	, 
	 [Date Requested] = CAST(Dateadd(second, Cast(wo.CREATEDTIME AS BIGINT) / 1000,  '1-1-1970 00:00:00')  AS DATETIME)  ,
	 [Comment] = wo.TITLE,  
	 [Processing User] = aau2.FIRST_NAME	,
	 [Date Processed] = CASE WHEN wo.RESOLVEDTIME =0 THEN NULL ELSE CAST(Dateadd(second, Cast(wo.RESOLVEDTIME  AS BIGINT) / 1000, '1-1-1970 00:00:00')  AS DATETIME) END ,
     [Result] = CASE WHEN sta.STATUSDESCRIPTION = 'Request Pending' THEN 'PENDING'
        WHEN sta.STATUSDESCRIPTION = 'Request Resolved, waiting for approval by Requester' THEN 'COMPLETED'
		WHEN sta.STATUSDESCRIPTION = 'Request action in progress' THEN 'PENDING'
		WHEN sta.STATUSDESCRIPTION = 'Request Completed' THEN 'COMPLETE'
		ELSE 'ALL' END,
     [Days Old] = CASE WHEN sta.STATUSDESCRIPTION NOT IN ( 'Request Completed' , 'Request Resolved, waiting for approval by Requester')
		THEN DATEDIFF( day , CAST( DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00'))AS DATE)  , GETDATE() ) 
			ELSE NULL END, 
	 [scan_datetime] = NULL,
     [document_link] = CASE WHEN sta.STATUSNAME = 'Open' 
			THEN 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID=' + CAST(wo.WORKORDERID AS VARCHAR(20))
		  WHEN sta.STATUSNAME = 'In Progress' 
			THEN 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID='+ CAST(wo.WORKORDERID AS VARCHAR(20)) +'&&fromListView=true'
			ELSE 'https://sdp.weightmans.com/WorkOrder.do?woMode=viewWO&woID=' + CAST(wo.WORKORDERID AS VARCHAR(20))
			END ,
     [SourceSystem] =  'Service Desk'   ,   
	 [OriginalStatus] = sta.STATUSDESCRIPTION

	 FROM [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[WorkOrder] wo 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[ModeDefinition] mdd 
	ON wo.MODEID=mdd.MODEID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[SDUser] sdu 
	ON wo.REQUESTERID =sdu.USERID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[SDUser] sdu2 
	ON wo.CREATEDBYID =sdu2.USERID
	

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[AaaUser] aau 
	ON sdu.USERID=aau.USER_ID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[AaaUser] aau2 
	ON sdu2.USERID=aau2.USER_ID 

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[DepartmentDefinition] dpt
	ON wo.DEPTID=dpt.DEPTID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[WorkOrderStates] wos
	ON wo.WORKORDERID=wos.WORKORDERID 
	
LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].[StatusDefinition] sta
	ON sta.STATUSID = wos.STATUSID

LEFT JOIN [SVR-LIV-3PTY-01].[ServiceDeskPlus].[dbo].CategoryDefinition cd
	ON wos.CATEGORYID=cd.CATEGORYID
	
	WHERE 1= 1
	
	AND wo.CREATEDTIME != 0 
	AND wo.CREATEDTIME IS NOT NULL 
	AND wo.CREATEDTIME != -1   
	AND wo.ISPARENT='1'  
	AND cd.[CATEGORYID]	= 100000602 --Document retrieval
	AND DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00')) > @Start 
    AND DATEADD(s, convert(bigint, wo.CREATEDTIME) / 1000, convert(datetime, '1-1-1970 00:00:00'))  < @End 

) Final 

WHERE final.Result = 'PENDING'

ORDER BY Final.[Date Requested] DESC

END

/* TESTING DATA - Day old  = 0 and Result - PENDING - Green*/

--UNION 

--SELECT 
-- 1,
--  'Test',
--  GETDATE(),
--  'Test',
--  'Test',
--  GETDATE(),
--  'PENDING' AS Result,
--   0 AS[Days Old],
--  'Test' AS document_link
--  ,'Test'
--   ,'Test'

--  FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]

--  UNION 

--  /* TESTING DATA - Day old  = 1 and Result - PENDING (Amber)*/
--SELECT 
-- 2,
--  'Test',
--  GETDATE(),
--  'Test',
--  'Test',
--  GETDATE(),
--  'PENDING' AS Result,
--   1 AS[Days Old],
--  'Test' AS document_link
--    ,'Test'
--	 ,'Test'
--  FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]


--   UNION 

--  /* TESTING DATA - Day old  = 2 and Result - PENDING (Red)*/
--SELECT 
-- 3,
--  'Test',
--  GETDATE(),
--  'Test',
--  'Test',
--  GETDATE(),
--  'PENDING' AS Result,
--   2 AS[Days Old],
--  'Test' AS document_link
--    ,'Test'
--	 ,'Test'
--  FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog]
	
GO
