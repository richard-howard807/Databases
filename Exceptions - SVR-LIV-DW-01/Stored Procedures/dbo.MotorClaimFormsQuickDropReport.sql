SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--exec [MotorClaimFormsQuickDropReport]
CREATE PROCEDURE [dbo].[MotorClaimFormsQuickDropReport]

--@RedEventTime DATETIME, 
--@YellowEventTime DATETIME,
--@BlankComment VARCHAR(20)



AS 

BEGIN
   
 --DECLARE @BlankComment AS VARCHAR(20) = ''
 --,@YellowEventTime AS DATE =  GETDATE()
 --,@RedEventTime AS DATE = GETDATE() - 2
 
 --114806
 --113235

 SELECT x.[Created Date],
        x.[Document ID],
        [Requesting User] = RequestingUser.[Requesting User] ,
        Comment.Comment,
        x.document_link,
        x.owner,
        x.owner_type,
        x.owner_user,
        [Status] = CASE WHEN  LEN(Comment.Comment)  > 0 THEN 'Green'
                   WHEN  ISNULL(LEN(Comment.Comment),0)  < 1 AND  CAST(x.[Added to Motor Claims forms] AS DATE)= CAST(GETDATE() AS DATE) THEN 'Yellow'
				   WHEN  ISNULL(LEN(Comment.Comment),0)  < 1 AND  CAST(x.[Added to Motor Claims forms] AS DATE) < CAST(GETDATE() -5 AS DATE) THEN 'Red'
				   END,
		x.[Added to Motor Claims forms]
		,[Added to Quickdrop by] = AssignedBY.[Assigned By]

 FROM 
 (
 SELECT DISTINCT	
   [Created Date] = T1.scan_datetime,
   [Document ID] = T1.[job_id],				
   [Requesting User] = MAX(dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT  +' (' +T1.[username] +')') OVER  (PARTITION BY T1.[job_id])  , --T1.[username] 					
   [Comment] = T1.[comment],							
   [document_link] = '\\SVR-LIV-FMTX-01\workspace$' + '\' + LEFT(j.guid, 2) 				
		+ '\' + RIGHT(LEFT(j.guid, 4), 2) + '\' + RIGHT(LEFT(j.guid, 6), 2) 		
		+ '\' + RIGHT(j.guid, LEN(j.guid)-6) + '\' + j.label + '.TIF' 		
   ,T1.owner 				
  , j.owner_type				
  , j.owner_user	
  ,[Status] = CASE WHEN  LEN(T1.[comment])  > 0 THEN 'Green'
                   WHEN  LEN(T1.[comment])  < 1 AND  CAST(T1.[event_time] AS DATE)= CAST(GETDATE() AS DATE) THEN 'Yellow'
				   WHEN  LEN(T1.[comment])  < 1 AND  CAST(T1.[event_time] AS DATE) < CAST(GETDATE() -5 AS DATE) THEN 'Red'
				   END
 ,  T1.event
, [Added to Motor Claims forms] = T1.[event_time]
 -- ,T1.[event_time]

  ,ROW_NUMBER() OVER (PARTITION BY j.job_id ORDER BY T1.event_time DESC) AS RN


	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)			
					
				
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j				
		ON j.job_id = T1.job_id		
				
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 				
	    ON windowsusername COLLATE DATABASE_DEFAULT = T1.[username] 			
		AND dss_current_flag = 'Y' AND activeud = 1		
							
WHERE 1 = 1 				
AND (T1.owner  LIKE 'Motor Cl%'	OR TRIM(T1.owner) = 'shassa')
AND T1.event =  'Job sent to QuickDrop'
AND T1.job_id NOT IN (SELECT DISTINCT ISNULL(a.job_id, '') FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] a WHERE a.event IN ( 'Route to Mattersphere Complete', 'Delete Document'))

) x





LEFT JOIN ( SELECT DISTINCT	
 
   [Document ID] = T1.[job_id],								
   [Comment] = T1.[comment],	
   [Requesting User] = MAX(dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT  +' (' +T1.[username] +')') OVER  (PARTITION BY T1.[job_id])  ,
  ROW_NUMBER() OVER (PARTITION BY j.job_id ORDER BY T1.event_time DESC) AS RN


	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)			
	LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j				
		ON j.job_id = T1.job_id		
	LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 				
	    ON windowsusername COLLATE DATABASE_DEFAULT = T1.[username] 			
		AND dss_current_flag = 'Y' AND activeud = 1		
							
WHERE 1 = 1 				
AND (T1.owner  LIKE 'Motor Cl%'	OR TRIM(T1.owner) = 'shassa')
AND T1.event =  'Document Saved'
AND T1.job_id NOT IN (SELECT DISTINCT ISNULL(a.job_id, '') FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] a WHERE a.event IN ( 'Route to Mattersphere Complete', 'Delete Document'))
) Comment ON Comment.[Document ID] = x.[Document ID] AND Comment.RN = 1



