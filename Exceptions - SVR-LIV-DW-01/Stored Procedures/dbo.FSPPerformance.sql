SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO














CREATE PROCEDURE [dbo].[FSPPerformance] -- EXEC FSPPerformance '2022-05-01','2022-08-14'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Division AS NVARCHAR(MAX)
,@Segment AS NVARCHAR(MAX)
)

AS 

BEGIN
--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE

--SET @StartDate='2022-05-01'
--SET @EndDate='2022-08-14'

SELECT ListValue  INTO #Division FROM Reporting.dbo.[udt_TallySplit]('|', @Division)
SELECT ListValue  INTO #Segment FROM Reporting.dbo.[udt_TallySplit]('|', @Segment)

DECLARE @Finmonth AS INT
SET @Finmonth=(SELECT gl_fin_month_no FROM red_dw.dbo.dim_gl_date WHERE gl_calendar_date=@EndDate)

DECLARE @FinYear AS INT
SET @FinYear=(SELECT gl_fin_year FROM red_dw.dbo.dim_gl_date WHERE gl_calendar_date=@EndDate)



IF OBJECT_ID(N'tempdb..#HrsTarget') IS NOT NULL
BEGIN
DROP TABLE #HrsTarget
END

SELECT CAST([Cascade No] AS NVARCHAR(50)) AS [Cascade No], Amount
,CASE WHEN up.Amounts='May' THEN 1
WHEN up.Amounts='June' THEN 2
WHEN up.Amounts='July' THEN 3
WHEN up.Amounts='Aug' THEN 4
WHEN up.Amounts='Sept' THEN 5
WHEN up.Amounts='Oct' THEN 6
WHEN up.Amounts='Nov' THEN 7
WHEN up.Amounts='Dec' THEN 8
WHEN up.Amounts='Jan' THEN 9
WHEN up.Amounts='Feb' THEN 10
WHEN up.Amounts='Mar' THEN 11
WHEN up.Amounts='Apr' THEN 12 END AS  [FinMonth]
,2023 AS FinYear
INTO #HrsTarget
FROM 
(
    SELECT [Cascade No], May, June,July,
           Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr
    FROM dbo.FSPHoursTargets2223
) AS cp
UNPIVOT 
(
  Amount FOR Amounts IN (May, June,July,Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr)
) AS up;




IF OBJECT_ID(N'tempdb..#RevenueTarget') IS NOT NULL
BEGIN
DROP TABLE #RevenueTarget
END

SELECT CAST([Cascade No] AS NVARCHAR(50)) AS [Cascade No], up.RevenueTarget
,CASE WHEN up.Revenues='May' THEN 1
WHEN up.Revenues='June' THEN 2
WHEN up.Revenues='July' THEN 3
WHEN up.Revenues='Aug' THEN 4
WHEN up.Revenues='Sept' THEN 5
WHEN up.Revenues='Oct' THEN 6
WHEN up.Revenues='Nov' THEN 7
WHEN up.Revenues='Dec' THEN 8
WHEN up.Revenues='Jan' THEN 9
WHEN up.Revenues='Feb' THEN 10
WHEN up.Revenues='Mar' THEN 11
WHEN up.Revenues='Apr' THEN 12 END AS  [FinMonth]
,2023 AS FinYear
INTO #RevenueTarget
FROM 
(
    SELECT [Cascade No], May, June,July,
           Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr
    FROM dbo.FSPRevenueTargets2223
) AS cp
UNPIVOT 
(
  RevenueTarget FOR Revenues IN (May, June,July,Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr)
) AS up;




IF OBJECT_ID(N'tempdb..#UtilisationTarget') IS NOT NULL
BEGIN
DROP TABLE #UtilisationTarget
END

SELECT CAST([Cascade No] AS NVARCHAR(50)) AS [Cascade No], up.UtilisationTarget
,CASE WHEN up.Utilisation='May' THEN 1
WHEN up.Utilisation='June' THEN 2
WHEN up.Utilisation='July' THEN 3
WHEN up.Utilisation='Aug' THEN 4
WHEN up.Utilisation='Sept' THEN 5
WHEN up.Utilisation='Oct' THEN 6
WHEN up.Utilisation='Nov' THEN 7
WHEN up.Utilisation='Dec' THEN 8
WHEN up.Utilisation='Jan' THEN 9
WHEN up.Utilisation='Feb' THEN 10
WHEN up.Utilisation='Mar' THEN 11
WHEN up.Utilisation='Apr' THEN 12 END AS  [FinMonth]
,2023 AS FinYear
INTO #UtilisationTarget
FROM 
(
    SELECT [Cascade No], May, June,July,
           Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr
    FROM dbo.FSPUtilisationTargets2223
) AS cp
UNPIVOT 
(
  UtilisationTarget FOR Utilisation IN (May, June,July,Aug, Sept, Oct,Nov,Dec,Jan,Feb,Mar,Apr)
) AS up;



