SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MotorSLAC_BK20190724]
(
	@Team AS VARCHAR(MAX) 
	, @FedCode AS VARCHAR(MAX)
	,@StartDate AS DATE
	,@EndDate AS DATE
	,@Status AS VARCHAR(MAX) 
	,@PresentPosition AS VARCHAR(MAX) 
	,@Client AS VARCHAR(MAX) 
	,@ClosedCases AS CHAR (3)
)
AS
BEGIN
	--For testing purposes
	--===========================================================
	--DECLARE  @vTeam AS VARCHAR(MAX) = 'Motor Manchester'
	--, @vFedCode AS VARCHAR(MAX) = '1363'
	--,@StartDate AS DATE = '2013-01-01'
	--,@EndDate AS DATE = '2019-07-03'
	--,@vStatus AS VARCHAR(MAX)  = 'Open,Re-opened'
	--,@vPosition AS VARCHAR(MAX) = 'Claim and costs outstanding'
	--,@Client AS VARCHAR(MAX)  = '00162924,Z00006,MIB005'
	--,@Closed AS CHAR (3) = 'No'



	
	IF OBJECT_ID('tempdb..#FeeEarnerList') IS NOT NULL   DROP TABLE #FeeEarnerList
	IF OBJECT_ID('tempdb..#Client') IS NOT NULL   DROP TABLE #Client
	IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
	IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status
	IF OBJECT_ID('tempdb..#PresentPosition') IS NOT NULL   DROP TABLE #PresentPosition


	SELECT ListValue  INTO #FeeEarnerList FROM 	dbo.udt_TallySplit(',', @FedCode)
	SELECT ListValue  INTO #Client FROM 	dbo.udt_TallySplit(',', @Client)
	SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
	SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit(',', @Status)
	SELECT ListValue  INTO #PresentPosition FROM 	dbo.udt_TallySplit(',', @PresentPosition)
	
SELECT AllData.client_code,
       AllData.matter_number,
       AllData.matter_description,
       AllData.matter_owner_fed_code,
       AllData.master_client_matter_combined,
       AllData.matter_owner_name,
       AllData.matter_owner_team,
       AllData.matter_opened_practice_management_calendar_date,
       AllData.matter_opened_case_management_calendar_date,
       AllData.matter_closed_practice_management_calendar_date,
       AllData.matter_closed_case_management_calendar_date,
       AllData.referral_reason,
       AllData.date_claim_concluded,
       AllData.date_instructions_received,
       AllData.grpageas_motor_date_of_receipt_of_clients_file_of_papers,
       AllData.date_initial_report_sent,
       AllData.date_subsequent_sla_report_sent,
       AllData.days_to_send_report,
       AllData.days_to_report_outstanding,
       AllData.days_to_file_opened,
       AllData.present_position,
       AllData.motor_status,
       AllData.days_to_subsequent_report,
       AllData.days_to_subsequent_reportV2,
       AllData.days_to_closure_report,
       AllData.no_closure_reports_sent,
       AllData.date_costs_settled,
       AllData.date_the_closure_report_sent,
       AllData.days_to_resolution,
       AllData.elapsed_days,
       AllData.insurerclient_reference,
       AllData.is_this_the_lead_file,
       AllData.outcome_of_case,
       AllData.reporting_exclusions,
       AllData.authorised_to_be_excluded_from_reports,
       AllData.SummaryInclude,
       AllData.LevelGroup,
       AllData.ExcludeFromReports,
       AllData.NoSettlementDate,
       AllData.CCNumber,
       AllData.CCONumber,
       AllData.CCBCO,
       AllData.CCRO,
       AllData.POpen,
       AllData.PClosed,
       AllData.PMissing,
       AllData.DisputeCase,
       AllData.RecoveryCase,
       AllData.NoClosureReportsOustanding,
       AllData.MissingDateInstruction,
       AllData.ExceptionDescription1,
       AllData.DaysToOpenRag,
       AllData.DaysToSubsequentRag,
       AllData.DaystoClosureReportRAG,
       AllData.Status,
       AllData.[Present Position]	

	    FROM 
