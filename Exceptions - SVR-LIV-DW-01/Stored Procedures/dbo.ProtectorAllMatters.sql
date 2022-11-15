SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







CREATE PROCEDURE [dbo].[ProtectorAllMatters]
AS
BEGIN

IF OBJECT_ID(N'tempdb..#KeyDates') IS NOT NULL
BEGIN
DROP TABLE #KeyDates
END
SELECT t.dim_matter_header_curr_key,
MAX(red_dw.dbo.dim_task_due_date.calendar_date) AS [TaskDueDate]
INTO #KeyDates
FROM [red_dw].[dbo].[fact_tasks] t 
  INNER JOIN red_dw.dbo.dim_matter_header_current
   ON dim_matter_header_current.dim_matter_header_curr_key = t.dim_matter_header_curr_key
  JOIN [red_dw].[dbo].[dim_tasks] dimt ON t.dim_tasks_key = dimt.dim_tasks_key
  LEFT OUTER JOIN red_dw.dbo.dim_task_due_date
   ON dim_task_due_date.dim_task_due_date_key = t.dim_task_due_date_key
  WHERE 
     (t.task_code IN ('TRAA0348', 'NHSA0183')  -- Task Codes TRAA0348 REM: Trial due today - [CASE MAN] ,     REM: Disposal hearing due today [CASE MAN]   
	 OR dimt.task_desccription IN ('Trial date - today' ,  'Trial window - today')   )
	 AND master_client_code IN
	 ('W17427','W15632','W15366','W15442','W20163')
     
GROUP BY  t.dim_matter_header_curr_key


