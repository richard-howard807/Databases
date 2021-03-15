SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--============================================
-- ES 11-03-2021 #90787, amended some field logic and added key dates
--============================================

CREATE PROCEDURE [dbo].[LGSSListings]

AS 

BEGIN


SELECT
'Weightmans' AS [Law Firm]
,name AS [Fee Earner]
,claimant_name AS [Claimant]
,dim_detail_core_details.[incident_date] AS  [Date of Loss]
,dim_detail_core_details.[incident_location] AS  [Location]
,defendant_name+' '+dim_client_involvement.insurerclient_reference AS  [Defendant]
,fact_finance_summary.[total_reserve] AS  [Reserve total (gross)]
,ISNULL(total_amount_billed,0) - ISNULL(vat_billed,0) AS  [Own costs (exc. VAT)]
,CASE WHEN ISNULL(fact_finance_summary.[damages_interims],0) + ISNULL(fact_finance_summary.[claimants_costs_interims],0)>0 THEN 'Yes' ELSE 'No' END AS [Interim payments yes/no]
,dim_detail_core_details.[present_position]
,CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid') THEN  'Own costs only'
WHEN dim_detail_core_details.[present_position]='Claim and costs concluded but recovery outstanding' THEN 'Recovery'
WHEN dim_detail_core_details.[present_position]='Claim concluded but costs outstanding' THEN 'Claim concluded - costs outstanding'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND ISNULL(dim_detail_core_details.[proceedings_issued],'No')='No' THEN 'Pre-Lit'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND CONVERT(DATE,dim_detail_court.[defence_due_date],103)>=CONVERT(DATE,GETDATE(),103) THEN  'Defence'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND CONVERT(DATE,CMC,103)>=CONVERT(DATE,GETDATE(),103)  THEN 'Directions'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND CONVERT(DATE,dim_detail_claim.[date_of_witness_statement_exchange],103)>=CONVERT(DATE,GETDATE(),103) THEN  'Witness statement'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND CONVERT(DATE,dim_detail_claim.[date_of_witness_statement_exchange],103)<CONVERT(DATE,GETDATE(),103) AND dim_detail_court.[date_of_trial] IS NULL THEN 'Listing'
WHEN ISNULL(dim_detail_core_details.[present_position],'Blank') IN ('Claim and costs outstanding','Blank') AND CONVERT(DATE,dim_detail_court.[date_of_trial],103)>=CONVERT(DATE,GETDATE(),103) THEN 'Trial or listing windows or awaiting either'
END AS [Position of claim]
,dim_detail_core_details.[clients_claims_handler_surname_forename]+' ('+dim_matter_header_current.client_name+')' AS [LGSS Handler]
,CASE WHEN dim_detail_core_details.[is_there_an_issue_on_liability]='No' THEN 'Yes' ELSE 'No' END AS [Admitted?] 
,CASE WHEN CMC IS NOT NULL THEN 'Yes' ELSE 'No' END AS [Conference?]

,CASE WHEN (CASE WHEN dim_detail_court.[date_of_trial]> dim_detail_court.[date_of_first_day_of_trial_window] THEN 
dim_detail_court.[date_of_trial] ELSE dim_detail_court.[date_of_first_day_of_trial_window] END) >CONVERT(DATE,GETDATE(),103) THEN (CASE WHEN dim_detail_court.[date_of_trial]> dim_detail_court.[date_of_first_day_of_trial_window] THEN 
dim_detail_court.[date_of_trial] ELSE dim_detail_court.[date_of_first_day_of_trial_window] END) ELSE NULL END AS [Trial Dates/windows]

,CASE WHEN dim_matter_header_current.date_closed_case_management IS NULL  AND ISNULL(red_dw.dbo.dim_matter_header_current.present_position,'') <>'To be closed/minor balances to be clear' THEN 'Open'
ELSE 'Closed' END AS Tab
,dim_matter_header_current.present_position AS [Present Position]
,RTRIM(master_client_code) + '-' + RTRIM(master_matter_number) AS [Weightmans Mattersphere Reference]
,matter_description AS [Matter Description]
, dim_matter_header_current.date_opened_case_management AS [Date Opened]
, dim_detail_core_details.referral_reason AS [Refrerral Reason]
,wip AS [WIP]
,fact_finance_summary.unpaid_bill_balance AS [Unpaid Bill Balance]
,last_bill_date AS [Last Bill Date]
,proceedings_issued AS [Proceedings Issued]
,defence_due_date AS [Defence]
,CMC AS [CMC]
,date_of_witness_statement_exchange AS [Witness Statements]
,dim_detail_court.[date_of_trial] AS [Date of Trial]
,dim_matter_header_current.date_closed_case_management AS [Date Closed]
,work_type_group
, [Defence].key_date AS [Defence Due]
, [CMCDate].key_date AS [CMC Due]
, [Disclosure].key_date AS [Disclosure]
, [WitEvidence].key_date AS [Witness evidence]
, [TrialWindow].key_date AS [Trial window]
, [Trial].key_date AS [Trial Date]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fee_earner_code=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
  ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
  AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
  ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
  AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
  ON fact_finance_summary.client_code = dim_matter_header_current.client_code
  AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
  ON dim_defendant_involvement.client_code = dim_matter_header_current.client_code
  AND dim_defendant_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court
  ON dim_detail_court.client_code = dim_matter_header_current.client_code
  AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
  ON dim_detail_claim.client_code = dim_matter_header_current.client_code
  AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
   ON fact_matter_summary_current.client_code = dim_matter_header_current.client_code
  AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
  
