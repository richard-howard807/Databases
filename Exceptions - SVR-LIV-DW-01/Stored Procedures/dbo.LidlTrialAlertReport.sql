SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[LidlTrialAlertReport]

AS 

BEGIN

SELECT DISTINCT
dim_matter_header_current.master_client_code AS [Client Code]
,dim_matter_header_current.master_matter_number AS [Matter Number]
,name AS [Matter Owner]
,matter_description AS [Matter Description]
,dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Client Claims Handler]
,insuredclient_reference AS [Insured Client Reference]
,dim_detail_court.[date_of_trial] AS [Trial Date]
,court_name AS [Trial location]
,dim_detail_core_details.[incident_date] AS [Incident Date]
,dim_detail_core_details.[incident_location] AS [Incident Location]
,dim_detail_claim.[dst_claimant_solicitor_firm] AS [Claimant Solicitors]
,work_type_name AS [Matter Type]
,work_type_group AS [Matter type Group]
,dim_detail_core_details.[brief_details_of_claim] AS [Brief details of claim]
,dim_detail_core_details.[injury_type] AS [Injury/Loss]
,CASE WHEN dim_detail_core_details.[is_there_an_issue_on_liability]= 'Yes' THEN 'Disputed' WHEN dim_detail_core_details.[is_there_an_issue_on_liability]='No' THEN 'Admitted' END  AS [Liability position]
,NULL AS [Reason for Denial]
,witness_name AS [Witness]
,fact_finance_summary.[damages_reserve] AS [Damages Reserve Current]
,fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [TP Costs Reserve Current]
,fact_finance_summary.[defence_costs_reserve] AS [Defence Costs Reserve]
,dim_detail_outcome.[outcome_of_case] AS [Outcome]
,NULL [Reason for Outcome]
,[TrialKeyDateProcedureDate].calendar_date AS [Next Key Date for Trial]
,[TrialDateTodayDate].calendar_date AS [Reminder Trial Due Today]
,dim_detail_claim.date_of_disposal_hearing AS [Date of Disposal Hearing]
,[DisposalHearingKeyDateProcedureDate].calendar_date AS [Next Key Date for Disposal Hearing]
,[SmallClaimsHearingTodayDate].calendar_date AS [Next Key Date for Small Claims Hearing]
,dim_detail_court.date_small_track_hearing AS [Date Small Track Hearing]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.fact_dimension_main
 ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_court_involvement
 ON dim_court_involvement.client_code = dim_matter_header_current.client_code
 AND dim_court_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_witness_involvement
 ON dim_witness_involvement.client_code = dim_matter_header_current.client_code
 AND dim_witness_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
 ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
-----------------------------------------------------
LEFT OUTER JOIN 
(
SELECT dim_matter_header_curr_key
,MIN(TrialDateToday.tskdue) AS calendar_date
FROM red_dw.dbo.dim_tasks AS [TrialDateToday]
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = TrialDateToday.client_code
 AND dim_matter_header_current.matter_number = TrialDateToday.matter_number
WHERE TrialDateToday.task_desccription='Trial date - today'
AND TrialDateToday.tskactive=1
AND CONVERT(DATE,TrialDateToday.tskdue,103)>CONVERT(DATE,GETDATE(),103)
GROUP BY dim_matter_header_curr_key
) AS [TrialDateTodayDate]
 ON TrialDateTodayDate.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [TrialDateToday]
--ON [TrialDateToday].client_code = fact_dimension_main.client_code 
--AND [TrialDateToday].matter_number = fact_dimension_main.matter_number
--AND TrialDateToday.task_desccription='Trial date - today'
--LEFT OUTER JOIN red_dw.dbo.fact_tasks [TrialDateTodayFact] 
--ON [TrialDateTodayFact].dim_tasks_key = TrialDateToday.dim_tasks_key
--LEFT OUTER JOIN red_dw.dbo.dim_date AS [TrialDateTodayDate] 
--ON [TrialDateTodayDate].dim_date_key = [TrialDateTodayFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [TrialKeyDateProcedure] ON [TrialKeyDateProcedure].client_code = fact_dimension_main.client_code 
AND [TrialKeyDateProcedure].matter_number = fact_dimension_main.matter_number
AND TrialKeyDateProcedure.task_desccription='Trial key date procedure'
LEFT OUTER JOIN red_dw.dbo.fact_tasks [TrialKeyDateProcedureFact] ON [TrialKeyDateProcedureFact].dim_tasks_key = [TrialKeyDateProcedure].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [TrialKeyDateProcedureDate] ON [TrialKeyDateProcedureDate].dim_date_key = [TrialKeyDateProcedureFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [DisposalHearingKeyDateProcedure] ON [DisposalHearingKeyDateProcedure].client_code = fact_dimension_main.client_code 
AND [DisposalHearingKeyDateProcedure].matter_number = fact_dimension_main.matter_number
AND DisposalHearingKeyDateProcedure.task_desccription='Disposal hearing key date procedure'
LEFT OUTER JOIN red_dw.dbo.fact_tasks [DisposalHearingKeyDateProcedureFact] ON [DisposalHearingKeyDateProcedureFact].dim_tasks_key = [DisposalHearingKeyDateProcedure].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [DisposalHearingKeyDateProcedureDate] ON [DisposalHearingKeyDateProcedureDate].dim_date_key = [DisposalHearingKeyDateProcedureFact].dim_task_due_date_key

LEFT OUTER JOIN red_dw.dbo.dim_tasks AS [SmallClaimsHearingToday] ON [SmallClaimsHearingToday].client_code = fact_dimension_main.client_code 
AND [SmallClaimsHearingToday].matter_number = fact_dimension_main.matter_number
AND [SmallClaimsHearingToday].task_desccription='Small Claim Track hearing due - today                                                               '
LEFT OUTER JOIN red_dw.dbo.fact_tasks [SmallClaimsHearingTodayFact] ON [SmallClaimsHearingTodayFact].dim_tasks_key = [SmallClaimsHearingToday].dim_tasks_key
LEFT OUTER JOIN red_dw.dbo.dim_date AS [SmallClaimsHearingTodayDate] ON [SmallClaimsHearingTodayDate].dim_date_key = [SmallClaimsHearingTodayFact].dim_task_due_date_key


WHERE 
(
dim_matter_header_current.master_client_code='659'
OR (dim_matter_header_current.master_client_code IN ('A1001','A2002','Z1001') AND UPPER(matter_description) LIKE '%LIDL%')
OR (dim_matter_header_current.master_client_code IN ('A1001','A2002','Z1001') AND UPPER(insured_client_name) LIKE '%LIDL%')
)
AND 
(
CONVERT(DATE,date_of_trial,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,[TrialKeyDateProcedureDate].calendar_date,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,[TrialDateTodayDate].calendar_date,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,dim_detail_claim.date_of_disposal_hearing ,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,[DisposalHearingKeyDateProcedureDate].calendar_date,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,[SmallClaimsHearingTodayDate].calendar_date ,103)>CONVERT(DATE,GETDATE(),103) OR 
CONVERT(DATE,dim_detail_court.date_small_track_hearing,103)>CONVERT(DATE,GETDATE(),103) 
)
AND date_claim_concluded IS NULL

END
GO
