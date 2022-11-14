SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-08-08
-- Description:	#160501 Client Request - AXA XL Dashboard
-- =============================================
CREATE PROCEDURE [dbo].[axa_xl_kpi]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT DISTINCT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name AS [Handler]
	, ISNULL(dim_client_involvement.client_reference, dim_client_involvement.insurerclient_reference) AS [ Insurer Client Reference]
	, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Date Received]
	, CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END AS [Date Closed]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_matter_header_current.date_closed_case_management AS [MS Date Closed]
	, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
	, dim_matter_worktype.work_type_name AS [Work Type]
	, CASE WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040') THEN 'Motor' ELSE dim_detail_client.[axa_line_of_business] END AS [AXA Line of Business]
	--, _20210909_AXA_ProductsandBusinessType.CaseText AS [AXA Line of Business]
	, CASE WHEN dim_detail_client.[axa_line_of_business] IN ('Financial Institutions & D&O','Financial Lines','Fine Art & Specie','Accident and Health') THEN 'Speciality'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Casualty','Employer’s Liability and Public Liability','Property','Property Damage','Construction') THEN 'Property & Casualty'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Motor') THEN 'Motor'
			WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040')THEN 'Motor' 
			WHEN dim_detail_client.[axa_line_of_business]  IS NOT NULL THEN 'Speciality' 
			ELSE 'Other' END AS [Line of Business Group]
	, CASE WHEN dim_detail_claim.axa_coverage_defence LIKE 'Coverage & defence' THEN 'Defence' 
		WHEN dim_detail_claim.[axa_coverage_defence] LIKE '%Coverage%' THEN 'Coverage'
		WHEN dim_detail_claim.axa_coverage_defence LIKE '%Defence%' THEN 'Defence' 
		WHEN dim_detail_claim.axa_coverage_defence ='Recovery' THEN 'Subrogation' ELSE dim_detail_claim.axa_coverage_defence END AS [AXA Coverage Defence]
	, dim_detail_claim.[axa_first_acknowledgement_date] AS [AXA First Acknowledgement Date]
	, dim_detail_claim.[axa_reason_for_panel_budget_change] AS [AXA Reason for Panel Budget Change]
	, dim_detail_claim.date_pretrial_report_sent AS [Date Pre-trial Report Sent]
	, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)) AS [Trial Date]
	, CASE WHEN DATEDIFF(DAY, dim_detail_outcome.date_claim_concluded, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)))>60 THEN NULL
		ELSE DATEDIFF(DAY, dim_detail_claim.date_pretrial_report_sent, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key))) END AS [Days Report Sent Prior to Trial]
	, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
	, dim_detail_health.[date_of_service_of_proceedings] AS [Date of Service of Proceedings]
	, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received) AS [Date of Receipt of Client Papers]
	, dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an extension for the initial report?]
	, dim_detail_core_details.[date_initial_report_due] AS [Date Initial Report Due]
	, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
	, dim_detail_claim.date_90_day_post_instruction_plan_sent AS [Date 90 Day Post Instruction Stratergy Plan Sent]
	, dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date Subsequent Report Sent]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
	, dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded]
	, fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Costs Reserve Initial]
	, fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
	, fact_detail_claim.axa_budget_half_life AS [AXA Budget at Half Life]
	, fact_finance_summary.defence_costs_billed AS [Revenue]
	, fact_finance_summary.disbursements_billed AS [Disbursements]
	, DATEDIFF(DAY, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management),dim_detail_claim.[axa_first_acknowledgement_date]) AS [Days to Acknowledge]
	, CASE WHEN dim_detail_core_details.[do_clients_require_an_initial_report] ='No' THEN NULL 
	WHEN dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report='Yes' AND dim_detail_core_details.[date_initial_report_sent]<=dim_detail_core_details.date_initial_report_due THEN DATEDIFF(DAY, dim_detail_core_details.[date_initial_report_sent],dim_detail_core_details.date_initial_report_due)
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NULL AND DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received), GETDATE())<=30 THEN NULL
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL THEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent])
	ELSE DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent]) 
	END AS [Days to Initial Report]
	, CASE WHEN ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent) IS NOT NULL 
	THEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent))
	WHEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received), GETDATE())<=90 THEN NULL 
	ELSE DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent))
	END AS [Days to Updated Management Plan]
	, FirstSubsequentDate.SubsequentReportDate AS [First Subsequent Report]
	, dim_detail_claim.date_90_day_post_instruction_plan_sent AS [Date 90 day post instruction plan sent]
	--, [SubsequentDate].[SubsequentReportDate]
	--, [LatestBillDate]
	--, wip
	, CASE WHEN dim_matter_header_current.date_opened_case_management>='2022-06-01' THEN 1
	WHEN [SubsequentDate].[LatestBillDate] IS NULL AND wip<250 THEN 1 ELSE SubsequentDate.DaysFromSubsequentReport END AS [Days From Susequent Report to Invoice]
	, CASE WHEN [SubsequentDate].[LatestBillDate] IS NULL AND wip<250 THEN 1 ELSE SubsequentDate.DaysFromSubsequentReport END AS [Days From Susequent Report to Invoice - Actual]
	, dim_detail_client.[axa_reason_bill_not_sent_within_three_days] AS [Reason bill not sent within -/+3 days of a subsquent report]
	, dim_detail_client.[axa_reason_final_bill_not_sent_within_thirty_days] AS [Reason final bill not sent within 30 days of final disposition]
	, dim_detail_client.[axa_reason_instr_not_ack_within_seventy_two_hours] AS [Reason intsructions not acknowledged within 72 hours]
	, dim_detail_client.[axa_reason_initial_report_not_sent_within_thirty_days] AS [Reason initial report not sent within 30 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_lit_mgmt_plan_not_sent_within_ninety_days] AS [Reason litigation management plan not sent within 90 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_pretrial_report_not_sent_sixty_days] AS [Reason pre-trial report not sent within 60 days ahead of trial]
	, dim_detail_client.[axa_reason_wip_disbs_billed_exceeds_budget] AS [Reason WIP/disbs billed exceeds budget]
	, 1 AS [Cases]
	, 'Open' AS [Level]
	, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Date]
	, NULL AS [Billed]
	--, ROW_NUMBER() OVER (PARTITION BY dim_matter_header_current.ms_fileid ORDER BY dim_matter_header_current.ms_fileid  ) AS RN

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
left OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_key_dates 
ON dim_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND  dim_key_dates.description = 'Date of Trial'
--LEFT OUTER JOIN SQLAdmin.dbo._20210909_AXA_ProductsandBusinessType
--ON _20210909_AXA_ProductsandBusinessType.ClNo=dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
--AND _20210909_AXA_ProductsandBusinessType.FileNo=master_matter_number COLLATE DATABASE_DEFAULT
--AND MSCode='cboLineofBus'
LEFT OUTER JOIN (SELECT * FROM (
SELECT  udSubSLARep.fileId
, dim_matter_header_current.master_client_code
, dim_matter_header_current.master_matter_number
, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL) AS [SubsequentReportDate]
, LastBillDate.[LatestBillDate]
, ABS(DATEDIFF(DAY, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL), LastBillDate.LatestBillDate)) AS [DaysFromSubsequentReport]
, ROW_NUMBER() OVER (PARTITION BY dim_matter_header_current.ms_fileid ORDER BY  DATEDIFF(DAY, udSubSLARep.dteSubSLARepSSL, LastBillDate.LatestBillDate) asc) AS RN
FROM MS_Prod.dbo.udSubSLARep
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON udSubSLARep.fileId=dim_matter_header_current.ms_fileid
LEFT OUTER JOIN (
SELECT fact_bill_activity.master_fact_key
, fact_bill_activity.client_code
, fact_bill_activity.matter_number
, dim_matter_header_current.ms_fileid
, MAX(fact_bill_activity.bill_date) AS [LatestBillDate]
FROM red_dw.dbo.fact_bill_activity
LEFT outer JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_activity.dim_matter_header_curr_key
WHERE fact_bill_activity.client_code='A1001'
group BY fact_bill_activity.master_fact_key, 
		 fact_bill_activity.client_code,
         fact_bill_activity.matter_number,
		 dim_matter_header_current.ms_fileid
		 ) AS [LastBillDate] ON udSubSLARep.fileId=LastBillDate.ms_fileid
