SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AXAXLCasualtySubmissionDataTEST]

AS 

BEGIN 


SELECT  dim_matter_header_current.ms_fileid
,client_reference AS [AXA XL Claim Number]
, RTRIM(dim_matter_header_current.client_code)+ '-' + RTRIM(dim_matter_header_current.matter_number) AS [Law Firm Matter Number]
, hierarchylevel3hist [Line of Business]
, work_type_name AS  [Product Type]
, insuredclient_name AS [Insured Name]
, 1 AS [AXA XL Percentage line share of loss / expenses / recovery]
, dim_detail_core_details.[clients_claims_handler_surname_forename]  AS [AXA XL Claims Handler]
, NULL [Third Party Administrator]
, NULL [Coverage / defence?]
, branch_name AS [Law firm handling office (city)]
, dim_detail_core_details.[date_instructions_received] AS [Date Instructed]
, red_dw.dbo.dim_claimant_thirdparty_involvement.claimantsols_name AS  [Opposing Side's Solicitor Firm Name]
, NULL [Reason For instruction]
, dim_detail_finance.[output_wip_fee_arrangement] [Fee Scale]
, damages_reserve AS [Damages Claimed]

, NULL [First acknowledgement Date]
, ISNULL(date_subsequent_sla_report_sent,date_initial_report_sent) [Report Date]
, dim_detail_court.[date_proceedings_issued] AS  [Date Proceedings Issued]
, NULL [AXA XL as defendant]
, NULL [Reason for proceedings]
,  dim_detail_core_details.[track]  AS [Proceeding Track]
, ISNULL(dim_detail_court.[date_of_trial],Trials.TrialDate) AS   [Trial date]
, damages_reserve AS [Damages Reserve]
, tp_costs_reserve AS [Opposing side's costs reserve]
, defence_costs_reserve AS [Panel budget/reserve]
, NULL [Reason for panel budget change if occurred]
, defence_costs_billed AS [Panel Fees Paid]
, NULL [Counsel Paid]
, NULL [Other Disbursements Paid]
, fact_finance_summary.[tp_total_costs_claimed]  AS [Opposing side's Costs Claimed]
, NULL [Timekeepers - Details of anyone who worked on the case during the time period.]
, BilledTime.Name [Name]
, BilledTime.[Unique timekeeper ID per timekeeper] [Unique timekeeper ID per timekeeper]
, BilledTime.[Level (solicitor, partner)] AS  [Level (solicitor, partner)]
, BilledTime.PQE [PQE]
, BilledTime.[Hours spent on case] [Hours spent on case]
, NULL [Upon closing a case add the following information]
, red_dw.dbo.dim_matter_header_current.date_closed_case_management AS [Date closed]
, final_bill_date [Date of Final Panel Invoice]
, date_claim_concluded [Date Damages settled]
,  fact_detail_paid_detail.[total_damages_paid] AS [Final Damages Amount]
, NULL [Claimants Costs Handled by Panel?]
, date_costs_settled AS  [Date Claimants costs settled]
,  fact_finance_summary.[total_tp_costs_paid_to_date] [Final Claimants Costs Amount]
, NULL [Mediated outcome - Select from list]
, NULL [Outcome of Instruction - Select from list]
, NULL [Was litigation avoidable - Select from list]
,hierarchylevel3hist
,hierarchylevel4hist AS [Team]
,dim_fed_hierarchy_history.name AS [Weightmans Handler name]


FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK)
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH(NOLOCK)
 ON  fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON  dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement WITH(NOLOCK)
 ON  dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH(NOLOCK)
 ON  dim_detail_finance.client_code = dim_matter_header_current.client_code
 AND dim_detail_finance.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_court WITH(NOLOCK)
 ON  dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH(NOLOCK)
 ON  fact_matter_summary_current.client_code = dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON  dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail WITH(NOLOCK)
 ON  fact_detail_paid_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_paid_detail.matter_number = dim_matter_header_current.matter_number

 
LEFT OUTER JOIN 
(
SELECT ms_fileid,MAX(tskDue) AS TrialDate FROM red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.dbo.dbTasks WITH(NOLOCK)
 ON ms_fileid=fileID
WHERE client_group_name='AXA XL'
--AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
AND tskActive=1
AND tskDesc LIKE '%Trial date - today%'
GROUP BY ms_fileid
) AS Trials
 ON Trials.ms_fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.dim_matter_header_curr_key
, TimeRecordedBy.name [Name]
, TimeRecordedBy.fed_code [Unique timekeeper ID per timekeeper]
, TimeRecordedBy.jobtitle [Level (solicitor, partner)]
, DATEDIFF(YEAR,admissiondateud,CONVERT(DATE,bill_date,103)) [PQE]
, SUM(CAST(minutes_recorded AS DECIMAL(10,2)))/60 [Hours spent on case]
FROM red_dw.dbo.fact_bill_billed_time_activity WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
 ON dim_bill_date.dim_bill_date_key = fact_bill_billed_time_activity.dim_bill_date_key
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS TimeRecordedBy
 ON TimeRecordedBy.dim_fed_hierarchy_history_key = fact_bill_billed_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_employee WITH(NOLOCK)
 ON dim_employee.dim_employee_key = TimeRecordedBy.dim_employee_key
WHERE client_group_name='AXA XL'
--AND dim_fed_hierarchy_history.hierarchylevel3hist='Casualty'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
GROUP BY dim_matter_header_current.dim_matter_header_curr_key
, TimeRecordedBy.name 
, TimeRecordedBy.fed_code 
, TimeRecordedBy.jobtitle
, DATEDIFF(YEAR,admissiondateud,CONVERT(DATE,bill_date,103))
) AS BilledTime
 ON BilledTime.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


WHERE client_group_name='AXA XL'
--AND hierarchylevel3hist='Casualty'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR CONVERT(DATE,dim_matter_header_current.date_closed_case_management,103)='2021-03-29')
AND date_costs_settled  IS NULL 
AND date_claim_concluded IS NULL
--just a quick one on this for the time being - can you restrict it to show files that are "live" - 
--so this will be where date claim concluded or date costs settled are null
AND TRIM(dim_matter_header_current.matter_number) <> 'ML'


END 
GO
