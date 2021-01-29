SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-02-03
-- Description:	MS Alerts Report, 45153
-- =============================================
CREATE PROCEDURE [dbo].[MSAlerts_LTA]

(
@FedCode AS VARCHAR(MAX)
,@Level AS VARCHAR(100)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


DROP TABLE IF EXISTS #finacial_calcs
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

/*
	Created a table to deal with the calculated columns
	for readability with the length of them and the amount of times some are used
*/	


SELECT	
	dim_matter_header_current.master_client_code																										AS client_code
	, dim_matter_header_current.master_matter_number																									AS matter_number

	, ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.wip, 0)														AS ff_revenue_billed
	, ISNULL(fact_finance_summary.fixed_fee_amount, 0) - (ISNULL(fact_finance_summary.defence_costs_billed, 0) + ISNULL(fact_finance_summary.wip, 0))	AS outstanding_ff
	, ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0)		AS total_billed_unbilled
	, ISNULL(fact_finance_summary.defence_costs_reserve, 0) - 
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0))	AS os_def_reserve
	, ISNULL(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate), 0) -
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.disbursement_balance, 0))	AS os_costs_est
INTO #finacial_calcs
FROM red_dw.dbo.dim_matter_header_current 
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary 
		ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary fact_bill_detail_summary
		ON fact_bill_detail_summary.master_fact_key = fact_finance_summary.master_fact_key
WHERE dim_matter_header_current.date_closed_practice_management IS NULL
	AND dim_matter_header_current.reporting_exclusions <> 1

CREATE INDEX INX_1 ON #finacial_calcs (matter_number) INCLUDE (client_code)



--========================================================================================================================================================================
--  Main report query
--========================================================================================================================================================================



SELECT 
	dim_matter_header_current.master_client_code															AS [Client Code]
	, dim_matter_header_current.master_matter_number														AS [Matter Number]
	, dim_matter_header_current.dim_matter_header_curr_key													AS [Matter Header Current Key]
	, dim_matter_header_current.matter_description															AS [Matter Description]
	, dim_matter_header_current.matter_owner_full_name														AS [Matter Owner]
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
			fact_finance_summary.fixed_fee_amount
		ELSE
			NULL
	  END																					AS [Fixed Fee Amount]
	, CASE	
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			ISNULL(#finacial_calcs.ff_revenue_billed, 0)
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
				WHEN #finacial_calcs.ff_revenue_billed > (fact_finance_summary.fixed_fee_amount * 0.9) THEN
					'Red'
				WHEN #finacial_calcs.ff_revenue_billed > (fact_finance_summary.fixed_fee_amount * 0.75) THEN
					'Amber'
				WHEN 	fact_finance_summary.fixed_fee_amount IS NULL THEN 'nocolour'
				ELSE
					'Green'
			END	
		ELSE
			'N/A'
	  END																					AS [Fixed Fee RAG Status]
	--, ISNULL(fact_finance_summary.defence_costs_reserve, 0)												AS [Defence Costs Reserve]
	, ISNULL(ISNULL(fact_finance_summary.revenue_and_disb_estimate_net_of_vat,fact_finance_summary.commercial_costs_estimate), 0)											AS [Current Costs Estimate]
	, ISNULL(#finacial_calcs.total_billed_unbilled, 0)											AS [Total of Total Billed + WIP + Unbilled Disbursements]
	--, CASE
	--	WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN
	--		ISNULL(#finacial_calcs.os_def_reserve, 0)	
	--	ELSE 
	--		NULL
	--	END																					AS [Outstanding defence reserve amount]
	--, CASE
	--	WHEN RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'hourly rate' THEN
	--		CASE 
	--			WHEN fact_finance_summary.defence_costs_reserve IS NULL OR fact_finance_summary.defence_costs_reserve = 0 THEN
	--				'Red'
	--			WHEN #finacial_calcs.total_billed_unbilled > (fact_finance_summary.defence_costs_reserve * 0.9) THEN
	--				'Red'
	--			WHEN #finacial_calcs.total_billed_unbilled > (fact_finance_summary.defence_costs_reserve * 0.75) THEN
	--				'Amber'
	--			ELSE
	--				'Green'
	--		END
	--	ELSE	
	--		'N/A'
	--  END																					AS [Defence Costs Reserve RAG Status]
	--, ISNULL(#finacial_calcs.os_costs_est, 0)													AS [Outstanding costs estimate amount]
	--,CASE 
	--	WHEN fact_finance_summary.commercial_costs_estimate IS NULL OR fact_finance_summary.commercial_costs_estimate = 0 THEN
	--		'Red'
	--	WHEN #finacial_calcs.total_billed_unbilled > (fact_finance_summary.commercial_costs_estimate * 0.9) THEN
	--		'Red'
	--	WHEN #finacial_calcs.total_billed_unbilled > (fact_finance_summary.commercial_costs_estimate * 0.75) THEN
	--		'Amber'
	--	ELSE
	--		'Green'
	--  END																					AS [Current Costs Estimate RAG Status]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)												AS [Revenue Billed (net of VAT)]
	, ISNULL(fact_bill_detail_summary.disbursements_billed_exc_vat, 0)						AS [Disbursements Billed (excl VAT)]
	, ISNULL(fact_bill_detail_summary.vat_amount, 0)										AS [VAT]
	, ISNULL(fact_bill_detail_summary.bill_total, 0)										AS [Total Billed]
	, ISNULL(fact_finance_summary.wip, 0)																AS [WIP]
	, ISNULL(fact_finance_summary.disbursement_balance, 0)												AS [Unbilled Disbursements]
	, CASE
		WHEN RTRIM(dim_matter_header_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			CASE 
				WHEN (fact_finance_summary.fixed_fee_amount IS NULL OR fact_finance_summary.fixed_fee_amount = 0) THEN 
					'FF amount missing'
				ELSE 
					'FF amount complete'
			END 
		ELSE 
			CASE 
				WHEN (fact_finance_summary.defence_costs_reserve IS NULL OR fact_finance_summary.defence_costs_reserve = 0) THEN 
					'Defence costs reserve missing'
				ELSE
					'Defence costs reserve complete'
			END 
	   END																								AS [Missing FF or Defence Costs Reserve]
	--, dim_detail_outcome.outcome_of_case																AS [Outcome]
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
	AND RTRIM(LOWER(dim_matter_header_current.fee_arrangement)) = 'fixed fee/fee quote/capped fee'
	--AND (h_current.present_position IS NULL OR RTRIM(h_current.present_position) NOT IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear'))
	AND (RTRIM(dim_matter_worktype.work_type_name) NOT IN (
													'Property View', 'Debt Recovery', 'Employment Advice Line', 'Holidays (including holiday pay)'
													, 'Early Conciliation', 'Claims Handling', 'Plot Sales'
												  )
	--OR (RTRIM(dim_matter_worktype.work_type_name) = 'Plot Sales' AND RTRIM(dim_detail_property.commercial_bl_status) <> 'Pending')		--removed until Mandy's team can set up on MS
		)
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
ORDER BY
	[Business Line]
	, Department
	, Team
	, [Matter Owner]

END
		
GO