WHERE dim_matter_header_current.master_client_code='A1001'
) AS data 
WHERE data.LatestBillDate IS NOT NULL 
AND data.RN=1) AS [SubsequentDate]
ON SubsequentDate.master_client_code = dim_matter_header_current.master_client_code
AND SubsequentDate.master_matter_number = dim_matter_header_current.master_matter_number

LEFT OUTER JOIN (SELECT * FROM (
SELECT  udSubSLARep.fileId
, dim_matter_header_current.master_client_code
, dim_matter_header_current.master_matter_number
, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL) AS [SubsequentReportDate]
--, ABS(DATEDIFF(DAY, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL), LastBillDate.LatestBillDate)) AS [DaysFromSubsequentReport]
, ROW_NUMBER() OVER (PARTITION BY dim_matter_header_current.ms_fileid ORDER BY udSubSLARep.dteSubSLARepSSL asc) AS RN
FROM MS_Prod.dbo.udSubSLARep
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON udSubSLARep.fileId=dim_matter_header_current.ms_fileid
WHERE red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL) IS NOT NULL ) AS data
WHERE data.RN=1
AND data.master_client_code='A1001'
--AND data.master_matter_number='6474'
) AS [FirstSubsequentDate]
ON [FirstSubsequentDate].master_client_code = dim_matter_header_current.master_client_code
AND [FirstSubsequentDate].master_matter_number = dim_matter_header_current.master_matter_number

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='A1001'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-11688'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-7017'
AND dim_matter_header_current.matter_description<>'AXA General File'
AND ((CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END) >='2020-01-01'
	OR CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END	IS NULL	
	OR dim_detail_client.[axa_line_of_business] IS NOT NULL)
