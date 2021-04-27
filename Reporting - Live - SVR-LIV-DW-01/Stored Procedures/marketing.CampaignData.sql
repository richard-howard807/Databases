SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [marketing].[CampaignData]
(
@DateFrom AS DATE
,@DateTo AS DATE
,@Campaign AS NVARCHAR(100)
)
AS

BEGIN

DROP TABLE IF EXISTS #Campaign
SELECT ListValue  INTO #Campaign FROM Reporting.dbo.[udt_TallySplit]('|', @Campaign)

SELECT 
CASE
WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
--WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Building Safer Future' -- removed #90349
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
ELSE is_this_part_of_a_campaign
END Campaign,
dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number	AS [Mattersphere Weightmans Reference],
RTRIM(dim_client.client_code) client_code,
dim_client.client_name,
dim_client.segment		AS [Client Segment],
dim_client.sector		AS [Client Sector],
dim_matter_header_current.matter_number,
matter_description,
name,
worksforname,
dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team],
dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department],
work_type_name,
date_opened_case_management,
date_closed_case_management,
bill_amount,
injury_type,
brief_description_of_injury,
is_this_part_of_a_campaign
,wip
, CASE WHEN RTRIM(dim_client.client_code)+'-'+dim_matter_header_current.matter_number 
			IN ('00350490-00000035'
				,'00350490-00000036'
				,'00350490-00000038'
				,'00733225-00000563'
				,'G00016-11111136'
				,'G00016-11111137'
				,'G00016-11111138'
				,'G00016-11111139'
				,'G00016-11111141'
				,'T2002-00000394'
				,'T2002-00000406'
				,'T2002-00000408'
				,'T2002-00000411'
				,'T2002-00000412'
				,'T2002-00000413'
				,'T2002-00000414'
				,'T2002-00000423'
				,'W19286-00000013'
				,'T2002-00000438'
                ,'W23719-00000001'
                ,'W23745-00000001'
                ,'G00016-11111147'
                ,'119698R-00000033'
                ,'G00016-11111146'
                ,'00350490-00000042'
                ,'00733225-00000987'
                ,'119698R-00000035'
                ,'00247515-00000067'
                ,'T2002-00000442'
                ,'T2002-00000445'
				,'00350490-00000041'
				,'00350490-00000030'
                ,'T2002-00000379'
                ,'119698R-00000029'
                ,'119698R-00000030'
                ,'G00016-11111143'
                ,'G00016-11111134'
                ,'T2002-00000427'
                ,'00733225-00000713'
                ,'Z1001-00081930'
				)
				THEN 'Grey' ELSE 'Transparent' END AS [Background Colour]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)															AS [Revenue Billed Excl VAT]
	, ISNULL(fact_finance_summary.disbursements_billed, 0)															AS [Disbursments Excl VAT]
	, ISNULL(fact_finance_summary.defence_costs_vat, 0) 
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)											AS [Total VAT Billed]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0)
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)
			+ ISNULL(fact_finance_summary.defence_costs_vat, 0)														AS [Total Amount Billed]
	, 'Date Opened' AS [Date Range]		
			
			FROM red_Dw.dbo.fact_dimension_main
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

LEFT JOIN 
(
SELECT master_fact_key, SUM(bill_amount) bill_amount
FROM red_dw.dbo.fact_bill_activity
WHERE bill_date >= @DateFrom AND bill_date <= @DateTo
GROUP BY master_fact_key) fact_bill_activity ON fact_bill_activity.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN #Campaign AS Campaign ON Campaign.ListValue COLLATE DATABASE_DEFAULT = CASE
WHEN is_this_part_of_a_campaign IS NOT NULL THEN is_this_part_of_a_campaign
WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
--WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Building Safer Future'
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


ELSE is_this_part_of_a_campaign
END


WHERE 
(date_opened_case_management >= @DateFrom AND date_opened_case_management <= @DateTo) 

AND dim_matter_header_current.reporting_exclusions = 0

AND LOWER(dim_client.client_name) NOT LIKE '%test%'


UNION

SELECT 
CASE
WHEN is_this_part_of_a_campaign IS NOT NULL THEN is_this_part_of_a_campaign
WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
--WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Building Safer Future' removed #90349
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


