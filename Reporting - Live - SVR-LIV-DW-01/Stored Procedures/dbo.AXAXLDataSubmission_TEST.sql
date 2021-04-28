SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AXAXLDataSubmission_TEST]

AS 

BEGIN 


SELECT  DISTINCT

dim_matter_header_current.ms_fileid
,COALESCE(client_reference, insurerclient_reference) AS [AXA XL Claim Number]
, RTRIM(dim_matter_header_current.master_client_code)+ '-' + RTRIM(dim_matter_header_current.master_matter_number) AS [Law Firm Matter Number]
, hierarchylevel3hist [Line of Business]
, CASE WHEN TRIM(hierarchylevel3hist) = 'Casualty' then 'Casualty' else 'Accident and Health' END [New Line of Business]

/*If Department is Casualty and  matter type:

i)                    begins EL or PL then show as “Employer’s Liability and Public Liability”,
ii)                   if it starts Motor then “Motor”
iii)                 If begins Recovery then “Other”

If Department is not Casualty and matter type:
i)                    Begins Motor, EL or PL then “Accident”
ii)                   Else “Other”
 */
 ,work_type_name   AS  [Product Type]
,  CASE WHEN TRIM(hierarchylevel3hist) = 'Casualty' AND (work_type_name LIKE 'EL %' OR work_type_name LIKE 'PL %') THEN 'Employer’s Liability and Public Liability'
        WHEN TRIM(hierarchylevel3hist) = 'Casualty' AND work_type_name LIKE 'Motor%' THEN 'Motor'
		WHEN TRIM(hierarchylevel3hist) = 'Casualty' AND work_type_name LIKE 'Recovery%' THEN 'Other'
		WHEN TRIM(ISNULL(hierarchylevel3hist,'')) <> 'Casualty' AND (work_type_name LIKE 'Motor%' OR work_type_name LIKE 'EL %' OR  work_type_name LIKE 'PL %') then 'Accident'
		WHEN TRIM(ISNULL(hierarchylevel3hist,'')) <> 'Casualty' THEN 'Other'
		ELSE  work_type_name END  AS  [Product Type New]

