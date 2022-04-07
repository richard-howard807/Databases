SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-01-06
-- Description:	#122977 New DTD report (Digital, Technology and Data), summary report
-- =============================================
CREATE PROCEDURE [dbo].[DTDSummary]
	
AS
BEGIN
	
	SET NOCOUNT ON;



SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Mattter Number]
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_client.segment AS [Segment]
, dim_client.sector AS [Sector]
, dim_client.sub_sector AS [Sub Sector]
, dim_detail_core_details.insured_sector AS [Insured Sector]
, dim_matter_header_current.client_name AS [Client Name]
, dim_client_involvement.insuredclient_name AS [Insured Client Name]
, dim_detail_core_details.is_this_part_of_a_campaign AS [Campaign]
, dim_matter_worktype.work_type_name AS [Matter Type]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
, fact_finance_summary.total_amount_billed AS [Total Billed]
, fact_finance_summary.defence_costs_billed AS [Revenue]
, fact_finance_summary.disbursements_billed AS [Disbursements Billed]
, fact_finance_summary.vat_billed AS [VAT]
, fact_matter_summary_current.last_bill_date AS [Date of Last Bill Date]
, fact_finance_summary.wip AS [WIP]
, fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
, 'FY '+CAST(dim_date.fin_year AS VARCHAR(4)) AS [Financial Year]
, dim_date.fin_period AS [Period]
, 1 AS [Measure]
, 'Instructions' AS Level

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON CAST(dim_matter_header_current.date_opened_case_management AS date)=CAST(dim_date.calendar_date AS date)
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND (dim_detail_core_details.insured_sector='Digital/New Media'
OR dim_client.sub_sector='Digital/media'
OR dim_detail_core_details.is_this_part_of_a_campaign='Digital, Technology and Data (DTD)'
OR dim_matter_worktype.work_type_name IN ('Specialty: Professions: Digital'
											,'Intellectual property'
											,'Education - FOIA and DPA'
											,'Education - IP (Due Diligence)'
											,'Data Protection'
											,'Direct Selling'
											,'GDPR'
											,'Non-contentious IP & IT Contracts')
)
AND NOT LOWER(dim_matter_worktype.work_type_name) LIKE '%cyber%'

AND dim_matter_header_current.date_opened_case_management>='2020-05-01'

UNION
--matters that sean and nicola have recorded revenue on
SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Mattter Number]
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_client.segment AS [Segment]
, dim_client.sector AS [Sector]
, dim_client.sub_sector AS [Sub Sector]
, dim_detail_core_details.insured_sector AS [Insured Sector]
, dim_matter_header_current.client_name AS [Client Name]
, dim_client_involvement.insuredclient_name AS [Insured Client Name]
, dim_detail_core_details.is_this_part_of_a_campaign AS [Campaign]
, dim_matter_worktype.work_type_name AS [Matter Type]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
, fact_finance_summary.total_amount_billed AS [Total Billed]
, fact_finance_summary.defence_costs_billed AS [Revenue]
, fact_finance_summary.disbursements_billed AS [Disbursements Billed]
, fact_finance_summary.vat_billed AS [VAT]
, fact_matter_summary_current.last_bill_date AS [Date of Last Bill Date]
, fact_finance_summary.wip AS [WIP]
, fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
, 'FY '+CAST(dim_date.fin_year AS VARCHAR(4)) AS [Financial Year]
, dim_date.fin_period AS [Period]
, 1 AS [Measure]
, 'Instructions' AS Level

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_date
ON CAST(dim_matter_header_current.date_opened_case_management AS date)=CAST(dim_date.calendar_date AS date)
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
--AND ISNULL(dim_detail_core_details.insured_sector,'')<>'Digital/New Media'
--AND ISNULL(dim_client.sub_sector,'')<>'Digital/media'
--AND ISNULL(dim_detail_core_details.is_this_part_of_a_campaign,'')<>'Digital, Technology and Data (DTD)'
--AND ISNULL(dim_matter_worktype.work_type_name,'') NOT IN ('Specialty: Professions: Digital'
--											,'Intellectual property'
--											,'Education - FOIA and DPA'
--											,'Education - IP (Due Diligence)'
--											,'Data Protection'
--											,'Direct Selling'
--											,'GDPR'
--											,'Non-contentious IP & IT Contracts')