SELECT date_opened_case_management [Date Opened ] ,
       date_closed_case_management [DateClosed ] ,
       RTRIM([master_client_code]) + '-' + [master_matter_number] AS [Mattersphere Weightmans Reference] ,
	   dim_client.client_name,
	   master_client_code,master_matter_number,
       matter_description [Matter Description ] ,
       dim_fed_hierarchy_history.name [Case Manager Name] ,
	   hierarchylevel4hist AS [Team],
       work_type_name [Worktype] ,
       client_reference [Client Reference] ,
       dim_detail_core_details.clients_claims_handler_surname_forename AS [Clients Claim Handler ] ,
       dim_detail_core_details.[present_position] [Present Position] ,
       date_instructions_received [Date Instructions Recieved] ,
       dim_detail_core_details.[referral_reason] [Referral Reason] ,
       dim_detail_previous_details.[proceedings_issued] [Proceedings Issued] ,
       dim_detail_core_details.[track] [Track] ,
       dim_detail_core_details.[suspicion_of_fraud] [Suspicion of Fraud] ,
       dim_detail_core_details.[credit_hire] [Credit Hire ? ] ,
       dim_claimant_thirdparty_involvement.claimantsols_name AS [Claimant's Solicitor] ,
       dim_detail_core_details.[date_initial_report_sent] [Date Initial Report ] ,
       dim_detail_core_details.[date_subsequent_sla_report_sent] [Date of Subsequent Report] ,
       fact_finance_summary.[damages_reserve] [Damages Reserve Current] ,
       fact_detail_reserve_detail.[claimant_costs_reserve_current] [Claimants Cost Reserve Current] ,
       fact_finance_summary.[defence_costs_reserve] [Defence Cost Reserve Current ] ,
       dim_detail_outcome.[outcome_of_case] [Outcome of Case] ,
       CASE WHEN ISNULL(dim_detail_core_details.present_position, '') LIKE 'Claim%' THEN
                1
            ELSE 0
       END AS claimpres ,
       CASE WHEN dim_detail_core_details.present_position NOT LIKE 'Claim%' THEN
                1
            ELSE 0
       END AS closey ,
       dim_detail_outcome.[date_claim_concluded] [Date Claim Concluded] ,
       fact_finance_summary.[damages_paid] [Damages Paid by Client] ,
       dim_detail_outcome.[date_costs_settled] [Date Costs Settled] ,
       fact_finance_summary.[tp_total_costs_claimed] [Claimants Total Costs Claimed against Client] ,
       fact_finance_summary.[claimants_costs_paid] [Claimant's Costs Paid by Client - Disease] ,
       CASE WHEN ISNULL(dim_detail_core_details.reason_for_instruction, '') <> 'NO                                                          ' THEN
                1
            ELSE 0
       END AS [New cases opened] ,
       CASE WHEN dim_matter_worktype.work_type_name LIKE 'EL%' THEN 1
            ELSE 0
       END AS [EL] ,
       CASE WHEN dim_matter_worktype.work_type_name LIKE 'PL%' THEN 1
            ELSE 0
       END AS [PL] ,
       CASE WHEN dim_matter_worktype.work_type_name LIKE 'Motor%'
                 AND ISNULL(dim_detail_core_details.suspicion_of_fraud, '') <> 'Yes'
                 AND ISNULL(dim_detail_core_details.credit_hire, '') <> 'Yes' THEN
                1
            ELSE 0
       END AS [Motor] ,
       CASE WHEN dim_detail_core_details.suspicion_of_fraud = 'Yes' THEN 1
            ELSE 0
       END AS [Fraud ] ,
       CASE WHEN dim_detail_core_details.credit_hire = 'Yes' THEN 1
            ELSE 0
       END [Credit Hire] ,
       dim_client.open_date [Open Date] ,
       cal_year ,
       cal_month_name + '-' + CAST(cal_year AS NVARCHAR) year_month_char ,
       CASE WHEN cal_month_no = MONTH(GETDATE()) THEN 1
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -12, GETDATE())) THEN 2
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -11, GETDATE())) THEN 3
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -10, GETDATE())) THEN 4
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -9, GETDATE())) THEN 5
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -8, GETDATE())) THEN 6
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -7, GETDATE())) THEN 7
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -6, GETDATE())) THEN 8
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -5, GETDATE())) THEN 9
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -4, GETDATE())) THEN 10
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -3, GETDATE())) THEN 11
            WHEN cal_month_no = MONTH(DATEADD(MONTH, -2, GETDATE())) THEN 1
       END AS [month_order] ,
       cal_month_no,
	   dim_detail_finance.[output_wip_fee_arrangement] AS [Fee Arrangement],
	   wip AS [WIP],
	   defence_costs_billed AS [Revenue]
	   ,CAST(dim_detail_core_details.[date_subsequent_sla_report_sent] AS DATE)                 AS [date_subsequent_sla_report_sent] 
	   ,COALESCE(dim_detail_court.[date_of_trial],KeyDates.TaskDueDate)   AS [date_of_trial]
	   ,fact_detail_elapsed_days.[elapsed_days_damages] 
	   ,CAST(dim_detail_core_details.[date_initial_report_due] AS DATE)                         AS [date_initial_report_due] 
	   ,dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report]
	   ,elapsed_days_live_files
	   ,elapsed_days_costs_to_settle
	   ,does_claimant_have_personal_injury_claim
	   ,injury_type
	   ,claimant_name AS [Claimant Name]
	   ,incident_date AS [Incident Date]
	   ,dim_matter_header_current.delegated AS Delegated
	   ,dst_claimant_solicitor_firm
	  --,CASE WHEN date_initial_report_sent IS NULL THEN NULL ELSE elapsed_days - days_to_first_report_lifecycle END AS [Days to first report]
	   	   ,CASE WHEN date_initial_report_sent IS NULL THEN NULL ELSE days_to_first_report_lifecycle END [Days to first report]


FROM red_dw.dbo.dim_matter_header_current
INNER JOIN (SELECT	* FROM dbo.ProtectorMatters) AS Clients
 ON Clients.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
  ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
 ON dim_detail_outcome.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN  red_dw.dbo.dim_date ON date_instructions_received = calendar_date
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days
 ON fact_detail_elapsed_days.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement 
 ON dim_claimant_thirdparty_involvement.client_code = dim_matter_header_current.client_code
 AND dim_claimant_thirdparty_involvement.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
 ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
 ON fact_detail_reserve_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
 ON dim_detail_previous_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_previous_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
LEFT JOIN red_dw.dbo.dim_detail_court 
ON dim_detail_court.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN #KeyDates AS KeyDates
 ON KeyDates.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
 ON  dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
 LEFT OUTER JOIN MS_Prod.config.dbFile
 ON dbFile.fileID=dim_matter_header_current.ms_fileid
 
 WHERE (date_closed_case_management IS NULL OR date_closed_case_management>='2018-07-01')
 AND master_matter_number <>'0'
 AND ISNULL(outcome_of_case,'')<>'Exclude from reports'
 AND ISNULL(dbFile.fileStatus,'')<>'OPENERROR'


 END 
GO
