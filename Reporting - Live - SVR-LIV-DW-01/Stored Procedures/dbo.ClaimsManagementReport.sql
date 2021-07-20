SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [dbo].[ClaimsManagementReport] 
	
	@Division VARCHAR(MAX)
	, @Department VARCHAR(MAX)
	, @Team VARCHAR(MAX)
	, @Individual VARCHAR(MAX)
	,@Period NVARCHAR(MAX)

AS
BEGIN

	SET NOCOUNT ON;

	IF OBJECT_ID('tempdb..#Division') IS NOT NULL   DROP TABLE #Division
	IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Individual') IS NOT NULL   DROP TABLE #Individual

			CREATE TABLE #Division 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Division
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Division) 

		CREATE TABLE #Department 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Department
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Department) 

	CREATE TABLE #Team 
	( ListValue NVARCHAR(200) collate Latin1_General_BIN)
	INSERT INTO #Team
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Team) 

	CREATE TABLE #Individual 
	( ListValue NVARCHAR(200) COLLATE Latin1_General_BIN)
	INSERT INTO #Individual
	SELECT ListValue  FROM 	dbo.udt_TallySplit(',', @Individual) 




SELECT ClaimsManagementReportSnapshotTable.employeeid,
       RTRIM(ISNULL(display_name,Name)) AS Name,
       Division,
       Department,
       Team,
       [Contractual hours per day],
       [Annual Holiday Allowance],
       [Annual Working Days],
       [Holidays Taken to Date],
       [Holidays yet to Take],
       [Working Days to Date],
       [Chargeable Hours],
       AVGChargeableHours,
       ChargeableHoursMTD,
       [Utilisation %],
       SicknessDays,
       OtherDays,
       MonthlyContribution,
       YTDContribution,
       [Chargeable hours target],
       [Revenue target],
       YTDTargetHrs,
       YTDTargetRevenue,
       [Chargeable hours target Annual],
       [Revenue target Annual],
       FinMonth,
       FinYear,
       Period,
       classification,ISNULL(MaternityDays,0) AS MaternityDays
	   ,ISNULL(MaternityYTD,0) AS MaternityYTD
	   ,displayemployeeid
	   FROM dbo.ClaimsManagementReportSnapshotTable
	   LEFT OUTER JOIN red_dw.dbo.dim_employee
	    ON dim_employee.employeeid = ClaimsManagementReportSnapshotTable.employeeid


INNER JOIN #Division AS Division ON Division.ListValue = Division 
	INNER JOIN #Department AS Department ON Department.ListValue = Department 
	INNER JOIN #Team AS Team ON Team.ListValue = REPLACE(Team,',','')
	INNER JOIN #Individual AS Individual ON Individual.ListValue = ClaimsManagementReportSnapshotTable.employeeid
WHERE [Period]=@Period

ORDER BY name
END

GO
