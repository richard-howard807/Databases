SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Health Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[HealthDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT  
		RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
	    , fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_client.client_code AS [Client Name]
		, dim_detail_health.claimant_type AS [Claimant Type]
		, dim_detail_health.date_info_provided_to_nhs AS [Date Info Provided to NHS]
		, dim_detail_health.nhs_date_letter_of_claim AS [NHS Date Letter of Claim]
		, fact_detail_client.nhs_charges_paid_by_all_parties AS [NHS Charges Paid by all Parties]
		, dim_detail_health.disciplines AS Disciplines
		, dim_detail_health.division AS Division
		, dim_detail_health.location AS Location
		, dim_detail_health.pennine_site AS [Pennine Site]
		, dim_detail_health.reason_for_settlement AS [Reason for Settlement]
		, dim_detail_health.site AS [Site]
		, dim_detail_rsu.[is_there_a_prevention_of_future_deaths_report] AS [Prevention of Future Deaths Report]
		, dim_detail_rsu.[reg_complaint_or_claim_by_family_intimated] AS [Complaint or Claim by Family Intimated]
		, dim_detail_rsu.[reg_date_of_inquest] AS [Date of Inquest]
		, dim_detail_rsu.[reg_do_you_have_a_pre_inquest_review_hearing_date] AS [Pre Inquest Review Hearing Date?]
		, dim_detail_rsu.[reg_is_the_media_currently_involved] AS [Media Currently Involved]
		, dim_detail_rsu.[reg_is_this_an_article_two_inquest] AS [Is this an Article Two Inquest?]
		, dim_detail_rsu.[reg_is_this_an_inquest_with_a_jury] AS [Is this an Inquest With a Jury?]
		, dim_detail_rsu.[reg_name_of_coroner] AS [Name of Coroner]
		, dim_detail_rsu.[reg_press_involvement] AS [Press Involvement]
		, dim_detail_rsu.[reg_si_rca_undertaken] AS [SI/RCA Undertaken?]
		, dim_detail_rsu.[reg_verdict] AS [Verdict]
		, fact_client.[recovery_nhs_amount_recovered] AS [Recovery NHS Amount Recovered]
		, fact_detail_reserve.nhs_charges_reserve_current AS [NHS Charges Reserve Current]
		, dim_detail_claim.date_letter_of_claim AS [Date Letter of Claim]
		, dim_detail_claim.loc_periods AS [LOC Periods]
		, dim_detail_claim.month_letter_of_claim [Month Letter of Claim]
		, dim_detail_claim.year_letter_of_claim [Year Letter of Claim]
		, DATEDIFF(DAY,dim_detail_core_details.[date_letter_of_claim],dim_detail_health.[date_info_provided_to_nhs]) [Elapsed Days from LOC to NHS Info Given]
		, DATEDIFF(DAY,dim_detail_core_details.[date_letter_of_claim],dim_detail_outcome.date_claim_concluded) [Elapsed Days from LOC to Concluded]
		, DATEDIFF(DAY,dim_detail_core_details.[date_letter_of_claim],dim_detail_outcome.[date_costs_settled]) [Elapsed Days from LOC to Settlement]
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NULL AND dim_matter_header_current.date_closed_case_management IS NULL THEN 1 ELSE 0 END AS [Live Cases - NHSLA]
		, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL AND dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 1 ELSE 0 END AS [Closed/Settled Cases - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim])<=3 THEN CAST(DATEPART(YEAR,dim_detail_core_details.[date_letter_of_claim])-1 AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_core_details.[date_letter_of_claim]) AS VARCHAR)
				WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim])>3 THEN CAST(DATEPART(YEAR,dim_detail_core_details.[date_letter_of_claim]) AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_core_details.[date_letter_of_claim])+1 AS VARCHAR)
				END AS [Financial Year Letter of Claim Received - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_matter_header_current.date_opened_case_management)<=3 THEN CAST(DATEPART(YEAR,dim_matter_header_current.date_opened_case_management)-1 AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_matter_header_current.date_opened_case_management) AS VARCHAR)
				WHEN DATEPART(MONTH,dim_matter_header_current.date_opened_case_management)>3 THEN CAST(DATEPART(YEAR,dim_matter_header_current.date_opened_case_management) AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_matter_header_current.date_opened_case_management)+1 AS VARCHAR)
				END AS [Financial Year Opened - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim]) <=3 THEN 'Qtr4'
				WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim]) <=6 THEN 'Qtr1'
				WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim]) <=9 THEN 'Qtr2'
				WHEN DATEPART(MONTH,dim_detail_core_details.[date_letter_of_claim]) >9 THEN 'Qtr3'
				END AS [Quarter Letter of Claim Received - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled])<=3 THEN CAST(DATEPART(YEAR,dim_detail_outcome.[date_costs_settled])-1 AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_outcome.[date_costs_settled]) AS VARCHAR)
				WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled])>3 THEN CAST(DATEPART(YEAR,dim_detail_outcome.[date_costs_settled]) AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_outcome.[date_costs_settled])+1 AS VARCHAR)
				END AS [Financial Year Costs Settled - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled]) <=3 THEN 'Qtr4'
				WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled]) <=6 THEN 'Qtr1'
				WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled]) <=9 THEN 'Qtr2'
				WHEN DATEPART(MONTH,dim_detail_outcome.[date_costs_settled]) >9 THEN 'Qtr3'
				END AS [Quarter Costs Settled - NHSLA]
		, CASE WHEN DATEPART(MONTH,dim_detail_outcome.[date_claim_concluded])<=3 THEN CAST(DATEPART(YEAR,dim_detail_outcome.[date_claim_concluded])-1 AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_outcome.[date_claim_concluded]) AS VARCHAR)
				WHEN DATEPART(MONTH,dim_detail_outcome.[date_claim_concluded])>3 THEN CAST(DATEPART(YEAR,dim_detail_outcome.[date_claim_concluded]) AS VARCHAR)+'/'+CAST(DATEPART(YEAR,dim_detail_outcome.[date_claim_concluded])+1 AS VARCHAR)
				END AS [Financial Year Concluded - NHSLA]
		, CASE WHEN dim_detail_outcome.date_costs_settled >= '20130401' THEN 'Post April 2013'
				WHEN dim_detail_outcome.date_costs_settled < '20130401' THEN 'Pre April 2013' ELSE 'BlankDate' END AS [Settlement Periods_Pennine - inhouse]
		, CASE WHEN dim_detail_outcome.date_costs_settled IS NOT NULL THEN 'concluded' ELSE 'open' END AS [Costs Settled Status]
		, MONTH(dim_detail_outcome.date_costs_settled) as [Month Costs Settled]
	    , YEAR(dim_detail_outcome.date_costs_settled) as [Year Costs Settled]
		, CASE WHEN dim_detail_health.[coroners_court] LIKE 'Manchester North%' OR dim_detail_health.[coroners_court] LIKE 'Manchester' OR dim_detail_health.[coroners_court] LIKE 'Rochdale' THEN 'Manchester North'
				  WHEN dim_detail_health.[coroners_court] LIKE 'Manchester  City%' THEN 'Manchester City'
				  WHEN dim_detail_health.[coroners_court] LIKE 'Bolton' THEN 'Manchester West'
				  ELSE dim_detail_health.[coroners_court] END AS [Coroner's Court Location]
		, CASE WHEN dim_detail_health.[coroners_court] IN ('Manchester West') OR dim_detail_health.[coroners_court] LIKE 'Bolton' THEN 'BL1 1QY'
				  WHEN dim_detail_health.[coroners_court] IN ('Manchester City') OR dim_detail_health.[coroners_court] LIKE 'Manchester  City%' THEN 'M60 2LA'
				  WHEN dim_detail_health.[coroners_court] IN ('Manchester North') OR dim_detail_health.[coroners_court] LIKE 'Manchester North%' OR dim_detail_health.[coroners_court] LIKE 'Manchester' OR dim_detail_health.[coroners_court] LIKE 'Rochdale' THEN 'OL10 1LR'
				  WHEN dim_detail_health.[coroners_court] IN ('Manchester South') THEN 'SK1 3PA'
				  WHEN dim_detail_health.[coroners_court] IN ('Wirral, Birkenhead') THEN 'CH62 7ER'
				  WHEN dim_detail_health.[coroners_court] IN ('Liverpool') THEN 'L5 2QD'
			 ELSE '' END AS [Inquest Postcode]
		, CASE WHEN ((LOWER(dim_detail_outcome.[outcome_of_case]) LIKE 'settled%') OR (LOWER(dim_detail_outcome.[outcome_of_case]) LIKE 'assesment%') OR (LOWER(dim_detail_outcome.[outcome_of_case]) LIKE 'appeal%') 
					OR (dim_detail_outcome.[outcome_of_case] LIKE LOWER('lost%')) )  THEN 'Settled'
				  WHEN dim_detail_outcome.[outcome_of_case] IS NULL THEN ''
				  ELSE 'Repudiated' END AS [Repudiated/ Settled - NHSLA]
		, CASE WHEN (dim_client.client_code = '00041095' AND dim_matter_worktype.work_type_code = '0023') AND (dim_detail_rsu.[reg_date_of_inquest] IS NULL OR dim_detail_rsu.[reg_date_of_inquest] >= GETDATE()) THEN 'Open'
				  WHEN (dim_client.client_code = '00041095' AND dim_matter_worktype.work_type_code = '0023') AND dim_detail_rsu.[reg_date_of_inquest] < GETDATE() THEN 'Closed'
				  ELSE '' END AS [Inquest Open/Closed]
		, CASE WHEN dim_detail_health.[instruction_type]='Claims' THEN 'Claim' ELSE dim_detail_health.[instruction_type] END AS [Instruction_Type]
		, CASE WHEN dim_detail_outcome.[liability_admitted]='N' THEN 1 ELSE 0 END AS [Liability Denied]
		,dim_detail_core_details.brief_details_of_claim
		,dim_detail_advice.advice_name_dentist_surgeon
		,dim_detail_advice.advice_profession
		,dim_detail_advice.advice_coverage
		,dim_detail_advice.advice_type_of_claim
		,dim_detail_advice.advice_liability
		,dim_detail_advice.advice_dental_surgeon_helpline
		,dim_detail_advice.[status]
		,dim_detail_health.call_status
		,dim_detail_health.status_summary
		,dim_detail_health.profession_type
		,dim_detail_advice.advice_status_description
		,dim_detail_health.[broker]
		,dim_detail_health.broker_reference
		,dim_detail_claim.cfc_notification_date
			
		

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_rsu ON dim_detail_rsu.dim_detail_rsu_key = fact_dimension_main.dim_detail_rsu_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client AS fact_client ON fact_client.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_detail_reserve ON fact_detail_reserve.master_fact_key=fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice ON dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key



LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key


WHERE 
ISNULL(dim_detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)

END
GO
