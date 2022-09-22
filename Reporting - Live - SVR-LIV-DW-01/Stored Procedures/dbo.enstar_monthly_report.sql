SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================  
-- Author:  Jamie Bonner  
-- Create date: 31/08/2022
-- Description: initial Create  #165636
-- =============================================  

CREATE PROCEDURE [dbo].[enstar_monthly_report]
   
AS  

DROP TABLE IF EXISTS #last_reserve_update


SELECT *, ROW_NUMBER() OVER(PARTITION BY reserve_changes.dim_matter_header_curr_key ORDER BY reserve_changes.dss_version DESC)	AS rw_num
INTO #last_reserve_update
FROM (
SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, ds_sh_ms_udmicurrentreserves_history.curtotreservcur
	, LAG(ds_sh_ms_udmicurrentreserves_history.curtotreservcur, 1) OVER(PARTITION BY dim_matter_header_current.dim_matter_header_curr_key ORDER BY ds_sh_ms_udmicurrentreserves_history.dss_version)	AS previous_reserve
	-- get previous total current reserve entry and checks if there has been a reserve change. If not, it's excluded as we only need the latest reserve change date	
	, IIF(ds_sh_ms_udmicurrentreserves_history.curtotreservcur = LAG(ds_sh_ms_udmicurrentreserves_history.curtotreservcur, 1) OVER(PARTITION BY dim_matter_header_current.dim_matter_header_curr_key ORDER BY ds_sh_ms_udmicurrentreserves_history.dss_version), 'no_change', 'change')	AS change_check
	, ds_sh_ms_udmicurrentreserves_history.dss_version
	, CAST(ds_sh_ms_udmicurrentreserves_history.dss_update_time AS DATE) AS last_updated
FROM red_dw.dbo.ds_sh_ms_udmicurrentreserves_history
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON ds_sh_ms_udmicurrentreserves_history.fileid = dim_matter_header_current.ms_fileid
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'W26065'
	AND dim_matter_header_current.reporting_exclusions = 0
	-- Exclude matters with no total reserve entered
	AND ds_sh_ms_udmicurrentreserves_history.curtotreservcur IS NOT NULL
) AS reserve_changes
WHERE
	reserve_changes.change_check = 'change'


SELECT 
	COALESCE(dim_client_involvement.insurerclient_reference, dim_client_involvement.client_reference)		AS [Pro Claims Reference]
	, dim_matter_worktype.work_type_name		AS [Disease Type]
	, 'Weightmans LLP'			AS [Supplier Name]
	, dim_matter_header_current.matter_owner_full_name		AS [Supplier Fee Earner]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Matter Number]
	, dim_claimant_thirdparty_involvement.claimant_name		AS [Claimant Name]
	, COALESCE(dim_detail_claim.dst_claimant_solicitor_firm, dim_claimant_thirdparty_involvement.claimantsols_name) 			AS [Claimant Solicitor]
	, CAST(dim_detail_core_details.date_instructions_received AS DATE)		AS [Date of Supplier Instruction]
	, CAST(dim_detail_health.date_of_service_of_proceedings AS DATE)		AS [Date of Service of Proceedings]
	, dim_detail_core_details.present_position			AS [Current Case Status]
	, dim_detail_core_details.delegated		AS [Delegated/Non-Delegated]
	, dim_detail_core_details.referral_reason		AS [Reason for Litigation]
	--, dim_detail_core_details.was_litigation_avoidable			AS [Litigation Avoidable]
	, dim_detail_core_details.zurich_grp_rmg_was_litigation_avoidable		AS [Litigation Avoidable]
	, dim_detail_practice_area.learning_for_pro			AS [Learning for Pro]
	, CAST(dim_detail_court.date_of_trial AS DATE)			AS [Trial Date]
	, fact_detail_reserve_detail.asbestos_disease_perc_of_contribution_from_insurer_client_dmgs	AS [Mercantile % Contribution to Damages]
	, fact_detail_reserve_detail.asbestos_disease_perc_of_contribution_from_ins_client_cls_costs	AS [Mercantile % Contribution to Claimant costs]
	, fact_detail_reserve_detail.asbestos_disease_perc_of_contribution_from_ins_client_def_costs	AS [Mercantile % Contribution to Supplier Fees]
	, dim_detail_practice_area.private_treatment_claimed		AS [Private Treatement Claimed]
	, dim_detail_practice_area.indemnity_order_for_treatment_signed_meso		AS [Indemnity Order for Treatment Signed (Meso)]
	, dim_detail_practice_area.potential_recovery_opportunity		AS [Potential Recovery Opportunity]
	, CASE	
		WHEN dim_detail_claim.date_recovery_concluded IS NOT NULL THEN
			CASE
				WHEN ISNULL(fact_detail_recovery_detail.recovery_claimants_damages_via_third_party_contribution, 0) + ISNULL(fact_detail_recovery_detail.recovery_defence_costs_from_claimant, 0)
					+ ISNULL(fact_detail_recovery_detail.recovery_claimants_costs_via_third_party_contribution, 0) + ISNULL(fact_detail_recovery_detail.recovery_defence_costs_via_third_party_contribution, 0) > 0 THEN
					'Yes'
				ELSE
					'No'
			END 
		ELSE 
			'n/a' 
	  END								AS [Successful Recovery Made]
	, fact_detail_reserve_detail.damages_reserve		AS [Damages Reserve]
	, fact_detail_reserve_detail.claimant_costs_reserve_current		AS [Claimant Costs Reserve]
	, fact_detail_reserve_detail.defence_costs_reserve			AS [Defence Costs Reserve]
	, fact_detail_reserve_detail.total_current_reserve		AS [Total Current Reserve]
	, #last_reserve_update.last_updated AS [Date Reserve Last Amended]
	, NULL				AS [Date Reserve Last Reviewed]
FROM red_dw.dbo.dim_matter_header_current
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.client_code = dim_matter_header_current.client_code
			AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
		ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
			AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_health
		ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_court
		ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
		ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN #last_reserve_update
		ON #last_reserve_update.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND #last_reserve_update.rw_num = 1
	LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
		ON dim_detail_practice_area.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE
	dim_matter_header_current.master_client_code = 'W26065'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND RTRIM(LOWER(ISNULL(dim_detail_outcome.outcome_of_case, ''))) <> 'exclude from reports'
	AND dim_matter_worktype.work_type_group = 'Disease'


GO
