SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<ORlagh Kelly>
-- Create date: <2021-01-15>
-- Description:	<#84997 Royal Mail Employment Audit Report & stored procedure>
-- Matters to include - client code R1001 where Matter Group is “Employment” 
-- and limited to where the MI field cboProspAcc (the first of the audit questions) has been completed.
-- =============================================

CREATE PROCEDURE [dbo].[RoyalMailEmploymentAudit]

AS
BEGIN

    SET NOCOUNT ON;
    SELECT 

	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number AS [Weightmans Reference], 
	dim_matter_header_current.matter_description [Matter Description], 
	dim_fed_hierarchy_history.[name] [Case Manager],
    dim_employee.postid AS [Grade],
	dim_matter_header_current.date_opened_case_management [Date Opened],


dim_detail_practice_area.[primary_case_classification][Primary Case Classification],
dim_detail_practice_area.[secondary_case_classification][Secondary Case Classification],
dim_detail_outcome.[date_claim_concluded][Date of Outcome],
dim_detail_practice_area.[emp_prospects_of_success][Prospects of Success],
dim_detail_practice_area.[emp_outcome][Outcome],
fact_detail_reserve_detail.[potential_compensation][Potential Compensation],
fact_detail_paid_detail.[actual_compensation][Compensation Paid],
--[Date of Audit],
dim_detail_audit.[rmg_was_the_assessment_of_prospects_accurate][Was the assessment of prospects accurate?],
dim_detail_audit.[rmg_was_the_assessment_of_compensation_accurate][Was the assessment of compensation accurate? ],
dim_detail_audit.[rmg_comments_re_accuracy_of_case_assessment][Comments re: accuracy of case assessment],
dim_detail_audit.[rmg_was_the_advice_suitable][Was the advice suitable?],
dim_detail_audit.[rmg_were_all_key_elements_and_risks_been_identified][Were all key elements and risks been identified? ],
dim_detail_audit.[rmg_comments_re_suitability_of_advice][Comments re: suitability of advice],
dim_detail_audit.[rmg_was_the_claim_allocated_at_the_correct_level][Was the claim allocated at the correct level?],
dim_detail_audit.[rmg_comments_re_allocation][Comments re: allocation],
dim_detail_audit.[rmg_was_the_advice_clear_and_concise][Was the advice clear and concise?],
dim_detail_audit.[rmg_comments_re_quality_of_advice][Comments re: quality of advice],
--dim_detail_audit.[rmg_were_issues_impeding_case_preparation_escalated_without_delay] [Were issues impeding case preparation escalated without delay? ],
dim_detail_audit.[rmg_comments_re_issues_impeding_case_preparation][Comments re: issues impeding case preparation],
dim_detail_audit.[rmg_was_the_advice_aligned_to_rmgs_strategic_goals][Was the advice aligned to RMG’s strategic goals?],
dim_detail_audit.[rmg_comments_re_strategic_alignment_of_advic][Comments re: strategic alignment of advice],
dim_detail_audit.[rmg_were_key_stakeholders_notified_of_key_dates][Were key stakeholders notified of key dates?],
dim_detail_audit.[rmg_comments_re_key_date_notifications][Comments re: key date notifications],
--dim_detail_audit.[were_witnesses_provided_with_documents_at_least_seven_days_before_the_hearing] [Were witnesses provided with documents at least 7 days before the hearing?],
dim_detail_audit.[rmg_comments_provision_of_documents_to_witnesses][Comments re: provision of documents to witnesses],
dim_detail_audit.[rmg_was_the_case_assessment_provided_on_time][Was the case assessment provided on time?],
dim_detail_audit.[rmg_comments_re_provision_of_case_assessment][Comments re: provision of case assessment],
dim_detail_audit.[rmg_was_a_prehearing_update_provided_on_high_profile_cases][Was a pre-hearing update provided on high profile cases?],
dim_detail_audit.[rmg_comments_re_provision_of_prehearing_update][Comments re: provision of pre-hearing update],
dim_detail_audit.[rmg_was_outcome_report_provided_within_two_days][Was outcome report provided within 2 days?],
dim_detail_audit.[rmg_comments_re_outcome_report][Comments re: outcome report],
dim_detail_audit.[rmg_other_auditors_comments][Other auditor's comments]



				   FROM red_dw.dbo.fact_dimension_main 
				   LEFT JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
				   LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
				   LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
				   LEFT JOIN red_dw.dbo.dim_employee ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
				   LEFT JOIN red_dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
				   LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
				   LEFT JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
				   LEFT JOIN red_dw.dbo.fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_detail_paid_detail.master_fact_key
				   LEFT JOIN red_dw.dbo.dim_detail_audit ON dim_detail_audit.dim_detail_audit_key = fact_dimension_main.dim_detail_audit_key



    WHERE fact_dimension_main.master_client_code = 'R1001'
	AND dim_matter_worktype.work_type_code IN
(
'0012    ',
'1078    ',
'1114    ',
'1325    '
)

AND dim_matter_header_current.matter_number <> 'ML'
AND dim_matter_header_current.reporting_exclusions = 0 
AND dim_detail_audit.rmg_was_the_assessment_of_prospects_accurate IS NOT NULL 


END;
GO
