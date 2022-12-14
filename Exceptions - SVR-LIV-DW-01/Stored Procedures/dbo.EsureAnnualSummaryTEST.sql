SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[EsureAnnualSummaryTEST]
(
@Year AS INT
)

AS
BEGIN

DECLARE @ClientCode AS NVARCHAR(10)
SET @ClientCode='433281' --433281

SELECT	ReportingPeriods.bill_cal_month_no,
        ReportingPeriods.bill_cal_month_name,
        ReportingPeriods.bill_cal_year,
		--------------------- Volume Snapshot -------------------------
		VolumesSnapshot.Volume - ISNULL([SettledLagDate],0) AS [Volume],
		--------------------- New Instructions ------------------------
		Litigated.NewLitigated AS [New Litigated],
		UnLitigated.NewUnLitigated AS [New UnLitigated],
		ISNULL(Litigated.NewLitigated, 0) + ISNULL(UnLitigated.NewUnLitigated, 0) AS [Total New Cases],
		--------------------- Existing Cases ---------------------------
		LitigatedInMonth AS [Existing Cases Litiaged within Month],
		ALLLitigatedMonth AS [All Litigated within Month],
		--------------------- Case Load Breakdown ----------------------
		VolumesSnapshotTotalLitigated.TotalAllLitigated AS [Total Litigated - All],
		VolumesSnapshotTotalAllUnLitigated.TotalAllUnLitigated AS[Total UnLitigated - All],
		------------------- Settlement Data ----------------------------
		SettledMonth.LitigatedClosed AS [Litigated Closed],
		SettledMonth.UnLitigatedClosed AS [UnLitigated Closed],
		SettledMonth.AllClosed AS [All Closed],
		SettledMonth.AverageDaysToConclude AS [Average Settlement Days],
		
        --------------------- INVOICING --------------------------------
		Financials.TotalBilled,
        Financials.RevenueExcVat,
		Financials.RevenueVat,
        Financials.Disbursements,
        Financials.VAT,
        Financials.RevenueBilledIncVat,
        Financials.PartnerBilled,
        Financials.NonPartnerBilled,
        Financials.AverageRevenue,
        Financials.[No Cases Billed]	
FROM 
(SELECT  DISTINCT bill_cal_month_no,bill_cal_month_name,bill_cal_year FROM red_dw.dbo.dim_bill_date
WHERE bill_cal_year=@Year
) AS ReportingPeriods
----------------------------------------------------------
LEFT OUTER JOIN 
(
SELECT bill_cal_month_no,bill_cal_year,COUNT(CASE WHEN [Date Claim Concluded] IS NULL THEN 1 ELSE 0 END) AS Volume
--,SUM(CASE WHEN ProceedingsIssued='Y' OR [Date ProceedingsIssued] IS NOT NULL THEN 1 ELSE 0 END) AS TotalAllLitigated
,SUM(CASE WHEN ISNULL(ProceedingsIssued, 'N') <>'Yes' OR [Date ProceedingsIssued] IS NULL THEN 1 ELSE 0 END) AS TotalAllUnLitigated
FROM dbo.EnsureHistoryData
GROUP BY bill_cal_month_no,bill_cal_year
) AS VolumesSnapshot
 ON VolumesSnapshot.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND VolumesSnapshot.bill_cal_year = ReportingPeriods.bill_cal_year


 /*Total UnLitigated*/

 LEFT OUTER JOIN 
