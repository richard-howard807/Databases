SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 21/02/2018
-- Description:	Webby Ticket 295245 (Based on the Fraud Indicator Score report)
-- =============================================
-- ES 2020-03-12 42547 Amended the logic to look at the FIC Process task rather than
--						filter based on the FIC score which is based on case details
-- ES 2020-06-09 58589 Removed fixed fee from total calc
--==============================================
CREATE  PROCEDURE [fraud].[fic_results_report_test]

(
    @FedCode AS VARCHAR(MAX),
    --@Month AS VARCHAR(100)
    @Level AS VARCHAR(100)
	,@Status AS VARCHAR(MAX)
)
	
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED




	IF OBJECT_ID('tempdb..#FICProcess') IS NOT NULL   DROP TABLE #FICProcess
	DROP TABLE  IF EXISTS #FedCodeList
    	CREATE TABLE #FedCodeList  (
ListValue  NVARCHAR(MAX)
)

IF OBJECT_ID('tempdb..#Status') IS NOT NULL   DROP TABLE #Status

IF @level  <> 'Individual'
	BEGIN
	PRINT ('not Individual')
DECLARE @sql NVARCHAR(MAX)

SET @sql = '
use red_dw;
DECLARE @nDate AS DATE = GETDATE()

SELECT DISTINCT
dim_fed_hierarchy_history_key
FROM red_Dw.dbo.dim_fed_hierarchy_history 
WHERE dim_fed_hierarchy_history_key IN ('+@FedCode+')'