AND ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management)<DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
--AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number='A1001-12530'

UNION

SELECT DISTINCT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name AS [Handler]
	, ISNULL(dim_client_involvement.client_reference, dim_client_involvement.insurerclient_reference) AS [ Insurer Client Reference]
	, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Date Received]
	, CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END AS [Date Closed]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_matter_header_current.date_closed_case_management AS [MS Date Closed]
	, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
	, dim_matter_worktype.work_type_name AS [Work Type]
	, CASE WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040') THEN 'Motor' ELSE dim_detail_client.[axa_line_of_business] END AS [AXA Line of Business]
	--, _20210909_AXA_ProductsandBusinessType.CaseText AS [AXA Line of Business]
	, CASE WHEN dim_detail_client.[axa_line_of_business] IN ('Financial Institutions & D&O','Financial Lines','Fine Art & Specie','Accident and Health') THEN 'Speciality'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Casualty','Employer’s Liability and Public Liability','Property','Property Damage','Construction') THEN 'Property & Casualty'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Motor') THEN 'Motor'
			WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040')THEN 'Motor' 
			WHEN dim_detail_client.[axa_line_of_business]  IS NOT NULL THEN 'Speciality' 
			ELSE 'Other' END AS [Line of Business Group]
	, CASE WHEN dim_detail_claim.axa_coverage_defence LIKE 'Coverage & defence' THEN 'Defence' 
		WHEN dim_detail_claim.[axa_coverage_defence] LIKE '%Coverage%' THEN 'Coverage'
		WHEN dim_detail_claim.axa_coverage_defence LIKE '%Defence%' THEN 'Defence' 
		WHEN dim_detail_claim.axa_coverage_defence ='Recovery' THEN 'Subrogation' ELSE dim_detail_claim.axa_coverage_defence END AS [AXA Coverage Defence]
	, dim_detail_claim.[axa_first_acknowledgement_date] AS [AXA First Acknowledgement Date]
	, dim_detail_claim.[axa_reason_for_panel_budget_change] AS [AXA Reason for Panel Budget Change]
	, dim_detail_claim.date_pretrial_report_sent AS [Date Pre-trial Report Sent]
	, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)) AS [Trial Date]
	, CASE WHEN DATEDIFF(DAY, dim_detail_outcome.date_claim_concluded, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)))>60 THEN NULL
		ELSE DATEDIFF(DAY, dim_detail_claim.date_pretrial_report_sent, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key))) END AS [Days Report Sent Prior to Trial]
	, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
	, dim_detail_health.[date_of_service_of_proceedings] AS [Date of Service of Proceedings]
	, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received) AS [Date of Receipt of Client Papers]
	, dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an extension for the initial report?]
	, dim_detail_core_details.[date_initial_report_due] AS [Date Initial Report Due]
	, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
	, dim_detail_claim.date_90_day_post_instruction_plan_sent AS [Date 90 Day Post Instruction Stratergy Plan Sent]
	, dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date Subsequent Report Sent]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
	, dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded]
	, fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Costs Reserve Initial]
	, fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
	, fact_detail_claim.axa_budget_half_life AS [AXA Budget at Half Life]
	, fact_finance_summary.defence_costs_billed AS [Revenue]
	, fact_finance_summary.disbursements_billed AS [Disbursements]
	, DATEDIFF(DAY, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management),dim_detail_claim.[axa_first_acknowledgement_date]) AS [Days to Acknowledge]
	, CASE WHEN dim_detail_core_details.[do_clients_require_an_initial_report] ='No' THEN NULL 
	WHEN dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report='Yes' AND dim_detail_core_details.[date_initial_report_sent]<=dim_detail_core_details.date_initial_report_due THEN DATEDIFF(DAY, dim_detail_core_details.[date_initial_report_sent],dim_detail_core_details.date_initial_report_due)
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NULL AND DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received), GETDATE())<=30 THEN NULL
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL THEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent])
	ELSE DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent]) 
	END AS [Days to Initial Report]
	, NULL AS [Days to Updated Management Plan]
	, NULL AS [First Subsequent Report]
	, NULL AS [Date 90 day post instruction plan sent]
	, NULL AS [Days From Susequent Report to Invoice]
	, NULL AS [Days From Susequent Report to Invoice - Actual]
	, dim_detail_client.[axa_reason_bill_not_sent_within_three_days] AS [Reason bill not sent within -/+3 days of a subsquent report]
	, dim_detail_client.[axa_reason_final_bill_not_sent_within_thirty_days] AS [Reason final bill not sent within 30 days of final disposition]
	, dim_detail_client.[axa_reason_instr_not_ack_within_seventy_two_hours] AS [Reason intsructions not acknowledged within 72 hours]
	, dim_detail_client.[axa_reason_initial_report_not_sent_within_thirty_days] AS [Reason initial report not sent within 30 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_lit_mgmt_plan_not_sent_within_ninety_days] AS [Reason litigation management plan not sent within 90 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_pretrial_report_not_sent_sixty_days] AS [Reason pre-trial report not sent within 60 days ahead of trial]
	, dim_detail_client.[axa_reason_wip_disbs_billed_exceeds_budget] AS [Reason WIP/disbs billed exceeds budget]
	, 1 AS [Cases]
	, 'Closed' AS [Level]
	, CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END AS [Date]
	--, [Is insured Associate a Payor?] = ISNULL(CASE WHEN isPayor.fileID IS NOT NULL THEN 'Yes' ELSE 'No' END, 'No')
	, CASE WHEN isPayor.fileID IS NOT NULL THEN ISNULL(fact_finance_summary.defence_costs_billed,0)+ISNULL(fact_finance_summary.disbursements_billed,0)
		ELSE ISNULL(fact_finance_summary.defence_costs_billed,0)+ISNULL(fact_finance_summary.disbursements_billed,0)+ISNULL(fact_finance_summary.vat_billed,0) END AS [Billed]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
left OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_key_dates 
ON dim_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND  dim_key_dates.description = 'Date of Trial'
--LEFT OUTER JOIN SQLAdmin.dbo._20210909_AXA_ProductsandBusinessType
--ON _20210909_AXA_ProductsandBusinessType.ClNo=dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
--AND _20210909_AXA_ProductsandBusinessType.FileNo=master_matter_number COLLATE DATABASE_DEFAULT
--AND MSCode='cboLineofBus'

/*Associate isPayor*/
LEFT JOIN  ( SELECT DISTINCT fileID 
FROM ms_prod.[config].[dbAssociates]
WHERE uIsPayor = 1 
AND assocType = 'INSUREDCLIENT'
) isPayor ON isPayor.fileID = dim_matter_header_current.ms_fileid 


WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='A1001'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-11688'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-7017'
AND dim_matter_header_current.matter_description<>'AXA General File'
AND ((CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END) >='2022-06-01')
AND (CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END)<DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
--AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number='A1001-12170'

UNION
SELECT * FROM (
SELECT DISTINCT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name AS [Handler]
	, ISNULL(dim_client_involvement.client_reference, dim_client_involvement.insurerclient_reference) AS [ Insurer Client Reference]
	, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management) AS [Date Received]
	, CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END AS [Date Closed]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_matter_header_current.date_closed_case_management AS [MS Date Closed]
	, fact_matter_summary_current.last_bill_date AS [Last Bill Date]
	, dim_matter_worktype.work_type_name AS [Work Type]
	, CASE WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040') THEN 'Motor' ELSE dim_detail_client.[axa_line_of_business] END AS [AXA Line of Business]
	--, _20210909_AXA_ProductsandBusinessType.CaseText AS [AXA Line of Business]
	, CASE WHEN dim_detail_client.[axa_line_of_business] IN ('Financial Institutions & D&O','Financial Lines','Fine Art & Specie','Accident and Health') THEN 'Speciality'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Casualty','Employer’s Liability and Public Liability','Property','Property Damage','Construction') THEN 'Property & Casualty'
			WHEN dim_detail_client.[axa_line_of_business] IN ('Motor') THEN 'Motor'
			WHEN dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number IN ('A1001-4429','A1001-7617','A1001-8439','A1001-9040')THEN 'Motor' 
			WHEN dim_detail_client.[axa_line_of_business]  IS NOT NULL THEN 'Speciality' 
			ELSE 'Other' END AS [Line of Business Group]
	, CASE WHEN dim_detail_claim.axa_coverage_defence LIKE 'Coverage & defence' THEN 'Defence' 
		WHEN dim_detail_claim.[axa_coverage_defence] LIKE '%Coverage%' THEN 'Coverage'
		WHEN dim_detail_claim.axa_coverage_defence LIKE '%Defence%' THEN 'Defence' 
		WHEN dim_detail_claim.axa_coverage_defence ='Recovery' THEN 'Subrogation' ELSE dim_detail_claim.axa_coverage_defence END AS [AXA Coverage Defence]
	, dim_detail_claim.[axa_first_acknowledgement_date] AS [AXA First Acknowledgement Date]
	, dim_detail_claim.[axa_reason_for_panel_budget_change] AS [AXA Reason for Panel Budget Change]
	, dim_detail_claim.date_pretrial_report_sent AS [Date Pre-trial Report Sent]
	, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)) AS [Trial Date]
	, CASE WHEN DATEDIFF(DAY, dim_detail_outcome.date_claim_concluded, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)))>60 THEN NULL
		ELSE DATEDIFF(DAY, dim_detail_claim.date_pretrial_report_sent, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key))) END AS [Days Report Sent Prior to Trial]
	, dim_detail_core_details.proceedings_issued AS [Proceedings Issued]
	, dim_detail_health.[date_of_service_of_proceedings] AS [Date of Service of Proceedings]
	, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received) AS [Date of Receipt of Client Papers]
	, dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an extension for the initial report?]
	, dim_detail_core_details.[date_initial_report_due] AS [Date Initial Report Due]
	, dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
	, dim_detail_claim.date_90_day_post_instruction_plan_sent AS [Date 90 Day Post Instruction Stratergy Plan Sent]
	, dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date Subsequent Report Sent]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
	, dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded]
	, fact_finance_summary.[defence_costs_reserve_initial] AS [Defence Costs Reserve Initial]
	, fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
	, fact_detail_claim.axa_budget_half_life AS [AXA Budget at Half Life]
	, fact_finance_summary.defence_costs_billed AS [Revenue]
	, fact_finance_summary.disbursements_billed AS [Disbursements]
	, DATEDIFF(DAY, ISNULL(dim_detail_core_details.date_instructions_received, dim_matter_header_current.date_opened_case_management),dim_detail_claim.[axa_first_acknowledgement_date]) AS [Days to Acknowledge]
	, CASE WHEN dim_detail_core_details.[do_clients_require_an_initial_report] ='No' THEN NULL 
	WHEN dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report='Yes' AND dim_detail_core_details.[date_initial_report_sent]<=dim_detail_core_details.date_initial_report_due THEN DATEDIFF(DAY, dim_detail_core_details.[date_initial_report_sent],dim_detail_core_details.date_initial_report_due)
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NULL AND DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received), GETDATE())<=30 THEN NULL
	WHEN dim_detail_core_details.[date_initial_report_sent] IS NOT NULL THEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent])
	ELSE DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),dim_detail_core_details.[date_initial_report_sent]) 
	END AS [Days to Initial Report]
	, CASE WHEN ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent) IS NOT NULL 
	THEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent))
	WHEN DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received), GETDATE())<=90 THEN NULL 
	ELSE DATEDIFF(DAY, ISNULL(dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers],dim_detail_core_details.date_instructions_received),ISNULL(FirstSubsequentDate.SubsequentReportDate, dim_detail_claim.date_90_day_post_instruction_plan_sent)) 
	END AS [Days to Updated Management Plan]
	, FirstSubsequentDate.SubsequentReportDate AS [First Subsequent Report]
	, dim_detail_claim.date_90_day_post_instruction_plan_sent AS [Date 90 day post instruction plan sent]
	, NULL AS [Days From Susequent Report to Invoice]
	, NULL AS [Days From Susequent Report to Invoice - Actual]
	, dim_detail_client.[axa_reason_bill_not_sent_within_three_days] AS [Reason bill not sent within -/+3 days of a subsquent report]
	, dim_detail_client.[axa_reason_final_bill_not_sent_within_thirty_days] AS [Reason final bill not sent within 30 days of final disposition]
	, dim_detail_client.[axa_reason_instr_not_ack_within_seventy_two_hours] AS [Reason intsructions not acknowledged within 72 hours]
	, dim_detail_client.[axa_reason_initial_report_not_sent_within_thirty_days] AS [Reason initial report not sent within 30 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_lit_mgmt_plan_not_sent_within_ninety_days] AS [Reason litigation management plan not sent within 90 days of receiving instructions/file of papers]
	, dim_detail_client.[axa_reason_pretrial_report_not_sent_sixty_days] AS [Reason pre-trial report not sent within 60 days ahead of trial]
	, dim_detail_client.[axa_reason_wip_disbs_billed_exceeds_budget] AS [Reason WIP/disbs billed exceeds budget]
	, 1 AS [Cases]
	, 'Trial' AS [Level]
	, COALESCE(dim_detail_court.[date_of_trial], MAX(dim_key_dates.key_date) OVER (PARTITION BY fact_dimension_main.master_fact_key)) AS [Date]
	, NULL AS [Billed]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
