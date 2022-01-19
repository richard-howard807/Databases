SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
	
	/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2021-01-29
Description:		Zurich Large Loss Tableau Dashboard
Current Version:	Initial Create
====================================================
	 
====================================================

*/
CREATE PROCEDURE [dbo].[ZurichLargeLoss]

AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	 
	 IF OBJECT_ID('tempdb..#ClientReportDates') IS NOT NULL DROP TABLE #ClientReportDates
	 IF OBJECT_ID('tempdb..#MainData') IS NOT NULL DROP TABLE #MainData

	 SET NOCOUNT ON 

	 

SELECT 
  dim_matter_header_current.master_client_code
 ,dim_matter_header_current.master_matter_number
 ,dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers
 ,ClientSLAs.[Initial Report SLA (days)]
 --LOGIC for Initial Report Due
	--, CASE 
	--WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL 
	--THEN [dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
	--WHEN date_initial_report_due IS NULL 
	--THEN [dbo].[AddWorkDaysToDate](CAST(dim_matter_header_current.date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
	--ELSE date_initial_report_due 
	--END	AS [initial_report_due]
	--,date_initial_report_due

	, CASE 
	WHEN dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers IS NOT NULL 
	THEN [dbo].[AddWorkDaysToDate](CAST(dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
	WHEN date_initial_report_due IS NULL 
	THEN [dbo].[AddWorkDaysToDate](date_instructions_received ,ISNULL(ClientSLAs.[Initial Report SLA (days)], 10))
	WHEN date_instructions_received IS NULL
	THEN [dbo].[AddWorkDaysToDate](CAST(dim_matter_header_current.date_opened_case_management AS DATE),ISNULL(ClientSLAs.[Initial Report SLA (days)], 10)) 
	ELSE date_initial_report_due 
	END	AS [initial_report_due]
  	, [dbo].[ReturnElapsedDaysExcludingBankHolidays] (COALESCE(grpageas_motor_date_of_receipt_of_clients_file_of_papers,red_dw.dbo.dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
--Logic for Subsequent Report Due (Date)
, CASE 
	WHEN do_clients_require_an_initial_report = 'No' 
	THEN NULL
	WHEN RTRIM(dim_detail_core_details.present_position) 
	IN ('Final bill due - claim and costs concluded',
		'Final bill sent - unpaid',
		'To be closed/minor balances to be clear') 
	THEN NULL
	WHEN dim_detail_core_details.date_initial_report_sent IS NULL AND dim_detail_core_details.date_subsequent_sla_report_sent IS NULL 
	THEN NULL
	WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NOT NULL 
	THEN CASE 
		-- Needing to make sure future date is a weekday
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Saturday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+2
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)) = 'Sunday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)+1
		ELSE 
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_subsequent_sla_report_sent)
	END
	WHEN dim_detail_core_details.date_subsequent_sla_report_sent IS NULL 
	THEN CASE 
		 --Needing to make sure future date is a weekday
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Saturday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+2
		WHEN DATENAME(wk, DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)) = 'Sunday' THEN
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)+1
		ELSE 
			DATEADD(MONTH, ISNULL(CAST(ClientSLAs.[Update Report SLA (months)] AS INT), 3), dim_detail_core_details.date_initial_report_sent)
	END
	ELSE NULL
	END	AS [date_subsequent_report_due]
	,date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]


INTO #ClientReportDates

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
		AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days ON days.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN Reporting.dbo.ClientSLAs ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key



WHERE 
	reporting_exclusions = 0
	AND  dim_client.client_group_name='Zurich'
	AND hierarchylevel3hist = 'Large Loss'
	AND ((dim_detail_outcome.[date_claim_concluded] >='20190201' OR dim_detail_outcome.[date_claim_concluded]IS NULL))
	--ISNULL(dim_detail_outcome.[date_claim_concluded],dim_detail_outcome.zurich_result_date) IS NULL))
	AND dim_matter_worktype.work_type_name <> 'Cross Border'
	AND dim_fed_hierarchy_history.hierarchylevel4hist <> 'Niche Costs'
	AND red_dw.dbo.dim_detail_core_details.referral_reason IN ('Dispute on Liability', 'Dispute on liability','Dispute on liability and quantum','Dispute on quantum')  
	AND dim_matter_header_current.ms_only = '1'
					
--=========================================================================================================================================================================================================================================================================
--=========================================================================================================================================================================================================================================================================