(
  SELECT DISTINCT 
 
 cal_month_no, 
 cal_year,
 TotalAllUnLitigated = MAX(xx.TotalAllUnLitigated) OVER (ORDER BY cal_year, cal_month_no )

 FROM red_dw.dbo.dim_date

LEFT JOIN 
(

 SELECT DISTINCT x.bill_cal_month_no, x.bill_cal_year, 
[TotalAllUnLitigated]= MAX(x.TotalAllUnLitigated) OVER (PARTITION BY x. bill_cal_month_no, x.bill_cal_year)  - ISNULL(Settled.CountSettled, 0)

FROM
(
 SELECT MONTH([Date Opened]) bill_cal_month_no , YEAR([Date Opened]) bill_cal_year
,SUM(1) OVER (ORDER BY [Date Opened]) TotalAllUnLitigated
FROM dbo.EnsureHistoryData
WHERE (ISNULL(ProceedingsIssued, 'N') <>'Yes' AND  [Date ProceedingsIssued] IS NULL)
GROUP BY MONTH([Date Opened]), YEAR([Date Opened]) , [Date Opened]
 ) x

 LEFT JOIN 
( SELECT DISTINCT MONTH([Date Claimants Costs Settled]) SettledMonth , 
 YEAR([Date Claimants Costs Settled]) SettledYear, COUNT(DISTINCT master_matter_number) AS CountSettled
 FROM dbo.EnsureHistoryData
 WHERE [Date Claimants Costs Settled] IS NOT NULL 
 AND (ISNULL(ProceedingsIssued, 'N') <>'Yes' AND  [Date ProceedingsIssued] IS NULL)
 GROUP BY 
 MONTH([Date Claimants Costs Settled]),
 YEAR([Date Claimants Costs Settled])  
 
 ) Settled ON Settled.SettledYear = x.bill_cal_year
 AND Settled.SettledMonth = x.bill_cal_month_no
 
 ) xx ON dim_date.cal_year = xx.bill_cal_year AND  xx.bill_cal_month_no = cal_month_no
 
 WHERE calendar_date BETWEEN '2020-01-01' AND GETDATE()
 ) VolumesSnapshotTotalAllUnLitigated
 ON VolumesSnapshotTotalAllUnLitigated.cal_month_no = ReportingPeriods.bill_cal_month_no
 AND VolumesSnapshotTotalAllUnLitigated.cal_year = ReportingPeriods.bill_cal_year



/*Total Litigated*/

-- LEFT JOIN 
-- (
-- SELECT MONTH([Date Opened]) bill_cal_month_no , YEAR([Date Opened]) bill_cal_year
--,SUM(1) OVER (ORDER BY [Date Opened] ASC) TotalAllLitigated
--FROM dbo.EnsureHistoryData
--WHERE ProceedingsIssued='Yes' OR [Date ProceedingsIssued] IS NOT NULL
--GROUP BY MONTH([Date Opened]), YEAR([Date Opened]) , [Date Opened]
--) AS VolumesSnapshotTotalLitigated
-- ON VolumesSnapshotTotalLitigated.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
-- AND VolumesSnapshotTotalLitigated.bill_cal_year = ReportingPeriods.bill_cal_year

 LEFT JOIN 
 (
  SELECT 
 x.cal_month_no, 
 x.cal_year,
 [TotalAllLitigated] = TotalAllLitigated - ISNULL(x.SetlledCount, 0)

FROM 

(

  SELECT DISTINCT 
 
 cal_month_no, 
 cal_year,
 TotalAllLitigated = MAX(xx.TotalAllLitigated) OVER (ORDER BY cal_year, cal_month_no )
 ,SetlledCount = MAX(Settled.CountSettled) OVER (ORDER BY cal_year, cal_month_no )
 FROM red_dw.dbo.dim_date

LEFT JOIN 
 (
 SELECT MONTH([Date Opened]) bill_cal_month_no , YEAR([Date Opened]) bill_cal_year
,SUM(1) OVER (ORDER BY [Date Opened] ASC) TotalAllLitigated
FROM dbo.EnsureHistoryData
WHERE ProceedingsIssued='Yes' OR [Date ProceedingsIssued] IS NOT NULL
GROUP BY MONTH([Date Opened]), YEAR([Date Opened]) , [Date Opened]

 ) xx ON dim_date.cal_year = xx.bill_cal_year AND  xx.bill_cal_month_no = cal_month_no

 LEFT JOIN 
 (

SELECT DISTINCT  
 
 MONTH(date_claim_concluded) SettledMonth , 
 YEAR(date_claim_concluded) SettledYear, 
 
 COUNT(DISTINCT master_matter_number) AS CountSettled
 FROM red_dw.dbo.dim_matter_header_current
 JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
 LEFT JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
  
 WHERE 1= 1 
 AND dim_matter_header_current.master_client_code = @ClientCode
 AND ( proceedings_issued='Yes' OR date_proceedings_issued IS NOT NULL)
 AND date_claim_concluded IS NOT NULL 
 GROUP BY 
 MONTH(date_claim_concluded) , 
 YEAR(date_claim_concluded) 


 ) Settled ON Settled.SettledMonth = cal_month_no AND Settled.SettledYear = cal_year
  WHERE calendar_date BETWEEN '2020-01-01' AND GETDATE()

  ) x
) AS VolumesSnapshotTotalLitigated
 ON VolumesSnapshotTotalLitigated.cal_month_no = ReportingPeriods.bill_cal_month_no
 AND VolumesSnapshotTotalLitigated.cal_year = ReportingPeriods.bill_cal_year



 /*Settled Lag Date for Total */

 LEFT JOIN 

 (
 SELECT 
 x.cal_month_no, 
 x.cal_year,
[SettledLagDate] = LAG(ISNULL(x.SetlledCount, 0)) OVER (ORDER BY x.cal_year,x.cal_month_no) 
FROM 
(
  SELECT DISTINCT 
 
 cal_month_no, 
 cal_year,
 SetlledCount = MAX(Settled.CountSettled) OVER (ORDER BY cal_year, cal_month_no )
 FROM red_dw.dbo.dim_date

 LEFT JOIN 
 (
SELECT DISTINCT  
 
 MONTH(date_claim_concluded) SettledMonth , 
 YEAR(date_claim_concluded) SettledYear, 
 
 COUNT(DISTINCT master_matter_number) AS CountSettled
 FROM red_dw.dbo.dim_matter_header_current
 JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
 LEFT JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
  
 WHERE 1= 1 
 AND dim_matter_header_current.master_client_code = @ClientCode
 AND date_claim_concluded IS NOT NULL 
 GROUP BY 
 MONTH(date_claim_concluded) , 
 YEAR(date_claim_concluded) 


 ) Settled ON Settled.SettledMonth = cal_month_no AND Settled.SettledYear = cal_year
  WHERE calendar_date BETWEEN '2020-01-01' AND GETDATE()

  ) x
 ) Lagsettleddate 
 ON Lagsettleddate.cal_month_no = ReportingPeriods.bill_cal_month_no
 AND Lagsettleddate.cal_year = ReportingPeriods.bill_cal_year
