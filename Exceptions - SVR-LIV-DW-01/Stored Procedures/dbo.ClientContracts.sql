SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-11-29
-- Description:	#180135 New Report for client number W08209 - Client Contract Details
-- =============================================
CREATE PROCEDURE [dbo].[ClientContracts]
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT dim_matter_header_current.master_client_code AS [Client Code],
	dim_matter_header_current.master_matter_number AS [Matter Number],
	dim_matter_header_current.matter_description AS [Matter Description],
    dim_detail_suppliers.claims_lta AS [Claims/LTA],
    dim_detail_suppliers.client_data_location_restrictions AS [Client data location restrictions],
	dim_detail_suppliers.client_relationship_partner AS [Client Relationship Partner],
    dim_detail_suppliers.contractual_prerequisites AS [Contractual prerequisites],
    dim_detail_suppliers.contract_auto_renew AS [Contract auto-renew],
    dim_detail_suppliers.client_cont_status AS [Status],
    dim_detail_suppliers.client_formal_contract_agreed AS [Formal contract agreed],
    dim_detail_suppliers.initial_term AS [Initial term],
    dim_detail_suppliers.payment_terms AS [Payment terms],
    dim_detail_suppliers.permitted_use_of_client_data AS [Permitted use of client data],
    dim_detail_suppliers.sla AS [SLA],
    dim_detail_suppliers.sop_fact_sheet AS [SOP (Fact Sheet)],
    dim_detail_suppliers.client_termination_notice_period AS [Termination notice period ],
    dim_detail_suppliers.contract_start_date AS [Contract start date],
    dim_detail_suppliers.client_next_annual_review_date AS [Next annual review date],
    dim_detail_suppliers.renewalexpiry_date AS [Renewal/Expiry date],
    dim_detail_suppliers.client_termination_notice_date AS [Termination notice date],
    dim_detail_suppliers.billing_terms AS [Billing terms],
    dim_detail_suppliers.charge_rate_increase_clause AS [Charge rate increase clause],
    dim_detail_suppliers.client_name AS [Client name],
    dim_detail_suppliers.client_comments AS [Comments],
    dim_detail_suppliers.client_contract_description AS [Contract description],
    dim_detail_suppliers.indemnityliability_caps AS [Indemnity/Liability caps],
    dim_detail_suppliers.risk_register_number AS [Risk Register number],
    dim_detail_suppliers.specified_insurance_level_requirements AS [Specified insurance level requirements],
    dim_detail_suppliers.variation_agreement_description AS [Variation agreement description]
    
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_suppliers
ON dim_detail_suppliers.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.master_matter_number='W08209'

END
GO
