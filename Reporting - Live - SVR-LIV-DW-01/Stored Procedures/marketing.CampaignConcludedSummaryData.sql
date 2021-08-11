SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- ===============================================
-- Author:		Emily Smith
-- Create date: 20210602
-- Description:	#99328, data for new rolling 12 months summary tab
-- ================================================
-- ES 2021-07-01 Removed some campaigns requested by HF
-- ================================================
CREATE PROCEDURE [marketing].[CampaignConcludedSummaryData]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT DISTINCT 
CASE WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%'  THEN 'Building Safer Future'
WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
		OR (
			CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
			AND (
					LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
					LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
				)
			) THEN 'Coronavirus'
WHEN LOWER(is_this_part_of_a_campaign) ='energy get ready' THEN 'Get ready!  Energy in transition'
WHEN LOWER(is_this_part_of_a_campaign) ='industrial and logistics' THEN 'Industrial and Logistics development'
WHEN LOWER(is_this_part_of_a_campaign) ='investment and asset management' THEN 'Investors, Property investment and Asset management'
WHEN LOWER(is_this_part_of_a_campaign) ='private rent schemes (prs)' THEN 'PRS Private Rented Sector'
WHEN LOWER(is_this_part_of_a_campaign) ='supply chain' THEN 'Future of supply chain'
WHEN LOWER(dim_matter_worktype.work_type_name)='healthcare - remedy' THEN 'Healthcare - Remedy'
ELSE is_this_part_of_a_campaign
END AS Campaign
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
--LEFT OUTER JOIN (SELECT Bills.dim_matter_header_curr_key
--				, CASE WHEN Bills.dim_matter_header_curr_key IS NOT NULL THEN 1 ELSE 0 END AS BillFilter
--				FROM red_dw.dbo.dim_matter_header_current
--				LEFT OUTER JOIN 
--				(
--				SELECT DISTINCT dim_matter_header_curr_key FROM red_dw.dbo.fact_bill
--				INNER JOIN red_dw.dbo.dim_bill_date
--				 ON dim_bill_date.dim_bill_date_key = fact_bill.dim_bill_date_key
--				WHERE dim_bill_date.bill_fin_year>=(SELECT bill_fin_year FROM red_dw.dbo.dim_bill_date
--									WHERE CONVERT(DATE,bill_date,103)=CONVERT(DATE,DATEADD(Year,-1,GETDATE()),103))
									
--				) AS Bills
--				 ON Bills.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key ) AS [Bill]
--				 ON Bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE  dim_matter_header_current.reporting_exclusions = 0
AND LOWER(dim_client.client_name) NOT LIKE '%test%'
--AND Bill.BillFilter=1
AND CASE
         WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN
         'Stalking Protection Order'
         WHEN LOWER(work_type_name) LIKE '%cyber%'
         OR LOWER(matter_description) LIKE '%cyber%' THEN
         'Cyber, Privacy & Data'
         WHEN LOWER(work_type_name) LIKE '%gdpr%'
         OR LOWER(matter_description) LIKE '%gdpr%' THEN
         'GDPR'
         WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN
         'Building Safer Future'
         WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
         OR
         (
         CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
         AND
         (
         LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%covid%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%sars%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
         )
         ) THEN
         'Coronavirus'
         WHEN LOWER(is_this_part_of_a_campaign) = 'energy get ready' THEN
         'Get ready!  Energy in transition'
         WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN
         'Industrial and Logistics development'
         WHEN LOWER(is_this_part_of_a_campaign) = 'investment and asset management' THEN
         'Investors, Property investment and Asset management'
         WHEN LOWER(is_this_part_of_a_campaign) = 'private rent schemes (prs)' THEN
         'PRS Private Rented Sector'
         WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN
         'Future of supply chain'
         WHEN LOWER(dim_matter_worktype.work_type_name) = 'healthcare - remedy' THEN
         'Healthcare - Remedy'
         ELSE
         is_this_part_of_a_campaign
         END  IN ('No', 'Pro Bono', 'GDPR', 'Construction','Brexit','Emergency Services Collab', 'Environmental Claims','Industrial and Logistics development','PRS Private Rented Sector','Healthcare Commercial Masterclass') 

GROUP BY CASE
         WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN
         'Stalking Protection Order'
         WHEN LOWER(work_type_name) LIKE '%cyber%'
         OR LOWER(matter_description) LIKE '%cyber%' THEN
         'Cyber, Privacy & Data'
         WHEN LOWER(work_type_name) LIKE '%gdpr%'
         OR LOWER(matter_description) LIKE '%gdpr%' THEN
         'GDPR'
         WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN
         'Building Safer Future'
         WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
         OR
         (
         CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
         AND
         (
         LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%covid%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%sars%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
         )
         ) THEN
         'Coronavirus'
         WHEN LOWER(is_this_part_of_a_campaign) = 'energy get ready' THEN
         'Get ready!  Energy in transition'
         WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN
         'Industrial and Logistics development'
         WHEN LOWER(is_this_part_of_a_campaign) = 'investment and asset management' THEN
         'Investors, Property investment and Asset management'
         WHEN LOWER(is_this_part_of_a_campaign) = 'private rent schemes (prs)' THEN
         'PRS Private Rented Sector'
         WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN
         'Future of supply chain'
         WHEN LOWER(dim_matter_worktype.work_type_name) = 'healthcare - remedy' THEN
         'Healthcare - Remedy'
         ELSE
         is_this_part_of_a_campaign
         END,
         CONCAT(dim_bill_date.bill_cal_month_name, '-', dim_bill_date.bill_cal_year),
         dim_bill_date.bill_fin_year,
         dim_bill_date.bill_fin_month_no,
         dim_bill_date.bill_cal_year,
         dim_bill_date.bill_cal_month_no,
         dim_bill_date.bill_cal_month_name


