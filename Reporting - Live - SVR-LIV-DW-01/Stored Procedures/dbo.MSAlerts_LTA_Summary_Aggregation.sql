SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-03-05
-- Description:	MS Alerts Report, 45153
-- =============================================
CREATE PROCEDURE [dbo].[MSAlerts_LTA_Summary_Aggregation]

(
@FedCode AS VARCHAR(MAX)
,@Level AS VARCHAR(100)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- For testing
--DECLARE @FedCode AS VARCHAR(MAX) = '127181,138212,137683,135888,127686,127626,127498,138361,138079,136747,135311,130451,130430,130414,138467,137680,135873,128142,128096,128035,128012,135262,129988,129933,129894,129858,127160,135837,130280,129702,127565,127510,128042,136381,132563,127198,137461,127408,127156,134559,129183,129150,127138,135110,129715,129535,129113,127154,134521,131084,131069,131058,131032,135058,128175,127973,127150,135561,127683,127248,127174,134969,133096,132812,132783,138419,134952,132840,132280,132075,127403,127134,132208,127643,127133,119660,129513,127144,138517,137848,134879,132277,130939,134832,128371,127807,127143'		
--		, @Level AS VARCHAR(10) = 'Individual'

DROP TABLE IF EXISTS #finacial_calcs
DROP TABLE IF EXISTS #lta_report
DROP TABLE IF EXISTS #FedCodeList

CREATE TABLE #FedCodeList  (
ListValue  NVARCHAR(MAX)
)
IF @Level  <> 'Individual'
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


INSERT INTO #FedCodeList 
EXEC sp_executesql @sql
	END
	
	
	IF  @Level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT INTO #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END
	
--=========================================================================================================================================================================
--	Created a table to deal with the calculated columns for readability with the length of them and the amount of times some are used
--=========================================================================================================================================================================	

SELECT	
	dim_matter_header_current.master_client_code																										AS client_code
	, dim_matter_header_current.master_matter_number																									AS matter_number

	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.wip, 0)														AS revenue_billed_plus_wip
	, ISNULL(fact_finance_summary.fixed_fee_amount, 0) - (ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.wip, 0))	AS outstanding_ff
	, ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0)		AS total_billed_unbilled
	, ISNULL(fact_finance_summary.defence_costs_reserve, 0) - 
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0))	AS os_def_reserve
	, ISNULL(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate), 0) -
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0))	AS os_costs_est
	, ISNULL(fact_bill_detail_summary.disbursements_billed_exc_vat, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0)							AS total_billed_unbilled_disb
	, ISNULL(fact_detail_reserve_detail.disbursements_estimate_net_of_vat, 0) - 
		(ISNULL(fact_bill_detail_summary.disbursements_billed_exc_vat, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0))						AS os_disbursements
	, ISNULL(fact_detail_reserve_detail.revenue_estimate_net_of_vat, 0) - 
		(ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.wip, 0))													AS os_revenue_estimate
INTO #finacial_calcs
FROM red_dw.dbo.dim_matter_header_current 
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary 
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary fact_bill_detail_summary
		ON fact_bill_detail_summary.master_fact_key = fact_finance_summary.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.client_code = dim_matter_header_current.client_code
			AND fact_detail_reserve_detail.matter_number = dim_matter_header_current.matter_number
WHERE dim_matter_header_current.date_closed_practice_management IS NULL
	AND dim_matter_header_current.reporting_exclusions <> 1

CREATE INDEX INX_1 ON #finacial_calcs (matter_number) INCLUDE (client_code)



--========================================================================================================================================================================
--  LTA report temp table
--========================================================================================================================================================================


