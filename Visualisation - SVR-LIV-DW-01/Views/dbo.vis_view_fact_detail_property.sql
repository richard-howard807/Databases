SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






CREATE VIEW [dbo].[vis_view_fact_detail_property]
AS 

SELECT  [master_fact_key]
--		,[source_system_id]
--      ,[client_code]
--      ,[bibbys_agent_estimate]
--      ,[capital_contribution]
      ,[car_spaces_inc]
--      ,[claim_bibbys_landlord]
      ,[client_paying]
--      ,[company_search_fee]
      ,[contribution]
      ,[contribution_percent]
      ,[current_rent]
--      ,[deposit]
      ,[disbursements_estimate]
--      ,[disposal_price]
      ,[fee_estimate]
      ,[floor_area_square_foot]
      ,[full_price]
      ,[gifa_as_let_sq_feet]
--      ,[individual_search_fee]
      ,[mezz_sq_feet]
      ,[next_rent_amount]
      ,[no_of_bedrooms]
      ,[original_rent]
      ,[passing_rent]
--      ,[penalty_sum_1]
--      ,[penalty_sum_2]
--      ,[penalty_sum_3]
--      ,[penalty_sum_4]
--      ,[penalty_sum_5]
      ,[proposed_rent]
      ,[ps_purchase_price]
--      ,[punch_outlet_number]
      ,[purchase_price]
      ,[reduced_purchase_price]
--      ,[rent]
      ,[rent_arrears]
--      ,[reservation_fee]
      ,[sales_admin_sq_ft]
      ,[service_charge]
--      ,[settled]
--      ,[shg_amount_of_costs]
--      ,[shg_tp_actual_costs]
--      ,[shg_tp_estimate_costs]
      ,[size_square_foot]
      ,[store_sq_ft]
      ,[third_party_pay]
      ,[total_sq_ft]
--      ,[value_price]
--      ,[matter_number]
--      ,[dss_create_time]
--      ,[dss_update_time]
--      ,[ps_stamp_duty]
--      ,[amount_claimed_tenant]
--      ,[damages_tenant]
--      ,[tenants_solicitors_costs]
--      ,[sub_lease_rent]
  FROM [red_dw].[dbo].[fact_detail_property] WITH (NOLOCK)


GO
