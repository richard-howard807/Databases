SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2022-09-28
-- Description:	#156744, new data source at matter level for see the possibilty dashboard

--added CTE, Row_Number and Tasks JL 
--added in history table for date outcome
-- =============================================                       
CREATE PROCEDURE [dbo].[STPMatterLevel] 
	
AS
BEGIN
IF OBJECT_ID('tempdbNULL.#temptb1') IS NOT null 
DROP TABLE #temptb1
	
	SET NOCOUNT ON;



----go and get the prev date--
 WITH CTE_PREV_DATE AS(
SELECT [recordid]
      ,[fileid]
      ,[bitactive]
      ,[dtesubslarepssl]
	  ,ROW_NUMBER() OVER (PARTITION BY fileid
	  ORDER BY  [dtesubslarepssl] DESC ) as row_num
      ,[dss_create_time]
      ,[dss_update_time]
  FROM [red_dw].[dbo].[ds_sh_ms_udsubslarep]
 -- WHERE fileid = '5074120'

  )
  SELECT 
   CTE_PREV_DATE.row_num
  ,CTE_PREV_DATE.fileid
  ,CTE_PREV_DATE.dtesubslarepssl AS prev_date_subsequent_sla_report_sent
  INTO #temptb1
  FROM CTE_PREV_DATE
  WHERE CTE_PREV_DATE.row_num = 2	--this is to get the prev date subsequent sla report sent (this field in the DWH is not correct -  dim_detail_previous_details.prev_date_subsequent_sla_report so this is a work around) 


-----------------------------------------------------------------------------------------------------------------
--MainQuery

SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MS Client/Matter Reference]
	,COALESCE(dim_matter_header_current.client_group_name, dim_matter_header_current.client_name) AS [Client Group/Client Name]
	,dim_matter_header_current.matter_owner_full_name AS [Case Manager]
	,dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	,dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	,dim_matter_header_current.date_opened_case_management AS [Date Opened]
	,dim_matter_header_current.date_closed_case_management AS [Date Closed]
	,dim_detail_outcome.[date_claim_concluded] AS [Date Claim Concluded]
	,dim_matter_worktype.work_type_name AS [Matter Type]
	,dim_matter_worktype.work_type_group AS [Matter Group]
	,dim_detail_core_details.[present_position] AS [Present Position]
	,dim_detail_core_details.[track] AS [Track]
	,fact_finance_summary.[damages_reserve] AS [Damages Reserve]
	,dim_detail_core_details.[do_clients_require_an_initial_report] AS [Do clients require an initial report?]
	,dim_detail_core_details.[date_initial_report_sent] AS [Date of initial report]
	,dim_detail_core_details.[grpageas_motor_date_of_receipt_of_clients_file_of_papers] AS [Date of receipt of client's file of papers]
	,dim_detail_core_details.[ll00_have_we_had_an_extension_for_the_initial_report] AS [Extension for initial report]
	,dim_detail_core_details.[date_initial_report_due] AS [Date initial report due]
	,dim_detail_core_details.[date_subsequent_sla_report_sent] AS [Date of subsequent report (most recent entry)]
	,#temptb1.prev_date_subsequent_sla_report_sent AS [Date of subsequent report (penultimate entry)]
	--,dim_detail_outcome.[ll00_settlement_basis] AS [Date of subsequent report (most recent entry)]
	,dim_detail_core_details.[date_the_closure_report_sent] AS [Date of closure report]
	,dim_detail_claim.[axa_claim_strategy] AS [Claims strategy]
	,dim_detail_outcome.date_claim_concluded_date_last_changed  AS [Date claims strategy MI field completed]
	,dim_detail_core_details.[anticipated_settlement_date] AS [Anticipated settlement date]
	,dim_detail_outcome.[outcome_of_case] AS [Outcome]
	---,NULL AS [Date outcome MI field completed]
	,dim_detail_outcome.[reason_for_settlement] AS [Reason for settlement]
	--,NULL AS [Reason for successful outcome]
	,fact_finance_summary.[damages_paid] AS [Damages Paid]
	,fact_detail_paid_detail.[total_settlement_value_of_the_claim_paid_by_all_the_parties] AS [Damages Paid (100%)]
	,fact_finance_summary.[tp_total_costs_claimed] AS [Claimant's Costs Claimed]
	,fact_detail_paid_detail.[tp_total_costs_claimed_all_parties] AS [Claimant's Costs Claimed (100%)]
	,fact_finance_summary.[claimants_costs_paid] AS [Claimant's Costs Paid]
	,fact_finance_summary.[claimants_total_costs_paid_by_all_parties] AS [Claimant's Costs Paid (100%)]
	,dim_detail_outcome.[date_costs_settled] AS [Date Costs Settled]
	--,NULL AS [Total Billed exc. VAT]
	,last_bill_date  AS [Last bill date (MS) (include composite)]
	,fileopener.[No. of red Paperlite] AS [No. of red entries in MS action list (Paperlite)]
	,NonePaperLight.[No. of red Other] AS [No. of red entries in MS action list (Other)]
	,fileopener.[No. of red 5+ days old Paperlite] AS [No. of red entries in MS action list over 5 days old (Paperlite)]	--5 days old greater than today
	,NonePaperLight.[No. of red 5+ days old Other] AS [No. of red entries in MS action list over 5 days old (Other)]	--5 days old greater than today
	,DateOfOutcome.[Date Outcome of case Completed]
	
 
FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN #temptb1
ON #temptb1.fileid	= dim_matter_header_current.ms_fileid
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

LEFT JOIN (

SELECT 

client_code AS [client_code]
	,matter_number AS [matter_number]
	,COUNT(CASE WHEN  tskType ='PAPERLITE' THEN 1 ELSE NULL END) AS [No. of red Paperlite]
	,SUM(CASE WHEN  DATEDIFF(dd,tskDue, getdate()) >=5 THEN 1 ELSE 0 END)  AS [No. of red 5+ days old Paperlite]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN MS_Prod.dbo.dbTasks	WITH (NOLOCK) 
 ON ms_fileid=fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser WITH (NOLOCK)  ON dbTasks.UpdatedBy=dbUser.usrid
WHERE 
--fileID = '5237307' 
 tskComplete=0 
AND tskActive=1
AND  tskType ='PAPERLITE'
AND MS_Prod.dbo.dbTasks.tskDue < GETDATE()

GROUP BY
client_code 
,matter_number 

) AS fileopener ON fileopener.client_code = dim_matter_header_current.client_code AND fileopener.matter_number = dim_matter_header_current.matter_number


LEFT JOIN (

SELECT 

client_code AS [client_code]
	,matter_number AS [matter_number]
	,COUNT(CASE WHEN  tskType <>'PAPERLITE' THEN 1 ELSE NULL END) AS [No. of red Other]
	,SUM(CASE WHEN  DATEDIFF(dd,tskDue, getdate()) >=5 THEN 1 ELSE 0 END)  AS [No. of red 5+ days old Other]
FROM red_dw.dbo.dim_matter_header_current  WITH (NOLOCK) 
INNER JOIN MS_Prod.dbo.dbTasks	  WITH (NOLOCK) 
 ON ms_fileid=fileID
LEFT OUTER JOIN MS_Prod.dbo.dbUser WITH (NOLOCK)  ON dbTasks.UpdatedBy=dbUser.usrid
WHERE 
--fileID = '5078349'
  tskComplete=0 
AND tskActive=1
AND  tskType <>'PAPERLITE'
AND  tskDesc NOT LIKE '%Wizard%'
AND MS_Prod.dbo.dbTasks.tskDue < GETDATE()

GROUP BY
client_code 
	,matter_number 
	--,tskDesc 


) AS NonePaperLight ON NonePaperLight.client_code = dim_matter_header_current.client_code AND NonePaperLight.matter_number = dim_matter_header_current.matter_number
	--AND fileopener.rw_num = 1

	--Get the date the outcome field was completed
 LEFT OUTER JOIN (
  SELECT 
  --cbooutcomecase AS [Outcome of Case] 
  MIN(CAST(dss_start_date AS DATE) ) AS [Date Outcome of case Completed]
  ,fileid
  FROM red_dw.dbo.ds_sh_ms_udmioutcomedamages_history
    WHERE cbooutcomecase IS NOT NULL
	AND CAST(dss_start_date AS DATE) > '1900-01-01'-- AND fileid = '5201163'
  GROUP BY
fileid
  )AS DateOfOutcome ON DateOfOutcome.fileid =dim_matter_header_current.ms_fileid 





WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'') <>'Exclude from reports'
AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
AND (red_dw.dbo.dim_matter_header_current.date_closed_case_management >= '2022-05-01' OR red_dw.dbo.dim_matter_header_current.date_closed_case_management IS NULL ) 


END
GO
