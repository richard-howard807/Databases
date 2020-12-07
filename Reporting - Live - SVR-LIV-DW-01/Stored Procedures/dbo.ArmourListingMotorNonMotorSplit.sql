SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[ArmourListingMotorNonMotorSplit]
(
	@report_type AS VARCHAR(10)
)

AS 

-- Ticket #81827 split out SP into Motor/Non-Motor as needed to capture Motor worktypes as well as department 

--Testing
--DECLARE @report_type AS VARCHAR(10) = 'Motor'

-- For Armour Motor Claims MI Report
IF @report_type = 'Motor'

BEGIN

SELECT 
	matter_description AS [Case Name]
	,dim_matter_header_current.client_code AS [Client Code]
	,dim_matter_header_current.matter_number AS [Matter Number]
	,RTRIM(dim_matter_header_current.client_code) + '.' +RTRIM(dim_matter_header_current.matter_number) AS Ref
	,master_client_code + '.' + master_matter_number AS [Weightmans Ref]
	,client_reference AS [Amour Reference]
	,CASE 
		WHEN UPPER(matter_description) LIKE 'ELITE%' 
			THEN 'Elite'
		WHEN UPPER(matter_description) LIKE 'TRADEX%' 
			THEN 'Tradex'
		ELSE 'Armour' 
	  END				AS Client
	,dim_detail_core_details.[incident_date] AS [Incident Date]
	,date_opened_case_management AS [Date file opened]
	,date_closed_case_management AS [Date file closed (MS)]
	,name AS [Fee Earner]
	,fee_arrangement AS [Fee Arrangement]
	,dim_detail_core_details.[referral_reason] AS [Referral Reason]
	,defence_costs_billed AS [Amount billed in 3E]
	,wip AS [WIP]
	,locationidud AS [Office]
	,hierarchylevel3hist  AS [Department]
	,COALESCE(claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
	,dim_detail_core_details.[present_position] AS [Claim Status]
	,fact_finance_summary.[total_reserve] AS [Current reserve total]
	,fact_finance_summary.[damages_reserve] AS [Current reserve damages]
	,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Current reserve costs ]
	,CASE WHEN dim_detail_core_details.[date_initial_report_sent]>  dim_detail_core_details.[date_subsequent_sla_report_sent]
	THEN dim_detail_core_details.[date_initial_report_sent] ELSE dim_detail_core_details.[date_subsequent_sla_report_sent] END AS [Last reserve review date]
	,dim_detail_core_details.[date_initial_report_sent] AS [Date of initial report]
	,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Subsequent report date ]
	,fact_finance_summary.[total_paid] AS [Amount paid to date]
	,dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liabiilty admitted/denied]
	,NULL AS [Upcoming JSM?]
	,NULL AS [Anticipated settlement date?]
	,NULL AS [Previous Clegg Gifford file?]
	,dim_detail_outcome.outcome_of_case AS [Outcome of Claim]
	,dim_detail_outcome.[date_claim_concluded] AS [Date Claim concluded ]
	,fact_finance_summary.[damages_paid_to_date] AS [Damages Paid]
	, fact_finance_summary.[total_tp_costs_paid]  AS [TP Costs Paid]
	, dim_matter_worktype.work_type_name		AS [Matter Type]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE 
	master_client_code IN ('752920','W15608')
	AND reporting_exclusions=0
	AND (dim_fed_hierarchy_history.hierarchylevel3hist = 'Motor' OR dim_matter_worktype.work_type_name LIKE '%Motor%')

END

-- For Armour Non Motor Claims MI Report
IF @report_type = 'Non-Motor'

BEGIN

SELECT 
	matter_description AS [Case Name]
	,dim_matter_header_current.client_code AS [Client Code]
	,dim_matter_header_current.matter_number AS [Matter Number]
	,RTRIM(dim_matter_header_current.client_code) + '.' +RTRIM(dim_matter_header_current.matter_number) AS Ref
	,master_client_code + '.' + master_matter_number AS [Weightmans Ref]
	,client_reference AS [Amour Reference]
	,CASE 
		WHEN UPPER(matter_description) LIKE 'ELITE%' 
			THEN 'Elite'
		WHEN UPPER(matter_description) LIKE 'TRADEX%' 
			THEN 'Tradex'
		ELSE 'Armour' 
	  END				AS Client
	,dim_detail_core_details.[incident_date] AS [Incident Date]
	,date_opened_case_management AS [Date file opened]
	,date_closed_case_management AS [Date file closed (MS)]
	,name AS [Fee Earner]
	,fee_arrangement AS [Fee Arrangement]
	,dim_detail_core_details.[referral_reason] AS [Referral Reason]
	,defence_costs_billed AS [Amount billed in 3E]
	,wip AS [WIP]
	,locationidud AS [Office]
	,hierarchylevel3hist  AS [Department]
	,COALESCE(claimantsols_name, dim_claimant_thirdparty_involvement.claimantrep_name) AS [Claimant's Solicitor]
	,dim_detail_core_details.[present_position] AS [Claim Status]
	,fact_finance_summary.[total_reserve] AS [Current reserve total]
	,fact_finance_summary.[damages_reserve] AS [Current reserve damages]
	,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Current reserve costs ]
	,CASE WHEN dim_detail_core_details.[date_initial_report_sent]>  dim_detail_core_details.[date_subsequent_sla_report_sent]
	THEN dim_detail_core_details.[date_initial_report_sent] ELSE dim_detail_core_details.[date_subsequent_sla_report_sent] END AS [Last reserve review date]
	,dim_detail_core_details.[date_initial_report_sent] AS [Date of initial report]
	,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Subsequent report date ]
	,fact_finance_summary.[total_paid] AS [Amount paid to date]
	,dim_detail_core_details.[is_there_an_issue_on_liability] AS [Liabiilty admitted/denied]
	,NULL AS [Upcoming JSM?]
	,NULL AS [Anticipated settlement date?]
	,NULL AS [Previous Clegg Gifford file?]
	,dim_detail_outcome.outcome_of_case AS [Outcome of Claim]
	,dim_detail_outcome.[date_claim_concluded] AS [Date Claim concluded ]
	,fact_finance_summary.[damages_paid_to_date] AS [Damages Paid]
	, fact_finance_summary.[total_tp_costs_paid]  AS [TP Costs Paid]
	, dim_matter_worktype.work_type_name		AS [Matter Type]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
	INNER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code
			AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE 
	master_client_code IN ('752920','W15608')
	AND reporting_exclusions=0
	AND dim_fed_hierarchy_history.hierarchylevel3hist <> 'Motor' 
	AND dim_matter_worktype.work_type_name NOT LIKE '%Motor%'

END

GO
