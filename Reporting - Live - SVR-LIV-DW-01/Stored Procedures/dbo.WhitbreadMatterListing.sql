SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[WhitbreadMatterListing]
AS
BEGIN
SELECT 
dim_matter_header_current.client_code AS [Client Number]
,dim_matter_header_current.matter_number AS [Matter Number]
,master_client_code AS [MatterSphere Client Number]
,master_matter_number AS [MatterSphere Matter Number]
,matter_description AS [Matter Description]
,dim_detail_practice_area.[case_description] AS [Case Description]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,work_type_name AS [Work Type]
,dim_matter_header_current.date_opened_case_management AS [Date Opened]
,dim_matter_header_current.date_closed_practice_management AS [Date Closed]
,client_group_name AS [Client Group]
,client_name AS [Client Name]
,dim_detail_client.whitbread_brand		AS [Whitbread Brand]
,fact_finance_summary.[fixed_fee_amount] [Fixed Fee Amount]
,dim_detail_finance.[output_wip_fee_arrangement] [Fee Arrangement]
,fact_finance_summary.[revenue_estimate_net_of_vat] [Revenue Estimate]
,dim_detail_practice_area.[primary_case_classification] AS [Primary Case Classification]
,dim_detail_practice_area.[secondary_case_classification] AS [Secondary Case Classification]
,dim_detail_client.[emp_case_classification] AS [EMP Case Classification]
,dim_detail_practice_area.[emp_claimant_represented] AS [Claimant represented?]
,dim_detail_client.[emp_claimants_place_of_work] AS [Claimant's Place of Work]
,dim_detail_client.[emp_rmg_sensitive_case] AS [Sensitive case]
,dim_detail_practice_area.[ec_expiry] AS [EC Expiry]
,dim_detail_advice.[ec_outcome] AS [EC Outcome]
,dim_detail_advice.[ec_status] AS [EC Status]
,dim_detail_advice.[et_claim] AS [ET Claim?]
,dim_detail_practice_area.[emp_present_position] AS [Present position]
,dim_detail_practice_area.[date_et3_due] AS [Date ET3 due]
,dim_detail_practice_area.[emp_prospects_of_success] AS [Prospects of success]
,fact_detail_reserve_detail.[potential_compensation] AS [Potential compensation/pension loss]
,dim_detail_court.[emp_date_of_preliminary_hearing_case_management] AS [Date of preliminary hearing (case management)]
,dim_detail_court.[emp_date_of_preliminary_hearing_jurisdictionprospects] AS [Date of preliminary hearing (jurisdiction/prospects)]
,dim_detail_court.[emp_date_of_final_hearing] AS [Date of final hearing]
,dim_detail_practice_area.[who_was_the_advocate_at_the_hearing] AS [Advocate at hearing]
,dim_detail_court.[length_of_hearing] AS [Length of hearing]
,dim_detail_court.[location_of_hearing] AS [Location of hearing]
,dim_detail_practice_area.[emp_outcome] AS [Outcome]
,dim_detail_practice_area.[emp_stage_of_outcome] AS [Stage of outcome]
,dim_detail_outcome.[date_claim_concluded] AS [Date claim concluded]
,fact_detail_paid_detail.[actual_compensation] AS [Actual compensation]
,dim_detail_practice_area.[date_remedy_hearing] AS [Date of remedy hearing]
,dim_detail_client.[emp_what_isare_the_issues] AS [What are the issues?]
,dim_detail_client.[emp_what_were_the_learning_points] AS [Learning Points]
,dim_detail_client.[financial_risk] AS [Financial Risk]
,dim_detail_client.[reputational_risk] AS [Reputational Risk]
,dim_detail_client.[case_prospects] AS [Case Prospects]
,dim_detail_advice.[brief_description] AS [Brief Description of Advice]
,dim_detail_advice.[issue] AS [Advice Issue]
,dim_detail_advice.[emph_primary_issue] AS [Advice Issue 1]
,dim_detail_advice.[secondary_issue] AS [Secondary Advice Issue]
,dim_detail_advice.[emph_secondary_issue] AS [Secondary Advice Issue 1]
,dim_detail_advice.[case_classification] AS [Advice Case Classification]
,dim_detail_advice.[category_of_advice] AS [Category of Advice]
,dim_detail_advice.[name_of_caller] AS [Caller Name]
,dim_detail_advice.[name_of_caller] AS [Caller Name 1]
,dim_detail_advice.[job_title_of_caller_emp] AS [Caller Job Title]
,dim_detail_advice.[site] AS [Site]
,dim_detail_advice.[region] AS [Region]
,dim_detail_advice.[geography] AS [Geography]
,dim_detail_advice.[name_of_employee] AS [Employee Name]
,dim_detail_advice.[job_title_of_employee] AS [Employee Job Title]
,dim_detail_advice.[job_title_of_employee] AS [Employee Job Title 1]
,dim_detail_advice.[workplace_postcode] AS [Workplace Postcode]
,dim_detail_advice.[employment_start_date] AS [Employment Start Date]
,dim_detail_advice.[risk] AS [Risk]
,dim_detail_advice.[outcome] AS [Advice Outcome]
,dim_detail_advice.[outcome_pe] AS [Advice Outcome 1 ]
,dim_detail_advice.[status] AS [Status]
,dim_detail_advice.[knowledge_gap] AS [Knowledge Gap]
,dim_detail_advice.[policy_issue] AS [Policy Issue]
,dim_detail_advice.[diversity_issue] AS [Diversity Issue]
,dim_detail_advice.[date_last_call] AS [Date of Last Call]
,total_amount_bill_non_comp AS [Total Billed]
,defence_costs_billed_composite AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_non_comp AS [VAT]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled disbursements]
,last_bill_date AS [Date of last bill]
,last_time_transaction_date AS [Date of last time posting]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
  AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_detail_practice_area
 ON dim_detail_practice_area.client_code = dim_matter_header_current.client_code
 AND dim_detail_practice_area.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client
 ON dim_detail_client.client_code = dim_matter_header_current.client_code
 AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_advice
 ON dim_detail_advice.client_code = dim_matter_header_current.client_code
 AND dim_detail_advice.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
 ON fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
 LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_matter_header_curr_key = dim_detail_advice.dim_matter_header_curr_key
WHERE dim_matter_header_current.department_code='0012'
AND dim_matter_header_current.master_client_code = 'W15630'
AND (dim_matter_header_current.date_closed_practice_management IS NULL 
OR dim_matter_header_current.date_closed_practice_management>='2016-01-01')
END
GO