, insuredclient_name AS [Insured Name]
, 1 AS [AXA XL Percentage line share of loss / expenses / recovery]
, dim_detail_core_details.[clients_claims_handler_surname_forename]  AS [AXA XL Claims Handler]
, NULL [Third Party Administrator]
, NULL [Coverage / defence?]
, branch_name AS [Law firm handling office (city)]
, COALESCE(dim_detail_core_details.[date_instructions_received], dim_matter_header_current.date_opened_case_management) AS [Date Instructed]
, red_dw.dbo.dim_claimant_thirdparty_involvement.claimantsols_name AS  [Opposing Side's Solicitor Firm Name]
, NULL [Reason For instruction]
, dim_detail_finance.[output_wip_fee_arrangement] [Fee Scale]
, damages_reserve AS [Damages Claimed]

, NULL [First acknowledgement Date]
, ISNULL(date_subsequent_sla_report_sent,date_initial_report_sent) [Report Date]
, dim_detail_court.[date_proceedings_issued] AS  [Date Proceedings Issued]
, NULL [AXA XL as defendant]
, NULL [Reason for proceedings]
, CASE WHEN dim_detail_core_details.[proceedings_issued] = 'Yes' THEN  dim_detail_core_details.[track] ELSE NULL END AS [Proceeding Track]
, ISNULL(dim_detail_court.[date_of_trial],Trials.TrialDate) AS   [Trial date]
, damages_reserve AS [Damages Reserve]
, COALESCE(fact_finance_summary.[tp_total_costs_claimed], tp_costs_reserve) AS [Opposing side's costs reserve]
, defence_costs_reserve AS [Panel budget/reserve]
, NULL [Reason for panel budget change if occurred]
, defence_costs_billed AS [Panel Fees Paid]
, Disbursements.[Disbs - Counsel fees] AS  [Counsel Paid]
, ISNULL(Disbursements.DisbAmount, 0) - ISNULL(Disbursements.[Disbs - Counsel fees], 0) [Other Disbursements Paid]
, fact_finance_summary.[tp_total_costs_claimed]  AS [Opposing side's Costs Claimed]
, NULL [Timekeepers - Details of anyone who worked on the case during the time period.]
, BilledTime.Name [Name]
, BilledTime.[Unique timekeeper ID per timekeeper] [Unique timekeeper ID per timekeeper]
, BilledTime.[Level (solicitor, partner)] AS  [Level (solicitor, partner)]
, BilledTime.PQE [PQE]
, BilledTime.[Hours spent on case] [Hours spent on case]
, NULL [Upon closing a case add the following information]
, CASE WHEN final_bill_date IS NOT NULL THEN DATEADD(DAY, 28, CAST(final_bill_date AS DATE)) ELSE NULL END AS [Date closed]
, final_bill_date [Date of Final Panel Invoice]
, date_claim_concluded [Date Damages settled]
,  fact_detail_paid_detail.[total_damages_paid] AS [Final Damages Amount]
, CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL THEN 'Yes' ELSE NULL END [Claimants Costs Handled by Panel?]
, date_costs_settled AS  [Date Claimants costs settled]
,  fact_finance_summary.[total_tp_costs_paid_to_date] [Final Claimants Costs Amount]
, NULL [Mediated outcome - Select from list]
, NULL [Outcome of Instruction - Select from list]
, NULL [Was litigation avoidable - Select from list]
,hierarchylevel3hist
,hierarchylevel4hist AS [Team]
,dim_fed_hierarchy_history.name AS [Weightmans Handler name]
,dim_detail_core_details.referral_reason AS [Referral reason]
,dim_detail_core_details.[proceedings_issued] 
,[Counsel Paid / Other disbursements] = Disbursements.[Disbs - Counsel fees]
,[Disbursements] = Disbursements.DisbAmount

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


 /*Disbursements*/
LEFT JOIN(
 SELECT dim_matter_header_current.dim_matter_header_curr_key
,SUM(bill_total_excl_vat) AS DisbAmount
,SUM(CASE WHEN LOWER(cost_type_description) IN ('counsel') THEN bill_total_excl_vat ELSE 0 END) AS  [Disbs - Counsel fees]
FROM red_dw.dbo.fact_bill_detail WITH(NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current 
ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_detail.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill WITH(NOLOCK)
ON dim_bill.dim_bill_key = fact_bill_detail.dim_bill_key
INNER JOIN red_dw.dbo.fact_bill WITH(NOLOCK)
ON fact_bill.dim_bill_key = fact_bill_detail.dim_bill_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK)
ON dim_bill_date.dim_bill_date_key = fact_bill_detail.dim_bill_date_key
LEFT OUTER JOIN red_dw.dbo.dim_bill_cost_type ON dim_bill_cost_type.dim_bill_cost_type_key = fact_bill_detail.dim_bill_cost_type_key
WHERE client_group_name='AXA XL'
AND (date_closed_case_management IS NULL OR CONVERT(DATE,date_closed_case_management,103)='2021-03-29')
AND  fact_bill_detail.charge_type='disbursements'
AND bill_reversed=0
GROUP BY dim_matter_header_current.dim_matter_header_curr_key


) Disbursements ON Disbursements.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key


WHERE client_group_name='AXA XL'
--AND hierarchylevel3hist='Casualty'
AND (dim_matter_header_current.date_closed_case_management IS NULL OR CONVERT(DATE,dim_matter_header_current.date_closed_case_management,103)='2021-03-29')
AND date_costs_settled  IS NULL 
AND date_claim_concluded IS NULL
--just a quick one on this for the time being - can you restrict it to show files that are "live" - 
--so this will be where date claim concluded or date costs settled are null
AND TRIM(dim_matter_header_current.matter_number) <> 'ML'
AND reporting_exclusions = 0

END 
GO
