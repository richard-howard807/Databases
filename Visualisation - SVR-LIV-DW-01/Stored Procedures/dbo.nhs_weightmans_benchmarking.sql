SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/*

	NHS Resolution Dashboard Query:  Will link to tables that contain the data provided by NHS Resolution for the Panel Averages
									 We are concerned with damages paid, defence costs and life cycle.  
									 Tolerance need to be within 10% of the panel average.
									 Damages Paid and shelf life use Date Claim Concluded
									 Defence Costs use Date Claimant Costs Paid Or Date Closed in Case Management System		
									 Office Liverpool Birmingham and London (Manchester fee earners need to fall under Liverpool)
									 We will exclude where Damages Paid is Null but include where Damages Paid = 0

									 Clinical = IN ('CNST','ELS','DH CL')
									 Risk = IN ('DH Liab','LTPS','PES')

									 Shelf life = Date instructions were received (TRA094) to date claim concluded. 

									 PPO Banding - files where NHS122 = Periodical Payments 

									 Levels -	Panel Total
												Best in Show
												Liverpool
												London
												Birmingham
												Weightmans Overall	
									
									Bandings 

									On the spreadsheet you have a defence costs billed banding and a damages paid banding, 
									there should only be one and it is based on the damages paid figure.  For example if we have settled a 
									matter for  £1500 then for all metrics (shelf life, defence costs and damages) the matter should fall under the 
									tranche/banding £1-5000 for risk pool and £1-50,000 for clinical.     Does that make sense?   

									Cases should fall in the shelf life and damages stats for 12 months from the date claim concluded.   
									Cases for the defence costs stats should only be in there for 12 months from date costs paid.   
									Can we also just look at cases where the referral reason is dispute, costs only and infant approval.  

									Lastly, when looking at defence costs can you ensure it’s revenue and disbursements but excludes VAT please.  
	

*/


CREATE PROCEDURE  [dbo].[nhs_weightmans_benchmarking]

AS


