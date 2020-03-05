SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2016-05-27
Description:		Operations Data to drive the Omniscope Dashboards
Current Version:	Initial Create
====================================================
====================================================

*/
 
CREATE PROCEDURE [Omni].[OperationsDataFile]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
		RTRIM(fact_dimension_main.client_code)+'/'+fact_dimension_main.matter_number AS [Weightmans Reference]
		, fact_dimension_main.client_code AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, dim_detail_audit.[client_name] AS  [Client Name]
		, dim_detail_audit.[date_funds_received_client] AS [Date Funds Received Client]
		, dim_detail_audit.[matter_description] AS [Matter Description]
		, dim_detail_audit.[reason_retaining_funds] AS [Reason Retaining Funds]
		, dim_detail_client.[lees_office_where_claim_arose] AS [Lees Office where Claim Arose]
		, COALESCE(dim_detail_client.[lees_practice_area], dim_detail_client.[pa_where_claim_arose]) AS [Lee's Practice Area]
		, dim_detail_client.[office_where_claim_arose] AS [Office where Claim Arose]
		, dim_detail_compliance.[action_plan] AS [Action Plan]
		, dim_detail_compliance.[business_line] AS [Business Line]
		, dim_detail_compliance.[date_of_gift] AS [Date of Gift]
		, dim_detail_compliance.[delivery_date] AS [Delivery Date]
		, dim_detail_compliance.[donor_name] AS [Donor Name]
		, dim_detail_compliance.[gift_description] AS [Gift Description]
		, dim_detail_compliance.[impact] AS Impact
		, dim_detail_compliance.[incident_category] AS [Incident Category]
		, dim_detail_compliance.[incident_type] AS [Incident Type]
		, dim_detail_compliance.[owner] AS [Owner]
		, dim_detail_compliance.[potential_breach_consequences] AS  [Potential Breach Consequences]
		, dim_detail_compliance.[probability] AS Probability
		, dim_detail_compliance.[recipient_name] AS [Recipient Name]
		, dim_detail_compliance.[relationship] AS Relationship
		, dim_detail_compliance.[response] AS Response
		, dim_detail_compliance.[review_date] AS [Review Date]
		, dim_detail_compliance.[status] AS [Status]
		, dim_detail_compliance.[weightmans_involvement] AS [Weightmans Involvement]
		, dim_detail_compliance.date_costs_paid AS [Date Costs Paid]
		, dim_detail_core_details.[regulatory_category] AS [Regulatory Category]
		, dim_detail_practice_area.[better_supervision] AS [Better Supervision]
		, dim_detail_practice_area.[case_managers_name] AS [Case Managers Name]
		, dim_detail_practice_area.[cause] AS Cause
		, dim_detail_practice_area.[complaint_category] AS [Complaint Category]
		, dim_detail_practice_area.[date_closed] AS [Date Closed]
		, dim_detail_practice_area.[date_complaint_received] AS [Date Complaint Received]
		, dim_detail_practice_area.[date_damages_paid] AS [Date Damages Paid]
		, dim_detail_practice_area.[date_insurers_notified] AS [Date Insurance Notified]
		, dim_detail_practice_area.[disciplinary_action] AS [Disciplinary Action]
		, dim_detail_practice_area.[discovery_date] AS [Discovery Date]
		, dim_detail_practice_area.[formal_finding] AS [Formal Finding]
		, dim_detail_practice_area.[insurers_notified] AS [Insurers Notified]
		, dim_detail_practice_area.[internal_notification] AS [Internal Notifications]
		, dim_detail_practice_area.[leo_involved] AS [Leo Involved]
		, dim_detail_practice_area.[nature_of_matter] AS [Nature of Matter]
		--, dim_detail_practice_area.[office_where_claim_arose] AS [Office where Claim Arose] -- is this the same as one above
		, dim_detail_practice_area.[original_clientmatter_number] AS [Original Client Matter Number]
		, dim_detail_practice_area.[pa_where_claim_arose] AS [PA where Claim Arose] 
		, dim_detail_practice_area.[status_of_complaint] AS [Status of Complaint]
		, dim_detail_practice_area.[top_up_notified] AS [Top Up Notified]
		, dim_detail_practice_area.[weightmans_office] AS [Weightmans Office]
		, dim_detail_practice_area.[weightmans_team] AS [Weightmans Team]
		, dim_detail_practice_area.[work_type_code] AS [Work Type Code]
		, dim_detail_practice_area.nature_of_matter AS [Nature of Matter]
		, dim_detail_practice_area.office AS Office
		, fact_detail_client.[aggregate_excess_per_year] AS [Aggregate Excess per year]
		, fact_detail_client.[damages_reserve_risk] AS [Damages Reserve Risk]
		, fact_detail_client.[gift_value] AS [Gift Value]
		, fact_detail_paid_detail.[damages_paid_risk] AS [Damages Paid Risk]
		, fact_detail_client.[costs_paid] AS [Costs Paid Risk]
		, fact_detail_reserve_detail.[total_outstanding_reserve_risk] AS [Total Outstanding Reserve - Risk]
		, fact_detail_paid_detail.[total_payments_made] AS [Total Payments Made Risk]
		, dim_detail_audit.[date_of_audit] AS [Audit Date]
		, dim_detail_audit.[matter_allocation_form] AS [Matter Allocation Form]
		, dim_detail_audit.[schedule_of_payments_form] AS [Schedule of Payments Form]
		, dim_detail_audit.[has_the_file_opening_procedure_been_run_at_outset_of_file] AS [File Opening Procedure]
		, dim_detail_audit.[conflict_search_been_done_at_the_outset] AS [Conflict of Interest Search]
		, dim_detail_audit.[client_care_complied] AS [Client Care Complied]
		, dim_detail_audit.[key_dates_compliant] AS [Key Dates Compliant]
		, dim_detail_audit.[is_the_cru_expiry_date_key_dated] AS [CRU Expiry Date]
		, dim_detail_audit.[expertcounsel_inst_p11_of_emanual] AS [Expert Counsel Instructed]
		, dim_detail_audit.[future_review_activity] AS [Future Review Activity]
		, dim_detail_audit.[money_in_client_account_which_has_been_there_more_than_28ds] AS [Money in Client Account]
		, dim_detail_audit.[letter_year_retention] AS [Letter sent re: 1 year retention?]
		, fact_detail_client.[client_balance] AS [Client Balance]
		, dim_detail_audit.[date_funds_received_client] AS [Date Funds Received into Client Account]
		, dim_detail_audit.[reason_retaining_funds] AS [Reason Provided for Retaining Funds]
		-- audit details will need amendming every year, used in the compliance dashboard
		, dim_detail_audit.[q1_201617_form_b_complete] AS [Q1 Form B Complete]
		, dim_detail_audit.[q2_201617_form_b_complete] AS [Q2 Form B Complete]
		, dim_detail_audit.[q3_201617_form_b_complete] AS [Q3 Form B Complete]
		, dim_detail_audit.[q4_201617_form_b_complete] AS [Q4 Form B Complete]
		, dim_detail_audit.[q1_date_of_audit_1617] AS [Q1 Date of Audit]
		, dim_detail_audit.[q1_201617_client_matter] AS [Q1 Client & Matter]
		, dim_detail_audit.[q2_date_of_audit_1617] AS [Q2 Date of Audit]
		, dim_detail_audit.[q2_201617_client_matter] AS [Q2 Client & Matter]
		, dim_detail_audit.[q3_date_of_audit_1617] AS [Q3 Date of Audit]
		, dim_detail_audit.[q3_201617_client_matter] AS [Q3 Client & Matter]
		, dim_detail_audit.[q4_date_of_audit_1617] AS [Q4 Date of Audit]
		, dim_detail_audit.[q4_201617_client_matter] AS [Q4 Client & Matter]
		, dim_detail_audit.[reason_no_audit_required_201617] AS [Reason no Audit Required]
		, dim_detail_audit.[bcms_name] AS [Audit) BCM Name]
		, dim_detail_audit.[case_managers_fed_initials] AS [Audit) Fee Earner]
		, dim_detail_practice_area.[practice_areas] AS [Audit) Practice Area]
		, dim_detail_practice_area.[weightmans_team] AS [Audit) Team]
		, fact_detail_reserve_detail.[total_outstanding_reserve] AS [Risk Total Outstanding Reserve]
		, dim_detail_practice_area.[practice_area] AS [Practice Areas]
		, fact_detail_reserve_detail.compensation_reserve_compliance AS [Compensation Reserve (Compliance)]
		, fact_detail_paid_detail.compensation_paid_compliance AS [Compensation Paid (Compliance)]
		, dim_detail_practice_area.leo_case_fee_imposed AS [LeO Case Fee Imposed?]
		, fact_detail_cost_budgeting.costs_written_off_compliance AS [Costs Written Off (Compliance)]
		, CASE WHEN dim_detail_practice_area.[date_complaint_received] IS NULL THEN dim_matter_header_current.date_opened_case_management ELSE  dim_detail_practice_area.[date_complaint_received] END  AS [Date Complaint Received/Opened]
		, CASE WHEN dim_detail_compliance.[impact]='4' AND dim_detail_compliance.[probability] IN ('4', '5') THEN 'P1'
			WHEN dim_detail_compliance.[impact]='5' AND dim_detail_compliance.[probability]  IN ('4', '5') THEN 'P1'
			WHEN dim_detail_compliance.[impact]='1' AND dim_detail_compliance.[probability]  IN ('4', '5') THEN 'P2'
			WHEN dim_detail_compliance.[impact]='2' AND dim_detail_compliance.[probability]  IN ('2', '3', '4', '5') THEN 'P2'
			WHEN dim_detail_compliance.[impact]='3' AND dim_detail_compliance.[probability]  IN ('2', '3', '4', '5') THEN 'P2'
			WHEN dim_detail_compliance.[impact]='4' AND dim_detail_compliance.[probability]  IN ('1','2', '3') THEN 'P2'
			WHEN dim_detail_compliance.[impact]='5' AND dim_detail_compliance.[probability]  IN ('1','2', '3') THEN 'P2'
			WHEN dim_detail_compliance.[impact]='1' AND dim_detail_compliance.[probability]  IN ('1','2', '3') THEN 'P3'
			WHEN dim_detail_compliance.[impact]='2' AND dim_detail_compliance.[probability]  IN ('1') THEN 'P3'
			WHEN dim_detail_compliance.[impact]='3' AND dim_detail_compliance.[probability]  IN ('1') THEN 'P3' ELSE ''
	     END AS [Priority]
		 , CAST((CASE WHEN MONTH(dim_matter_header_current.date_opened_case_management) >= 10 THEN CAST(YEAR(dim_matter_header_current.date_opened_case_management) as varchar) + '/' + CAST((YEAR(dim_matter_header_current.date_opened_case_management) + 1) AS varchar)
              ELSE CAST((YEAR(dim_matter_header_current.date_opened_case_management) - 1) AS VARCHAR) + '/' + CAST(YEAR(dim_matter_header_current.date_opened_case_management) AS VARCHAR) 
              END) AS VARCHAR) [Fiscal Period]
			  


FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_detail_audit ON dim_detail_audit.dim_detail_audit_key = fact_dimension_main.dim_detail_audit_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance ON dim_detail_compliance.dim_detail_compliance_key = fact_dimension_main.dim_detail_compliance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area ON dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_client ON fact_detail_client.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_cost_budgeting ON fact_detail_cost_budgeting.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome AS detail_outcome ON detail_outcome.dim_detail_outcome_key=fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current AS dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_client AS dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail AS fact_detail_reserve_detail ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key

WHERE 
ISNULL(detail_outcome.outcome_of_case,'') <> 'Exclude from reports'
AND dim_matter_header_current.matter_number<>'ML'
AND dim_client.client_code NOT IN ('00030645','95000C','00453737')
AND dim_matter_header_current.reporting_exclusions=0
AND (dim_matter_header_current.date_closed_case_management >= '20120101' OR dim_matter_header_current.date_closed_case_management IS NULL)
--AND dim_client.client_code='00006930'
--AND dim_matter_header_current.matter_number='00001524'

ORDER BY 
fact_dimension_main.matter_number
,fact_dimension_main.client_code

END
GO
