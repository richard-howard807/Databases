SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Emily Smith
-- Create date: 18/09/2017
-- Description:	Data for Tesco Bordereau report tab 1
-- =============================================

CREATE PROCEDURE [dbo].[TescoBordereau]

@Insurer AS VARCHAR(100)

AS

	-- For testing purposes
	--DECLARE @Insurer VARCHAR(100) = 'Ageas Insurance Ltd (AIL),Tesco Underwriting (TU)'

BEGIN

SELECT ListValue  INTO #Insurer FROM 	dbo.udt_TallySplit(',', @Insurer)

SELECT fact_dimension_main.client_code
		, fact_dimension_main.matter_number
		, dim_matter_header_current.master_client_code
		, master_matter_number
		, matter_description
		, matter_owner_full_name
		, dim_detail_core_details.fixed_fee
		, fact_finance_summary.fixed_fee_amount
		, date_instructions_received
		, dim_detail_core_details.present_position
		, date_claim_concluded
		, date_costs_settled
		, SUM(wipamt) AS WIP
		, last_bill_date
		, last_bill_total
		, final_bill_flag
		, total_amount_billed
		, fact_finance_summary.disbursement_balance
		, CASE WHEN name_of_instructing_insurer='Ageas Insurance Ltd (AIL)' THEN 'Ageas Insurance Ltd (AIL)'
				WHEN name_of_instructing_insurer='Tesco Underwriting (TU)' THEN 'Tesco Underwriting (TU)'
				WHEN fact_dimension_main.client_code='T3003' THEN 'Tesco Underwriting (TU)'  END AS [Insurer]
		, fact_finance_summary.defence_costs_billed AS [Profit Costs]
		, fact_finance_summary.disbursements_billed AS [Disbursements]
		, fact_finance_summary.vat_billed AS [VAT]
		, dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference]
		, dim_client_involvement.insurerclient_reference AS [Insurer Client Reference]
		, dim_client_involvement.[insuredclient_name] AS [Insured Client Name]
		, dim_detail_core_details.[grpageas_case_handler] AS [Claim Handler]
		, dim_detail_core_details.[incident_date] AS [Accident Date]

	
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN (SELECT master_fact_key, SUM(wipamt) AS wipamt, dim_transaction_date_key, cal_year, cal_quarter_no, billed_record
				FROM red_dw.dbo.fact_all_time_activity
				LEFT OUTER JOIN red_dw.dbo.dim_all_time_activity ON dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
				LEFT OUTER JOIN (SELECT dim_date_key, cal_year, cal_quarter_no FROM red_dw.dbo.dim_date) AS dim_date ON dim_date.dim_date_key=fact_all_time_activity.dim_transaction_date_key
				GROUP BY master_fact_key, dim_transaction_date_key, cal_year, cal_quarter_no, billed_record
) AS Time ON Time.master_fact_key = fact_dimension_main.master_fact_key 
AND cal_year=datepart(year, GETDATE())
AND cal_quarter_no= (CASE WHEN DATEPART(MONTH, GETDATE())<=3 THEN 1
						WHEN DATEPART(MONTH, GETDATE())<=6 THEN 2
						WHEN DATEPART(MONTH, GETDATE())<=9 THEN 3
						WHEN DATEPART(MONTH, GETDATE())<=12 THEN 4 ELSE NULL END-1)						
AND Time.wipamt>0
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
INNER JOIN #Insurer AS Insurer ON CASE WHEN name_of_instructing_insurer='Ageas Insurance Ltd (AIL)' THEN 'Ageas Insurance Ltd (AIL)'
				WHEN name_of_instructing_insurer='Tesco Underwriting (TU)' THEN 'Tesco Underwriting (TU)'
				WHEN fact_dimension_main.client_code='T3003' THEN 'Tesco Underwriting (TU)'  END COLLATE DATABASE_DEFAULT = Insurer.ListValue COLLATE DATABASE_DEFAULT 


WHERE fact_dimension_main.master_client_code IN ('T3003','A3003')
--AND (ageas_office LIKE '%Tesco%' OR name_of_instructing_insurer LIKE '%Tesco%')
AND dim_detail_core_details.[fixed_fee]='No'
AND Time.billed_record=0
AND dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_claim.[tier_1_3_case],'') <> 'Yes'  


