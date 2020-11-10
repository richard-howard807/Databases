SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- Ticket #71119 - JB - added in Last FY figures

CREATE PROCEDURE [dbo].[ClaimMilestoneBenefits] --'2021-02 (Jun-2020)','2021-03 (Jul-2020)' 
(
@Period1 NVARCHAR(MAX)
,@Period2 NVARCHAR(MAX)
)
AS

BEGIN

--------------------------------------------------
DECLARE @FinYear1 AS INT DECLARE @FinMonth1 AS INT

SET @FinMonth1=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period1)

SET @FinYear1=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period1)
---------Period1 ---------------------------------------------------------------------------
DECLARE @FinYear2 AS INT DECLARE @FinMonth2 AS INT

SET @FinMonth2=(SELECT  DISTINCT  bill_fin_month_no FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period2)

SET @FinYear2=(SELECT DISTINCT  bill_fin_year FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period2)

---------Period2 ---------------------------------------------------------------------------
DECLARE @StartDate1 AS DATE
DECLARE @StartDate2 AS DATE
DECLARE @StartDate3 AS DATE
DECLARE @EndDate1 AS DATE
DECLARE @EndDate2 AS DATE
DECLARE @EndDate3 AS DATE
SET @StartDate1=(SELECT MIN(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period1)
SET @EndDate1=(SELECT MAX(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period1)
SET @StartDate2=(SELECT MIN(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period2)
SET @EndDate2=(SELECT MAX(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE bill_fin_period=@Period2)
SET @StartDate3=(SELECT MIN(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE dim_bill_date.bill_fin_year=@FinYear2-1)
SET @EndDate3=(SELECT MAX(bill_date) FROM red_dw.dbo.dim_bill_date
WHERE dim_bill_date.bill_fin_year=@FinYear2-1)
------- Start and EndDates----------------------------------------------------------------------

SELECT structure.Department
       ,structure.Team
       ,structure.Period
	   ,ISNULL(RevenueYTD,0)  AS Revenue
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(RevenueYTD,0) ELSE NULL END AS RevenueP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(RevenueYTD,0) ELSE NULL END AS RevenueP2
	   ,Concluded.NoConcluded AS NoConcluded
	   ,Concluded.DayToConclude AS DaysToConcluded
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Concluded.NoConcluded,0) ELSE NULL END AS NoConcludedP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Concluded.NoConcluded,0) ELSE NULL END AS NoConcludedP2
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Concluded.DayToConclude,0) ELSE NULL END AS DayToConcludeP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Concluded.DayToConclude,0) ELSE NULL END AS DayToConcludeP2
	   ,Settled.NoSettled AS NoSettled
	   ,Settled.DayToSettle AS DayToSettle
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Settled.NoSettled,0) ELSE NULL END AS NoSettledP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Settled.NoSettled,0) ELSE NULL END AS NoSettledP2
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Settled.DayToSettle,0) ELSE NULL END AS DayToSettleP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Settled.DayToSettle,0) ELSE NULL END AS DayToSettleP2
	   ,ISNULL(Wizards.WizardCompleted,0)  AS WizardCompleted
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(WizardCompleted,0) ELSE NULL END AS WizardCompletedP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(WizardCompleted,0) ELSE NULL END AS WizardCompletedP2
	   ,ISNULL(WriteOffs.WriteOff,0)  AS WriteOff
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(WriteOffs.WriteOff,0) ELSE NULL END AS WriteOffP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(WriteOffs.WriteOff,0) ELSE NULL END AS WriteOffP2
	   ,ISNULL(Utilisation.ChargeableHrs,0)  AS ChargeableHrs
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Utilisation.ChargeableHrs,0) ELSE NULL END AS ChargeableHrsP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Utilisation.ChargeableHrs,0) ELSE NULL END AS ChargeableHrsP2
	   	   ,ISNULL(Utilisation.ContractedHrs,0)  AS ContractedHrs
	   ,CASE WHEN structure.PERIOD='Period 1' THEN ISNULL(Utilisation.ContractedHrs,0) ELSE NULL END AS ContractedHrsP1
	   ,CASE WHEN structure.PERIOD='Period 2' THEN ISNULL(Utilisation.ContractedHrs,0) ELSE NULL END AS ContractedHrsP2

	   
	   
	   
	   FROM (SELECT DISTINCT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
--AND activeud=1

UNION
SELECT DISTINCT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
--AND activeud=1

UNION
SELECT DISTINCT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
--AND activeud=1
) AS structure
----------------Hierarchy-------------------------------------------------
LEFT OUTER JOIN (SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period],
SUM(bill_amount) AS RevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date

WHERE bill_fin_year= @FinYear1
AND bill_fin_month_no=@FinMonth1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
GROUP BY  hierarchylevel3hist 
,hierarchylevel4hist
UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period],
SUM(bill_amount) AS RevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date

