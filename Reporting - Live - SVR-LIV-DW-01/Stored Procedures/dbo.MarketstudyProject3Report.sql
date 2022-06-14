SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [dbo].[MarketstudyProject3Report]

AS
BEGIN
       


SELECT
matter_description AS [Insured]
,YEAR(incident_date) AS [YOA]
,client_reference  AS [Claim No]
,clients_claims_handler_surname_forename AS [MISL Handler]
,incident_date AS [Date of Loss]
,'Weightmans' AS [Panel Firm]
,name AS [Fee Earner]
,RTRIM(master_client_code)+'-'+master_matter_number AS [Panel Firm Ref]
,date_instructions_received AS [Date Instructed]
,fact_detail_recovery_detail.msg_client_recoveries_made_on_instruction AS [Net Paid]
,fact_detail_reserve_detail.msg_client_outstanding_reserve_on_instruction AS [Outstanding]
,fact_detail_reserve_detail.msg_client_recovery_reserve_on_instruction AS [Incurred]
,CASE WHEN date_claim_concluded IS NULL THEN 'No' ELSE 'Yes' END AS [Damages Settled?]
,fact_detail_claim.damages_paid_by_client AS [Damages Settlement Amount]
,dim_detail_outcome.date_claim_concluded AS [Date Settled]
,fact_detail_paid_detail.claimants_total_costs_paid_by_all_parties AS [If settlement inclusive of costs, confirm costs amount]
,fact_detail_claim.msg_def_damages_amt AS [Defendant Offer Made]
,dim_detail_claim.msg_def_damages_date_of_offer AS [Date Defendant Offer Made]
,dim_detail_claim.msg_def_type_of_offer AS [Type of Defendant Offer]
,fact_detail_claim.msg_claim_damages_amt AS [Claimant Offer Made]
,dim_detail_claim.msg_claim_damages_date_of_offer AS [Date Claimant Offer Made]
,dim_detail_claim.msg_claim_type_of_offer AS [Type of Claimant Offer]
,dim_detail_core_details.proceedings_issued AS [Proceedings Issued?]
,fact_detail_reserve_detail.damages_reserve AS [Reserve Recommendation Made?]
,dim_detail_outcome.date_referral_to_costs_unit AS [Date QM Costs Instructed]
,date_closed_case_management AS [Date File Closed]
,NULL AS [Relevant Comments (Optional)]
,dim_detail_predict.doc_created_date_key
,dim_detail_predict.predict_run_date_key
,dim_detail_predict.doc_updated_date_key
,dim_detail_core_details.present_position
,msg_claim_strategy
,matter_description AS [Full Case Description]
,dim_detail_claim.[number_of_claimants]
,fileNotes
,fileExternalNotes
,HoursRec.[Hours recorded to date]
,claimant_name
,outcome_of_case
,dim_detail_claim.[dst_insured_client_name]  
FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_predict WITH(NOLOCK)
 ON dim_detail_predict.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail WITH(NOLOCK)
 ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail WITH(NOLOCK)
 ON fact_detail_recovery_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_claim WITH(NOLOCK)
 ON fact_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim WITH(NOLOCK)
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK)
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN ms_prod.config.dbFile WITH(NOLOCK)
 ON fileID=ms_fileid
LEFT OUTER JOIN (SELECT dim_matter_header_current.dim_matter_header_curr_key,SUM(minutes_recorded)/60 AS [Hours recorded to date] FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.fact_all_time_activity WITH(NOLOCK)
 ON fact_all_time_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE  ms_fileid IN 
(
5235647,5235648,5235649,5235679,5235680,5235681,5235682
,5235683,5235684,5235685,5235686,5235687,5235688,5235689
,5235690,5235691,5235692,5235693,5235694,5235695,5235696
,5235697,5235698,5235650,5235651,5235652,5235653,5235654
,5235655,5235656,5235657,5235658,5235659,5235660,5235661
,5235662,5235663,5235664,5235665,5235666,5235667,5235668
,5235669,5235670,5235671,5235672,5235673,5235674,5235675
,5235676,5235677,5235678,5235338
)
GROUP BY dim_matter_header_current.dim_matter_header_curr_key) AS HoursRec
 ON HoursRec.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE  ms_fileid IN 
(
5235647,5235648,5235649,5235679,5235680,5235681,5235682
,5235683,5235684,5235685,5235686,5235687,5235688,5235689
,5235690,5235691,5235692,5235693,5235694,5235695,5235696
,5235697,5235698,5235650,5235651,5235652,5235653,5235654
,5235655,5235656,5235657,5235658,5235659,5235660,5235661
,5235662,5235663,5235664,5235665,5235666,5235667,5235668
,5235669,5235670,5235671,5235672,5235673,5235674,5235675
,5235676,5235677,5235678,5235338
)

END
GO
