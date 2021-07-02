SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE PROCEDURE [marketing].[CampaignSummaryDataBrexit]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT DISTINCT is_this_part_of_a_campaign AS Campaign
, dim_bill_date.bill_fin_year AS [Fin Year]
, dim_bill_date.bill_fin_month_no AS [Fin Month No]
, dim_bill_date.bill_cal_year AS [Year]
, dim_bill_date.bill_cal_month_no AS [Month No]
, dim_bill_date.bill_cal_month_name AS [Month Name]
, CONCAT(dim_bill_date.bill_cal_month_name,'-',dim_bill_date.bill_cal_year) AS [Period]
, SUM(bill_amount) AS [Value]
, 'Bill Date' AS [Date Range]

FROM red_dw.dbo.fact_bill_activity
INNER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.bill_date = fact_bill_activity.bill_date
AND dim_bill_date.bill_fin_year>=(SELECT bill_fin_year FROM red_dw.dbo.dim_bill_date
									WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()),103))
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key=fact_bill_activity.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key

WHERE  dim_matter_header_current.reporting_exclusions = 0
AND LOWER(dim_client.client_name) NOT LIKE '%test%'
AND 
(
is_this_part_of_a_campaign='Brexit'
OR LOWER(matter_description) LIKE '%brexit%'
OR LOWER(matter_description) LIKE '%sponsor lic%'
OR LOWER(matter_description) LIKE '%immigration%'
OR LOWER(matter_description) LIKE '%settled status%'
OR LOWER(matter_description) LIKE '%business immigration%'
OR LOWER(matter_description) LIKE '%right to work%'
)
GROUP BY  is_this_part_of_a_campaign
         ,
         CONCAT(dim_bill_date.bill_cal_month_name, '-', dim_bill_date.bill_cal_year),
         dim_bill_date.bill_fin_year,
         dim_bill_date.bill_fin_month_no,
         dim_bill_date.bill_cal_year,
         dim_bill_date.bill_cal_month_no,
         dim_bill_date.bill_cal_month_name


UNION

SELECT DISTINCT is_this_part_of_a_campaign AS Campaign
	, dim_date.fin_year AS [Fin Year]
	, dim_date.fin_month_no AS [Fin Month No]
	, dim_date.cal_year AS [Year]
	, dim_date.cal_month_no AS [Month No]
	, dim_date.cal_month_name AS [Month Name]
	, CONCAT(dim_date.cal_month_name,'-',dim_date.cal_year) AS [Period]
	, COUNT(dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number) AS [Value] 
	, 'Date Opened' AS [Date Range]


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_date
ON dim_date.calendar_date=CAST(dim_matter_header_current.date_opened_case_management AS DATE)
AND dim_date.cal_year>=(SELECT cal_year FROM red_dw.dbo.dim_date
						WHERE CONVERT(DATE,dim_date.calendar_date,103)=CONVERT(DATE,DATEADD(YEAR,-1,GETDATE()),103))
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key

WHERE 
dim_matter_header_current.reporting_exclusions = 0
AND LOWER(dim_client.client_name) NOT LIKE '%test%'
AND 
(
is_this_part_of_a_campaign='Brexit'
OR LOWER(matter_description) LIKE '%brexit%'
OR LOWER(matter_description) LIKE '%sponsor lic%'
OR LOWER(matter_description) LIKE '%immigration%'
OR LOWER(matter_description) LIKE '%settled status%'
OR LOWER(matter_description) LIKE '%business immigration%'
OR LOWER(matter_description) LIKE '%right to work%'
)
GROUP BY          is_this_part_of_a_campaign
         ,
         CONCAT(dim_date.cal_month_name, '-', dim_date.cal_year),
         dim_date.fin_year,
         dim_date.fin_month_no,
         dim_date.cal_year,
         dim_date.cal_month_no,
         dim_date.cal_month_name

END
GO