SELECT
FixedSharePartners.fed_code AS [Cascade No]
,FixedSharePartners.name AS [Name]
,RTRIM(FixedSharePartners.name) +' (' +FixedSharePartners.fed_code +')' AS DisplayName
,FixedSharePartners.levelidud
,FixedSharePartners.hierarchylevel2hist AS [Division]
,FixedSharePartners.hierarchylevel3hist AS Department
,FixedSharePartners.hierarchylevel4hist
,ISNULL(FixedSharePartners.management_role_one,'') + ' ' + ISNULL(FixedSharePartners.management_role_two,'')  AS [Significant Client/ Management Responsibilities]
,ISNULL(PersonalBilling,FeeRev.RevenueYTD) AS PersonalBilling
,[Work Won and Referred]
,Revenue.[Clients Introduced to the Firm]
,FeeRev.RevenueYTD
,ChargeableHrs.ChargeableHours
,ClientPartnerRev.ClientRevenueYTD AS [YTD CRP Revenue]
, CASE WHEN ContractedHours.ContractedHours>0 THEN (ChargeableHours/ContractedHours.ContractedHours) END AS [Utilisation %]
,FSPHrsTarget.HrsAnnualTarget
,FSPHrsTarget.HrsYTDTarget
,CASE WHEN FSPHrsTarget.HrsYTDTarget IS NOT NULL
THEN ChargeableHrs.ChargeableHours/FSPHrsTarget.HrsYTDTarget ELSE NULL END AS [YTDHrsTargetAchieved]
,CASE WHEN FSPHrsTarget.HrsAnnualTarget IS NOT NULL
THEN ChargeableHrs.ChargeableHours/FSPHrsTarget.HrsAnnualTarget ELSE NULL END AS [AnnualHrsTargetAchieved]

,FSPRevTarget.RevenueYTDTarget
,FSPRevTarget.RevenueAnnualTarget
,CASE WHEN RevenueYTDTarget IS NOT NULL
THEN FeeRev.RevenueYTD/RevenueYTDTarget ELSE NULL END AS [YTDRevTargetAchieved]
,CASE WHEN RevenueAnnualTarget IS NOT NULL
THEN FeeRev.RevenueYTD/RevenueAnnualTarget ELSE NULL END AS [AnnualRevTargetAchieved]
,FixedSharePartners.Segment
,DebtOver90
,FSPUtTarget.utilistationYTDTarget AS utilistation_target
--,utilistation_target_team
FROM 
(
SELECT fed_code,name,hierarchylevel2hist,hierarchylevel3hist,hierarchylevel4hist,dim_employee.jobtitle,levelidud,dim_employee.windowsusername
,management_role_one
,management_role_two
,leftdate
,dim_employee.employeeid
,CASE WHEN ISNULL(client_segment,'')='' THEN 'N/A'  ELSE client_segment END AS Segment
FROM red_dw.dbo.dim_fed_hierarchy_history
INNER JOIN red_dw.dbo.dim_employee
 ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
WHERE dss_current_flag='Y' AND activeud=1
AND leftdate IS NULL 
AND deleted_from_cascade=0
--AND hierarchylevel2hist IN ('Legal Ops - Claims','Legal Ops - LTA')
AND (levelidud IN ('Fixed Share Partner')
--, 'Legal Director') OR fed_code IN 
--('1817','3449','3808','5084','3456','3804','3463','6383','4615','6770','3799')
)
) FixedSharePartners 
INNER JOIN #Division AS Division  ON Division.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel2hist COLLATE DATABASE_DEFAULT
INNER JOIN #Segment AS Segment  ON Segment.ListValue COLLATE DATABASE_DEFAULT = FixedSharePartners.Segment COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN 
(
SELECT Timekeeper.number AS fed_code,SUM(CASE WHEN ref_type='Personal Billing' THEN  billamt_v2 ELSE 0 END) AS PersonalBilling
,SUM(CASE WHEN ref_type='Intro of Client Billing' THEN  billamt_v2 ELSE 0 END) AS [Clients Introduced to the Firm]
,SUM(CASE WHEN ref_type NOT IN ('Intro of Client Billing','Personal Billing') THEN  billamt_v2 ELSE 0 END) AS [Work Won and Referred]
FROM Visualisation.dbo.ROI
LEFT JOIN te_3e_prod.dbo.Timekeeper
 ON timekeeper=TkprIndex
WHERE       CONVERT(DATE,ROI.postdate,103) BETWEEN @StartDate AND @EndDate
GROUP BY Timekeeper.number
) AS Revenue
ON Revenue.fed_code = FixedSharePartners.fed_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT fed_code,SUM(chargeable_minutes_recorded)/60 AS ChargeableHours
FROM red_dw.dbo.fact_agg_kpi_monthly_rollup
INNER JOIN red_dw.dbo.dim_gl_date
 ON dim_gl_date.dim_gl_date_key = fact_agg_kpi_monthly_rollup.dim_gl_date_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_agg_kpi_monthly_rollup.dim_fed_hierarchy_history_key