-------------------------------------------------------------------
LEFT OUTER JOIN 
(
SELECT MONTH(date_opened_case_management) AS bill_cal_month_no
,YEAR(date_opened_case_management) AS bill_cal_year
,COUNT(1) AS NewInstructions
,SUM(CASE WHEN CAST(MONTH(date_proceedings_issued) AS NVARCHAR(5)) +'-' + CAST(YEAR(date_proceedings_issued) AS NVARCHAR(5))= CAST(MONTH(date_opened_case_management) AS NVARCHAR(5)) + '-' +CAST(YEAR(date_opened_case_management) AS NVARCHAR(5)) THEN 1 ELSE 0 END)  AS NewLitigated
,COUNT(1) - SUM(CASE WHEN date_proceedings_issued=date_opened_case_management THEN 1 ELSE 0 END) AS NewUnLitigated
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND date_opened_case_management>='2020-12-01'
AND dim_matter_header_current.matter_number <>'00000011'
GROUP BY MONTH(date_opened_case_management) 
,YEAR(date_opened_case_management)
) AS NewInstructions
 ON NewInstructions.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND NewInstructions.bill_cal_year = ReportingPeriods.bill_cal_year
-------------------------------------------------------------------
LEFT OUTER JOIN 
(
SELECT MONTH(date_proceedings_issued) AS bill_cal_month_no
,YEAR(date_proceedings_issued) AS bill_cal_year
,COUNT(1) AS LitigatedInMonth
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND dim_matter_header_current.matter_number <>'00000011'
AND date_proceedings_issued IS NOT NULL
AND date_proceedings_issued > date_opened_case_management
AND date_opened_case_management>='2020-12-01'
GROUP BY MONTH(date_proceedings_issued) 
,YEAR(date_proceedings_issued)
) AS LitigatedMonth
 ON LitigatedMonth.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND LitigatedMonth.bill_cal_year = ReportingPeriods.bill_cal_year
-------------------------------------------------------------------------


LEFT OUTER JOIN 
(
SELECT MONTH(date_proceedings_issued) AS bill_cal_month_no
,YEAR(date_proceedings_issued) AS bill_cal_year
,COUNT(1) AS ALLLitigatedMonth
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND dim_matter_header_current.matter_number <>'00000011'
AND date_proceedings_issued IS NOT NULL
AND date_opened_case_management>='2020-12-01'
GROUP BY MONTH(date_proceedings_issued) 
,YEAR(date_proceedings_issued)
) AS ALLLitigatedMonth
 ON ALLLitigatedMonth.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND ALLLitigatedMonth.bill_cal_year = ReportingPeriods.bill_cal_year