LEFT JOIN (

SELECT DISTINCT	
 
   [Document ID] = T1.[job_id],				
   [Requesting User] = MAX(dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT  +' (' +T1.[username] +')') OVER  (PARTITION BY T1.[job_id])  , --T1.[username] 					
   ROW_NUMBER() OVER (PARTITION BY j.job_id ORDER BY T1.event_time DESC) AS RN

	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)			
									
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j				
		ON j.job_id = T1.job_id		
				
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 				
	    ON windowsusername COLLATE DATABASE_DEFAULT = T1.[username] 			
		AND dss_current_flag = 'Y' AND activeud = 1		
							
WHERE 1 = 1 				
--AND T1.owner  ='shassa'
--AND T1.event =  'Document Saved'
--AND T1.job_id NOT IN (SELECT DISTINCT ISNULL(a.job_id, '') FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] a WHERE a.event = 'Route to Mattersphere Complete')
--AND T1.job_id = 172676
) RequestingUser ON RequestingUser.[Document ID] = x.[Document ID] AND RequestingUser.RN = 1 




LEFT JOIN (

SELECT DISTINCT	
 
   [Document ID] = T1.[job_id],				
    [Assigned By] = name +' (' +windowsusername +')', --TRIM(REPLACE(SUBSTRING(T1.comment ,charindex('Assigned by',T1.comment ) + LEN('Assigned by'), LEN(T1.comment ) ), ')', '')), --SUBSTRING(@YourField,charindex(@Keyword,@YourField) + LEN(@Keyword), LEN(@YourField) ), 					
   ROW_NUMBER() OVER (PARTITION BY j.job_id ORDER BY T1.event_time DESC) AS RN

	 FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] T1 WITH(NOLOCK)			
LEFT JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].[Jobs] AS j				
		ON j.job_id = T1.job_id									
				
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history 				
	    ON windowsusername COLLATE DATABASE_DEFAULT = TRIM(REPLACE(SUBSTRING(T1.comment ,charindex('Assigned by',T1.comment ) + LEN('Assigned by'), LEN(T1.comment ) ), ')', ''))		
		AND dss_current_flag = 'Y' AND activeud = 1		
							
WHERE 1 = 1 				
--AND T1.owner  ='shassa'
--AND T1.event =  'Document Saved'
--AND T1.job_id NOT IN (SELECT DISTINCT ISNULL(a.job_id, '') FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] a WHERE a.event = 'Route to Mattersphere Complete')
--AND T1.job_id = 172676

AND t1.comment LIKE '%Assigned by%'
) AssignedBY ON AssignedBY.[Document ID] = x.[Document ID] AND AssignedBY.RN = 1 



WHERE  x.RN = 1

AND x.[Document ID] <> 	163574 

 --AND x.event = 'Document Saved'

--ORDER BY T1.[job_id], t1.event_time 

--/* Test Data */
--			-- Yellow
--			UNION 
--			SELECT 
--  [Created Date] = @YellowEventTime,	
--   [Document ID] = 1,				
--   [Requesting User] = 'Test'  , 					
--   [Comment] = @BlankComment,							
--   [document_link] = 'Test' 		
--   ,'Test' 				
--  , 'Test' 					
--  , 'Test' 	
--  ,[Status] = CASE WHEN  LEN(@BlankComment)  > 0 THEN 'Green'
--                   WHEN  LEN(@BlankComment)  < 1 AND  CAST(@YellowEventTime AS DATE) = CAST(GETDATE() AS DATE) THEN 'Yellow'
--				   WHEN  LEN(@BlankComment)  < 1 AND  CAST(@YellowEventTime AS DATE)  <= CAST(GETDATE()-5 AS DATE) THEN 'Red'
--				   END
--    FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] 

--	--Red

--				UNION 
--			SELECT 
--  [Created Date] = @RedEventTime,	
--   [Document ID] = 2,				
--   [Requesting User] = 'Test'  , 					
--   [Comment] = @BlankComment,							
--   [document_link] = 'Test' 		
--   ,'Test' 				
--  , 'Test' 					
--  , 'Test' 	
--  ,[Status] = CASE WHEN  LEN(@BlankComment)  > 0 THEN 'Green'
--                   WHEN  LEN(@BlankComment)  < 1 AND  CAST(@RedEventTime AS DATE) = CAST(GETDATE() AS DATE) THEN 'Yellow'
--				   WHEN  LEN(@BlankComment)  < 1 AND  CAST(@RedEventTime AS DATE)  <= CAST(GETDATE() -5 AS DATE) THEN 'Red'
--				   END
--    FROM [SVR-LIV-3PTY-01].[PaperRiverAudit].[dbo].[RecentAuditLog] 

--	ORDER BY 1 desc

END 
GO