left OUTER JOIN red_dw.dbo.dim_detail_client
ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim
ON fact_detail_claim.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_key_dates 
ON dim_key_dates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND  dim_key_dates.description = 'Date of Trial'
--LEFT OUTER JOIN SQLAdmin.dbo._20210909_AXA_ProductsandBusinessType
--ON _20210909_AXA_ProductsandBusinessType.ClNo=dim_matter_header_current.master_client_code COLLATE DATABASE_DEFAULT
--AND _20210909_AXA_ProductsandBusinessType.FileNo=master_matter_number COLLATE DATABASE_DEFAULT
--AND MSCode='cboLineofBus'

LEFT OUTER JOIN (SELECT * FROM (
SELECT  udSubSLARep.fileId
, dim_matter_header_current.master_client_code
, dim_matter_header_current.master_matter_number
, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL) AS [SubsequentReportDate]
--, ABS(DATEDIFF(DAY, red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL), LastBillDate.LatestBillDate)) AS [DaysFromSubsequentReport]
, ROW_NUMBER() OVER (PARTITION BY dim_matter_header_current.ms_fileid ORDER BY udSubSLARep.dteSubSLARepSSL asc) AS RN
FROM MS_Prod.dbo.udSubSLARep
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON udSubSLARep.fileId=dim_matter_header_current.ms_fileid
WHERE red_dw.dbo.datetimelocal(udSubSLARep.dteSubSLARepSSL) IS NOT NULL ) AS data
WHERE data.RN=1
AND data.master_client_code='A1001'
--AND data.master_matter_number='6474'
) AS [FirstSubsequentDate]
ON [FirstSubsequentDate].master_client_code = dim_matter_header_current.master_client_code
AND [FirstSubsequentDate].master_matter_number = dim_matter_header_current.master_matter_number

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_matter_header_current.master_client_code='A1001'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-11688'
AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number<>'A1001-7017'
AND dim_matter_header_current.matter_description<>'AXA General File'
AND dim_detail_outcome.date_claim_concluded IS NOT NULL
AND ((CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END) >='2020-01-01'
	OR CASE WHEN (dim_detail_core_details.present_position='Final bill sent - unpaid' OR dim_detail_core_details.present_position='To be closed/minor balances to be clear')
			THEN ISNULL(last_bill_date,dim_matter_header_current.date_closed_case_management) 
		WHEN (dim_detail_core_details.present_position<>'Final bill sent - unpaid' AND dim_detail_core_details.present_position<>'To be closed/minor balances to be clear') 
			THEN dim_matter_header_current.date_closed_case_management END	IS NULL	
	OR dim_detail_client.[axa_line_of_business] IS NOT NULL)


) AS Trial
WHERE Trial.Date<DATEFROMPARTS(YEAR(GETDATE()),MONTH(GETDATE()),1)
--AND Trial.[Client/Matter Number]='A1001-12170'
END
GO