ELSE is_this_part_of_a_campaign
END Campaign,
dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number	AS [Mattersphere Weightmans Reference],
RTRIM(dim_client.client_code) client_code,
dim_client.client_name,
dim_client.segment		AS [Client Segment],
dim_client.sector		AS [Client Sector],
dim_matter_header_current.matter_number,
matter_description,
name,
worksforname,
dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team],
dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department],
work_type_name,
date_opened_case_management,
date_closed_case_management,
bill_amount,
injury_type,
brief_description_of_injury,
is_this_part_of_a_campaign
,wip
, CASE WHEN RTRIM(dim_client.client_code)+'-'+dim_matter_header_current.matter_number 
			IN ('00350490-00000035'
				,'00350490-00000036'
				,'00350490-00000038'
				,'00733225-00000563'
				,'G00016-11111136'
				,'G00016-11111137'
				,'G00016-11111138'
				,'G00016-11111139'
				,'G00016-11111141'
				,'T2002-00000394'
				,'T2002-00000406'
				,'T2002-00000408'
				,'T2002-00000411'
				,'T2002-00000412'
				,'T2002-00000413'
				,'T2002-00000414'
				,'T2002-00000423'
				,'W19286-00000013'
				,'T2002-00000438'
                ,'W23719-00000001'
                ,'W23745-00000001'
                ,'G00016-11111147'
                ,'119698R-00000033'
                ,'G00016-11111146'
                ,'00350490-00000042'
                ,'00733225-00000987'
                ,'119698R-00000035'
                ,'00247515-00000067'
                ,'T2002-00000442'
                ,'T2002-00000445'
				,'00350490-00000041'
				,'00350490-00000030'
                ,'T2002-00000379'
                ,'119698R-00000029'
                ,'119698R-00000030'
                ,'G00016-11111143'
                ,'G00016-11111134'
                ,'T2002-00000427'
                ,'00733225-00000713'
                ,'Z1001-00081930'
				)
				THEN 'Grey' ELSE 'Transparent' END AS [Background Colour]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)															AS [Revenue Billed Excl VAT]
	, ISNULL(fact_finance_summary.disbursements_billed, 0)															AS [Disbursments Excl VAT]
	, ISNULL(fact_finance_summary.defence_costs_vat, 0) 
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)											AS [Total VAT Billed]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.disbursements_billed, 0)
		+ ISNULL(fact_finance_summary.total_billed_disbursements_vat, 0)
			+ ISNULL(fact_finance_summary.defence_costs_vat, 0)														AS [Total Amount Billed]
	, 'Bill Date' AS [Date Range]				
			
			FROM red_Dw.dbo.fact_dimension_main
LEFT JOIN red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

LEFT JOIN 
(
SELECT master_fact_key, SUM(bill_amount) bill_amount
FROM red_dw.dbo.fact_bill_activity
WHERE bill_date >= @DateFrom AND bill_date <= @DateTo
GROUP BY master_fact_key) fact_bill_activity ON fact_bill_activity.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN #Campaign AS Campaign ON Campaign.ListValue COLLATE DATABASE_DEFAULT = CASE
WHEN is_this_part_of_a_campaign IS NOT NULL THEN is_this_part_of_a_campaign
WHEN LOWER(work_type_name) LIKE'%stalking protection order%' THEN 'Stalking Protection Order'
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
--WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Building Safer Future'
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


ELSE is_this_part_of_a_campaign
END

LEFT OUTER JOIN (SELECT DISTINCT Bills.dim_matter_header_curr_key
				, CASE WHEN Bills.dim_matter_header_curr_key IS NOT NULL THEN 1 ELSE 0 END AS BillFilter
				FROM red_dw.dbo.dim_matter_header_current
				LEFT OUTER JOIN 
				(
				SELECT DISTINCT dim_matter_header_curr_key FROM red_dw.dbo.fact_bill_activity
				INNER JOIN red_dw.dbo.dim_bill_date
				 ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
				WHERE dim_bill_date.bill_date BETWEEN @DateFrom AND @DateTo
				) AS Bills
				 ON Bills.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key ) AS [Bill]
				 ON Bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE 
Bill.BillFilter=1

AND dim_matter_header_current.reporting_exclusions = 0

AND LOWER(dim_client.client_name) NOT LIKE '%test%'

END
GO