AND dim_matter_header_current.dim_matter_header_curr_key IN (SELECT DISTINCT fact_bill_activity.dim_matter_header_curr_key
														FROM red_dw.dbo.fact_bill_activity
														LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
														ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
														WHERE dim_fed_hierarchy_history.name IN ('Sean Crotty','Nicola Gonnella'))


AND dim_matter_header_current.date_opened_case_management>='2020-05-01'

UNION

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Mattter Number]
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_client.segment AS [Segment]
, dim_client.sector AS [Sector]
, dim_client.sub_sector AS [Sub Sector]
, dim_detail_core_details.insured_sector AS [Insured Sector]
, dim_matter_header_current.client_name AS [Client Name]
, dim_client_involvement.insuredclient_name AS [Insured Client Name]
, dim_detail_core_details.is_this_part_of_a_campaign AS [Campaign]
, dim_matter_worktype.work_type_name AS [Matter Type]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
, SUM(fact_bill_activity.bill_total) AS [Total Billed]
, SUM(fact_bill_activity.bill_amount) AS [Revenue]
, SUM(fact_bill_activity.payed_disbursement) AS [Disbursements Billed]
, SUM(fact_bill_activity.vat_amount) AS [VAT]
, fact_matter_summary_current.last_bill_date AS [Date of Last Bill Date]
, fact_matter_summary_current.wip_balance AS [WIP]
, SUM(fact_bill_activity.unpaid_disbursement) AS [Unbilled Disbursements]
, 'FY '+CAST(dim_bill_date.bill_fin_year AS VARCHAR(4)) AS [Financial Year]
, dim_bill_date.bill_fin_period AS [Period]
, SUM(fact_bill_activity.bill_amount) AS [Measure]
, 'Revenue' AS Level
 
FROM red_dw.dbo.fact_bill_activity
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key = fact_bill_activity.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [FeeEarner]
ON [FeeEarner].dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
--AND [FeeEarner].name IN ('Sean Crotty')--,'Nicola Gonnella')
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND (dim_detail_core_details.insured_sector='Digital/New Media'
OR dim_client.sub_sector='Digital/media'
OR dim_detail_core_details.is_this_part_of_a_campaign='Digital, Technology and Data (DTD)'
OR dim_matter_worktype.work_type_name IN ('Specialty: Professions: Digital'
											,'Intellectual property'
											,'Education - FOIA and DPA'
											,'Education - IP (Due Diligence)'
											,'Data Protection'
											,'Direct Selling'
											,'GDPR'
											,'Non-contentious IP & IT Contracts')
)
AND NOT LOWER(dim_matter_worktype.work_type_name) LIKE '%cyber%'
AND dim_bill_date.bill_date>='2020-05-01'

--AND dim_bill_date.bill_fin_period='2022-11 (Mar-2022)'

GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
         dim_matter_header_current.matter_description,
         dim_matter_header_current.date_opened_case_management,
         dim_matter_header_current.date_closed_case_management,
         dim_matter_header_current.matter_owner_full_name,
         dim_fed_hierarchy_history.hierarchylevel2hist,
         dim_fed_hierarchy_history.hierarchylevel3hist,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         dim_client.segment,
         dim_client.sector,
         dim_client.sub_sector,
         dim_detail_core_details.insured_sector,
         dim_matter_header_current.client_name,
         dim_client_involvement.insuredclient_name,
         dim_detail_core_details.is_this_part_of_a_campaign,
         dim_matter_worktype.work_type_name,
         dim_detail_finance.output_wip_fee_arrangement,
         fact_matter_summary_current.last_bill_date,
         fact_matter_summary_current.wip_balance,
         dim_bill_date.bill_fin_year,
         dim_bill_date.bill_fin_period


