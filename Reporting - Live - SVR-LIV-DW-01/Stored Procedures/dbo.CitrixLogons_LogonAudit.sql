SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[CitrixLogons_LogonAudit] -- EXEC dbo.CitrixLogons_LogonAudit '2016-01-01','2016-01-26','Eif Williams'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Name AS VARCHAR(MAX)
,@Team AS VARCHAR(MAX)
)
AS
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--DECLARE @Name AS VARCHAR(MAX)
--DECLARE @Team AS VARCHAR(MAX)

--SET @StartDate='2019-09-02'
--SET @EndDate='2019-09-02'
--SET @Name='Jill Sheridan'
--SET @Team='Data Services'

BEGIN

SELECT ListValue  INTO #Name FROM Reporting.dbo.[udt_TallySplit]('|', @Name)

SELECT s.SessionID,	s.TimeStamp, s.EventType, s.Username, s.ComputerName, s.DisplayName, s.SessionName, s.ClientName, s.Domain, hierarchylevel4hist
		FROM [SVR-LIV-XASQ-01].[LogonAudit].[dbo].[session] s
	INNER JOIN red_dw.dbo.dim_employee ON RTRIM(dim_employee.windowsusername) = RTRIM(REPLACE([s].[Username],'SBC\','')) COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_employee_key = dim_employee.dim_employee_key 
	AND dss_current_flag='Y' AND activeud=1
	
	INNER JOIN #Name AS Name ON Name.ListValue   COLLATE DATABASE_DEFAULT = name COLLATE DATABASE_DEFAULT
	
	WHERE s.TimeStamp BETWEEN @StartDate AND DATEADD(DAY,1,@EndDate)

	AND hierarchylevel4hist=@Team
	
	ORDER BY s.TimeStamp
END


GO