(
SELECT  dim_matter_header_current.[client_code]
,dim_matter_header_current.[matter_number]
,dim_matter_header_current.[matter_description]
,fed_code AS [matter_owner_fed_code]
,master_client_code +'-' + master_matter_number AS [master_client_matter_combined]
,name AS [matter_owner_name]
,hierarchylevel4hist AS [matter_owner_team]
,date_opened_practice_management AS [matter_opened_practice_management_calendar_date]
,date_opened_case_management AS [matter_opened_case_management_calendar_date]
,date_closed_practice_management AS [matter_closed_practice_management_calendar_date]
,date_closed_case_management AS [matter_closed_case_management_calendar_date]
,dim_detail_core_details.[referral_reason] AS [referral_reason]
,dim_detail_outcome.[date_claim_concluded] AS [date_claim_concluded]
,dim_detail_core_details.[date_instructions_received] AS [date_instructions_received]
,dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [grpageas_motor_date_of_receipt_of_clients_file_of_papers]
,dim_detail_core_details.[date_initial_report_sent] AS [date_initial_report_sent]
,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [date_subsequent_sla_report_sent]
,fact_detail_elapsed_days.[days_to_send_report] AS [days_to_send_report]
,fact_detail_elapsed_days.[days_to_report_outstanding]  AS [days_to_report_outstanding]
,fact_detail_elapsed_days.[days_to_file_opened] AS [days_to_file_opened]
,dim_detail_core_details.[present_position] AS [present_position]
,CASE WHEN dim_detail_core_details.[motor_status] IS NULL THEN 'Missing' ELSE dim_detail_core_details.[motor_status] END  AS [motor_status]
,fact_detail_elapsed_days.[days_to_subsequent_report] AS [days_to_subsequent_reportV2]
,CASE WHEN dim_detail_outcome.[date_costs_settled] IS NOT NULL AND ISNULL(dim_detail_core_details.present_position,'') <>'Claim and costs concluded but recovery outstanding' THEN NULL
				WHEN dim_detail_core_details.[date_subsequent_sla_report_sent] is null and dim_detail_core_details.[date_initial_report_sent] is null then  NULL
				WHEN dim_detail_core_details.[date_initial_report_sent] is null then NULL
				WHEN dim_detail_core_details.[date_initial_report_sent] is not null and dim_detail_core_details.[date_subsequent_sla_report_sent] is null  THEN	(DATEDIFF(dd, dim_detail_core_details.[date_initial_report_sent], GETDATE()))-- + 1)
																					-(DATEDIFF(wk, dim_detail_core_details.[date_initial_report_sent], GETDATE()) * 2)
																					-(CASE WHEN DATENAME(dw, dim_detail_core_details.[date_initial_report_sent]) = 'Sunday' THEN 1 ELSE 0 END)
																					-(CASE WHEN DATENAME(dw, GETDATE()) = 'Saturday' THEN 1 ELSE 0 END)
				WHEN dim_detail_core_details.[date_subsequent_sla_report_sent] is not NULL 
				THEN (DATEDIFF(dd, dim_detail_core_details.[date_subsequent_sla_report_sent], GETDATE()))-- + 1)
					-(DATEDIFF(wk, dim_detail_core_details.[date_subsequent_sla_report_sent], GETDATE()) * 2)
					-(CASE WHEN DATENAME(dw, dim_detail_core_details.[date_subsequent_sla_report_sent]) = 'Sunday' THEN 1 ELSE 0 END)
					-(CASE WHEN DATENAME(dw, GETDATE()) = 'Saturday' THEN 1 ELSE 0 END)
		
				ELSE 9999999999989999999
			END AS days_to_subsequent_report
,fact_detail_elapsed_days.[days_to_closure_report] AS [days_to_closure_report]
,dim_detail_core_details.[no_closure_reports_sent] AS [no_closure_reports_sent]
,dim_detail_outcome.[date_costs_settled] AS [date_costs_settled]
,dim_detail_core_details.[date_the_closure_report_sent] AS [date_the_closure_report_sent]
,fact_detail_elapsed_days.[days_to_resolution] AS [days_to_resolution] 
,fact_detail_elapsed_days.[elapsed_days] AS [elapsed_days]
,dim_client_involvement.[insurerclient_reference] AS [insurerclient_reference]
,dim_detail_core_details.[is_this_the_lead_file] AS [is_this_the_lead_file]
,dim_detail_outcome.[outcome_of_case] AS [outcome_of_case] 
,dim_matter_header_current.[reporting_exclusions] AS [reporting_exclusions] 
,dim_detail_core_details.[authorised_to_be_excluded_from_reports] AS [authorised_to_be_excluded_from_reports] 
,[SummaryInclude]='Include'
,[LevelGroup]= dim_client_involvement.[insurerclient_reference] + 'Include'
,[ExcludeFromReports]= CASE WHEN dim_detail_outcome.[outcome_of_case]='Exclude from reports' OR  dim_detail_core_details.[referral_reason] ='Advice only' 
OR dim_detail_core_details.[referral_reason] = 'Nomination only' THEN 1 ELSE 0 END 
,[NoSettlementDate]=CASE WHEN dim_detail_outcome.[date_costs_settled] IS NULL AND dim_detail_core_details.[date_the_closure_report_sent] IS NOT NULL THEN 1 ELSE 0 END 

