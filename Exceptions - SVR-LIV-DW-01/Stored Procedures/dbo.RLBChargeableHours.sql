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
  
 IF OBJECT_ID(N'tempdb..#ContractedHrs') IS NOT NULL
BEGIN
DROP TABLE #ContractedHrs
END
 SELECT DailyContractedHours.employeeid,
        DailyContractedHours.fin_year,
        DailyContractedHours.fin_month_no,
        DailyContractedHours.contacted_hours_day * TradingDays.TradingDays AS ContractedHrsMonth
		INTO #ContractedHrs
		FROM
 (SELECT DISTINCT    load_cascade_employee_jobs.employeeid,
    stage_fact_3e_contracted_hours_02_dates.fin_year,
    stage_fact_3e_contracted_hours_02_dates.fin_month_no,
    load_cascade_employee_jobs.normalhours / 5 contacted_hours_day
	,previousfirmud

  FROM red_dw.dbo.load_cascade_employee_jobs
  INNER JOIN red_dw.dbo.load_cascade_employee ON load_cascade_employee_jobs.employeeid = load_cascade_employee.employeeid
 INNER JOIN red_dw.dbo.ds_sh_valid_hierarchy_x AS load_cascade_valid_hierarchy_x
  ON load_cascade_valid_hierarchy_x.hierarchynode = load_cascade_employee_jobs.hierarchynode AND load_cascade_valid_hierarchy_x.dss_current_flag='Y'
  INNER JOIN red_dw.dbo.stage_fact_3e_contracted_hours_02_dates on stage_fact_3e_contracted_hours_02_dates.calendar_date BETWEEN
              CASE WHEN load_cascade_employee_jobs.sys_effectivedate <= employeestartdate THEN employeestartdate ELSE load_cascade_employee_jobs.sys_effectivedate end
                  AND
              CASE WHEN ISNULL(load_cascade_employee_jobs.sys_calculatedenddate,'20990101') >= leftdate THEN leftdate ELSE ISNULL(load_cascade_employee_jobs.sys_calculatedenddate,'20990101') end
  WHERE  fin_year='2023'
  AND previousfirmud='RadcliffesLeBrasseur'

) AS DailyContractedHours
LEFT OUTER JOIN (  SELECT  fin_year,fin_month_no,COUNT(1) AS TradingDays
  FROM red_dw.dbo.dim_date
  WHERE fin_year='2023'
  AND trading_day_flag='Y'
  GROUP BY fin_year,
           fin_month_no) AS TradingDays
		    ON TradingDays.fin_year = DailyContractedHours.fin_year
			AND TradingDays.fin_month_no = DailyContractedHours.fin_month_no
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
, CASE WHEN ISNULL(ContractedHours.ContractedHoursMTD,0)>0 THEN (CurrentMonth/ContractedHours.ContractedHoursMTD) END AS [Utilisation % Month]
, CASE WHEN ISNULL(ContractedHours.ContractedHoursYTD,0)>0 THEN (YTD/ContractedHours.ContractedHoursYTD) END AS [Utilisation % YTD]
,ContractedHours.ContractedHoursMTD
,ContractedHours.ContractedHoursYTD
,CASE WHEN ContractedHours.ContractedHoursMTD>0 THEN AllData.CurrentMonth ELSE NULL END AS ChargebleMTD
,CASE WHEN ContractedHours.ContractedHoursYTD>0 THEN AllData.YTD ELSE NULL END AS ChargebleYTD

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
SELECT employeeid
,SUM(ContractedHrsMonth) AS [ContractedHoursYTD] 
,SUM(CASE WHEN fin_month_no=@FinMonth THEN ContractedHrsMonth ELSE 0 END) [ContractedHoursMTD] 
				FROM  #ContractedHrs
				WHERE fin_year=@FinYear
				AND @FinMonth <=@FinMonth
				GROUP BY employeeid
) AS ContractedHours
 ON  ContractedHours.employeeid = AllData.employeeid





END
GO
