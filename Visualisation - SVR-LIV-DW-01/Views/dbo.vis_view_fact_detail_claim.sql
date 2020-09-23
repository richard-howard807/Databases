SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_fact_detail_claim]
AS 

SELECT [master_fact_key]
--		,[source_system_id]
--      ,[client_code]
--      ,[matter_number]
--      ,[rsa_motor_costs_payment]
--      ,[rsa_motor_cru]
--      ,[rsa_motor_generals]
--      ,[rsa_motor_damages_payment]
--      ,[rsa_motor_nhs]
--      ,[rsa_motor_rehab]
--      ,[rsa_motor_specials]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[claimant_legal_costs_paid]
      ,[claimant_sols_total_costs_sols_claimed]
--      ,[damages_paid_by_client]
--      ,[other_agreed]
--      ,[other_claimed]
--      ,[total_claimed]
--      ,[aig_final_percent_contribution_costs]
--      ,[aig_highest_valuation_offer_exc_claimant_costs]
--      ,[amount_outstanding_comp_costs_cru]
--      ,[amount_paid_comp_costs_cru]
--      ,[opponent_costs_net_reserve]
--      ,[capita_defence_counsels_fees]
--      ,[capita_defendant_audiometry_repeat_cost]
--      ,[capita_defendant_engineers_report_costs]
--      ,[capita_defendant_medical_report_costs]
--      ,[outstanding_claimant_costs]
--      ,[outstanding_reserve_damages_cru_nhs]
--      ,[payments_claimant_costs]
--      ,[payments_damages_cru]
--      ,[saving_costs_claimed]
--      ,[savings_costs_reserve]
--      ,[savings_damages]
--      ,[disease_total_estimated_settlement]
--      ,[coa_coa_maximum_valuation]
--      ,[coa_coa_settlement]
--      ,[disease_insurer_clients_contrib_costs]
--      ,[disease_insurer_clients_contrib_damages]
--      ,[covea_total_amount_last_offer]
--      ,[potential_fraud_saving]
--      ,[cabinet_office_instruction_claim_value]
  FROM [red_dw].[dbo].[fact_detail_claim] WITH (NOLOCK)



GO
