SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






-- =============================================
-- Author:		Max Taylor
-- Create date: 2022 - 02 - 03
-- Description:	Initial Create
-- =============================================

-- =============================================
CREATE PROCEDURE [dbo].[BAI_BAIMonthlyReport]--[dbo].[BAI_BAIMonthlyReport] 'Mar 2022'
(
@Period AS NVARCHAR(20)
)

AS		


DECLARE @StartDate AS DATE
DECLARE @EndDate AS DATE

/* Testing */
--DECLARE @Period AS VARCHAR(20) 
--SET @Period = 'Apr 2022'

SET @StartDate=(SELECT MIN(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month_name + ' ' + CAST(cal_year AS NVARCHAR(5))=@Period)
SET @EndDate=(SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE cal_month_name + ' ' + CAST(cal_year AS NVARCHAR(5))=@Period)
	
	PRINT @StartDate
	PRINT @EndDate
		 SELECT  ms_fileid,ms_only,
		    [BAICS ref] = COALESCE(dim_client_involvement.[insurerclient_reference],dim_client_involvement.client_reference,dim_client_involvement.insurerclient_reference),
            dim_client_involvement.[insurerclient_reference],
			dim_client_involvement.client_reference,
			[Weightmans ref] = dim_client.client_code + ' ' + dim_matter_header_current.matter_number,
			[Disease Type] = CASE  
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='NIHL' THEN 'Deafness'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Living Mesothelioma' THEN 'Mesothelioma'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Fatal Mesothelioma' THEN 'Mesothelioma'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Lung cancer with asbestosis' THEN 'Lung cancer'
            WHEN TRIM(dim_detail_core_details.capita_disease_type)='Lung cancer without asbestosis' THEN 'Lung cancer'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Asbestos Related Cancer' THEN 'Lung cancer with asbestosis'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Asbestos/Mesothelioma'  THEN  'Mesothelioma'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease – Asbestosis' THEN 'Asbestosis'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Industrial Deafness' THEN 'Deafness'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Pleural Thickening' THEN 'Pleural thickening'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - Pleural Plaques' THEN 'Pleural plaques'
			WHEN TRIM(dim_matter_worktype.work_type_name) = 'Disease - VWF/Reynauds Phenomemon' THEN 'HAVS/VWF'
			ELSE dim_detail_core_details.capita_disease_type END,
			[Fee Earner] = name,
			[Date Instructed] = date_opened_case_management,
			[Claimant] = dim_claimant_thirdparty_involvement.claimant_name,
			[Policyholder] = COALESCE(insuredclient_name, dim_defendant_involvement.[defendant_name]),
			[Claimant Solicitor] = COALESCE(dim_detail_claim.dst_claimant_solicitor_firm,dim_claimant_thirdparty_involvement.claimantsols_name),
		
		
				/*
			
			“Gross Reserve” – please can you check that this is just adding up the amended “Damages Reserve” “Costs Reserve” and “Defence Costs Reserve”
		
			*/
		
		[Gross Reserve] = ISNULL(CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL  then ISNULL(fact_finance_summary.[damages_paid], 0) ELSE ISNULL(fact_finance_summary.[damages_interims], 0) END ELSE fact_finance_summary.[damages_reserve] END, 0) -- [Damages Reserve]
		 + ISNULL(CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN fact_finance_summary.[total_tp_costs_paid_to_date] ELSE fact_detail_reserve_detail.[claimant_costs_reserve_current]   END, 0) -- [Costs Reserve]
		 + ISNULL(CASE WHEN TRIM(dim_detail_core_details.[present_position]) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear')  THEN  fact_finance_summary.total_amount_bill_non_comp  WHEN ISNULL(fact_finance_summary.total_amount_bill_non_comp,0) > ISNULL(fact_finance_summary.[defence_costs_reserve],0) THEN ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0) + ISNULL(fact_finance_summary.wip,0) ELSE fact_finance_summary.[defence_costs_reserve] END, 0), -- [Defence Costs Reserve]

			/*[Damages Reserve] = if dim_detail_outcome[date_claim_concluded] is complete then show “Damages Agreed,” 
			otherwise show fact_finance_summary[damages_reserve]
			
			*/

			[Damages Reserve] = CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL THEN CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL  then ISNULL(fact_finance_summary.[damages_paid], 0) ELSE ISNULL(fact_finance_summary.[damages_interims], 0) END ELSE fact_finance_summary.[damages_reserve] END, 


			/*[Damages Agreed] = dim_detail_outcome[date_claim_concluded] is completed then show fact_finance_summary[damages_paid] otherwise, show fact_finance_summary[damages_interims]
*/

			[Damages Agreed]  = CASE WHEN dim_detail_outcome.[date_claim_concluded] IS NOT NULL  then ISNULL(fact_finance_summary.[damages_paid], 0) ELSE ISNULL(fact_finance_summary.[damages_interims], 0) END, --fact_finance_summary.[damages_paid],

			/*“Costs Reserve” – if dim_detail_outcome[date_costs_settled] is complete then show “Costs Agreed,” 
			otherwise show fact_detail_reserve_detail[claimant_costs_reserve_current]*/

			[Costs Reserve]   = 	
			CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN fact_finance_summary.[total_tp_costs_paid_to_date]
			ELSE fact_detail_reserve_detail.[claimant_costs_reserve_current]   END,     


			[Costs Agreed]    =  fact_finance_summary.[total_tp_costs_paid_to_date],
	
			/*“Defence Costs Reserve” – if dim_detail_core_details[present_position] is 
			“Final bill sent – unpaid”/”To be closed/minor balances to be clear” 
			then show “Defence Cost,” otherwise show fact_finance_summary[defence_costs_reserve]
			
			
			if “Defence Cost” is greater than fact_finance_summary[defence_costs_reserve]show “Defence Cost
			
			
			*/

			[Defence Costs Reserve] = 
			CASE WHEN TRIM(dim_detail_core_details.[present_position]) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear')  THEN  fact_finance_summary.total_amount_bill_non_comp 
			     WHEN ISNULL(fact_finance_summary.total_amount_bill_non_comp,0) > ISNULL(fact_finance_summary.[defence_costs_reserve],0) THEN ISNULL(fact_finance_summary.total_amount_bill_non_comp, 0) + ISNULL(fact_finance_summary.wip,0)
					ELSE fact_finance_summary.[defence_costs_reserve] END,


			[Defence Cost] =        fact_finance_summary.total_amount_bill_non_comp, 
		
		
		    [FSCS Protected] = CASE WHEN ISNUMERIC(capita_fscs_protected_yes_enter_percent_no_leave_blank)=1 THEN CAST(capita_fscs_protected_yes_enter_percent_no_leave_blank AS NVARCHAR(4)) +'%'
			WHEN capita_fscs_protected_yes_enter_percent_no_leave_blank='Yes-100%' THEN '100%'
			                WHEN ISNULL(dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank], '') ='' THEN '0%' 
			                ELSE dim_detail_core_details.[capita_fscs_protected_yes_enter_percent_no_leave_blank] END,

            [Cause of Litigation] = dim_detail_core_details.[referral_reason],


			    [Status] = CASE 
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND UPPER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ( 'DISCONTINUED','DISCONTINUED  - PRE-LIT','DISCONTINUED - INDEMNIFIED BY 3RD PARTY', 'DISCONTINUED - INDEMNIFIED BY THIRD PARTY', 'DISCONTINUED - POST LIT WITH NO COSTS ORDER', 'DISCONTINUED - POST-LIT WITH COSTS ORDER', 'DISCONTINUED - POST-LIT WITH NO COSTS ORDER', 'DISCONTINUED - PRE LIT NO COSTS ORDER', 'DISCONTINUED - PRE-LIT', 'STRUCK OUT', 'WON', 'WON AT TRIAL' ) THEN 'Closed – Repudiated'
             WHEN dim_matter_header_current.date_closed_case_management IS NULL AND UPPER(TRIM(dim_detail_outcome.[outcome_of_case])) IN ( 'DISCONTINUED','DISCONTINUED  - PRE-LIT','DISCONTINUED - INDEMNIFIED BY 3RD PARTY', 'DISCONTINUED - INDEMNIFIED BY THIRD PARTY', 'DISCONTINUED - POST LIT WITH NO COSTS ORDER', 'DISCONTINUED - POST-LIT WITH COSTS ORDER', 'DISCONTINUED - POST-LIT WITH NO COSTS ORDER', 'DISCONTINUED - PRE LIT NO COSTS ORDER', 'DISCONTINUED - PRE-LIT', 'STRUCK OUT', 'WON', 'WON AT TRIAL' ) THEN 'Repudiated'
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL AND UPPER(TRIM(dim_detail_claim.[capita_settlement_basis])) IN ('CLAIM DISCONTINUED - QOCS','CLAIM DISCONTINUED - RECOVERED DEFENDANT COSTS','CLAIM DISCONTINUED - RECOVERING DEFENDANT COSTS','DROP HANDS','WON AT TRIAL' ) THEN 'Closed – Repudiated'
             WHEN dim_matter_header_current.date_closed_case_management IS NULL AND UPPER(TRIM(dim_detail_claim.[capita_settlement_basis])) IN ('CLAIM DISCONTINUED - QOCS','CLAIM DISCONTINUED - RECOVERED DEFENDANT COSTS','CLAIM DISCONTINUED - RECOVERING DEFENDANT COSTS','DROP HANDS','WON AT TRIAL' ) THEN 'Repudiated'
			 WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN 'Closed'
             WHEN dim_detail_core_details.[capita_category_position_code] = '15' THEN 'Recovery'
             WHEN dim_detail_core_details.[capita_category_position_code] = '14' AND ISNULL(fact_detail_client.[nhsla_spend], 0) = 0 THEN  'Repudiated'
             WHEN dim_detail_core_details.[capita_category_position_code] = '13' OR fact_finance_summary.[claimants_total_costs_paid_by_all_parties] > 0 OR fact_finance_summary.[claimants_costs_paid] > 0 OR dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN 'Costs Settled'
             WHEN dim_detail_core_details.[capita_category_position_code] = '12' OR  dim_detail_outcome.[outcome_of_case] IS NOT NULL  OR  dim_detail_outcome.[date_claim_concluded] IS NOT NULL OR  fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] > 0 OR fact_finance_summary.[damages_paid] > 0 THEN  'Damages Paid'
			   ELSE 'Live' END,
			   dim_detail_core_details.present_position,

			   date_closed_case_management ,

			   /* “Closed” tab – can I just check the logic on this tab

It should only include matters where last bill date is in the selected period AND 
dim_detail_core_details[present_position] is “Final bill sent – unpaid”/”To be closed/minor balances to be clear” OR closed in MatterSphere
*/

			Open_closed =
			
			CASE WHEN TRIM(dim_detail_core_details.[present_position]) IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear')
			          AND CAST(final_bill_date AS DATE)  BETWEEN @StartDate AND @EndDate THEN 'Closed' 
	             
				 WHEN date_closed_case_management IS NOT NULL AND CAST(final_bill_date AS DATE)  BETWEEN @StartDate AND @EndDate THEN 'Closed'  
			                  
				 WHEN date_closed_case_management IS NULL AND CAST(date_opened_case_management AS DATE) >='2022-01-01' THEN 'Open'
			     WHEN date_closed_case_management IS NULL AND (dim_detail_core_details.present_position NOT LIKE '%Final bill sent%' AND  dim_detail_core_details.present_position NOT LIKE '%To be closed%') THEN  'Current caseload' 
			     END


			,final_bill_date
			,dim_detail_core_details.capita_category_position_code
		,CASE WHEN CONVERT(DATE,final_bill_date,103) BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS [FileClosedPeriod]
		,CASE WHEN CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate AND @EndDate THEN 1 ELSE 0 END AS [FileOpenedPeriod]
		,date_costs_settled
		,date_claim_concluded
		--00516705 00000696
		FROM  red_dw.dbo.fact_dimension_main
		JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
		LEFT JOIN red_dw..dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
		LEFT JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
		LEFT JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
		LEFT JOIN red_dw.dbo.dim_detail_practice_area
		ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
		LEFT JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
		LEFT JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
		LEFT JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		LEFT JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
		LEFT JOIN red_dw.dbo.fact_detail_claim
		ON fact_detail_claim.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_elapsed_days
		ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
		LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
		LEFT JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
		LEFT JOIN red_dw.dbo.dim_defendant_involvement
		ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
		LEFT JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_client
		ON fact_detail_client.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		LEFT JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key
		
		WHERE 1 =1
		AND dim_matter_header_current.[reporting_exclusions] = 0
        AND dim_matter_header_current.[master_client_code] = 'W15349'
        AND 
		CASE WHEN date_closed_case_management IS NOT NULL  AND final_bill_date >= '2022-01-01'  THEN 'Closed' 
			                   WHEN (dim_detail_core_details.present_position  LIKE '%Final bill sent%' OR dim_detail_core_details.present_position LIKE '%To be closed%') AND final_bill_date >= '2022-01-01' THEN 'Closed'
							   WHEN date_closed_case_management IS NULL AND CAST(date_opened_case_management AS DATE) >='2022-01-01' THEN 'Open'
			                   WHEN date_closed_case_management IS NULL AND (dim_detail_core_details.present_position NOT LIKE '%Final bill sent%' AND  dim_detail_core_details.present_position NOT LIKE '%To be closed%') THEN  'Current caseload' 
							   END IS NOT NULL

		AND CAST(date_opened_case_management AS DATE) < @EndDate
		
		-- // search("Insurance/Costs*", dim_matter_worktype[work_type_name], 1, 0) = 0,
          --//  search("PIP*",  dim_client_involvement[insurerclient_reference], 1, 0) = 0
          --//,dim_matter_header_current[master_client_matter_combined]="W15373-1089"

ORDER BY
    dim_client.[client_code],
    dim_matter_header_current.[matter_number]




	
GO