SELECT 
	dim_client.client_name AS [Client Name]
	, dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [Mattersphere Weightmans Reference]
	, name AS [Matter Owner]
	--, [dbo].[ReturnElapsedDaysExcludingBankHolidays](COALESCE(#ClientReportDates.grpageas_motor_date_of_receipt_of_clients_file_of_papers,#ClientReportDates.date_instructions_received,dim_matter_header_current.date_opened_case_management),date_initial_report_sent) AS [Days to send initial report (working days)]
	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](#ClientReportDates.initial_report_due,red_dw.dbo.dim_detail_core_details.date_initial_report_sent) AS [Days to send initial report (working days)]
	, dim_detail_core_details.date_initial_report_sent
	--, #ClientReportDates.date_instructions_received AS [Date Instructions Received]
	,#ClientReportDates.initial_report_due  
, CASE
	WHEN do_clients_require_an_initial_report = 'No' THEN 'Report Not Required'
	WHEN ISNULL(dim_detail_core_details.ll00_have_we_had_an_extension_for_the_initial_report, '') = 'Yes' THEN 'Has had an extension'
	WHEN dim_detail_core_details.date_initial_report_sent IS NULL THEN 'No Date' --NOT GOT A DATE = 3
	WHEN  [Days to send initial report (working days)] >10 THEN 'SLA Not Met' 	--10 WORKING DAYS IS THE ZURICH SLA
	ELSE 'SLA Met'
	END	AS [Initial Report SLA Status]

	, dim_detail_core_details.present_position AS [Present Position]
	--, CASE WHEN CAST(date_instructions_received AS DATE)=CAST(date_opened_case_management AS DATE) THEN 0 ELSE dbo.ReturnElapsedDaysExcludingBankHolidays(date_instructions_received,date_opened_case_management) END AS [Days to File Opened from Date Instructions Received]
	, do_clients_require_an_initial_report AS [Do Clients Require an Initial Report?]
	, dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date Receipt of File Papers]
	, [ll00_have_we_had_an_extension_for_the_initial_report] AS [Have we had an Extension?]
	--, CASE WHEN do_clients_require_an_initial_report = 'No' THEN NULL
	--	WHEN date_initial_report_sent IS NOT NULL THEN NULL
	--	WHEN date_initial_report_sent IS NULL THEN dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())
	--	WHEN date_initial_report_sent IS NULL AND dbo.ReturnElapsedDaysExcludingBankHolidays(CASE WHEN grpageas_motor_date_of_receipt_of_clients_file_of_papers> date_opened_case_management THEN grpageas_motor_date_of_receipt_of_clients_file_of_papers ELSE date_opened_case_management END , GETDATE())<[Initial Report SLA (days)] THEN 'Not yet due'
	--	ELSE NULL END AS [Days without Report]
	, date_subsequent_sla_report_sent AS [Date Subsequent SLA Report Sent]
	,  #ClientReportDates.[date_subsequent_report_due]
	, CASE
	--WHEN red_dw.dbo.dim_detail_core_details.date_subsequent_sla_report_sent IS NULL AND #ClientReportDates.date_subsequent_report_due IS null THEN 0 -- no date
	WHEN #ClientReportDates.date_subsequent_report_due IS NOT NULL AND date_subsequent_sla_report_sent IS NULL THEN 3
		WHEN #ClientReportDates.date_subsequent_report_due < dim_detail_core_details.date_subsequent_sla_report_sent THEN
			1
		ELSE 
			0
	  END	AS [Subsequent Report is Overdue]
	  	, [dbo].[ReturnElapsedDaysExcludingBankHolidays](#ClientReportDates.date_subsequent_report_due,date_subsequent_sla_report_sent) AS [Days to send Subsequent report (working days)]
	  , DATEDIFF(DAY, dim_matter_header_current.date_opened_case_management, ISNULL(dim_detail_outcome.date_claim_concluded, dim_matter_header_current.date_closed_case_management)) AS [Lifecycle (date opened to date concluded)]
	  , red_dw.dbo.dim_detail_core_details.referral_reason AS [Referral Reason]
	  , red_dw.dbo.dim_date.calendar_date
	
	  ,red_dw.dbo.dim_date.current_fin_year
	,dim_detail_outcome.date_claim_concluded
 ,CASE WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(dim_matter_header_current.date_opened_case_management AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(dim_matter_header_current.date_opened_case_management AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilter] 
	,dim_matter_header_current.date_opened_case_management
,CASE WHEN CAST(date_claim_concluded AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(date_claim_concluded AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(date_claim_concluded AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(date_claim_concluded AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilterConcluded] 
,CASE WHEN CAST(date_costs_settled AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(date_costs_settled AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(date_costs_settled AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(date_costs_settled AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END [YearFilterCostSettled] 

	,CASE WHEN CAST(fact_matter_summary_current.last_bill_date AS DATE) >= CAST(DATEADD(YEAR, -1, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE)
	AND CAST(fact_matter_summary_current.last_bill_date AS DATE)<= CAST(DATEADD(YEAR, -1,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME)) AS DATE) THEN 'prioryear'
	WHEN CAST(fact_matter_summary_current.last_bill_date AS DATE) >= CAST(DATEADD(YEAR, 0, DATEADD(Month,-12,DATEADD(month, DATEDIFF(month, 0, GETDATE()), 0))) AS DATE) and
	CAST(fact_matter_summary_current.last_bill_date AS DATE)<= CAST(DATEADD(YEAR, 0,CAST(EOMONTH(DATEADD(MONTH,-1,GETDATE())) AS DATETIME))AS DATE) then 'currentyear' ELSE NULL END AS  [YearFilterDateofLastBill]

 ,CASE WHEN dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		AND LOWER(referral_reason) LIKE '%dispute%'
		AND suspicion_of_fraud ='No'
		--AND work_type_group IN ('EL','PL All','Motor','Disease') 
		AND (DATEDIFF(DAY,dim_matter_header_current.date_opened_case_management, GETDATE())>=14 OR totalpointscalc IS NOT null)
		THEN 1 ELSE 0 END AS [Number of Matters]
		, CASE WHEN totalpointscalc IS NOT NULL THEN 1 ELSE 0 END AS [countscore]
	,red_dw.dbo.fact_finance_summary.damages_paid
	,fact_finance_summary.damages_reserve AS [Damages Reserve Current ]
	,fact_detail_reserve_detail.claimant_costs_reserve_current AS [Claimant Costs Reserve Current ]
	,fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve Current]
	,red_dw.dbo.fact_finance_summary.total_damages_and_tp_costs_reserve
	,red_dw.dbo.fact_finance_summary.total_tp_costs_paid
	,red_dw.dbo.fact_finance_summary.defence_costs_billed
	,CASE WHEN fact_finance_summary.damages_paid IS NULL OR fact_finance_summary.total_tp_costs_paid IS NULL THEN NULL ELSE ISNULL(damages_paid,0)-ISNULL(total_tp_costs_paid,0) END AS [Damages - Costs Paid]
	,red_dw.dbo.dim_matter_header_current.final_bill_flag
	,fact_finance_summary.total_reserve
	,red_dw.dbo.fact_finance_summary.total_tp_costs_paid + red_dw.dbo.fact_finance_summary.damages_paid + red_dw.dbo.fact_finance_summary.defence_costs_billed	 AS  [Total Spend] 
	,red_dw.dbo.fact_finance_summary.total_recovery
	,(ISNULL(red_dw.dbo.fact_finance_summary.total_tp_costs_paid,0) + 
	ISNULL(red_dw.dbo.fact_finance_summary.damages_paid,0) + 
	ISNULL(red_dw.dbo.fact_finance_summary.defence_costs_billed,0))-ISNULL(red_dw.dbo.fact_finance_summary.total_recovery,0) AS Savings
	,dim_matter_worktype.work_type_group AS [Matter Type Group]
	,dim_detail_client.zurich_date_introductory_call
	,dim_detail_core_details.zurich_introductory_call
	,dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers
	,( SELECT MAX(v)FROM(VALUES(dim_matter_header_current.date_opened_case_management), (dim_detail_core_details.grpageas_motor_date_of_receipt_of_clients_file_of_papers)) AS value(v)) AS MaxValue
	,[Zurich Intro Date]   ---use this field for date of intro call for magic phone call
	,CASE WHEN dim_detail_client.zurich_date_introductory_call IS NULL THEN 1 ELSE 0 END AS CountPhoneCallNotComplete
	,fact_finance_summary.claimants_costs_paid
	,total_amount_billed
	,CAST(dim_matter_header_current.date_closed_case_management AS DATE) AS [Date Closed]
	, CASE 
	WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL  
	THEN 1
	WHEN RTRIM(dim_detail_core_details.present_position) 
	IN ('Final bill due - claim and costs concluded',
		'Final bill sent - unpaid',
		'To be closed/minor balances to be clear') 
	THEN 1
	ELSE 0
	END AS FILTER
	,dim_detail_outcome.repudiation_outcome
	, ISNULL(damages_paid,0) + ISNULL(claimants_costs_paid,0)	+ ISNULL(total_amount_billed,0) -ISNULL(vat_billed,0)   AS [Indemnity Spend]
	,vat_billed
	, dim_detail_finance.[damages_banding] AS [Damages Banding]
	, CASE 
			WHEN fact_finance_summary.damages_reserve < 500000 THEN 'Below 500k'
			WHEN fact_finance_summary.damages_reserve BETWEEN 500000 AND 1000000 THEN '500k to £1m'
			WHEN fact_finance_summary.damages_reserve BETWEEN 1000001 AND 3000000 THEN '£1m to £3m'
			WHEN fact_finance_summary.damages_reserve > 3000000 THEN '£3m+'
			END AS [Damages Banding_test]


	,dim_detail_core_details.[injury_type] [Injury Type]
	,CASE WHEN tskCompleted IS NOT NULL AND tskActive=1 THEN 1 ELSE 0 END AS [ProcessCompleted]
	,tskCompleted 
	,CASE WHEN cboCLNotInd IS NULL  AND cboIssDrCov IS NULL AND cboIssVehCov IS NULL
		AND cboIssInsVeh IS NULL AND cboSugBrePol IS NULL AND cboAccPrivLand IS NULL
		AND cboAnOthIns IS NULL AND cboAnoInsParty IS NULL AND cboEleSubLoss IS NULL
		AND cboInsSpecAdvDi IS NULL AND cboInsSpecAdvIn IS NULL AND cboInsRelTech IS NULL
		AND cboPolCanAv IS NULL THEN 1 ELSE 0 END  AS ScoreISBlank
	,1 AS [Number]
	,hierarchylevel3hist
	,hierarchylevel4hist
	,fact_finance_summary.[indemnity_spend] AS [Indemnity Spend_dwh]
	,dim_detail_core_details.referral_reason
	,dim_matter_header_current.ms_only
	,dim_detail_outcome.zurich_result_date
,dim_detail_outcome.outcome_of_case [Outcome of Case ]
	,CASE WHEN (outcome_of_case LIKE 'Discontinued%') OR (outcome_of_case IN
(
'Rejected (MIB untraced only)                                ',
'struck out                                                  ',
'won at trial                                                ',
'Struck Out                                                  ',
'Struck out                                                  ',
'Won At Trial                                                ',
'Won at Trial                                                ',
'Won at trial                                                '
, 'Withdrawn'
)) THEN 'Repudiated'


WHEN
((LOWER(outcome_of_case) LIKE 'settled%' ) OR (outcome_of_case IN
(
'Assessment of damages',
'Assessment of damages (damages exceed claimant''s P36 offer) ',
'Lost at Trial                                               ',
'Lost at trial                                               ',
'Lost at trial (damages exceed claimant''s P36 offer)         ',
'Settled',
'Settled  - claimant accepts P36 offer out of time',
'Settled - Infant Approval                                   ',
'Settled - Infant approval                                   ',
'Settled - JSM',
'Settled - Mediation                                         ',
'Settled - mediation                                         '
))) THEN 'Settled'
 

 WHEN 
 outcome_of_case 
 IN
(
'Appeal',
'Assessment of damages (claimant fails to beat P36 offer)    ',
'Exclude from reports                                        ',
'Returned to Client', 'Other', 'Exclude from Reports   ', 'Other'
) THEN 'Other' END AS [Repudiated/Settled]
,dim_detail_client.zurich_no_call_made
,[ll00_have_we_had_an_extension_for_the_initial_report]	AS [Have we had an extension for Initial Report]
,#ClientReportDates.date_initial_report_due 




INTO #MainData
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
	AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_detail_elapsed_days AS days ON days.master_fact_key = fact_dimension_main.master_fact_key
--LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileID = ms_fileid
LEFT OUTER JOIN Reporting.dbo.ClientSLAs ON [Client Name]=client_name COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN #ClientReportDates ON #ClientReportDates.master_client_code = dim_matter_header_current.master_client_code AND #ClientReportDates.master_matter_number = dim_matter_header_current.master_matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
LEFT OUTER JOIN red_dw.dbo.dim_date	ON 	dim_open_case_management_date_key	 = dim_date.dim_date_key
LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficmotor ON ds_sh_ms_udficmotor.fileid = dim_matter_header_current.ms_fileid
LEFT OUTER JOIN red_dw.dbo.ds_sh_ms_udficcommon ON 	 ds_sh_ms_udficmotor.fileid = ds_sh_ms_udficcommon.fileid
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key 
LEFT OUTER JOIN ms_prod.dbo.dbTasks  ON  ms_fileid=dbTasks.fileid AND tskFilter='tsk_01_02_010_TechCheckMot '
LEFT OUTER JOIN ms_prod.dbo.udTechMotor ON ms_fileid=udTechMotor.fileID
LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail WITH(NOLOCK) ON  fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
 AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
 ---this join is to get the Min date of the introductory phone call as there are a few dates
 LEFT OUTER JOIN
 
 (SELECT MIN(dim_child_detail.zurich_date_introductory_call_made) AS [Zurich Intro Date],client_code,matter_number FROM red_dw.dbo.dim_child_detail GROUP BY client_code,matter_number  ) AS ZurichIntroDate
ON ZurichIntroDate.client_code = dim_matter_header_current.client_code
AND    ZurichIntroDate.matter_number = dim_matter_header_current.matter_number



WHERE 
	reporting_exclusions=0
	AND  dim_client.client_group_name='Zurich'
	AND hierarchylevel3hist = 'Large Loss'
AND ((dim_detail_outcome.[date_claim_concluded] >='20190201' OR dim_detail_outcome.[date_claim_concluded]IS NULL))
	--ISNULL(dim_detail_outcome.[date_claim_concluded],dim_detail_outcome.zurich_result_date) IS NULL))
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	AND dim_matter_worktype.work_type_name <> 'Cross Border'
	AND dim_fed_hierarchy_history.hierarchylevel4hist <> 'Niche Costs'
	AND red_dw.dbo.dim_detail_core_details.referral_reason IN ('Dispute on Liability',                                        
'Dispute on liability',
'Dispute on liability and quantum',                            
'Dispute on quantum')  
AND dim_matter_header_current.ms_only = '1'
	AND dim_matter_header_current.client_code = 'Z1001'
	AND dim_matter_header_current.matter_number = '00080482'


SELECT 
[Client Name]
, [Mattersphere Weightmans Reference]
, [Matter Owner]
, [Days to send initial report (working days)]
--, [Days to send initial report (working days)_VERSION2]
, date_initial_report_sent
--, [Date Instructions Received]
, [Initial Report SLA Status]
, [Present Position]
, [Do Clients Require an Initial Report?]
, [Date Receipt of File Papers]
, [Have we had an Extension?]
, [Date Subsequent SLA Report Sent]
, [date_subsequent_report_due]
, [Subsequent Report is Overdue]
, [Days to send Subsequent report (working days)]
, [Lifecycle (date opened to date concluded)]
, [Referral Reason]
, calendar_date
, current_fin_year
, date_claim_concluded
, [YearFilter] 
, [YearFilterConcluded] 
, [YearFilterCostSettled]
, [YearFilterDateofLastBill]
, [Number of Matters]
, [countscore]
, damages_paid
, total_damages_and_tp_costs_reserve
, total_tp_costs_paid
, defence_costs_billed
, [Damages - Costs Paid]
, final_bill_flag
, (total_reserve	-Savings)/NULLIF(total_reserve,0)	AS [Total Reserve %]
, [Total Spend] 
, total_recovery
, Savings
, total_reserve
, [Matter Type Group]
, DATEDIFF(DAY,  MaxValue ,[Zurich Intro Date]  ) AS [Days between Date Opened and phone call date or receipt of client file of papers (whichever is later) ] 
,[Zurich Intro Date] 
,MaxValue
, grpageas_motor_date_of_receipt_of_clients_file_of_papers
, #MainData.date_opened_case_management
, CountPhoneCallNotComplete
, claimants_costs_paid
, NULLIF(total_amount_billed,0)	- NULLIF(vat_billed,0)  AS [total_amount_billed]
, [Date Closed]
, FILTER AS [Filter Date of Last Bill]
, repudiation_outcome
, [Indemnity Spend]
, vat_billed
, [Damages Banding]
, [Injury Type]
, [ProcessCompleted]
, tskCompleted 
, ScoreISBlank
, [Number]
, [Damages Banding_test]
, hierarchylevel3hist
, hierarchylevel4hist
, [Indemnity Spend_dwh]
, referral_reason
, ms_only
, zurich_result_date
,[Damages Reserve Current ]
,[Claimant Costs Reserve Current ]
,[Defence Costs Reserve Current]
,[Outcome of Case ]
,[Repudiated/Settled]
,zurich_no_call_made
,zurich_introductory_call
,[Have we had an extension for Initial Report]
,date_initial_report_due
,initial_report_due
FROM #MainData
--WHERE
--[Mattersphere Weightmans Reference] ='Z1001-81280'


   END

	
GO
