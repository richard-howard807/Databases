SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
CREATE PROCEDURE [dbo].[NEPOBilling] -- EXEC  dbo.NEPOBilling  '2019-05-01','2019-06-30'
(	@start_date DATE
	,@end_date DATE
)		
AS

	

	SELECT client.client_name
			, 'Weightmans LLP' panel_firm
			--, CASE WHEN header.matter_category = 'Real Estate' THEN 'Lot 1: Regeneration'  ELSE 'Lot 2: Full range of Legal Services' END lot
			, COALESCE (NULLIF(core.clients_claims_handler_surname_forename,''),client_invol.clientcontact_name) [instructing_officer]
			, header.date_opened_case_management [date_of_instruction]
			, RTRIM(bills.client_code)+ '-' + bills.matter_number [matter_no]
			, header.matter_description
			, header.fee_arrangement
			, COALESCE(ISNULL(finance.revenue_and_disb_estimate_net_of_vat,finance.commercial_costs_estimate),finance.fixed_fee_amount,finance.defence_costs_reserve) [fee_quoted]
			, bills.bill_number [invoice_number]
			, bills.bill_date [date_of_invoice]
			, header.matter_owner_full_name [weightmans_case_handler]
			, hierarchylevel2hist AS Division
			, SUM(bills.bill_amount) [invoiced_amount]
	

	FROM red_dw.dbo.fact_bill_activity bills
	INNER JOIN red_dw.dbo.dim_client client ON client.dim_client_key = bills.dim_client_key
	INNER JOIN red_dw.dbo.dim_matter_header_current header ON header.dim_matter_header_curr_key = bills.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.fact_finance_summary finance ON finance.client_code = bills.client_code AND finance.matter_number = bills.matter_number
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
	 ON header.fee_earner_code=dim_fed_hierarchy_history.fed_code AND dss_current_flag='Y'
	LEFT JOIN red_dw.dbo.dim_detail_core_details core ON core.client_code = bills.client_code AND core.matter_number = bills.matter_number
	LEFT JOIN red_dw.dbo.dim_client_involvement client_invol ON client_invol.client_code = bills.client_code AND client_invol.matter_number = bills.matter_number
	WHERE header.master_client_code IN 
	(
	'W21199','W23111','M15277','W20534','W27100','W20086'
	)
	AND bills.bill_date BETWEEN @start_date AND @end_date
	--AND hierarchylevel2hist='Legal Ops - LTA' -- Added per request #23052

	GROUP BY client.client_name
			--, CASE WHEN header.matter_category = 'Real Estate' THEN 'Lot 1: Regeneration'  ELSE 'Lot 2: Full range of Legal Services' END 
			, COALESCE (NULLIF(core.clients_claims_handler_surname_forename,''),client_invol.clientcontact_name) 
			, header.date_opened_case_management 
			, RTRIM(bills.client_code)+ '-' + bills.matter_number 
			, header.matter_description
			, header.fee_arrangement
			, COALESCE(ISNULL(finance.revenue_and_disb_estimate_net_of_vat,finance.commercial_costs_estimate),finance.fixed_fee_amount,finance.defence_costs_reserve) 
			, bills.bill_number 
			, bills.bill_date 
			, header.matter_owner_full_name 
			,hierarchylevel2hist

	


GO