WHERE bill_fin_year= @FinYear2
AND bill_fin_month_no=@FinMonth2
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
GROUP BY  hierarchylevel3hist 
,hierarchylevel4hist

UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period],
SUM(bill_amount) AS RevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date

WHERE bill_fin_year= @FinYear2-1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
GROUP BY  hierarchylevel3hist 
,hierarchylevel4hist
) AS Period1Revenue
 ON Period1Revenue.Department = structure.Department
 AND Period1Revenue.Period = structure.Period
 AND Period1Revenue.Team = structure.Team
--------------------- Revenue --------------------------------------------
LEFT OUTER JOIN 
(
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
,COUNT(1) AS NoConcluded
,SUM(DATEDIFF(DAY,date_opened_case_management,date_claim_concluded)) AS DayToConclude
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate1 AND @EndDate1
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
,COUNT(1) AS NoConcluded
,SUM(DATEDIFF(DAY,date_opened_case_management,date_claim_concluded)) AS DayToConclude
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate2 AND @EndDate2
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist

UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
,COUNT(1) AS NoConcluded
,SUM(DATEDIFF(DAY,date_opened_case_management,date_claim_concluded)) AS DayToConclude
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate3 AND @EndDate3
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
) AS Concluded
 ON Concluded.Department = structure.Department
 AND Concluded.Team = structure.Team
 AND Concluded.Period = structure.[Period]
 --------------------- Damages Concluded -------------------------------------------
 LEFT OUTER JOIN 
 (
 SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
,COUNT(1) AS NoSettled
,SUM(DATEDIFF(DAY,date_opened_case_management,date_costs_settled)) AS DayToSettle
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate1 AND @EndDate1
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
,COUNT(1) AS NoSettled
,SUM(DATEDIFF(DAY,date_opened_case_management,date_costs_settled)) AS DayToSettle
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate2 AND @EndDate2
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist

UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
,COUNT(1) AS NoSettled
,SUM(DATEDIFF(DAY,date_opened_case_management,date_costs_settled)) AS DayToSettle
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
AND date_claim_concluded BETWEEN @StartDate3 AND @EndDate3
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
 ) AS Settled
  ON Settled.Department = structure.Department
 AND Settled.Team = structure.Team
 AND Settled.Period = structure.[Period]
 ------------- Completed Wizards ---------------------------------

 LEFT OUTER JOIN 
 (
 SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
,SUM(CASE WHEN Milestones.Completed>=1 THEN 1 ELSE 0 END)  AS [WizardCompleted]
,SUM(CASE WHEN Milestones.Completed=0 THEN 1 ELSE 0 END)  AS [WizardIncomplete]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(tskCompleted) AS [DateLastCompleted]
FROM MS_PROD.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Stage%' AND tskDesc LIKE '%Wizard%'
AND tskactive=1
AND CONVERT(DATE,tskCompleted,103) BETWEEN @StartDate1 AND @EndDate1
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
,SUM(CASE WHEN Milestones.Completed>=1 THEN 1 ELSE 0 END)  AS [WizardCompleted]
,SUM(CASE WHEN Milestones.Completed=0 THEN 1 ELSE 0 END)  AS [WizardIncomplete]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(tskCompleted) AS [DateLastCompleted]
FROM MS_PROD.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Stage%' AND tskDesc LIKE '%Wizard%'
AND tskactive=1
AND CONVERT(DATE,tskCompleted,103) BETWEEN @StartDate2 AND @EndDate2
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist

UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
,SUM(CASE WHEN Milestones.Completed>=1 THEN 1 ELSE 0 END)  AS [WizardCompleted]
,SUM(CASE WHEN Milestones.Completed=0 THEN 1 ELSE 0 END)  AS [WizardIncomplete]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT fileID,SUM(CASE WHEN tskComplete=1 THEN 1 ELSE 0 END) AS Completed
,SUM(CASE WHEN tskComplete=0 THEN 1 ELSE 0 END) AS Incompleted
,MAX(tskCompleted) AS [DateLastCompleted]
FROM MS_PROD.dbo.dbTasks
WHERE tskType='MILESTONE'
AND tskDesc LIKE '%Stage%' AND tskDesc LIKE '%Wizard%'
AND tskactive=1
AND CONVERT(DATE,tskCompleted,103) BETWEEN @StartDate3 AND @EndDate3
GROUP BY fileID) AS Milestones
 ON ms_fileid=Milestones.fileID

WHERE hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
AND dss_current_flag='Y'
GROUP BY hierarchylevel3hist 
,hierarchylevel4hist
 ) AS Wizards
  ON Wizards.Department = structure.Department
 AND Wizards.Team = structure.Team
 AND Wizards.Period = structure.[Period]