LEFT OUTER JOIN (SELECT fileID,MAX(tskDue) AS [CMC]
	FROM ms_prod.dbo.dbTasks WHERE tskActive=1
	AND tskType='KEYDATE'AND tskDesc ='CMC due - today'
	GROUP BY fileID) AS CMC
	 ON ms_fileid=CMC.fileID

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('DEFENCE')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [Defence]
ON [Defence].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('CMC')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [CMCDate]
ON [CMCDate].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('DISC')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [Disclosure]
ON [Disclosure].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('WITEVIDENCE')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [WitEvidence]
ON [WitEvidence].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('TRIALWINDOW')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [TrialWindow]
ON [TrialWindow].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT dim_matter_header_curr_key, client_code, matter_number, type, description, MAX(key_date) AS key_date
FROM red_dw.dbo.dim_key_dates
WHERE type IN ('TRIAL')
AND is_active=1
GROUP BY dim_matter_header_curr_key, client_code, matter_number, type, description) AS [Trial]
ON [Trial].dim_matter_header_curr_key=dim_matter_header_current.dim_matter_header_curr_key
  
WHERE
(
LOWER(matter_description) LIKE '%cambridgeshire county council%' OR 
LOWER(matter_description) LIKE '%cambridgeshire council%' OR 
LOWER(matter_description) LIKE '%cambridgeshire cc%' OR 
LOWER(matter_description) LIKE '%northamptonshire county council%' OR 
LOWER(matter_description) LIKE '%northamptonshire council%' OR 
LOWER(matter_description) LIKE '%northamptonshire cc%' OR 
LOWER(matter_description) LIKE '%norwich city council%' OR 
LOWER(matter_description) LIKE '%norwich cc%' OR 
LOWER(matter_description) LIKE '%milton keynes council%' OR 
LOWER(matter_description) LIKE '%milton keynes city council%' OR 
LOWER(matter_description) LIKE '%milton keynes cc%' OR 
LOWER(matter_description) LIKE '%northampton borough council%' OR 
LOWER(matter_description) LIKE '%northampton council%' OR 
LOWER(matter_description) LIKE '%northampton bc%' OR 
LOWER(matter_description) LIKE '%northampton homes%'  OR
LOWER(insuredclient_name) LIKE '%cambridgeshire county council%' OR 
LOWER(insuredclient_name) LIKE '%cambridgeshire council%' OR 
LOWER(insuredclient_name) LIKE '%cambridgeshire cc%' OR 
LOWER(insuredclient_name) LIKE '%northamptonshire county council%' OR 
LOWER(insuredclient_name) LIKE '%northamptonshire council%' OR 
LOWER(insuredclient_name) LIKE '%northamptonshire cc%' OR 
LOWER(insuredclient_name) LIKE '%norwich city council%' OR 
LOWER(insuredclient_name) LIKE '%norwich cc%' OR 
LOWER(insuredclient_name) LIKE '%milton keynes council%' OR 
LOWER(insuredclient_name) LIKE '%milton keynes city council%' OR 
LOWER(insuredclient_name) LIKE '%milton keynes cc%' OR 
LOWER(insuredclient_name) LIKE '%northampton borough council%' OR 
LOWER(insuredclient_name) LIKE '%northampton council%' OR 
LOWER(insuredclient_name) LIKE '%northampton bc%' OR 
LOWER(insuredclient_name) LIKE '%northampton homes%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%cambridgeshire county council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%cambridgeshire council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%cambridgeshire cc%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northamptonshire county council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northamptonshire council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northamptonshire cc%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%norwich city council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%norwich cc%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%milton keynes council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%milton keynes city council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%milton keynes cc%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northampton borough council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northampton council%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northampton bc%' OR 
LOWER(dim_matter_header_current.client_name) LIKE '%northampton homes%' 
) 
AND (dim_matter_header_current.date_closed_case_management IS NULL OR dim_matter_header_current.date_closed_case_management>='2020-01-01')
AND reporting_exclusions=0
AND work_type_group IN 
(
'Claims Handling','Disease','EL','Insurance Costs','LMT','Motor'
,'NHSLA','PL All','Prof Risk','RECOVERY'
)

AND NOT RTRIM(master_client_code) + '-' + RTRIM(master_matter_number) IN ('A1001-11582','A1001-11662','G1001-5826','W21390-2','W19220-21')
END
GO
