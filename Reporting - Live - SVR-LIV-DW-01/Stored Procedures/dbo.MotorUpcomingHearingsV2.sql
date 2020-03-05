SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE  [dbo].[MotorUpcomingHearingsV2]
(
@StartDate AS DATE
,@EndDate AS DATE
,@Team AS NVARCHAR(MAX)
,@MatterOwner AS NVARCHAR(MAX)
,@Client AS NVARCHAR(MAX)
)
AS
BEGIN

SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit](',', @Team)
SELECT ListValue  INTO #MatterOwner FROM Reporting.dbo.[udt_TallySplit](',', @MatterOwner)
SELECT ListValue  INTO #Client FROM Reporting.dbo.[udt_TallySplit](',', @Client) 

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2019-02-01'
--SET @EndDate='2019-05-31'


IF OBJECT_ID('tempdb..#MainDataSet') IS NOT NULL DROP TABLE #MainDataSet

SELECT a.client_code
	, a.matter_number
	, CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) AS [Key Date]
	, RTRIM(tskDesc) AS [Key Date Narrative]
	, NULL AS task_amended_deleted_flag
	, CASE WHEN tskComplete=1 THEN 'a' ELSE 'p' END  task_status
	, CASE WHEN CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) >= GETDATE() THEN 'Future'
			WHEN CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) < GETDATE() OR tskActive=0 THEN 'Expired/Deleted'
			
	  END AS [Filter]
	, CASE WHEN CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) >= GETDATE() AND tskComplete=0  AND tskActive=1 THEN 'Live'
		ELSE  'Deleted/Completed'
		
		END AS [Tab Filter]
	, CASE WHEN  tskComplete=1 AND tskActive=1 THEN 'Completed'
		WHEN CONVERT(DATE,[red_dw].[dbo].[datetimelocal](tskDue),103) < GETDATE() AND tskActive=1   THEN 'Expired'
		WHEN tskActive=0 AND tskComplete=0   THEN 'Deleted'
		WHEN tskActive=0 AND tskComplete=1  THEN 'Completed/Deleted'
		ELSE NULL
		END AS [Flag]
	, NULL AS dim_task_due_date_key
INTO #MainDataSet	
FROM red_dw.dbo.dim_matter_header_current AS a WITH (NOLOCK)
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH (NOLOCK) 
 ON fed_code=fee_earner_code collate database_default
 AND dss_current_flag='Y'
INNER JOIN #Client AS Client ON Client.ListValue COLLATE database_default = a.client_code COLLATE database_default
INNER JOIN #MatterOwner AS MatterOwner ON MatterOwner.ListValue COLLATE database_default = fed_code COLLATE database_default
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = hierarchylevel4hist COLLATE database_default


INNER JOIN MS_Prod.dbo.dbTasks WITH (NOLOCK) ON a.ms_fileid=dbTasks.fileID
WHERE  CONVERT(DATE,tskDue,103) >=@StartDate
AND CONVERT(DATE,tskDue,103)<=@EndDate 
AND hierarchylevel3hist='Motor'
AND RTRIM(tskDesc) IN 
(
'REM: Appeal hearing today [CASE MAN]'
,'REM: Application hearing date today [CASE MAN]'
,'REM: CMC today - [CASE MAN]'
,'REM: Court hearing today [CASE MAN]'
,'REM: Date of Inquest due today [CASE MAN]'
,'REM: Detailed assessment hearing today - [CASE MAN]'
,'REM: Disposal hearing due today [CASE MAN]'
,'REM: Hearing date today [CASE MAN]'
,'REM: Infant approval due today [CASE MAN]'
,'REM: Inquest today [CASE MAN]'
,'REM: Interlocutory hearing today -  [CASE MAN]'
,'REM: Joint settlement meeting due today (CM)'
,'REM: Preliminary hearing due today - [CASE MAN]'
,'REM: Small claim track hearing due today - [CM]'
,'REM: Stage 3 infant approval hearing due today [CM]'
,'REM: Stage 3 oral hearing due today [CM]'
,'REM: Trial due today - [CASE MAN]'
,'Appeal hearing - today'
,'Application hearing - today'
,'CMC due - today'
,'Court hearing due - today'
,'Inquest date - today'
,'Detailed assessment hearing due - today'
,'Disposal hearing due - today'
,'Hearing – today'
,'Infant approval - today'
,'Interlocutory hearing - today'
,'Joint settlement meeting - today'
,'Preliminary hearing - today'
,'Small Claim Track hearing due - today'
,'Stage 3 infant approval hearing - today'
,'Stage 3 oral hearing - today'
,'Trial date - today'
,'Infant Settlement Hearing - today'
)