SELECT 
	dim_matter_header_current.master_client_code															AS [Client Code]
	, dim_matter_header_current.master_matter_number														AS [Matter Number]
	, dim_matter_header_current.dim_matter_header_curr_key													AS [Matter Header Current Key]
	, dim_matter_header_current.matter_description															AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name														AS [Matter Owner]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
		, CASE WHEN dim_matter_header_current.client_group_name IS NULL THEN dim_matter_header_current.client_name ELSE dim_matter_header_current.client_group_name END AS client
	, dim_fed_hierarchy_history.hierarchylevel4														AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3														AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel2														AS [Business Line]
	, dim_fed_hierarchy_history.worksforname															AS [Fee Earner Team Manager]
	, dim_fed_hierarchy_history.windowsusername														AS [Windows Username]
	, dim_matter_worktype.work_type_name																AS [Worktype]
	, dim_detail_core_details.present_position															AS [Present Position] 
	, dim_matter_header_current.fee_arrangement																AS [Fee Arrangement]
	, CASE 
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			1
		ELSE
			0
	  END							AS [ff_case_count]
	, CASE	
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN
			1
		ELSE
			0
	  END										AS [hr_case_count]
	, CASE 
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			fact_finance_summary.fixed_fee_amount
		ELSE
			NULL
	  END																					AS [Fixed Fee Amount]
	, CASE	
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			ISNULL(#finacial_calcs.revenue_billed_plus_wip, 0)
		ELSE
			NULL
	  END																					AS [Total of Revenue Billed (net of VAT) +  WIP]
	, CASE 
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			ISNULL(#finacial_calcs.outstanding_ff, 0)
		ELSE 
			NULL
	  END																					AS [Outstanding fixed fee amount]
	, CASE
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			CASE 
				WHEN fact_finance_summary.fixed_fee_amount = 0 THEN
					'Red'
				WHEN #finacial_calcs.revenue_billed_plus_wip > (fact_finance_summary.fixed_fee_amount * 0.9) THEN
					'Red'
				WHEN #finacial_calcs.revenue_billed_plus_wip > (fact_finance_summary.fixed_fee_amount * 0.75) THEN
					'Orange'
				WHEN fact_finance_summary.fixed_fee_amount IS NULL THEN 'nocolour'
				ELSE
					'Green'
			END	
		ELSE
			'Transparent'
	  END																					AS [Fixed Fee RAG Status]
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' 
		AND dim_matter_header_current.date_opened_practice_management < DATEADD(DAY, -14, CAST(GETDATE() AS DATE)) THEN
			CASE 
				WHEN fact_finance_summary.revenue_estimate_net_of_vat = 0 OR fact_finance_summary.revenue_estimate_net_of_vat IS NULL THEN
					'Red'
				WHEN #finacial_calcs.revenue_billed_plus_wip > (fact_finance_summary.revenue_estimate_net_of_vat * 0.9) THEN
					'Red'
				WHEN #finacial_calcs.revenue_billed_plus_wip > (fact_finance_summary.revenue_estimate_net_of_vat * 0.75) THEN
					'Orange'
				ELSE
					'Green'
			END	
		ELSE
			'Transparent'
	  END																					AS [Revenue Estimate RAG Status]
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate'
		AND	dim_matter_header_current.date_opened_practice_management > '2021-01-28'
		AND dim_matter_header_current.date_opened_practice_management < DATEADD(DAY, -14, CAST(GETDATE() AS DATE)) THEN
			CASE 
				WHEN fact_finance_summary.disbursements_estimate_net_of_vat = 0 OR fact_finance_summary.disbursements_estimate_net_of_vat IS NULL THEN
					'Red'
				WHEN #finacial_calcs.total_billed_unbilled_disb > (fact_finance_summary.disbursements_estimate_net_of_vat * 0.9) THEN
					'Red'
				WHEN #finacial_calcs.total_billed_unbilled_disb > (fact_finance_summary.disbursements_estimate_net_of_vat * 0.75) THEN
					'Orange'
				ELSE
					'Green'
			END	
		ELSE
			'Transparent'
	  END																					AS [Disbursement RAG Status]
	, ISNULL(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate), 0)							AS [Current Costs Estimate]
	, ISNULL(#finacial_calcs.total_billed_unbilled, 0)											AS [Total of Total Billed + WIP + Unbilled Disbursements]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)												AS [Revenue Billed (net of VAT)]
	, ISNULL(fact_bill_detail_summary.disbursements_billed_exc_vat, 0)						AS [Disbursements Billed (excl VAT)]
	, ISNULL(fact_bill_detail_summary.vat_amount, 0)										AS [VAT]
	, ISNULL(fact_bill_detail_summary.bill_total, 0)										AS [Total Billed]
	, ISNULL(fact_finance_summary.wip, 0)																AS [WIP]
	, ISNULL(fact_finance_summary.disbursement_balance, 0)												AS [Unbilled Disbursements]
	, CASE
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee'
		AND ISNULL(fact_finance_summary.fixed_fee_amount, 0) = 0 THEN 
			1
		ELSE 
			0
	   END																							AS [Missing FF Amount Reserve]
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' 
		AND dim_matter_header_current.date_opened_practice_management < DATEADD(DAY, -14, CAST(GETDATE() AS DATE))
		AND (fact_finance_summary.revenue_estimate_net_of_vat IS NULL OR fact_finance_summary.revenue_estimate_net_of_vat = 0) THEN 
			1
		ELSE 
			0
	   END																								AS [Missing Revenue Estimate]
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' 
		AND (ISNULL(fact_finance_summary.disbursements_estimate_net_of_vat, 0) = 0) 
		AND	dim_matter_header_current.date_opened_practice_management > '2021-01-28'
		AND dim_matter_header_current.date_opened_practice_management < DATEADD(DAY, -14, CAST(GETDATE() AS DATE)) THEN
			1
		ELSE 
			0
	   END																								AS [Missing Disbursement Estimate]
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN 
			#finacial_calcs.total_billed_unbilled_disb		
		ELSE
			NULL 
	  END						AS [Total of Billed disbs and Unbilled disbs]
	, fact_finance_summary.revenue_estimate_net_of_vat
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN 
			#finacial_calcs.os_revenue_estimate			
		ELSE
			NULL 
	  END										AS [Outstanding Revenue Estimate]
	, fact_finance_summary.disbursements_estimate_net_of_vat
	, CASE
		WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN 
			#finacial_calcs.os_disbursements				
		ELSE
			NULL 
	  END										AS [Outstanding Disbursements]
	--, dim_detail_outcome.outcome_of_case																AS [Outcome]
INTO #lta_report
--select *
FROM red_dw.dbo.dim_matter_header_current																							
	INNER JOIN red_dw.dbo.fact_dimension_main																						
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history																			
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key 
			AND dim_fed_hierarchy_history.dss_current_flag = 'Y' AND dim_fed_hierarchy_history.activeud = 1
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype																					
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details																				
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client																					
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary		
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN #finacial_calcs	
		ON #finacial_calcs.client_code = dim_matter_header_current.master_client_code AND #finacial_calcs.matter_number = dim_matter_header_current.master_matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome																					
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary fact_bill_detail_summary
		ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_property
		ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
WHERE 
	dim_matter_header_current.date_closed_practice_management IS NULL
	AND dim_matter_header_current.reporting_exclusions <> 1
	AND dim_fed_hierarchy_history.hierarchylevel2 = 'Legal Ops - LTA'
	--AND RTRIM(worktype.work_type_name) <> 'Claims Handling' --this excludes outsource cases (mainly Zurich matters, under 200 non Z matters)
	AND (dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(dim_detail_outcome.outcome_of_case) <> 'Exclude from reports')
	AND RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) IN ('fixed fee/fee quote/capped fee', 'hourly rate')
	--AND (h_current.present_position IS NULL OR RTRIM(h_current.present_position) NOT IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear'))
	AND (RTRIM(dim_matter_worktype.work_type_name) NOT IN (
													'Property View', 'Debt Recovery', 'Employment Advice Line', 'Holidays (including holiday pay)'
													, 'Early Conciliation', 'Claims Handling', 'Plot Sales'
												  )
	--OR (RTRIM(dim_matter_worktype.work_type_name) = 'Plot Sales' AND RTRIM(dim_detail_property.commercial_bl_status) <> 'Pending')		--removed until Mandy's team can set up on MS
		)
	--AND dim_fed_hierarchy_history.name = 'Edwina Farrell'
	AND red_dw.dbo.dim_fed_hierarchy_history.dim_fed_hierarchy_history_key IN
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
--=================================================================================================================================================================================
-- Aggregation of lta temp table
--=================================================================================================================================================================================

SELECT 
	--#lta_report.[Matter Header Current Key]												AS [Matter Header Current Key]
	#lta_report.[Business Line]														AS [Business Line]
	, #lta_report.Department															AS [Department]
	, #lta_report.Team																	AS [Team]
	, #lta_report.[Matter Owner]														AS [Matter Owner]
	, dim_fed_hierarchy_history.windowsusername
	, SUM(#lta_report.ff_case_count)													AS [Number of FF Cases]
	, SUM(#lta_report.hr_case_count)													AS [Number of HR Cases]
	, SUM(#lta_report.[Missing FF Amount Reserve])							AS [Missing FF Amount Reserve]
	, SUM(CASE 
		WHEN ISNULL(#lta_report.[Missing Revenue Estimate], 0) = 1 OR ISNULL(#lta_report.[Missing Disbursement Estimate], 0) = 1 THEN
			1 
		ELSE
			0
		END	
		)												AS [Number of Missing Revenue and Disb Estimate]	
	, SUM(CASE
			WHEN #lta_report.[Fixed Fee RAG Status] = 'Orange' THEN 
				1
			WHEN #lta_report.[Fixed Fee RAG Status] = 'Red' THEN 
				1
			ELSE
				0
		  END)																			AS [Total FF Alerts]
	,SUM(CASE
			WHEN #lta_report.[Fixed Fee RAG Status] = 'Orange' THEN 
				1
			ELSE
				0
		 END)																			AS [Fixed Fee Amber]
	,SUM(CASE
			WHEN #lta_report.[Fixed Fee RAG Status] = 'Red' THEN 
				1
			ELSE
				0
		 END)																			AS [Fixed Fee Red]	  
	, SUM(CASE	
			WHEN #lta_report.[Revenue Estimate RAG Status] = 'Red' OR #lta_report.[Revenue Estimate RAG Status] = 'Orange' THEN
				1
			ELSE
				0
		  END			
		) +
	  SUM(CASE 
			WHEN #lta_report.[Disbursement RAG Status] = 'Red' OR #lta_report.[Disbursement RAG Status] = 'Orange' THEN
				1
			ELSE 
				0
		  END
		 )					AS [Total HR Alerts]
	, SUM(CASE	
			WHEN #lta_report.[Revenue Estimate RAG Status] = 'Red' THEN
				1
			ELSE
				0
		  END 
		)			AS [Revenue Estimate Red]
	, SUM(CASE	
			WHEN #lta_report.[Revenue Estimate RAG Status] = 'Orange' THEN
				1
			ELSE
				0
		  END	
		)			AS [Revenue Estimate Amber]
	, SUM(CASE		
			WHEN #lta_report.[Disbursement RAG Status] = 'Red' THEN
				1
			ELSE
				0
		  END 
		)			AS [Disbursement Estimate Red]
	, SUM(CASE
			WHEN #lta_report.[Disbursement RAG Status] = 'Orange' THEN
				1
			ELSE
				0
		  END	
		)			AS [Disbursement Estimate Amber]
FROM #lta_report
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = #lta_report.[Matter Header Current Key]
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
GROUP BY 
	--#lta_report.[Matter Header Current Key]
	#lta_report.[Business Line]	
	, #lta_report.Department		
	, #lta_report.Team			
	, #lta_report.[Matter Owner]
	, dim_fed_hierarchy_history.windowsusername
ORDER BY 
	#lta_report.[Business Line]
	, #lta_report.Department
	, #lta_report.Team
	, #lta_report.[Matter Owner]

END
		




GO