LEFT OUTER JOIN 
(
SELECT MONTH(date_claim_concluded) AS bill_cal_month_no
,YEAR(date_claim_concluded) AS bill_cal_year
,COUNT(1) AS AllClosed
,SUM(CASE WHEN proceedings_issued='Yes' THEN 1 ELSE 0 END) AS LitigatedClosed
,SUM(CASE WHEN ISNULL(proceedings_issued,'')<>'Yes' THEN 1 ELSE 0 END) AS UnLitigatedClosed
,AVG(DATEDIFF(DAY,date_opened_case_management,date_claim_concluded)) AS AverageDaysToConclude
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND dim_matter_header_current.matter_number <>'00000011'
AND date_claim_concluded IS NOT NULL
AND date_opened_case_management>='2020-12-01'
GROUP BY MONTH(date_claim_concluded) 
,YEAR(date_claim_concluded)
) AS SettledMonth
 ON SettledMonth.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND SettledMonth.bill_cal_year = ReportingPeriods.bill_cal_year
 --------------------------------------------------------------------------------------
 /* New Litigated */
 LEFT JOIN 

 (SELECT 

MONTH(date_opened_case_management) AS bill_cal_month_no
,YEAR(date_opened_case_management) AS bill_cal_year
,SUM(CASE WHEN date_proceedings_issued IS NOT NULL  THEN 1 ELSE 0 END) AS NewLitigated
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND date_opened_case_management>='2020-12-01'
AND dim_matter_header_current.matter_number <> '00000011'
AND date_proceedings_issued IS NOT NULL 
GROUP BY MONTH(date_opened_case_management) 
,YEAR(date_opened_case_management))
 Litigated ON 
 Litigated.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND Litigated.bill_cal_year = ReportingPeriods.bill_cal_year

 /* New UnLitigated */
  LEFT JOIN 

 (SELECT 

MONTH(date_opened_case_management) AS bill_cal_month_no
,YEAR(date_opened_case_management) AS bill_cal_year
,SUM(CASE WHEN date_proceedings_issued IS NULL  THEN 1 ELSE 0 END) AS NewUnLitigated
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE master_client_code=@ClientCode
AND date_opened_case_management>='2020-12-01'
AND dim_matter_header_current.matter_number <> '00000011'
AND date_proceedings_issued IS NULL 
GROUP BY MONTH(date_opened_case_management) 
,YEAR(date_opened_case_management))
 UnLitigated ON 
 UnLitigated.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND UnLitigated.bill_cal_year = ReportingPeriods.bill_cal_year


LEFT OUTER JOIN 
(
SELECT	bill_cal_month_no
        ,bill_cal_month_name
        ,bill_cal_year
		,SUM(bill_total) AS TotalBilled
		,SUM(fees_total) AS RevenueExcVat
		,SUM(RevenueTotalIncVat) AS RevenueTotalIncVat
		,SUM(paid_disbursements) + SUM(unpaid_disbursements)  AS Disbursements
		,SUM(vat_amount) AS VAT
		,SUM(PartnerBilled) +SUM(PartnerHrs.NonPartnerBilled) AS RevenueBilledIncVat
		,SUM(PartnerHrs.RevenueVat) AS RevenueVat
		,SUM(PartnerBilled) AS PartnerBilled
		,SUM(NonPartnerBilled) AS NonPartnerBilled
		,AVG(RevenueTotalIncVat) AS AverageRevenue
		,COUNT(DISTINCT	dim_matter_header_current.dim_matter_header_curr_key) AS [No Cases Billed]

FROM red_dw.dbo.fact_bill
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill.dim_bill_key
LEFT OUTER JOIN 
(
SELECT fact_bill_detail.dim_bill_key
,SUM(CASE WHEN UPPER(jobtitle) LIKE 'PARTNER' THEN bill_total ELSE 0 END) AS PartnerBilled
,SUM(CASE WHEN UPPER(jobtitle) NOT LIKE 'PARTNER' THEN bill_total ELSE 0 END) AS NonPartnerBilled
,SUM(vat_amount) AS RevenueVat
,SUM(bill_total) AS RevenueTotalIncVat
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill
 ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_detail.dim_fed_hierarchy_history_key
WHERE master_client_code=@ClientCode
AND dim_matter_header_current.matter_number <>'00000011'
AND charge_type='time'
AND bill_reversed=0
AND date_opened_case_management>='2020-12-01'

GROUP BY fact_bill_detail.dim_bill_key
) AS PartnerHrs
 ON PartnerHrs.dim_bill_key = fact_bill.dim_bill_key

WHERE master_client_code=@ClientCode
AND bill_reversed=0
--
GROUP BY bill_cal_month_no,
        bill_cal_month_name,
        bill_cal_year
) AS Financials
 ON Financials.bill_cal_month_no = ReportingPeriods.bill_cal_month_no
 AND Financials.bill_cal_year = ReportingPeriods.bill_cal_year 


 END
GO