SELECT [Client Code]
	, [Matter Number]
	, [Client Group Code]
	, [Client Group Name]
	, [3E Reference]
	, [Case Handler]
	, [Team]
	, [Fee Regime]
	, [Fixed Fee (inc Costs)]
	, [Matter Description]
	, [Present Position]
	, [Outcome of Case]
	, [Date Claim Concluded]
	, [Date Costs Settled]
	, [Court Name]
	, [Track]
	, [Key Date]
	, [Deleted Key Date]
	, [Key Date Narrative]
	, [Deleted Key Date Narrative]
	, [Filter]
	, [Tab Filter]
	, [Flag]
	, wip
	, last_bill_date
	, ICAmount
	, dim_task_due_date_key

	
	,COALESCE([1st Nature of Work],[2nd Nature of Work],[3rd Nature of Work],[4th Nature of Work],[5th Nature of Work]) AS [Nature of Work]
	,COALESCE([1st Due Date for Paperwork Instruction],[2nd Due Date for Paperwork Instruction],[3rd Due Date for Paperwork Instruction],[4th Due Date for Paperwork Instruction],[5th Due Date for Paperwork Instruction]) AS [Due Date for Paperwork Instruction]
	,COALESCE([1st Internal/External],[2nd Internal/External],[3rd Internal/External],[4th Internal/External],[5th Internal/External]) AS [Internal/External]
	,COALESCE([1st Internal Counsel],[2nd Internal Counsel],[3rd Internal Counsel],[4th Internal Counsel],[5th Internal Counsel]) AS [Internal Counsel]
	,COALESCE([1st Internal Counsel's Fee],[2nd Internal Counsel's Fee],[3rd Internal Counsel's Fee],[4th Internal Counsel's Fee],[5th Internal Counsel's Fee]) AS [Internal Counsel's Fee]
	,COALESCE([1st Hearing Outcome],[2nd Hearing Outcome],[3rd Hearing Outcome],[4th Hearing Outcome],[5th Hearing Outcome]) AS [Hearing Outcome]
	
	,COALESCE([1st Hearing Date],[2nd Hearing Date],[3rd Hearing Date],[4th Hearing Date],[5th Hearing Date]) AS [Hearing Date]
	,COALESCE([1st Costs Ordered in our Favour],[2nd Costs Ordered in our Favour],[3rd Costs Ordered in our Favour],[4th Costs Ordered in our Favour],[5th Costs Ordered in our Favour]) AS [Costs Ordered in our Favour]
	,COALESCE([1st Notes],[2nd Notes],[3rd Notes],[4th Notes],[5th Notes]) AS [Notes]


,ICHrsRecorded
,ICHrsValueRecorded
,TotalICValueBilled
,TotalICHrsBilled	
,defence_costs_billed	
FROM 
(
SELECT DISTINCT dim_matter_header_current.client_code AS [Client Code]
	, dim_matter_header_current.matter_number AS [Matter Number]
	, dim_client.client_group_code AS [Client Group Code]
	, dim_client.client_group_name AS [Client Group Name]
	, dim_matter_header_current.master_client_code+'/'+dim_matter_header_current.master_matter_number AS [3E Reference]
	, name AS [Case Handler]
	, hierarchylevel4hist AS [Team]
	, CASE WHEN LOWER(output_wip_fee_arrangement) LIKE 'fixed fee%' THEN 'Fixed Fee' ELSE output_wip_fee_arrangement END AS [Fee Regime]
	, dim_matter_header_current.fixed_fee_amount AS [Fixed Fee (inc Costs)]
	, matter_description AS [Matter Description]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_detail_outcome.outcome_of_case AS [Outcome of Case]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, dim_detail_outcome.date_costs_settled AS [Date Costs Settled]
	, court_name AS [Court Name]
	, dim_detail_core_details.track AS [Track]
	, CASE WHEN [Tab Filter]='Live' THEN [Key Date] ELSE NULL END  AS [Key Date]
	, CASE WHEN [Tab Filter]='Deleted/Completed' THEN [Key Date] ELSE NULL END AS [Deleted Key Date]
	, CASE WHEN [Tab Filter]='Live' THEN [Key Date Narrative] ELSE NULL END  AS [Key Date Narrative]
	, CASE WHEN [Tab Filter]='Deleted/Completed' THEN [Key Date Narrative] ELSE NULL END AS [Deleted Key Date Narrative]
	, [Filter] AS [Filter]
	, [Tab Filter] AS [Tab Filter]
	, [Flag] AS [Flag]
	,wip
	,last_bill_date
	,ICAmount


	/*
	, CONVERT(DATE,[Key Date],103) AS dim_task_due_date_key

	
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_nature_of_work_pick_list ELSE NULL END AS [1st Nature of Work]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_date_paperwork_due ELSE NULL END AS [1st Due Date for Paperwork Instruction]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_internal_external_y_n_pick_list ELSE NULL END AS [1st Internal/External]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_internal_counsel_name ELSE NULL END AS [1st Internal Counsel]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_internal_counsel_fee ELSE NULL END AS [1st Internal Counsel's Fee]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_hearing_outcome ELSE NULL END AS [1st Hearing Outcome]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN [red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date) ELSE NULL END AS [1st Hearing Date]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_costs_ordered_in_our_favour ELSE NULL END AS [1st Costs Ordered in our Favour]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_1st_hearing_date),103) THEN counsel_1st_notes ELSE NULL END AS [1st Notes]

	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_nature_of_work_pick_list ELSE NULL END AS [2nd Nature of Work]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_date_paperwork_due ELSE NULL END AS [2nd Due Date for Paperwork Instruction]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_internal_external_y_n_pick_list ELSE NULL END AS [2nd Internal/External]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_internal_counsel_name ELSE NULL END AS [2nd Internal Counsel]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_internal_counsel_fee ELSE NULL END AS [2nd Internal Counsel's Fee]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_hearing_outcome ELSE NULL END AS [2nd Hearing Outcome]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  [red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date) ELSE NULL END AS [2nd Hearing Date]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_costs_ordered_in_our_favour ELSE NULL END AS [2nd Costs Ordered in our Favour]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_2nd_hearing_date),103) THEN  counsel_2nd_notes ELSE NULL END AS [2nd Notes]

	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_nature_of_work_pick_list ELSE NULL END AS [3rd Nature of Work]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_date_paperwork_due ELSE NULL END AS [3rd Due Date for Paperwork Instruction]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_internal_external_y_n_pick_list ELSE NULL END AS [3rd Internal/External]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_internal_counsel_name ELSE NULL END AS [3rd Internal Counsel]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_internal_counsel_fee ELSE NULL END AS [3rd Internal Counsel's Fee]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_hearing_outcome ELSE NULL END AS [3rd Hearing Outcome]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  [red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date) ELSE NULL END AS [3rd Hearing Date]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_costs_ordered_in_our_favour ELSE NULL END AS [3rd Costs Ordered in our Favour]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_3rd_hearing_date),103) THEN  counsel_3rd_notes ELSE NULL END AS [3rd Notes]

	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_nature_of_work_pick_list ELSE NULL END AS [4th Nature of Work]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_date_paperwork_due ELSE NULL END AS [4th Due Date for Paperwork Instruction]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_internal_external_y_n_pick_list ELSE NULL END AS [4th Internal/External]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_internal_counsel_name ELSE NULL END AS [4th Internal Counsel]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_internal_counsel_fee ELSE NULL END AS [4th Internal Counsel's Fee]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_hearing_outcome ELSE NULL END AS [4th Hearing Outcome]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  [red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date) ELSE NULL END AS [4th Hearing Date]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_costs_ordered_in_our_favour ELSE NULL END AS [4th Costs Ordered in our Favour]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_4th_hearing_date),103) THEN  counsel_4th_notes ELSE NULL END AS [4th Notes]

	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_nature_of_work_pick_list ELSE NULL END AS [5th Nature of Work]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_date_paperwork_due ELSE NULL END AS [5th Due Date for Paperwork Instruction]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_internal_external_y_n_pick_list ELSE NULL END AS [5th Internal/External]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_internal_counsel_name ELSE NULL END AS [5th Internal Counsel]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_internal_counsel_fee ELSE NULL END AS [5th Internal Counsel's Fee]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_hearing_outcome ELSE NULL END AS [5th Hearing Outcome]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  [red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date) ELSE NULL END AS [5th Hearing Date]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_costs_ordered_in_our_favour ELSE NULL END AS [5th Costs Ordered in our Favour]
	, CASE WHEN CONVERT(DATE,[Key Date],103)= CONVERT(DATE,[red_dw].[dbo].[datetimelocal](counsel_5th_hearing_date),103) THEN  counsel_5th_notes ELSE NULL END AS [5th Notes] 

	*/

 ,  CONVERT(DATE, [Key Date], 103) AS dim_task_due_date_key,
           CASE  WHEN CONVERT(DATE, [Key Date], 103) = CONVERT( DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_nature_of_work_pick_list 
				ELSE  NULL  END AS [1st Nature of Work],
           CASE  WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_date_paperwork_due
               ELSE NULL END AS [1st Due Date for Paperwork Instruction],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_internal_external_y_n_pick_list
               ELSE NULL END AS [1st Internal/External],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_internal_counsel_name
               ELSE NULL END AS [1st Internal Counsel],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_internal_counsel_fee
               ELSE NULL END AS [1st Internal Counsel's Fee],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_hearing_outcome
               ELSE NULL END AS [1st Hearing Outcome],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE,counsel_1st_hearing_date, 103) THEN counsel_1st_hearing_date
               ELSE NULL END AS [1st Hearing Date],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_costs_ordered_in_our_favour
               ELSE NULL END AS [1st Costs Ordered in our Favour],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_1st_hearing_date, 103) THEN counsel_1st_notes
               ELSE NULL END AS [1st Notes],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_nature_of_work_pick_list
               ELSE NULL END AS [2nd Nature of Work],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_date_paperwork_due
               ELSE NULL END AS [2nd Due Date for Paperwork Instruction],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_internal_external_y_n_pick_list
               ELSE NULL END AS [2nd Internal/External],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_internal_counsel_name
               ELSE NULL END AS [2nd Internal Counsel],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_internal_counsel_fee
               ELSE NULL END AS [2nd Internal Counsel's Fee],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_hearing_outcome
               ELSE NULL END AS [2nd Hearing Outcome],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_hearing_date
               ELSE NULL END AS [2nd Hearing Date],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_costs_ordered_in_our_favour
               ELSE NULL END AS [2nd Costs Ordered in our Favour],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_2nd_hearing_date, 103) THEN counsel_2nd_notes
               ELSE NULL END AS [2nd Notes],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_nature_of_work_pick_list
               ELSE NULL END AS [3rd Nature of Work],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_date_paperwork_due
               ELSE NULL END AS [3rd Due Date for Paperwork Instruction],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_internal_external_y_n_pick_list
               ELSE NULL END AS [3rd Internal/External],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE,counsel_3rd_hearing_date,103) THEN counsel_3rd_internal_counsel_name
               ELSE NULL END AS [3rd Internal Counsel],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_internal_counsel_fee
               ELSE NULL END AS [3rd Internal Counsel's Fee],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_hearing_outcome
               ELSE NULL END AS [3rd Hearing Outcome],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_hearing_date
               ELSE NULL END AS [3rd Hearing Date],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date,103) THEN counsel_3rd_costs_ordered_in_our_favour
               ELSE NULL END AS [3rd Costs Ordered in our Favour],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_3rd_hearing_date, 103) THEN counsel_3rd_notes
               ELSE NULL END AS [3rd Notes],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_nature_of_work_pick_list
               ELSE NULL END AS [4th Nature of Work],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_date_paperwork_due
               ELSE NULL END AS [4th Due Date for Paperwork Instruction],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_internal_external_y_n_pick_list
               ELSE NULL END AS [4th Internal/External],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_internal_counsel_name
               ELSE NULL END AS [4th Internal Counsel],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_internal_counsel_fee
               ELSE NULL END AS [4th Internal Counsel's Fee],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_hearing_outcome
               ELSE NULL END AS [4th Hearing Outcome],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_hearing_date
               ELSE NULL END AS [4th Hearing Date],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_costs_ordered_in_our_favour
               ELSE NULL END AS [4th Costs Ordered in our Favour],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_4th_hearing_date, 103) THEN counsel_4th_notes
               ELSE NULL END AS [4th Notes],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date,103) THEN counsel_5th_nature_of_work_pick_list
               ELSE NULL END AS [5th Nature of Work],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_date_paperwork_due
               ELSE NULL END AS [5th Due Date for Paperwork Instruction],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_internal_external_y_n_pick_list
               ELSE NULL END AS [5th Internal/External],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_internal_counsel_name
               ELSE NULL END AS [5th Internal Counsel],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_internal_counsel_fee
               ELSE NULL END AS [5th Internal Counsel's Fee],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_hearing_outcome
               ELSE NULL END AS [5th Hearing Outcome],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_hearing_date
               ELSE NULL END AS [5th Hearing Date],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, counsel_5th_hearing_date, 103) THEN counsel_5th_costs_ordered_in_our_favour
               ELSE NULL END AS [5th Costs Ordered in our Favour],
           CASE WHEN CONVERT(DATE, [Key Date], 103) = CONVERT(DATE, [counsel_5th_hearing_date], 103) THEN counsel_5th_notes
               ELSE NULL END AS [5th Notes]
	
