SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Max Taylor
-- Create date: 2020-12-02
-- Description:	New report called WWL Remedy Listing Report Ticket 81282 New Report for Remedy Campaign

-- =============================================
CREATE PROCEDURE [dbo].[HealthcareWWLRemedyListingReport]

AS

BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

SELECT 
 [File Ref]  =                                  red_dw.dbo.dim_matter_header_current.master_client_code + ' ' + dim_matter_header_current.master_matter_number
,[Trust Ref] =                                  dim_client_involvement.client_reference
,[Complaint Name] =                             dim_claimant_thirdparty_involvement.[claimant_name]
,[File Handler] =                               dim_fed_hierarchy_history.name 
,[Date Instructions Received] =                 CAST(dim_detail_core_details.[date_instructions_received] AS DATE)
,[Date instructions acknowledged] =             dim_detail_health.remedy_date_instructions_acknowledged
,[Date Complaint made] =                        dim_detail_health.remedy_date_complaint_made
,[Date Complaint Response due] =                dim_detail_health.remedy_date_complaint_response_due
,[Date Complaint Response sent to Trust] =   	dim_detail_health.remedy_date_complaint_response_sent_to_trust
,[Ward] =                                       dim_detail_health.remedy_ward
,[Speciality] =                                 dim_detail_health.[remedy_speciality]
,[Type of Complaint] =                          CASE WHEN cboTypeOfComp = 'TC1' THEN 'Individual' ELSE cboTypeOfComp  END COLLATE Latin1_General_BIN
,[NHS Staff comments required?] =               dim_detail_health.remedy_nhs_staff_comments_required
,[NHS Staff interview required?] =              dim_detail_health.remedy_nhs_staff_interview_required
,[Complaint Type] =                             COALESCE(dim_detail_health.remedy_complaint_type, cboCompType) COLLATE Latin1_General_BIN
,[Complaint Summary] =                          dim_detail_health.remedy_complaint_summary
,[Complaint Category] =                         dim_detail_health.[remedy_complaint_category]
,[Safety & Learning recommendations made?] =    dim_detail_health.[remedy_safety_and_learning_recommendations_made]
,[Medical records received?] =                  dim_detail_health.[remedy_medical_records_received]
,[CQC involvement?] =                           dim_detail_health.[remedy_cqc_involvement]
,[PHSO involvement?] =                          dim_detail_health.[remedy_phso_involvement]
,[Associated Inquest/Litigation?] =             CASE WHEN cboAssInqLit = 'AIG1' THEN 'No' ELSE cboAssInqLit END COLLATE Latin1_General_BIN --COALESCE(dim_detail_health.[remedy_associated_inquest_litigation], 
,[Revenue Billed] =                             fact_finance_summary.total_amount_billed 
,[Disbursements Billed] =                       fact_finance_summary.total_billed_disbursements_vat
,[WIP] =                                        fact_finance_summary.[wip]
,[Unbilled Disbursements]  =                    fact_finance_summary.total_unbilled_disbursements_vat
,[Open/Closed Case Status] =                    CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL 
	                                            THEN 'Open' ELSE 'Closed' END
												
,[Matter Description]   =                         REPLACE(matter_description, 'REMEDY: Complaint - ', '')


FROM red_dw.dbo.fact_dimension_main 

LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history  on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_matter_header_current on dim_matter_header_current.client_code = fact_dimension_main.client_code and dim_matter_header_current.matter_number = fact_dimension_main.matter_number 
LEFT JOIN red_dw.dbo.dim_detail_core_details on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.dim_detail_health on dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key 
LEFT JOIN red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key 
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_claimant_thirdparty_involvement ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key

/*Temp fix to correct DW issue*/

LEFT JOIN ms_prod.dbo.udRemedy ON CAST(dim_matter_header_current.ms_fileid AS NVARCHAR(20))   = CAST(udRemedy.fileID AS NVARCHAR(20)) COLLATE Latin1_General_BIN 

WHERE   1 = 1
		AND dim_matter_header_current.client_code = 'W15636'
		AND work_type_name = 'Healthcare - Remedy'



END
GO