--------------------- Write offs -------------------------------------
LEFT OUTER JOIN 
(
SELECT dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
,SUM(red_dw.dbo.fact_write_off.write_off_amt) AS WriteOff
FROM red_dw.dbo.fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
WHERE fin_period=@Period1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')
AND dim_write_off_date_key>=20180501
GROUP BY dim_fed_hierarchy_history.hierarchylevel3hist
,dim_fed_hierarchy_history.hierarchylevel4hist
UNION
SELECT dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
,SUM(red_dw.dbo.fact_write_off.write_off_amt) AS WriteOff
FROM red_dw.dbo.fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
WHERE fin_period=@Period2
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')
AND dim_write_off_date_key>=20180501
GROUP BY dim_fed_hierarchy_history.hierarchylevel3hist
,dim_fed_hierarchy_history.hierarchylevel4hist

UNION
SELECT dim_fed_hierarchy_history.hierarchylevel3hist AS Department
,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
,SUM(red_dw.dbo.fact_write_off.write_off_amt) AS WriteOff
FROM red_dw.dbo.fact_write_off
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
       ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_matter_owner_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  feeearner
       ON feeearner.dim_fed_hierarchy_history_key = fact_write_off.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON fact_write_off.dim_matter_header_curr_key
       = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key=fact_write_off.dim_write_off_date_key
WHERE dim_date.fin_year = @FinYear2-1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND fact_write_off.write_off_type IN ('WA','NC','BA','P')
AND dim_write_off_date_key>=20180501
GROUP BY dim_fed_hierarchy_history.hierarchylevel3hist
,dim_fed_hierarchy_history.hierarchylevel4hist
) AS WriteOffs
  ON WriteOffs.Department = structure.Department
 AND WriteOffs.Team = structure.Team
 AND WriteOffs.Period = structure.[Period]
----------------- Utilisation --------------------------------------------
LEFT OUTER JOIN 
(
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 1' AS [Period]
,CAST(SUM(minutes_recorded / 60) AS DECIMAL(10, 1)) AS ChargeableHrs
,SUM(fact_budget_activity.contracted_hours_in_month)  AS ContractedHrs
FROM red_dw.dbo.fact_agg_billable_time_monthly_rollup
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_billable_time_monthly_rollup.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_gl_date 
  ON dim_gl_date.dim_gl_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
LEFT OUTER JOIN red_dw.dbo.fact_budget_activity 
  ON fact_budget_activity.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
  AND fact_budget_activity.dim_budget_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
WHERE gl_fin_period = @Period1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
GROUP BY hierarchylevel3hist,
         hierarchylevel4hist
UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Period 2' AS [Period]
,CAST(SUM(minutes_recorded / 60) AS DECIMAL(10, 1)) AS ChargeableHrs
,SUM(fact_budget_activity.contracted_hours_in_month)  AS ContractedHrs
FROM red_dw.dbo.fact_agg_billable_time_monthly_rollup
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_billable_time_monthly_rollup.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_gl_date 
  ON dim_gl_date.dim_gl_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
LEFT OUTER JOIN red_dw.dbo.fact_budget_activity 
  ON fact_budget_activity.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
  AND fact_budget_activity.dim_budget_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
WHERE gl_fin_period = @Period2
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
GROUP BY hierarchylevel3hist,
         hierarchylevel4hist

UNION
SELECT hierarchylevel3hist AS Department
,hierarchylevel4hist AS [Team]
,'Last FY' AS [Period]
,CAST(SUM(minutes_recorded / 60) AS DECIMAL(10, 1)) AS ChargeableHrs
,SUM(fact_budget_activity.contracted_hours_in_month)  AS ContractedHrs
FROM red_dw.dbo.fact_agg_billable_time_monthly_rollup
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
  ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_billable_time_monthly_rollup.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_gl_date 
  ON dim_gl_date.dim_gl_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
LEFT OUTER JOIN red_dw.dbo.fact_budget_activity 
  ON fact_budget_activity.dim_fed_hierarchy_history_key = dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
  AND fact_budget_activity.dim_budget_date_key = fact_agg_billable_time_monthly_rollup.dim_gl_date_key
WHERE dim_gl_date.gl_fin_year = @FinYear2-1
AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
AND hierarchylevel4hist IS NOT NULL
GROUP BY hierarchylevel3hist,
         hierarchylevel4hist
) AS Utilisation
ON Utilisation.Department = structure.Department
 AND Utilisation.Team = structure.Team
 AND Utilisation.Period = structure.[Period]





 --WHERE structure.Team='Birmingham Healthcare 1'
 ORDER BY Period1Revenue.Department,Period1Revenue.Team,structure.Period






END
GO