,ICHrsRecorded
,ICHrsValueRecorded
,TotalICValueBilled
,BilledTime.TotalICHrsBilled
,defence_costs_billed

FROM  #MainDataSet AS TaskData
INNER JOIN red_dw.dbo.dim_matter_header_current (NOLOCK)
 ON dim_matter_header_current.client_code = TaskData.client_code
 AND dim_matter_header_current.matter_number = TaskData.matter_number
INNER JOIN red_dw.dbo.dim_client (NOLOCK)
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_detail_core_details (NOLOCK)
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.fact_finance_summary (NOLOCK)
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome  (NOLOCK)
  ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
 AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number 

LEFT OUTER JOIN red_dw.dbo.dim_detail_court  (NOLOCK)
  ON dim_detail_court.client_code = dim_matter_header_current.client_code
 AND dim_detail_court.matter_number = dim_matter_header_current.matter_number 

LEFT OUTER JOIN red_dw.dbo.fact_detail_court  (NOLOCK)
  ON fact_detail_court.client_code = dim_matter_header_current.client_code
 AND fact_detail_court.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance  (NOLOCK)
  ON dim_detail_finance.client_code = dim_matter_header_current.client_code
 AND dim_detail_finance.matter_number = dim_matter_header_current.matter_number 
 LEFT OUTER JOIN red_dw.dbo.dim_court_involvement (NOLOCK)
  ON dim_court_involvement.client_code = dim_matter_header_current.client_code
 AND dim_court_involvement.matter_number = dim_matter_header_current.matter_number 