WHERE gl_fin_month_no<=@Finmonth
AND gl_fin_year=@FinYear
GROUP BY fed_code) AS ChargeableHrs
 ON ChargeableHrs.fed_code = FixedSharePartners.fed_code
LEFT OUTER JOIN 
(
SELECT client_partner_code,SUM(bill_amount) AS ClientRevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY client_partner_code
) AS ClientPartnerRev
 ON FixedSharePartners.fed_code=ClientPartnerRev.client_partner_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN 
(
SELECT fed_code,SUM(bill_amount) AS RevenueYTD
FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
WHERE bill_fin_year= @FinYear
AND bill_fin_month_no<=@FinMonth
GROUP BY fed_code
) AS FeeRev
 ON FeeRev.fed_code = FixedSharePartners.fed_code
LEFT OUTER JOIN 
(
SELECT employeeid, SUM(contracted_hours_in_month) AS [ContractedHours] 
				FROM  red_dw.dbo.fact_budget_activity WITH(NOLOCK)
				LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_budget_activity.dim_fed_hierarchy_history_key
				WHERE financial_budget_year=@FinYear
				GROUP BY employeeid
) AS ContractedHours
 ON  ContractedHours.employeeid = FixedSharePartners.employeeid
LEFT OUTER JOIN (SELECT [Cascade No] AS fed_code,SUM(Amount) AS HrsAnnualTarget
,SUM(CASE WHEN FinYear=@FinYear AND FinMonth<=@Finmonth THEN Amount ELSE 0 END) HrsYTDTarget
FROM #HrsTarget
WHERE FinYear= @FinYear

GROUP BY [Cascade No]) AS FSPHrsTarget
 ON FSPHrsTarget.fed_code = FixedSharePartners.fed_code COLLATE DATABASE_DEFAULT

 LEFT OUTER JOIN (SELECT [Cascade No] AS fed_code,SUM(RevenueTarget) AS RevenueAnnualTarget
,SUM(CASE WHEN FinYear=@FinYear AND FinMonth<=@Finmonth THEN RevenueTarget ELSE 0 END) RevenueYTDTarget
FROM #RevenueTarget
WHERE FinYear= @FinYear

GROUP BY [Cascade No]) AS FSPRevTarget
 ON FSPRevTarget.fed_code = FixedSharePartners.fed_code COLLATE DATABASE_DEFAULT

  LEFT OUTER JOIN (SELECT [Cascade No] AS fed_code,AVG(#UtilisationTarget.UtilisationTarget) AS utilistationAnnualTarget
,AVG(CASE WHEN FinYear=@FinYear AND FinMonth<=@Finmonth THEN #UtilisationTarget.UtilisationTarget ELSE NULL END) utilistationYTDTarget
FROM #UtilisationTarget
WHERE FinYear= @FinYear

GROUP BY [Cascade No]) AS FSPUtTarget
 ON FSPUtTarget.fed_code = FixedSharePartners.fed_code COLLATE DATABASE_DEFAULT



 
LEFT OUTER JOIN 
(
SELECT 
fed_code
,SUM(outstanding_total_bill) AS DebtOver90

FROM red_dw.dbo.fact_debt_daily
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_matter_owner_key=dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_days_banding
 ON dim_days_banding.dim_days_banding_key = fact_debt_daily.dim_days_banding_key
WHERE CONVERT(DATE,debt_date,103)=(CASE WHEN @EndDate=CONVERT(DATE,GETDATE(),103) 
THEN CONVERT(DATE,DATEADD(DAY,-1,@EndDate),103) ELSE @EndDate END)
AND daysbanding='Greater than 90 Days'
GROUP BY fed_code
) AS Debt
 ON Debt.fed_code = FixedSharePartners.fed_code

 ORDER BY Division,Department,FixedSharePartners.fed_code
 END 
GO
