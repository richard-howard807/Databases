SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-07-16
-- Description:	#105216, new report request for supplier contract details, for risk and compliance
-- =============================================

-- =============================================

CREATE PROCEDURE [dbo].[SupplierContracts] 

	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT dim_matter_header_current.master_client_code AS [Client Code]
	, dim_matter_header_current.master_matter_number AS [Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, MS.[Annual Review Questionnaire complete] AS [Annual Review Questionnaire Complete]
	, [billing_frequency] AS [Billing Frequency]
	, [budget_holder] AS [Budget Holder]
	, [Business Services Dept] AS [Business Services Dept]
	, MS.[Signed Supplier Code of Conduct] AS [Signed Supplier Code of Conduct]
	, [currency] AS [Currency]
	, [formal_contract_agreed] AS [Formal Contract Agreed]
	, [pqq_complete] AS [PQQ Complete]
	, [savings] AS [Savings]
	, [supplier_criticality] AS [Supplier Criticality]
	, [status] AS [Status]
	, [termination_notice_period] AS [Termination Notice Period]
	, [wllp_contract_owner] AS [WLLP Contract Owner]
	, [budget_figure] AS [Budget Figure]
	, [contract_cost] AS [Contract Cost]
	, [cyber_insurance_limit_of_indemnity] AS [Cyber Insurance Limit of Indemnity]
	, [employers_liability_insurance_limit_of_indemnity] AS [Employer's Liability Insurance Limit of Indemnity]
	, [professional_indemnity_insurance_limit_of_indemnity] AS [Professional Indemnity Insurance Limit of Indemnity]
	, [public_liability_insurance_limit_of_indemnity] AS [Public Liability Insurance Limit of Indemnity]
	, [savings_amount] AS [Savings Amount]
	, [next_annual_review_date] AS [Next Annual Review Date]
	, [annual_review_questionnaire_sent] AS [Annual Review Questionnaire Sent]
	, [cyber_insurance_expiry_date] AS [Cyber Insurance Expiry Date]
	, [employers_liability_insurance_expiry_date] AS [Employer's Liability Insurance Expiry Date]
	, [expiry_date] AS [Expiry Date]
	, [iso_14001_certificate_expiry_date] AS [ISO 14001 Certificate Expiry date]
	, [iso_27001_certificate_expiry_date] AS [ISO 27001 Certificate Expiry date]
	, [iso_9001_certificate_expiry_date] AS [ISO 9001 Certificate Expiry Date]
	, [pqq_review_date] AS [PQQ Review Date]
	, [professional_indemnity_insurance_expiry_date] AS [Professional Indemnity Insurance Expiry Date]
	, [public_liability_insurance_expiry_date] AS [Public Liability Insurance Expiry Date]
	, [start_date] AS [Start Date]
	, [termination_notice_date] AS [Termination Notice Date]
	, [basis_of_contract] AS [Basis of Contract]
	, [changes_at_renewal] AS [Changes at Renewal]
	, [comments] AS [Comments]
	, [contract_number] AS [Contract Number (if known)]
	, [contract_description] AS [Contract Description]
	, [data_location] AS [Data Location]
	, [supplier_code_of_conduct_varied] AS [Supplier Code of Conduct Varied]
	, [supplier_contact_email_address] AS [Supplier Contact Email Address]
	, [supplier_contact_number] AS [Supplier Contact Number]
	, [supplier] AS [Supplier]
	, [supplier_contact] AS [Supplier Contact]
	--, dim_matter_header_current.client_balance_review AS [Client Balance Review]
	--, dim_matter_header_current.client_balance_review_comments AS [Client Balance Review Comments]
	--, dim_matter_header_current.date_client_balance_review AS [Date of last Client Balance Review]
	,MS.[Date Contract Reviewed]
	,MS.[Risk Captured]
	,MS.[Risk Classification]
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_suppliers
ON dim_detail_suppliers.dim_detail_suppliers_key = fact_dimension_main.dim_detail_suppliers_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_suppliers
ON fact_detail_suppliers.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_audit
ON dim_detail_audit.dim_detail_audit_key = fact_dimension_main.dim_detail_audit_key
LEFT OUTER JOIN 
(

SELECT fileID,txtRiskCaptured AS [Risk Captured]
,cboRiskClass AS [Risk Classification]
,dteContRe AS [Date Contract Reviewed]
,Description	AS [Business Services Dept]
,CASE WHEN cboCodeOfCond='Y' THEN 'Yes' WHEN cboCodeOfCond='N' THEN 'No' WHEN cboCodeOfCond='V' THEN 'Varied'  WHEN cboCodeOfCond='R' THEN 'Refused'  ELSE cboCodeOfCond END AS	[Signed Supplier Code of Conduct]
,CASE WHEN cboAnnuRevComp='Y' THEN 'Yes' WHEN cboAnnuRevComp='N' THEN 'No' WHEN cboAnnuRevComp='V' THEN 'Varied'  WHEN cboAnnuRevComp='R' THEN 'Rejected'  ELSE cboAnnuRevComp END  AS [Annual Review Questionnaire complete]
FROM  ms_prod.dbo.udMISupplierContracts
LEFT OUTER JOIN  TE_3E_Prod.dbo.SectionGroup 
ON cboBusServSup=Code COLLATE DATABASE_DEFAULT
WHERE txtRiskCaptured IS NOT NULL OR 
cboRiskClass IS NOT NULL OR 
dteContRe IS NOT NULL OR 
cboBusServSup IS NOT NULL OR 
cboCodeOfCond IS NOT NULL OR 
cboAnnuRevComp IS NOT NULL 
) AS MS
 ON ms_fileid=ms.fileID
WHERE dim_matter_header_current.reporting_exclusions=0
AND dim_matter_header_current.master_client_code='W04776'
    
END
GO