,[CCNumber]= CASE WHEN dim_detail_core_details.[present_position] IN ('Claim and costs outstanding','Claim and costs concluded but recovery outstanding') THEN 1 ELSE 0 END 
,[CCONumber]= CASE WHEN dim_detail_core_details.[present_position]='Claim and costs outstanding' THEN 1 ELSE 0 END 
,[CCBCO]= CASE WHEN dim_detail_core_details.[present_position] ='Claim concluded but costs outstanding' THEN 1 ELSE 0 END 
,[CCRO]= CASE WHEN dim_detail_core_details.[present_position]='Claim and costs concluded but recovery outstanding' THEN 1 ELSE 0 END 
,[POpen]= CASE WHEN dim_detail_core_details.[present_position] IN ('Claim and costs outstanding','Claim concluded but costs outstanding','Claim and costs concluded but recovery outstanding') THEN 1 ELSE 0 END 
,[PClosed]= CASE WHEN dim_detail_core_details.[present_position] IN ('Final bill due - claim and costs concluded','Final bill sent - unpaid','To be closed/minor balances to be clear') THEN 1 ELSE 0 END 
,[PMissing]= CASE WHEN dim_detail_core_details.[present_position] IS NULL THEN 1 ELSE 0 END 
,[DisputeCase]= CASE WHEN UPPER(dim_detail_core_details.[referral_reason]) IN ('DISPUTE ON LIABILITY','DISPUTE ON LIABILITY AND QUANTUM','DISPUTE ON QUANTUM','COSTS DISPUTE','INFANT APPROVAL') THEN 1 ELSE 0 END 


,[RecoveryCase] = CASE WHEN UPPER(dim_detail_core_details.[referral_reason]) LIKE '%RECOVERY%' OR  dim_detail_core_details.[present_position]='Claim and costs concluded but recovery outstanding' THEN 1 ELSE 0 END 
,[NoClosureReportsOustanding] = CASE WHEN dim_detail_core_details.[date_the_closure_report_sent] IS NULL THEN 1 ELSE 0 END 
,[MissingDateInstruction]= CASE WHEN dim_detail_core_details.[date_instructions_received] IS NULL THEN 1 ELSE 0 END 
,[ExceptionDescription1]=''
,[DaysToOpenRag]='Green'
,[DaysToSubsequentRag]='Red'
,[DaystoClosureReportRAG] = CASE WHEN fact_detail_elapsed_days.[days_to_closure_report] IS NULL THEN 'Transparent'
WHEN fact_detail_elapsed_days.[days_to_closure_report]<=3 THEN  'Green' ELSE 'Red' END 
,[Status]= CASE WHEN dim_detail_core_details.[motor_status] IS NULL THEN 'Missing' ELSE dim_detail_core_details.[motor_status] END 
,[Present Position] = CASE WHEN dim_detail_core_details.present_position IS NULL THEN 'Missing' ELSE dim_detail_core_details.present_position END 



FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN #client as Client ON dim_matter_header_current.client_code=Client.ListValue COLLATE database_default
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = hierarchylevel4hist COLLATE database_default
INNER JOIN #FeeEarnerList AS FedCode ON FedCode.ListValue COLLATE database_default = fee_earner_code COLLATE database_default
INNER JOIN red_dw.dbo.dim_detail_core_details 
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.fact_detail_elapsed_days 
 ON fact_detail_elapsed_days.client_code = dim_matter_header_current.client_code
 AND fact_detail_elapsed_days.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_detail_outcome 
 ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_client_involvement 
 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
 
 
WHERE CASE WHEN date_closed_practice_management is null THEN 1 
					 WHEN @ClosedCases = 'Yes' and date_closed_practice_management is not null or date_closed_practice_management is null then 1
					 ELSE 0	
				END = 1
			AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @StartDate and @EndDate
			AND dim_matter_header_current.matter_number <> 'ML'
			AND fee_earner_code NOT IN ('1480','JFA','3234','4912','4109','3562','4084','3316','4754','LED2','MIN1','RDD1','3718','LGF1','MKG1')
			AND hierarchylevel3hist='Motor'
			AND work_type_code <>'0032'
			AND (reporting_exclusions=0   OR outcome_of_case='Exclude from reports')
		

) AS AllData
INNER JOIN #Status AS Status 
	ON 	Status.ListValue COLLATE database_default = isnull(rtrim([Status]),'Missing Data') COLLATE database_default
INNER JOIN #PresentPosition AS Position 
	ON RTRIM(Position.ListValue) COLLATE database_default = isnull(rtrim([Present Position]),'Missing Data') COLLATE database_default

	END
GO
