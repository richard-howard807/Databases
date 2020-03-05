SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Orlagh Kelly>
-- Create date: <31st August 2018,>
-- Description:	<report to drive the sabre listing report >
-- =============================================
CREATE PROCEDURE [dbo].[SabreListingReport]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;





SELECT 
REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.client_code),'0',' ') ),' ','0')+'-'+REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.matter_number),'0',' ') ),' ','0') AS [Weightmans Reference Trimmmed]
, dim_fed_hierarchy_history.name [Solicitor Claims Handler ]
,dim_fed_hierarchy_history.fed_code
,dim_client_involvement.insurerclient_reference[Sabre Refeference]
, dim_detail_core_details.date_instructions_received  [Date Instructions Received]
, dim_detail_core_details.referral_reason [Referral Reason ]
,dim_detail_core_details.suspicion_of_fraud 
,dim_matter_header_current.date_closed_case_management



, case when dim_employee.locationidud = 'Glasgow' then 'Scottish Claim' 

when dim_detail_core_details.suspicion_of_fraud = 'Yes' then Ltrim(rtrim(dim_detail_core_details.track)) + '/'+  'Fraud '

when dim_detail_core_details.suspicion_of_fraud = 'No' and dim_detail_hire_details.[claim_for_hire] = 'Yes' then rtrim(ltrim(dim_detail_core_details.track))  + '/'+ 'C Hire'

--when Andew Sutton, Amy o Connor, Michelle pearsall , Emma Jevons, Juliet wood 
when dim_fed_hierarchy_history.fed_code  IN ('642' , '1580' ,  '1687', '1590', '1785') then  rtrim(ltrim(dim_detail_core_details.track ))+ '/'+  'Technical  '
when dim_detail_core_details.referral_reason= 'Nomination only                                             ' then 'Nomination'
else   LTRIM(RTRIM(dim_detail_core_details.track)) + '/'+ 'Motor'
end as [Reason For Instruction]

,dim_detail_client.sabre_coop_fraudrmgendsleigh_complaints [Complaint Recieved]
,  dim_matter_header_current.final_bill_date 
,case when dim_detail_core_details.[present_position] in ('Final bill due - claim and costs concluded                  ','To be closed/minor balances to be clear                     ','Final bill sent - unpaid                                    ') then 'Closed' else 'Open' end as 'Status'

, dim_detail_core_details.incident_date  [Date of Incident]
,dim_client_involvement.insuredclient_name [Name of Insured ]
,dim_claimant_thirdparty_involvement.claimant_name [Claimant] 

,dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant Solicitor ] 
--,dim_detail_core_details.claimants_solicitors_name [Claimant Solicitor ]
, dim_detail_core_details.proceedings_issued  [Proceedings Issued]
, dim_detail_core_details.date_proceedings_issued [Date Proceedings Issued ]
,dim_detail_court.[court_location] [Court Location]
, dim_detail_core_details.track  [Track] 
,dim_detail_core_details.[is_there_an_issue_on_liability] [Is there an issue on liability ]
, dim_detail_core_details.suspicion_of_fraud [Fraud ]

, dim_detail_core_details.[does_claimant_have_personal_injury_claim]  [Claim of PI] 
,dim_detail_core_details.[brief_description_of_injury] 

, dim_detail_incident.[description_of_injury_v] 
, case when dim_detail_hire_details.[claim_for_hire] = 'No                                                          ' then 'No'
when dim_detail_hire_details.[claim_for_hire] =  'Yes                                                         ' then 'Yes' else 'No' end as [claim_for_hire]
, fact_finance_summary.[damages_reserve]
, fact_detail_reserve_detail.[claimant_costs_reserve_current]  [TP Costs Reserve ]
, dim_detail_outcome.[outcome_of_case]  [Outcome of Case]
, dim_detail_outcome.date_claim_concluded  [Date Claim Concluded]
, datediff(dd,dim_matter_header_current.date_opened_case_management, dim_detail_outcome.date_claim_concluded)  as [Elapsed Days]
, fact_finance_summary.[damages_paid_to_date] [Damages Paid to Date]
, fact_finance_summary.[total_tp_costs_paid] [TP Costs Paid ]
, fact_finance_summary.[tp_total_costs_claimed] [TP Costs Claimed]
,dim_detail_outcome.[date_costs_settled] [Date TP Costs Paid]
, fact_finance_summary.defence_costs_billed [Revenue]
, fact_finance_summary.disbursements_billed [Disbursements Billed ]
--, case when dim_matter_header_current.date_closed_case_management is null then 'Open' else 'Closed' end as 'Status'
, dim_detail_core_details.incident_location_postcode AS [Accident Location]
, Doogal.Latitude AS [Accident Location Latitude]
, Doogal.Longitude AS [Accident Location Longitude]


from red_dw.dbo.fact_dimension_main 
inner join red_dw.dbo.dim_fed_hierarchy_history  on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_client  on dim_client.client_code = fact_dimension_main.client_code
left outer join red_dw.dbo.dim_detail_client on fact_dimension_main.client_code = dim_detail_client.client_code and dim_detail_client.matter_number = fact_dimension_main.matter_number
inner join red_dw.dbo.dim_matter_header_current on dim_matter_header_current.client_code = fact_dimension_main.client_code and dim_matter_header_current.matter_number = fact_dimension_main.matter_number 
inner join red_dw.dbo.fact_detail_client  on fact_dimension_main.master_fact_key = fact_detail_client.master_fact_key
Left outer join  red_dw.dbo.dim_client_involvement  on dim_client_involvement.dim_client_involvement_key =fact_dimension_main.dim_client_involvement_key 
Left outer join  red_dw.dbo.dim_claimant_thirdparty_involvement  on dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key =fact_dimension_main.dim_claimant_thirdpart_key
inner join red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
Left outer join  red_dw.dbo.dim_detail_outcome  on dim_detail_outcome.client_code = dim_matter_header_current.client_code and dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
Left outer join red_dw.dbo.dim_detail_core_details  on dim_detail_core_details.client_code = dim_matter_header_current.client_code and dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
left outer join red_dw.dbo.dim_detail_hire_details  on dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
left outer join  red_dw.dbo.fact_detail_recovery_detail  on fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
left outer join red_dw.dbo.fact_matter_summary_current  on fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_incident ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance ON dim_detail_compliance.dim_detail_compliance_key = fact_dimension_main.dim_detail_compliance_key
left join red_dw.dbo.dim_detail_practice_area on dim_detail_practice_area.dim_detail_practice_ar_key = fact_dimension_main.dim_detail_practice_ar_key
left join red_dw.dbo.dim_employee on dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
left join red_dw.dbo.dim_detail_health on dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT JOIN red_dw.dbo.dim_detail_court on dim_detail_court.dim_detail_court_key = fact_dimension_main.dim_detail_court_key
left join red_dw.dbo.fact_detail_reserve_detail on fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.Doogal ON Doogal.Postcode = dim_detail_core_details.incident_location_postcode

 
where dim_client.client_group_code = '00000070'

--and (dim_matter_header_current.date_closed_case_management >= '2017-01-01' or dim_matter_header_current.date_closed_case_management is null)
--and( dim_detail_core_details.date_instructions_received <'2017-01-01' ) 
 and( dim_detail_outcome.date_claim_concluded   >= '2017-01-01'  or dim_detail_outcome.date_claim_concluded is null )


and fact_dimension_main.matter_number <> 'ML'
AND dim_matter_header_current.reporting_exclusions <> 1
and dim_detail_outcome.[outcome_of_case]  <> 'Exclude from reports                                        '




END
--GO
GO
