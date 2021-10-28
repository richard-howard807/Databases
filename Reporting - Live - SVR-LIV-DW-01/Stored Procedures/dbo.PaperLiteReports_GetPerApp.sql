SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PaperLiteReports_GetPerApp] 
(
@EventStart AS DATE
,@EventEnd AS DATE


)
AS 


--DECLARE @EventStart AS DATE = GETDATE() - 300
--,@EventEnd AS DATE = GETDATE()



SELECT 
source, 
COUNT(job_id) as TotalCount, 
SUM(pages) as TotalPages, 
SUM(pages)/COUNT(pages) as AveragePages, 
MAX(pages) as MaxPages 
FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.RecentAuditLog 
WHERE message_id IN ( SELECT MAX(message_id) FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.RecentAuditLog 
WHERE Context = 'Reports' AND [event] = 'Scan Received' AND event_time > @EventStart AND event_time <= @EventEnd GROUP BY job_id ) 
GROUP BY source ORDER BY source ASC
GO