GROUP BY fact_dimension_main.client_code
		, fact_dimension_main.matter_number
		, dim_matter_header_current.master_client_code
		, master_matter_number
		, matter_description
		, matter_owner_full_name
		, dim_detail_core_details.fixed_fee
		, fact_finance_summary.fixed_fee_amount
		, date_instructions_received
		, dim_detail_core_details.present_position
		, date_claim_concluded
		, date_costs_settled
		, last_bill_date
		, last_bill_total
		, final_bill_flag
		, total_amount_billed
		, fact_finance_summary.disbursement_balance
		, CASE WHEN name_of_instructing_insurer='Ageas Insurance Ltd (AIL)' THEN 'Ageas Insurance Ltd (AIL)'
				WHEN name_of_instructing_insurer='Tesco Underwriting (TU)' THEN 'Tesco Underwriting (TU)'
				WHEN fact_dimension_main.client_code='T3003' THEN 'Tesco Underwriting (TU)'  END 
		, fact_finance_summary.defence_costs_billed 
		, fact_finance_summary.disbursements_billed
		, fact_finance_summary.vat_billed 
		, dim_client_involvement.[insuredclient_reference] 
		, dim_client_involvement.insurerclient_reference 
		, dim_client_involvement.[insuredclient_name] 
		, dim_detail_core_details.[grpageas_case_handler] 
		, dim_detail_core_details.[incident_date] 
UNION

SELECT fact_dimension_main.client_code
		, fact_dimension_main.matter_number
		, dim_matter_header_current.master_client_code
		, master_matter_number
		, matter_description
		, matter_owner_full_name
		, dim_detail_core_details.fixed_fee
		, fact_finance_summary.fixed_fee_amount
		, date_instructions_received
		, dim_detail_core_details.present_position
		, date_claim_concluded
		, date_costs_settled
		, wip AS [WIP]
		, last_bill_date
		, last_bill_total
		, final_bill_flag
		, total_amount_billed
		, fact_finance_summary.disbursement_balance
		, CASE WHEN name_of_instructing_insurer='Ageas Insurance Ltd (AIL)' THEN 'Ageas Insurance Ltd (AIL)'
				WHEN name_of_instructing_insurer='Tesco Underwriting (TU)' THEN 'Tesco Underwriting (TU)'
				WHEN fact_dimension_main.client_code='T3003' THEN 'Tesco Underwriting (TU)'  END AS [Insurer]
		, fact_finance_summary.defence_costs_billed AS [Profit Costs]
		, fact_finance_summary.disbursements_billed AS [Disbursements]
		, fact_finance_summary.vat_billed AS [VAT]
		, dim_client_involvement.[insuredclient_reference] AS [Insured Client Reference]
		, dim_client_involvement.insurerclient_reference AS [Insurer Client Reference]
		, dim_client_involvement.[insuredclient_name] AS [Insured Client Name]
		, dim_detail_core_details.[grpageas_case_handler] AS [Claim Handler]
		, dim_detail_core_details.[incident_date] AS [Accident Date]
	
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key 
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
INNER JOIN #Insurer AS Insurer ON CASE WHEN name_of_instructing_insurer='Ageas Insurance Ltd (AIL)' THEN 'Ageas Insurance Ltd (AIL)'
				WHEN name_of_instructing_insurer='Tesco Underwriting (TU)' THEN 'Tesco Underwriting (TU)'
				WHEN fact_dimension_main.client_code='T3003' THEN 'Tesco Underwriting (TU)'  END COLLATE DATABASE_DEFAULT = Insurer.ListValue COLLATE DATABASE_DEFAULT 


WHERE fact_dimension_main.master_client_code IN ('T3003','A3003')
--AND (ageas_office LIKE '%Tesco%' OR name_of_instructing_insurer LIKE '%Tesco%')
AND dim_detail_core_details.[fixed_fee]='Yes'
AND dim_detail_core_details.present_position IN ('To be closed/minor balances to be clear','Final bill sent - unpaid','Final bill due - claim and costs concluded')
AND wip>0
AND dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_claim.[tier_1_3_case],'') <> 'Yes' 


DROP TABLE #Insurer

END
GO