;WITH weightmans_data AS (


SELECT --TOP 100* 

	header.master_client_code,
	header.master_matter_number,
	header.client_group_name,
	header.matter_owner_full_name,
	emp_hierarchy.windowsusername,
	nhs_scheme,
	CASE WHEN nhs_scheme IN ('CNST','ELS','DH CL') THEN 'Clinical'
		  WHEN nhs_scheme IN ('DH Liab','LTPS','PES') THEN 'Risk'
	 END [Scheme],
	health.[nhs_claim_status],

	CASE WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid = 0 THEN 'Nil'
		 WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid BETWEEN 1 AND 5000 THEN '1-5,000'
		 WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid BETWEEN 5001 AND 10000 THEN '5,001-10,000'
		 WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid BETWEEN 10001 AND 25000 THEN '10,001-25,000'
		 WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid BETWEEN 25001 AND 50000 THEN '25,001-50,000'
		 WHEN nhs_scheme IN ('DH Liab','LTPS','PES') AND damages_paid >= 50001  THEN 'Over 50,001'

		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND health.[nhs_claim_status] = 'Periodical payments' THEN 'PPOs'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid = 0 THEN 'Nil'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid BETWEEN 1 AND 50000 THEN '1-50,000'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid BETWEEN 50001 AND 250000 THEN '50,001-250,000'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid BETWEEN 250001 AND 500000 THEN '250,001-500,000'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid BETWEEN 500001 AND 1000000 THEN '500,001-1,000,000'
		 WHEN nhs_scheme IN ('CNST','ELS','DH CL') AND damages_paid >= 1000001 THEN 'Over 1,000,000'

	END banding,

	fin.damages_paid,
	fin.defence_costs_billed + fin.disbursements_billed [defence_costs_inc_disbs],
	emp.locationidud [matter_owner_office],
	CASE WHEN emp.locationidud IN ('London NFL','London Hallmark') THEN 'London'
		 WHEN locationidud IN ('Liverpool','Manchester Spinningfields') THEN 'Liverpool'
		 ELSE locationidud
	END [Office],
	header.date_closed_case_management,
	outcome.date_claim_concluded, -- TRA086
	outcome.date_costs_settled, -- FTR087
	DATEADD(DAY,1, EOMONTH(COALESCE(date_costs_settled,date_closed_case_management),-1)) [defence_costs_month],
	DATEADD(DAY,1, EOMONTH(date_claim_concluded,-1)) [damages_and_shelf_month],
	core.date_instructions_received,
	shelf_life.elapsed_days_conclusion [shelf_life],
	outcome.outcome_of_case,
	AVG(fin.damages_paid) OVER () [overall_dp_averge],
	AVG(fin.damages_paid) OVER (PARTITION BY CASE WHEN emp.locationidud IN ('London NFL','London Hallmark') THEN 'London'
		 WHEN emp.locationidud IN ('Liverpool','Manchester Spinningfields') THEN 'Liverpool'
		 ELSE emp.locationidud
	END) [office_dp_average],
	AVG(fin.defence_costs_billed + fin.disbursements_billed) OVER () [overall_dc_averge],
	AVG(fin.defence_costs_billed + fin.disbursements_billed) OVER (PARTITION BY CASE WHEN emp.locationidud IN ('London NFL','London Hallmark') THEN 'London'
		 WHEN emp.locationidud IN ('Liverpool','Manchester Spinningfields') THEN 'Liverpool'
		 ELSE emp.locationidud
	END) [office_dc_average]




FROM red_dw.dbo.fact_dimension_main main
INNER JOIN red_dw.dbo.dim_matter_header_current header ON main.dim_matter_header_curr_key = header.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.fact_finance_summary fin ON fin.master_fact_key = main.master_fact_key
INNER JOIN red_dw.dbo.dim_detail_health health ON health.dim_detail_health_key = main.dim_detail_health_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history emp_hierarchy ON emp_hierarchy.dim_fed_hierarchy_history_key = main.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee emp ON emp_hierarchy.dim_employee_key = emp.dim_employee_key  
LEFT JOIN red_dw.dbo.dim_detail_outcome outcome ON outcome.dim_detail_outcome_key = main.dim_detail_outcome_key
LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.dim_detail_core_detail_key = main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_detail_elapsed_days shelf_life ON main.master_fact_key = shelf_life.master_fact_key

-- adding in panel average figures supplied by NHS



WHERE client_group_code = '00000003'
AND reporting_exclusions = 0
AND referral_reason IS NOT NULL 
AND referral_reason IN ('Dispute on liability and quantum','Dispute on quantum','Dispute on liability','Infant approval', 'Costs dispute','Dispute on Liability','Infant Approval')
AND (outcome.outcome_of_case IS NULL OR  outcome_of_case <> 'Exclude from reports')
AND nhs_scheme IN ('CNST','ELS','DH CL','DH Liab','LTPS','PES')
AND nhs_scheme IS NOT NULL 
AND NOT (header.date_closed_case_management IS NULL AND outcome.date_claim_concluded IS NULL AND outcome.date_costs_settled IS NULL) -- excludes all files where these dates are all null 
AND (date_claim_concluded >=  (SELECT MIN([Month]) FROM [Reporting].[nhs].[panel_averages])
	OR date_costs_settled>= (SELECT MIN([Month]) FROM [Reporting].[nhs].[panel_averages])
	OR date_closed_case_management >= (SELECT MIN([Month]) FROM [Reporting].[nhs].[panel_averages]))


)
	
	SELECT w.master_client_code,
           w.master_matter_number,
           w.client_group_name,
           w.matter_owner_full_name,
           w.windowsusername,
           w.nhs_scheme,
           w.Scheme,
           w.nhs_claim_status,
           w.banding,
           w.damages_paid,
           w.defence_costs_inc_disbs,
           w.matter_owner_office,
           w.Office,
           w.date_closed_case_management,
           w.date_claim_concluded,
           w.date_costs_settled,
           w.defence_costs_month,
           w.damages_and_shelf_month,
           w.date_instructions_received,
           w.shelf_life,
           w.outcome_of_case,
           w.overall_dp_averge,
           w.office_dp_average,
           w.overall_dc_averge,
           w.office_dc_average,
           pd.Panel_dp_average
	FROM weightmans_data w
	LEFT JOIN (SELECT 
			   [Scheme],
			   [Month],
			   [Banding],
			   [Damages Paid] [Panel_dp_average]
 
			FROM [dbo].[nhs_panel_averages]
		WHERE [Level] = 'Panel Total') pd ON w.Scheme = pd.Scheme AND pd.Banding = w.banding AND w.damages_and_shelf_month = pd.[Month]


GO
