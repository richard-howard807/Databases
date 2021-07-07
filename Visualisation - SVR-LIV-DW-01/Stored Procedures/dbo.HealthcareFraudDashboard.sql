SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	--USE Visualisation
	
	/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-01-29
Description:		Healthcare Fraud Dashboard
Current Version:	Initial Create
====================================================
	Ticket #104268
====================================================

*/
CREATE PROCEDURE [dbo].[HealthcareFraudDashboard]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
SELECT	

date_opened_case_management AS [Date Case Opened]
		,date_claim_concluded
		, date_closed_case_management AS [Date Case Closed]
		, RTRIM(dim_matter_header_current.master_client_code)+'-'+dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
		, matter_description AS [Matter Description]
		, matter_owner_full_name AS [Case Manager]
		, dim_matter_worktype.work_type_group AS [Matter Type]
		, suspicion_of_fraud AS [Suspicion of Fraud]
		, outcome_of_case AS [Outcome of Case]
		,DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]
		,red_dw.dbo.fact_finance_summary.total_tp_costs_paid + red_dw.dbo.fact_finance_summary.damages_paid + red_dw.dbo.fact_finance_summary.defence_costs_billed	 AS  [Total Paid] 
		--,fact_finance_summary.damages_paid
		,fact_finance_summary.[claimants_costs_paid] 
		,fact_finance_summary.total_amount_billed
		--, CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
		,fact_finance_summary.total_reserve
		, damages_paid AS [Damages Paid by Client]
		, date_costs_settled AS [Date Costs Settled]
		, total_tp_costs_paid AS [Total Third Party Costs Paid]
		--, fact_finance_summary.[claimants_costs_paid]
		--, DATEDIFF(DAY, incident_date, dim_detail_court.date_proceedings_issued) AS [Days to Issue]
		, DATEDIFF(DAY, dim_detail_core_details.date_instructions_received, dim_detail_outcome.date_claim_concluded) AS [Elapsed Days (Damages)]
		, DATEDIFF(DAY, dim_detail_core_details.incident_date, dim_detail_core_details.date_instructions_received) AS [Elapsed Days to Instructions]
		,dim_detail_core_details.present_position 
		, 1 AS [Number of Records]
		, CASE WHEN date_claim_concluded IS NULL AND date_closed_case_management<'2017-01-01' THEN 0
			WHEN date_claim_concluded<'2017-01-01'  THEN 0
			ELSE 1 END AS [Date Filter]
			,hierarchylevel2hist
			,hierarchylevel3hist
			, red_dw.dbo.dim_matter_header_current.client_group_name
			,date.fin_year	AS Date_Opened_FY
			   ,COALESCE(
                   dim_detail_fraud.fraud_type_motor,
                   dim_detail_fraud.fraud_type_casualty,
                   dim_detail_fraud.fraud_type_disease,
                   dim_detail_fraud.[fraud_initial_fraud_type],
                   dim_detail_fraud.[fraud_current_fraud_type],
                   dim_detail_fraud.[fraud_type_ageas],
                   dim_detail_fraud.[fraud_current_secondary_fraud_type],
                   dim_detail_client.[coop_fraud_current_fraud_type],
                   dim_detail_fraud.[fraud_type],
                   dim_detail_fraud.[fraud_type_disease_pre_lit]
               ) AS [Fraud Type] 
			   ,fact_detail_reserve_detail.savings_against_reserve AS [savings against reserve] 


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_date as date 
ON  CAST(date.calendar_date AS DATE) = CAST(dim_matter_header_current.date_opened_case_management AS DATE) 
LEFT OUTER JOIN red_dw.dbo.dim_detail_fraud 
ON dim_detail_fraud.dim_detail_fraud_key=fact_dimension_main.dim_detail_fraud_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key

WHERE

hierarchylevel2hist='Legal Ops - Claims'
AND hierarchylevel3hist ='Healthcare'
AND red_dw.dbo.dim_matter_header_current.client_group_name='NHS Resolution'
AND reporting_exclusions=0
AND NOT (LOWER(RTRIM(ISNULL(outcome_of_case,''))) IN ('exclude from reports','returned to client'))
AND (date_opened_case_management >= '2018-05-01')
--OR date_claim_concluded >= '2018-05-01' )
AND suspicion_of_fraud ='Yes'
END
GO
