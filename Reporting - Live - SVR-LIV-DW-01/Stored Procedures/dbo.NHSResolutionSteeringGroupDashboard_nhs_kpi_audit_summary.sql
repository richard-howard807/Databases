SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NHSResolutionSteeringGroupDashboard_nhs_kpi_audit_summary]

@date_period AS NVARCHAR(18)

AS




DECLARE @current_fin_period AS NVARCHAR(18) = @date_period
DECLARE @EndDate AS DATE = (SELECT MAX(calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @current_fin_period)
DECLARE @fin_year AS INT = (SELECT DISTINCT dim_date.fin_year FROM red_dw.dbo.dim_date WHERE dim_date.fin_period = @current_fin_period)
DECLARE @StartDate AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.fin_year = @fin_year - 1)


-- used to set fin year headings for NHSR MI Dashboard report
DECLARE @current_fin_year AS INT = (SELECT DISTINCT dim_date.fin_year FROM red_dw.dbo.dim_date WHERE dim_date.calendar_date = @EndDate)
DECLARE @previous_fin_year AS INT = @current_fin_year - 1
DECLARE @FinYearCheck AS INT = (SELECT fin_year FROM red_dw..dim_date WHERE calendar_date = CAST(GETDATE() AS DATE)  )

DROP TABLE IF EXISTS #handler_time_of_audit

SELECT 
	dim_matter_header_history.master_client_code
	, dim_matter_header_history.master_matter_number
	, dim_matter_header_history.fee_earner_code
	, dim_parent_detail.nhs_audit_date AS audit_date
	, dim_fed_hierarchy_history.name
	, dim_fed_hierarchy_history.hierarchylevel4hist
INTO #handler_time_of_audit
--select dim_matter_header_history.*, nhs_audit_date
FROM red_dw.dbo.dim_matter_header_history
	INNER JOIN red_dw.dbo.dim_parent_detail
		ON dim_parent_detail.client_code = dim_matter_header_history.client_code
			AND dim_parent_detail.matter_number = dim_matter_header_history.matter_number
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_matter_header_history.fee_earner_code = dim_fed_hierarchy_history.fed_code
			AND CAST(dim_parent_detail.nhs_audit_date AS DATE) BETWEEN CAST(dim_fed_hierarchy_history.dss_start_date AS DATE) AND CAST(dim_fed_hierarchy_history.dss_end_date AS DATE)
WHERE
	CAST(dim_parent_detail.nhs_audit_date AS DATE) BETWEEN CAST(dim_matter_header_history.dss_start_date AS DATE) AND CAST(dim_matter_header_history.dss_end_date AS DATE)
	AND dim_matter_header_history.master_client_code = 'N1001'
	--AND dim_matter_header_history.master_matter_number = '16830'


SELECT DISTINCT
	*
	, IIF(all_data.current_fin_year = 'Current', all_data.[Total Points], 0)		AS current_year_total_points 
	, IIF(all_data.current_fin_year = 'Current', all_data.[Possible Points], 0)		AS current_year_possible_points 
	, IIF(all_data.current_fin_year = 'Previous', all_data.[Total Points], 0)		AS previous_year_total_points 
	, IIF(all_data.current_fin_year = 'Previous', all_data.[Possible Points], 0)		AS previous_year_possible_points 