UNION

-- revenue billed by sean and nicola
SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Mattter Number]
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Closed]
, dim_matter_header_current.matter_owner_full_name AS [Case Manager]
, dim_fed_hierarchy_history.hierarchylevel2hist AS [Division]
, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
, dim_client.segment AS [Segment]
, dim_client.sector AS [Sector]
, dim_client.sub_sector AS [Sub Sector]
, dim_detail_core_details.insured_sector AS [Insured Sector]
, dim_matter_header_current.client_name AS [Client Name]
, dim_client_involvement.insuredclient_name AS [Insured Client Name]
, dim_detail_core_details.is_this_part_of_a_campaign AS [Campaign]
, dim_matter_worktype.work_type_name AS [Matter Type]
, dim_detail_finance.output_wip_fee_arrangement AS [Fee Arrangement]
, SUM(bill_total) AS [Total Amount Billed]
, SUM(fact_bill_activity.bill_amount) AS [Revenue]
, SUM(fact_bill_activity.payed_disbursement) AS [Disbursements Billed]
, SUM(fact_bill_activity.vat_amount) AS [VAT]
, fact_matter_summary_current.last_bill_date AS [Date of Last Bill Date]
, fact_matter_summary_current.wip_balance AS [WIP]
, SUM(fact_bill_activity.unpaid_disbursement) AS [Unbilled Disbursements]
, 'FY '+CAST(dim_bill_date.bill_fin_year AS VARCHAR(4)) AS [Financial Year]
, dim_bill_date.bill_fin_period AS [Period]
, SUM(fact_bill_activity.bill_amount) AS [Measure]
, 'Revenue' AS Level
 
FROM red_dw.dbo.fact_bill_activity
LEFT OUTER JOIN red_dw.dbo.dim_bill_date
ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.fact_dimension_main
ON fact_dimension_main.master_fact_key = fact_bill_activity.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [FeeEarner]
ON [FeeEarner].dim_fed_hierarchy_history_key = fact_bill_activity.dim_fed_hierarchy_history_key
AND [FeeEarner].name IN ('Sean Crotty','Nicola Gonnella')
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_bill_date.bill_date>='2020-05-01'
--AND ISNULL(dim_detail_core_details.insured_sector,'')<>'Digital/New Media'
--AND ISNULL(dim_client.sub_sector,'')<>'Digital/media'
--AND ISNULL(dim_detail_core_details.is_this_part_of_a_campaign,'')<>'Digital, Technology and Data (DTD)'
--AND ISNULL(dim_matter_worktype.work_type_name,'') NOT IN ('Specialty: Professions: Digital'
--											,'Intellectual property'
--											,'Education - FOIA and DPA'
--											,'Education - IP (Due Diligence)'
--											,'Data Protection'
--											,'Direct Selling'
--											,'GDPR'
--											,'Non-contentious IP & IT Contracts')
--AND dim_bill_date.bill_fin_period='2022-11 (Mar-2022)'

GROUP BY dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number,
         dim_matter_header_current.matter_description,
         dim_matter_header_current.date_opened_case_management,
         dim_matter_header_current.date_closed_case_management,
         dim_matter_header_current.matter_owner_full_name,
         dim_fed_hierarchy_history.hierarchylevel2hist,
         dim_fed_hierarchy_history.hierarchylevel3hist,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         dim_client.segment,
         dim_client.sector,
         dim_client.sub_sector,
         dim_detail_core_details.insured_sector,
         dim_matter_header_current.client_name,
         dim_client_involvement.insuredclient_name,
         dim_detail_core_details.is_this_part_of_a_campaign,
         dim_matter_worktype.work_type_name,
         dim_detail_finance.output_wip_fee_arrangement,
         fact_matter_summary_current.last_bill_date,
         fact_matter_summary_current.wip_balance,
         dim_bill_date.bill_fin_year,
         dim_bill_date.bill_fin_period



END
GO
