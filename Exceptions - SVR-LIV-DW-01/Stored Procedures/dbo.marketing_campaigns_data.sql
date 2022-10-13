SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego	
-- Create date: 2019-01-03
-- Description:	
/*
Stacey Damigos needs a new report to sit under Marketing to capture the revenue on some of the campaigns she is working on. the report needs to show:
Cyber - where either worktype or matter description contain "cyber"
GDPR - where either worktype or matter description contain "gdpr"
Construction - where worktype contains "construction"
Brain Injury - where injury type contains "brain"
the fields we need to see are:
Campaign (taken from list above) Weightmans ref, matter description, Case manager, Team manager, worktype, date opened, date closed, revenue, client name
she ideally needs to be able to filter the whole report to show revenue within a specific period.
*/

--ES 2019-11-14 39032
-- =============================================
CREATE PROCEDURE [dbo].[marketing_campaigns_data] --'2019-01-01','2019-11-15','Cyber, Privacy & Data'
(
@DateFrom DATE,
@DateTo DATE,
@Campaign VARCHAR(MAX)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT ListValue  INTO #Campaign FROM Reporting.dbo.[udt_TallySplit]('|', @Campaign)

SELECT 
CASE
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Construction'
ELSE is_this_part_of_a_campaign
END Campaign,
dim_client.client_code,
dim_client.client_name,
dim_matter_header_current.matter_number,
matter_description,
name,
worksforname,
work_type_name,
date_opened_case_management,
date_closed_case_management,
bill_amount,
injury_type,
brief_description_of_injury,
is_this_part_of_a_campaign,
wip
FROM red_Dw.dbo.fact_dimension_main
LEFT join red_Dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN 
(
SELECT master_fact_key, SUM(bill_amount) bill_amount
FROM red_dw.dbo.fact_bill_activity
WHERE bill_date >= @DateFrom AND bill_date <= @DateTo
GROUP BY master_fact_key) fact_bill_activity ON fact_bill_activity.master_fact_key = fact_dimension_main.master_fact_key

INNER JOIN #Campaign AS Campaign ON Campaign.ListValue COLLATE DATABASE_DEFAULT = CASE
WHEN LOWER(work_type_name) LIKE '%cyber%' OR LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber'
WHEN LOWER(work_type_name) LIKE '%gdpr%' OR LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR'
WHEN LOWER(work_type_name) LIKE '%prof risk - construction - contentious%'  THEN 'Construction'
ELSE is_this_part_of_a_campaign
END COLLATE DATABASE_DEFAULT


ORDER BY dim_client.client_code, dim_matter_header_current.matter_number

END
GO