FROM (
	SELECT 
	RTRIM(dim_matter_header_current.master_client_code) + '-' + RTRIM(dim_matter_header_current.master_matter_number)  AS [Weightmans reference AS [Panel Ref]
	,#handler_time_of_audit.name AS [Panel fee earner]
	,dim_detail_health.[nhs_scheme] AS [Scheme]
	,#handler_time_of_audit.hierarchylevel4hist [Team]
	, current_team.current_team
	,[red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) AS [Audit Date]
	, 'Q' + TRIM(STR(dim_date.fin_quarter_no))		AS fin_quarter_formatted
	, CASE
		WHEN dim_date.current_fin_year = 'Current' THEN
			'Q' + TRIM(STR(dim_date.fin_quarter_no)) + ' ' + TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2)))	
		ELSE
			'Q' + TRIM(STR(dim_date.fin_quarter_no)) + ' ' + TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))
	  END				AS quarter_headings
	, TRIM(STR(RIGHT(@previous_fin_year, 2))) + '/' +  TRIM(STR(RIGHT(@current_fin_year, 2)))		AS current_fin_year_formatted
	, TRIM(STR(RIGHT(@previous_fin_year - 1, 2))) + '/' +  TRIM(STR(RIGHT(@previous_fin_year, 2)))	AS previous_fin_year_formatted
	, CASE  WHEN dim_date.fin_year =  @FinYearCheck THEN dim_date.current_fin_year 
	        WHEN dim_date.fin_year <> @FinYearCheck AND dim_date.current_fin_year = 'Historic' THEN 'Previous' 
	        WHEN dim_date.fin_year <> @FinYearCheck AND dim_date.current_fin_year = 'Previous' THEN 'Current' 
	      END current_fin_year 


	---------------SCORING ---------------------------------
	,CASE WHEN nhs_correct_costs_scheme='Not applicable' THEN 0 ELSE 1 END 
	+ CASE WHEN nhs_proactivity_on_file ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_damages_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_c_costs_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_d_costs_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_probabilty_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_esd_reserve_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_breach_of_duty_decision_correct ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_causation_decision_correct ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_correct_choice_of_expert ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_supervisory_process_followed ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_sla_instructions_ack_in_48_hours ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_sla_first_report_deadline_met ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_sla_follow_up_report_deadlines_met ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_sla_pre_trial_report_deadline_met ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_advice_contains_all_required_fields_quality ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_court_deadlines_met ='Not applicable' THEN 0 ELSE 1 END
	+ CASE WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate ='Not applicable' THEN 0 ELSE 1 END
	+ 1 -- Hard Leakage
	+ CASE WHEN nhs_soft_leakage_difficult_unable_to_quantify ='Not applicable' THEN 0 ELSE 1 END AS [Possible Points]

	,CASE WHEN nhs_correct_costs_scheme IN ('Not applicable','No') THEN 0 
	WHEN nhs_correct_costs_scheme ='Partial' THEN 0.5
	ELSE 1 END 
	+ CASE WHEN nhs_proactivity_on_file IN ('Not applicable','No') THEN 0 
	WHEN nhs_proactivity_on_file ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_damages_reserve_accurate IN ('Not applicable','No') THEN 0 
	WHEN nhs_damages_reserve_accurate ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_c_costs_reserve_accurate IN ('Not applicable','No') THEN 0 
	WHEN nhs_c_costs_reserve_accurate ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_d_costs_reserve_accurate IN ('Not applicable','No') THEN 0 
	WHEN nhs_d_costs_reserve_accurate ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_probabilty_reserve_accurate IN ('Not applicable','No') THEN 0 
	WHEN nhs_probabilty_reserve_accurate='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_esd_reserve_accurate IN ('Not applicable','No') THEN 0 
	WHEN nhs_esd_reserve_accurate ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_breach_of_duty_decision_correct IN ('Not applicable','No') THEN 0 
	WHEN nhs_breach_of_duty_decision_correct ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_causation_decision_correct IN ('Not applicable','No') THEN 0 
	WHEN nhs_causation_decision_correct ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_correct_choice_of_expert IN ('Not applicable','No') THEN 0 
	WHEN nhs_correct_choice_of_expert ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_supervisory_process_followed IN ('Not applicable','No') THEN 0 
	WHEN nhs_supervisory_process_followed ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_sla_instructions_ack_in_48_hours IN ('Not applicable','No') THEN 0 
	WHEN nhs_sla_instructions_ack_in_48_hours  ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_sla_first_report_deadline_met IN ('Not applicable','No') THEN 0 
	WHEN nhs_sla_first_report_deadline_met ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_sla_follow_up_report_deadlines_met IN ('Not applicable','No') THEN 0 
	WHEN nhs_sla_follow_up_report_deadlines_met ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_sla_pre_trial_report_deadline_met IN ('Not applicable','No') THEN 0 
	 WHEN nhs_sla_pre_trial_report_deadline_met ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met IN ('Not applicable','No') THEN 0 
	WHEN nhs_sla_advice_on_claimant_p36_offer_deadline_met ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_advice_contains_all_required_fields_quality IN ('Not applicable','No') THEN 0 
	WHEN nhs_advice_contains_all_required_fields_quality ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_court_deadlines_met IN ('Not applicable','No') THEN 0 
	WHEN nhs_court_deadlines_met ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate IN ('Not applicable','No') THEN 0 
	 WHEN nhs_internal_and_nhsr_cms_consistent_and_accurate ='Partial' THEN 0.5
	ELSE 1 END
	+ CASE WHEN fact_child_detail.nhs_hard_leakage_quantified_at <>0 THEN 0 ELSE 1 END 
	+ CASE WHEN nhs_soft_leakage_difficult_unable_to_quantify  IN ('Not applicable','No') THEN 1 
	WHEN nhs_soft_leakage_difficult_unable_to_quantify ='Partial' 

	THEN 0.5 ELSE 0 END AS [Total Points]

	FROM red_dw.dbo.dim_parent_detail
	INNER JOIN red_dw.dbo.dim_child_detail ON dim_child_detail.case_id = dim_parent_detail.case_id
	AND dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
	LEFT OUTER JOIN red_dw.dbo.fact_child_detail ON fact_child_detail.case_id = dim_child_detail.case_id
	AND fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key

	INNER JOIN red_dw.dbo.dim_matter_header_current
	 ON dim_matter_header_current.client_code = dim_parent_detail.client_code
	 AND dim_matter_header_current.matter_number = dim_parent_detail.matter_number
	INNER JOIN red_dw.dbo.dim_detail_health 
	 ON dim_detail_health.client_code = dim_parent_detail.client_code
	 AND dim_detail_health.matter_number = dim_parent_detail.matter_number 

	 INNER JOIN ( SELECT client_code,matter_number,MAX(nhs_audit_date) nhs_audit_date 
					FROM red_dw.dbo.dim_parent_detail 
					WHERE [red_dw].[dbo].[datetimelocal](nhs_audit_date) BETWEEN @StartDate AND @EndDate

					GROUP BY client_code,matter_number ) max_date ON max_date.client_code = dim_parent_detail.client_code
					AND max_date.matter_number = dim_parent_detail.matter_number
					AND max_date.nhs_audit_date = dim_parent_detail.nhs_audit_date
	LEFT OUTER JOIN red_dw.dbo.dim_date
		ON CAST([red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) AS DATE) = dim_date.calendar_date
	INNER JOIN #handler_time_of_audit
		ON #handler_time_of_audit.master_client_code = dim_matter_header_current.master_client_code
			AND #handler_time_of_audit.master_matter_number = dim_matter_header_current.master_matter_number
				AND #handler_time_of_audit.audit_date = dim_date.audit_date
	LEFT OUTER JOIN (
						SELECT DISTINCT
							ds_sh_valid_hierarchy_x.hierarchylevel3
							, ds_sh_valid_hierarchy_x.hierarchylevel4		AS old_team
							, current_hierarchy.hierarchylevel4			AS current_team
						FROM red_dw.dbo.ds_sh_valid_hierarchy_x
							INNER JOIN (
										SELECT *
										FROM red_dw.dbo.ds_sh_valid_hierarchy_x
										WHERE 1 = 1
											AND ds_sh_valid_hierarchy_x.dss_current_flag = 'Y' 
										--	AND ds_sh_valid_hierarchy_x.disabled = 0
											AND ds_sh_valid_hierarchy_x.hierarchylevel3 IN ('Healthcare', 'Regulatory')
										--	AND ds_sh_valid_hierarchy_x.hierarchylevel4 IS NOT NULL
									) AS current_hierarchy
								ON current_hierarchy.hierarchylevel3 = ds_sh_valid_hierarchy_x.hierarchylevel3
									AND current_hierarchy.hierarchynode = ds_sh_valid_hierarchy_x.hierarchynode
								--Birmingham Healthcare 1,'Healthcare Birmingham 1'
						WHERE
							ds_sh_valid_hierarchy_x.hierarchylevel4 IS NOT NULL
				) AS current_team
		ON current_team.old_team = #handler_time_of_audit.hierarchylevel4hist
	WHERE dim_matter_header_current.master_client_code='N1001'
	AND dim_matter_header_current.reporting_exclusions=0
	AND [red_dw].[dbo].[datetimelocal](dim_parent_detail.nhs_audit_date) BETWEEN @StartDate AND @EndDate
) AS all_data
GO
