SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CitrixLogons_LogonAudit_new] -- EXEC dbo.CitrixLogons_LogonAudit '2016-01-01','2016-01-26','Eif Williams'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Name AS VARCHAR(MAX)
)
AS
BEGIN
SELECT s.SessionID,	s.TimeStamp, s.EventType, s.Username, s.ComputerName, s.DisplayName, s.SessionName, s.ClientName, s.Domain
		FROM [SVR-LIV-XASQ-01].[LogonAudit].[dbo].[session] s
	INNER JOIN red_dw..dim_employee Employee ON RTRIM(Employee.windowsusername) = RTRIM(REPLACE([s].[Username],'SBC\','')) COLLATE DATABASE_DEFAULT
	WHERE s.TimeStamp BETWEEN @StartDate AND DATEADD(DAY,1,@EndDate)
	AND (Employee.knownas + ' ' + Employee.surname) = @Name
	ORDER BY s.TimeStamp
END

GO
