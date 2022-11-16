SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PoliceInquestTriageTool]

AS 

BEGIN 

SELECT RTRIM(master_client_code)+'-'+RTRIM(master_matter_number) AS [Mattersphere Client/Matter Code]
,matter_description AS [Matter Description]
,red_dw.dbo.dim_matter_header_current.date_opened_case_management AS [Date Opened]
,matter_owner_full_name AS [Case Manager]
,work_type_name AS [Matter Type]
,client_name AS [Client Name]
,dim_detail_inquests.name_of_familys_rep AS [Name of Family’s representative (Counsel/Firm)]
,dim_detail_inquests.learning_points AS [Learning points]
,dim_detail_inquests.date_of_review AS [Date of Review ]
,fact_detail_inquests.years_call_pqe_own_advocate AS [Years call/PQE of own advocate]
,fact_detail_inquests.number_of_witnesses AS [Number of own witnesses]
,fact_detail_inquests.familys_rep_fees_paid AS [Family’s representatives’ fees (inc. VAT) paid]
,fact_detail_inquests.familys_rep_fees_claimed AS [Family’s representatives’ fees (inc. VAT) claimed]
,fact_detail_inquests.familys_rep_disbs_claimed AS [Family’s representatives’ disbursements (inc. VAT) claimed]
,fact_detail_inquests.familys_rep_disbs_paid AS [Family’s representatives’ disbursements (inc. VAT) paid]
,dim_detail_inquests.staff_specifically_requested_support_or_rep_at_hearing		 AS [Has a member of staff specifically requested support or representation at the hearing?]
,dim_detail_inquests.psd_report_critical_of_any_aspect_of_police_actions		 AS [Is the PSD report critical (or, if incomplete, expected to be critical) of any aspect of Police actions?]
,dim_detail_inquests.accept_pathologists_cause_of_death AS [Do we accept the Pathologist’s cause of death?]
,dim_detail_health.nhs_length_of_inquest		  AS [Length of Inquest?]
,dim_detail_inquests.ongoing_iopc_investigation  AS [Is there an ongoing IOPC investigation?]
,dim_detail_inquests.formal_complaint_or_incident_reported_in_connection_with_death		 AS [Has there been a formal complaint made or an Incident reported in connection with the death?]
,dim_detail_inquests.family_have_legal_representation  AS [Does the family (or any other IP) have legal representation?]
,dim_detail_inquests.evidence_of_failure_to_comply_with_relevant_police_policy_proced  AS [Is there evidence of a potential failure to comply with a relevant Police Policy, Procedure or Guideline? ]
,dim_detail_inquests.death_of_child_or_vulnerable_adult  AS [Was this a death of a child or vulnerable adult?]
,dim_detail_inquests.coroner_instructed_expert_or_evidence_to_coroner_relevant_to_pol  AS [Has the Coroner instructed an expert]
,dim_detail_inquests.deceased_have_vulnerable_person_profile_or_suicide_prevention_pl  AS [Does the deceased have a vulnerable person profile or suicide prevention plan?]
,dim_detail_inquests.conflicts_of_interest_or_dispute_between_police_staff  AS [Is there any concern about conflicts of interest or any dispute between police staff? ]
,dim_detail_inquests.deceased_in_contact_with_police_21_days_prior_to_death  AS [Was the deceased in contact with the police within 21 days prior to death?]
,dim_detail_inquests.case_inherently_striking_or_unusual  AS [Is this case inherently striking or unusual in any way?]
,dim_detail_inquests.involve_recurrent_issues_or_people_of_recurrent_concern  AS [Does this case involve recurrent issues or people of recurrent concern?]
,dim_detail_inquests.involve_or_connected_to_celebrity_or_high_profile_individual_bus  AS [Does the case involve or is it connected to a celebrity or high profile individual/business?]
,dim_detail_inquests.attracted_media_attention_or_expected  AS [Has this case attracted media attention already, or is extensive media coverage of the hearing expected?]
,dim_detail_inquests.potentially_article_2_case_and_or_likely_to_involve_a_jury  AS [Is this potentially  an Article 2 case and/or likely to involve a jury?]
,dim_detail_inquests.potential_for_high_value_civil_claim	 AS [Is there potential for high value civil claim (exposure over £100k including costs)?]
,dim_detail_inquests.issues_about_communications_with_other_agencies_or_organisations		  AS [Does the case involve issues about communications with other agencies or organisations?]
,dim_detail_inquests.all_deadlines_by_court_met		  AS [Have all deadlines imposed by the Court been met?]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_billed AS [VAT]
,wip AS [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled disbursements]
,last_bill_date AS [Date of last bill]
,last_time_transaction_date AS [Date of last time posting]
 FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_inquests
	ON dim_detail_inquests.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
	ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_inquests
	ON fact_detail_inquests.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
 ON fact_matter_summary_current.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE work_type_name='PL - Pol - Inquests'
AND dim_matter_header_current.date_closed_case_management IS NULL
AND reporting_exclusions=0

END 
GO