UNION

SELECT DISTINCT
	CASE WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
	WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
	WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
	WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%'  THEN 'Building Safer Future'
	WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
			OR (
				CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
				AND (
						LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
						LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
					)
				) THEN 'Coronavirus'
	WHEN LOWER(is_this_part_of_a_campaign) ='energy get ready' THEN 'Get ready!  Energy in transition'
	WHEN LOWER(is_this_part_of_a_campaign) ='industrial and logistics' THEN 'Industrial and Logistics development'
	WHEN LOWER(is_this_part_of_a_campaign) ='investment and asset management' THEN 'Investors, Property investment and Asset management'
	WHEN LOWER(is_this_part_of_a_campaign) ='private rent schemes (prs)' THEN 'PRS Private Rented Sector'
	WHEN LOWER(is_this_part_of_a_campaign) ='supply chain' THEN 'Future of supply chain'
	WHEN LOWER(dim_matter_worktype.work_type_name)='healthcare - remedy' THEN 'Healthcare - Remedy'
	ELSE is_this_part_of_a_campaign
	END AS Campaign
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
AND CASE
         WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN
         'Stalking Protection Order'
         WHEN LOWER(work_type_name) LIKE '%cyber%'
         OR LOWER(matter_description) LIKE '%cyber%' THEN
         'Cyber, Privacy & Data'
         WHEN LOWER(work_type_name) LIKE '%gdpr%'
         OR LOWER(matter_description) LIKE '%gdpr%' THEN
         'GDPR'
         WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN
         'Building Safer Future'
         WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
         OR
         (
         CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
         AND
         (
         LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%covid%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%sars%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
         )
         ) THEN
         'Coronavirus'
         WHEN LOWER(is_this_part_of_a_campaign) = 'energy get ready' THEN
         'Get ready!  Energy in transition'
         WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN
         'Industrial and Logistics development'
         WHEN LOWER(is_this_part_of_a_campaign) = 'investment and asset management' THEN
         'Investors, Property investment and Asset management'
         WHEN LOWER(is_this_part_of_a_campaign) = 'private rent schemes (prs)' THEN
         'PRS Private Rented Sector'
         WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN
         'Future of supply chain'
         WHEN LOWER(dim_matter_worktype.work_type_name) = 'healthcare - remedy' THEN
         'Healthcare - Remedy'
         ELSE
         is_this_part_of_a_campaign
         END  IN ('Pro Bono', 'GDPR', 'Construction','Emergency Services Collab', 'Environmental Claims','Industrial and Logistics development','PRS Private Rented Sector','Healthcare Commercial Masterclass')

GROUP BY CASE
         WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN
         'Stalking Protection Order'
         WHEN LOWER(work_type_name) LIKE '%cyber%'
         OR LOWER(matter_description) LIKE '%cyber%' THEN
         'Cyber, Privacy & Data'
         WHEN LOWER(work_type_name) LIKE '%gdpr%'
         OR LOWER(matter_description) LIKE '%gdpr%' THEN
         'GDPR'
         WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN
         'Building Safer Future'
         WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) = 'coronavirus'
         OR
         (
         CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01'
         AND
         (
         LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%covid%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%sars%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%'
         OR LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%'
         )
         ) THEN
         'Coronavirus'
         WHEN LOWER(is_this_part_of_a_campaign) = 'energy get ready' THEN
         'Get ready!  Energy in transition'
         WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN
         'Industrial and Logistics development'
         WHEN LOWER(is_this_part_of_a_campaign) = 'investment and asset management' THEN
         'Investors, Property investment and Asset management'
         WHEN LOWER(is_this_part_of_a_campaign) = 'private rent schemes (prs)' THEN
         'PRS Private Rented Sector'
         WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN
         'Future of supply chain'
         WHEN LOWER(dim_matter_worktype.work_type_name) = 'healthcare - remedy' THEN
         'Healthcare - Remedy'
         ELSE
         is_this_part_of_a_campaign
         END,
         CONCAT(dim_date.cal_month_name, '-', dim_date.cal_year),
         dim_date.fin_year,
         dim_date.fin_month_no,
         dim_date.cal_year,
         dim_date.cal_month_no,
         dim_date.cal_month_name

END
GO