INSERT into #FedCodeList 
exec sp_executesql @sql
	end
	
	
	IF  @level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT into #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END

	



	--SELECT ListValue  INTO #Department FROM 	dbo.udt_TallySplit(',', @Department)
	--SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)
	--SELECT ListValue  INTO #Handler FROM 	dbo.udt_TallySplit(',', @Handler)
	--SELECT ListValue  INTO #ClientGroupName FROM 	dbo.udt_TallySplit(',', @ClientGroupName)


	SELECT fileID, tskDesc, tskDue, tskCompleted 
	INTO #FICProcess
	FROM MS_Prod.dbo.dbTasks
	WHERE (tskDesc LIKE 'FIC Process'
	OR tskDesc LIKE '%ADM: Complete fraud indicator checklist%')
	AND tskActive=1

	SELECT ListValue  INTO #Status FROM 	dbo.udt_TallySplit(',', @Status)

	
	 SELECT 
		 [Client Code] = dim_matter_header_current.client_code
		 ,[Matter Number]=dim_matter_header_current.matter_number
		 ,[Date Opened] = dim_matter_header_current.date_opened_case_management
		 ,[Matter Description]=dim_matter_header_current.matter_description
		 ,dim_matter_header_current.matter_owner_full_name
		 ,dim_fed_hierarchy_history.hierarchylevel2hist AS Area 
		 ,dim_fed_hierarchy_history.hierarchylevel3hist AS Department
		 ,dim_fed_hierarchy_history.hierarchylevel4hist AS Team
		 ,dim_detail_core_details.suspicion_of_fraud
		 ,referral_reason AS [Referral Reason]
		 ,CASE WHEN date_closed_case_management IS NULL THEN DATEDIFF(DAY, date_opened_case_management,GETDATE())
					ELSE DATEDIFF(DAY,date_opened_case_management, date_closed_case_management) END AS [Days Opened]
					,dim_fed_hierarchy_history.name [FeeEarnerName]

		 ,fic =	 total_points_calc 

		 ,dim_detail_fraud.el_points AS FRA130
		 ,dim_detail_fraud.pl_points AS FRA131
		 ,dim_detail_fraud.motor_freight_liveried_points AS FRA133
		 ,dim_detail_fraud.motor_personal_line_insurance_points AS FRA134
		 ,dim_detail_fraud.disease_points AS FRA135
		 ,dim_detail_fraud.rmg_el_points AS FRA137
		 ,dim_detail_fraud.rmg_pl_points AS FRA129
		 ,fic_fraud_transfer_date [fic_review_date]
		 ,fic_fraud_transfer [fic_revew]
		 ,date_received 
		 ,date_intel_report_sent
		 ,FICProcess.tskDue
		 ,FICProcess.tskCompleted
		 ,FICProcess.tskDesc
		 ,ms_fileid
		 ,work_type_group
		 ,CASE WHEN (client_group_name IS NULL OR client_group_name='') THEN  client_name ELSE client_group_name END AS [Client Group Name]
		 		,dim_detail_core_details.[fixed_fee] AS [Fixed Fee]
		,ISNULL(fact_finance_summary.[fixed_fee_amount], 0) AS [Fixed Fee Amount]
		,RTRIM(ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0)) AS [Fee Arrangement]
		,fact_finance_summary.defence_costs_reserve AS [Defence Costs Reserve]
		,CASE WHEN FICProcess.tskDue IS NULL AND dim_detail_fraud.total_points_calc IS NULL THEN 1 ELSE 0 END AS [CountNoprocessdue]
	  
		,CASE WHEN FICProcess.tskDue IS NOT NULL AND FICProcess.tskCompleted IS NULL THEN 1 ELSE 0 END AS [countcompleteddate]
		,CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc IS NULL THEN 1 ELSE 0 END AS [countblankscore]
		,CASE WHEN  dim_detail_fraud.total_points_calc < 15 THEN 1 ELSE 0 END AS [countless15]
		,CASE WHEN  dim_detail_fraud.total_points_calc >= 15 THEN 1 ELSE 0 END AS [countmore15]
	
		, CASE WHEN (dim_matter_header_current.fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee ' AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0  ) OR (ISNULL(fact_finance_summary.defence_costs_reserve,0) = 0 ) THEN 1 ELSE 0
		END AS [countfixeddefence]
		, CASE WHEN FICProcess.tskCompleted IS NULL AND dim_detail_fraud.total_points_calc IS NOT NULL THEN 1 ELSE 0 END AS [countscorenotcompleted]
----------------------------
 	,(CASE WHEN FICProcess.tskDue IS NULL THEN 1 ELSE 0 END +
	CASE WHEN FICProcess.tskDue IS NOT NULL AND FICProcess.tskCompleted IS NULL THEN 1 ELSE 0 END + 
		CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc IS NULL THEN 1 ELSE 0 END +
		CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc < 15 THEN 1 ELSE 0 END +
		CASE WHEN FICProcess.tskCompleted IS NOT NULL AND dim_detail_fraud.total_points_calc > 15 THEN 1 ELSE 0 END) -
		CASE WHEN FICProcess.tskCompleted IS NULL AND dim_detail_fraud.total_points_calc IS NOT NULL THEN 1 ELSE 0 END
		--CASE WHEN (dim_matter_header_current.fee_arrangement = 'Fixed Fee/Fee Quote/Capped Fee ' AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0  ) OR (ISNULL(fact_finance_summary.defence_costs_reserve,0) = 0 ) THEN 1 ELSE 0
		--END 
		AS TOTAL 
	,  CASE WHEN 
		--dim_matter_header_current.date_closed_case_management IS NULL
	   dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
		--AND dim_detail_outcome.date_claim_concluded IS NULL
		AND LOWER(referral_reason) LIKE '%dispute%'
		AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease') 
		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR total_points_calc IS NOT null)
		THEN 1 ELSE 0 END AS [Number of Matters]
		, CASE WHEN dim_detail_fraud.total_points_calc IS NOT NULL THEN 1 ELSE 0 END AS [countscore]
		, CASE WHEN date_claim_concluded IS NULL THEN 'Open' else 'Closed' END AS [Status]

	FROM 
	red_dw.dbo.fact_dimension_main
	LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key=fact_dimension_main.dim_matter_header_curr_key  
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.fed_code =dim_matter_header_current.fee_earner_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'        
	AND GETDATE() BETWEEN dss_start_date AND dss_end_date 
	AND dim_fed_hierarchy_history.hierarchylevel2hist='Legal Ops - Claims'
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome ON fact_dimension_main.dim_detail_outcome_key = dim_detail_outcome.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw..dim_detail_fraud ON dim_detail_fraud.dim_detail_fraud_key = fact_dimension_main.dim_detail_fraud_key
	LEFT OUTER JOIN red_dw..dim_detail_core_details ON  dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key

	--LEFT OUTER JOIN (SELECT fileID, tskDesc, tskCompleted 
	--			FROM MS_Prod.dbo.dbTasks
	--			WHERE tskDesc LIKE 'FIC Process'
	--			AND tskCompleted IS NOT NULL 
	--			AND tskActive=1) AS FICProcess ON FICProcess.fileID=ms_fileid


	--INNER JOIN #Department AS Department ON Department.ListValue = hierarchylevel3hist 
	--INNER JOIN #Team AS Team ON Team.ListValue = hierarchylevel4hist 
	--INNER JOIN #Handler AS Handler ON Handler.ListValue = matter_owner_full_name 
	--INNER JOIN #ClientGroupName AS ClientGroupName ON ClientGroupName.ListValue = CASE WHEN (client_group_name IS NULL OR client_group_name='') THEN  client_name ELSE client_group_name END 
	
	LEFT OUTER JOIN #FICProcess FICProcess ON FICProcess.fileID = ms_fileid

	INNER JOIN #Status ON #Status.ListValue = CASE WHEN date_claim_concluded IS NULL THEN 'Open' ELSE 'Closed' END

	WHERE 
	--dim_matter_header_current.date_closed_case_management IS NULL
		 dim_matter_header_current.reporting_exclusions=0
		AND dim_matter_header_current.matter_number<>'ML'
		AND dim_matter_header_current.date_opened_case_management >= '2019-01-01'
	--AND dim_detail_outcome.date_claim_concluded IS NULL

		AND LOWER(referral_reason) LIKE '%dispute%'
	AND suspicion_of_fraud ='No'
		AND work_type_group IN ('EL','PL All','Motor','Disease')

		AND (DATEDIFF(DAY,date_opened_case_management, GETDATE())>=14 OR total_points_calc IS NOT null)

 AND dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
              (
                  SELECT (CASE
                              WHEN @Level = 'Firm' THEN
                                  dim_fed_hierarchy_history_key
                              ELSE
                                  0
                          END
                         )
                  FROM red_dw.dbo.dim_fed_hierarchy_history
                  UNION
                  SELECT  (CASE
                              WHEN @Level IN ( 'Individual' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
                  UNION
                  SELECT (CASE
                              WHEN @Level IN ( 'Area Managed' ) THEN
                                  ListValue
                              ELSE
                                  0
                          END
                         )
                  FROM #FedCodeList
              )

			  
END;




--SELECT fileID, tskDesc, tskCompleted,*
--				FROM MS_Prod.dbo.dbTasks
--				WHERE tskDesc LIKE 'FIC Process'
--				AND tskActive=1
GO
