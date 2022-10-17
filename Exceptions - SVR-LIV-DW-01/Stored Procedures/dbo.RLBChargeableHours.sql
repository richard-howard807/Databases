SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[RLBChargeableHours]
(
@Period AS NVARCHAR(MAX)
)
AS 

BEGIN

IF OBJECT_ID(N'tempdb..#RLBData') IS NOT NULL
BEGIN
DROP TABLE #RLBData
END
SELECT 
ttk AS [FE]
,tkfirst +' ' +tklast AS [Fe Name]
,tworkdt AS [Work Date]
,SUM(CASE WHEN tstatus='B' THEN tworkhrs ELSE 0 END) AS [Worked Billable HrsMins]
,SUM(CASE WHEN tstatus='NB' THEN tworkhrs ELSE 0 END) AS [Worked Non Billable HrsMins]
,SUM(CASE WHEN tstatus='B' THEN tworkdol ELSE 0 END) AS [Worked Billable £]
,SUM(CASE WHEN tstatus='NB' THEN tworkdol ELSE 0 END) AS [Worked Non Billable £]
,SUM(CASE WHEN tstatus='B' THEN tbillhrs ELSE 0 END) AS [Billed Billable HrsMins]
,SUM(CASE WHEN tstatus='NB' THEN tbillhrs ELSE 0 END) AS [Billed Non Billable HrsMins]
,SUM(CASE WHEN tstatus='B' THEN tbilldol ELSE 0 END) AS [Billed Billable £]
,SUM(CASE WHEN tstatus='NB' THEN tbilldol ELSE 0 END) AS [Billed Non Billable £]
INTO #RLBData
FROM [lon-elite1].son_db.dbo.timecard WITH(NOLOCK)
LEFT OUTER JOIN [lon-elite1].son_db.dbo.timekeep  WITH(NOLOCK)
 ON ttk=tkinit
WHERE  tworkdt>='2022-05-01'
AND tworkdt<=CONVERT(DATE,GETDATE(),103)

GROUP BY tkfirst + ' ' + tklast,
         tworkdt,
		 ttk
        
--DECLARE @Period AS NVARCHAR(500)
--SET @Period=(SELECT bill_fin_period FROM red_dw.dbo.dim_bill_date WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,GETDATE(),103))

--PRINT @Period

DECLARE @FinYear AS INT
DECLARE @FinMonth AS INT

SET @FinMonth=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

SET @FinYear=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period)

PRINT @FinMonth

SELECT AllData.FE,
       ISNULL(name,AllData.[Fe Name]) AS [Fe Name],
       AllData.fed_code,
       AllData.employeeid,
       AllData.Division,
       AllData.Department,
       AllData.Team,
       AllData.CurrentMonth,
       AllData.YTD
, CASE WHEN ContractedHours.ContractedHours>0 THEN (CurrentMonth/ContractedHours.ContractedHours) END AS [Utilisation % Month]
	   
	   FROM 
(SELECT #RLBData.FE
,#RLBData.[Fe Name]
,fed_code	
,name
,employeeid
,ISNULL(hierarchylevel2hist,'Other') AS [Division]
,ISNULL(hierarchylevel3hist,'Other') AS [Department]
,ISNULL(hierarchylevel4hist,'Other') AS [Team]
,SUM(CASE WHEN fin_month_no=@FinMonth THEN [Worked Billable HrsMins] ELSE 0 END) AS CurrentMonth
,SUM(CASE WHEN fin_year=@FinYear AND fin_month_no<=@FinMonth THEN  [Worked Billable HrsMins] ELSE 0 END) AS YTD
 FROM #RLBData
 INNER JOIN red_dw.dbo.dim_date
 ON CONVERT(DATE,[Work Date],103)=CONVERT(DATE,calendar_date,103)
 LEFT OUTER JOIN RLBStaff141022 
  ON #RLBData.FE=RLBStaff141022.FE
 LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON fed_code=FEDCode COLLATE DATABASE_DEFAULT AND dss_current_flag='Y' 
GROUP BY #RLBData.FE,
         #RLBData.[Fe Name],
		 fed_code,
		 name,
		 employeeid,
         hierarchylevel2hist,
         hierarchylevel3hist,
         hierarchylevel4hist
) AS AllData
LEFT OUTER JOIN 
(
SELECT employeeid, SUM(contracted_hours_in_month) AS [ContractedHours] 
				FROM  red_dw.dbo.fact_budget_activity WITH(NOLOCK)
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
				WHERE financial_budget_year=@FinYear
				GROUP BY employeeid
) AS ContractedHours
 ON  ContractedHours.employeeid = AllData.employeeid





END
GO
