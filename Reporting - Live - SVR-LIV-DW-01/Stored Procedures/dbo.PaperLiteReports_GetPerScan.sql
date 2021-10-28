SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[PaperLiteReports_GetPerScan] 
(
@EventStart AS DATE
,@EventEnd AS DATE


)
AS 



--DECLARE @EventStart AS DATE = GETDATE() - 300
--,@EventEnd AS DATE = GETDATE()

SELECT * FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.RecentAuditLog 
WHERE message_id IN ( SELECT MAX(message_id) 
FROM [SVR-LIV-3PTY-01].PaperRiverAudit.dbo.RecentAuditLog 

WHERE  Context = 'Reports' 

AND 
(
event_time > @EventStart AND event_time <= @EventEnd
)
)
GO