LEFT OUTER JOIN 
(
SELECT fact_all_time_activity.client_code,fact_all_time_activity.matter_number,SUM(time_charge_value) AS ICAmount
FROM red_dw.dbo.fact_all_time_activity (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current (NOLOCK)
 ON dim_matter_header_current.client_code = fact_all_time_activity.client_code
 AND dim_matter_header_current.matter_number = fact_all_time_activity.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE dim_bill_key=0
AND hierarchylevel3hist='Motor'
AND time_activity_code LIKE 'IC%'
GROUP BY fact_all_time_activity.client_code,fact_all_time_activity.matter_number
) AS ICTime
 ON ICTime.client_code=dim_matter_header_current.client_code
 AND ICTime.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current (NOLOCK)
 ON fact_matter_summary_current.client_code=dim_matter_header_current.client_code
 AND fact_matter_summary_current.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN (
SELECT AllData.client_code,AllData.matter_number,STRING_AGG(AllData.HrsRecorded,'; ') AS ICHrsRecorded
FROM 
(SELECT fact_all_time_activity.client_code,fact_all_time_activity.matter_number
,dim_fed_hierarchy_history2.name + ' '+ CAST(CAST(SUM(minutes_recorded)/60  AS DECIMAL(10,1))AS NVARCHAR(MAX)) AS HrsRecorded
--,STRING_AGG(dim_fed_hierarchy_history2.name + ' '+  CAST(CAST(SUM(time_charge_value) /60  AS DECIMAL(10,2))AS NVARCHAR(MAX)) AS ValueRecorded

FROM red_dw.dbo.fact_all_time_activity (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current (NOLOCK)
 ON dim_matter_header_current.client_code = fact_all_time_activity.client_code
 AND dim_matter_header_current.matter_number = fact_all_time_activity.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
 ON dim_fed_hierarchy_history.fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history.dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  AS  dim_fed_hierarchy_history2  (NOLOCK)
 ON dim_fed_hierarchy_history2.fed_code=fed_code_fee_earner COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history2.dss_current_flag='Y'
 WHERE  dim_fed_hierarchy_history.hierarchylevel3hist='Motor'
AND time_activity_code LIKE 'IC%'

GROUP BY fact_all_time_activity.client_code,fact_all_time_activity.matter_number,dim_fed_hierarchy_history2.name
) AS AllData
GROUP BY AllData.client_code,AllData.matter_number) AS ICHrs
 ON   ICHrs.client_code = TaskData.client_code
 AND ICHrs.matter_number = TaskData.matter_number

 LEFT OUTER JOIN (
SELECT fact_all_time_activity.client_code,fact_all_time_activity.matter_number
,SUM(time_charge_value)  AS ICHrsValueRecorded
FROM red_dw.dbo.fact_all_time_activity (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current (NOLOCK)
 ON dim_matter_header_current.client_code = fact_all_time_activity.client_code
 AND dim_matter_header_current.matter_number = fact_all_time_activity.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
 ON dim_fed_hierarchy_history.fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history.dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history AS  dim_fed_hierarchy_history2 (NOLOCK) 
 ON dim_fed_hierarchy_history2.fed_code=fed_code_fee_earner COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history2.dss_current_flag='Y'
 WHERE  dim_fed_hierarchy_history.hierarchylevel3hist='Motor'
AND time_activity_code LIKE 'IC%'

GROUP BY fact_all_time_activity.client_code,fact_all_time_activity.matter_number) AS ICValue
 ON   ICValue.client_code = TaskData.client_code
 AND ICValue.matter_number = TaskData.matter_number

LEFT OUTER JOIN (SELECT client_code,matter_number
,SUM(time_charge_value) AS TotalICValueBilled
,SUM(minutes_recorded) /60 AS TotalICHrsBilled
FROM red_dw.dbo.fact_bill_billed_time_activity (NOLOCK)
INNER JOIN red_dw.dbo.dim_matter_header_current (NOLOCK)
 ON dim_matter_header_current.dim_matter_header_curr_key = fact_bill_billed_time_activity.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history (NOLOCK)
 ON dim_fed_hierarchy_history.fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dim_fed_hierarchy_history.dss_current_flag='Y'
 WHERE  dim_fed_hierarchy_history.hierarchylevel3hist='Motor'
AND time_activity_code LIKE 'IC%'
GROUP BY client_code,matter_number) AS BilledTime
 ON   BilledTime.client_code = TaskData.client_code
 AND BilledTime.matter_number = TaskData.matter_number
) AS AllData;

END 
GO
