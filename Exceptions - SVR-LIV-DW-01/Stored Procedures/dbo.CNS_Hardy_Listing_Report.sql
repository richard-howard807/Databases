SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 28-01-2022
-- Description:	New Report for client CNS Hardy #130249
-- =============================================
CREATE PROCEDURE [dbo].[CNS_Hardy_Listing_Report]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;



 
 DROP TABLE IF EXISTS #count
  DROP TABLE IF EXISTS #month_billing


/* this gets the count of new instructions */
SELECT
dim_date_open.cal_year
,dim_date_open.cal_month
, COUNT(*) AS NumberOfInstructions
INTO #count
FROM red_dw.dbo.dim_matter_header_current
LEFT OUTER JOIN red_dw.dbo.dim_date AS dim_date_open ON dim_date_open.calendar_date = CAST(dim_matter_header_current.date_opened_case_management AS DATE)
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE 
red_dw.dbo.dim_matter_header_current.client_code = '00115222'
AND dim_matter_header_current.reporting_exclusions = 0
AND RTRIM(LOWER(ISNULL(dim_detail_outcome.outcome_of_case, ''))) <> 'exclude from reports'
GROUP BY 
dim_date_open.cal_month
,dim_date_open.cal_year

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* this gets revenue */

SELECT 

SUM(fact_bill_matter_detail_summary.fees_total)	AS revenue
, cal_month
, fin_year
INTO #month_billing

FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key = fact_bill_matter_detail_summary.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_matter_detail_summary.dim_matter_header_curr_key
INNER JOIN  red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
WHERE
fact_bill_matter_detail_summary.client_code = '00115222' 
AND dim_matter_header_current.reporting_exclusions = 0
AND RTRIM(LOWER(ISNULL(dim_detail_outcome.outcome_of_case, ''))) <> 'exclude from reports'
--AND dim_date.cal_month = @Month
--AND fin_year  IN('2019','2021','2022')
GROUP BY
cal_month
, fin_year

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
/* add the above two togther */
 
SELECT DISTINCT 
dim_date.cal_month
, dim_date.fin_year
,#count.NumberOfInstructions
,#month_billing.revenue
,cal_month_name
,CASE WHEN CAST(dim_date.fin_year  AS NVARCHAR(50)) = '2021' THEN '2020/2021'
WHEN CAST(dim_date.fin_year AS  NVARCHAR(50)) = '2022' THEN '2021/2022'
ELSE  CAST(dim_date.fin_year AS NVARCHAR(50)) END AS FY
,CAST(dim_date.cal_year AS char(4))+ ' - ' + CAST(cal_month_name as varchar(3)) AS [Display Date]
FROM
red_dw.dbo.dim_date 
LEFT OUTER JOIN  #count ON #count.cal_month = dim_date.cal_month
LEFT OUTER JOIN #month_billing ON #month_billing.cal_month = dim_date.cal_month 
WHERE dim_date.fin_year BETWEEN '2015'AND FORMAT(GETDATE(), 'yyyy') ORDER BY dim_date.cal_month


END
GO
