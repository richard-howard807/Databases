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
,@Level as VARCHAR(100)
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


INSERT into #FedCodeList 
exec sp_executesql @sql
	end
	
	
	IF  @Level  = 'Individual'
    BEGIN
	PRINT ('Individual')
    INSERT into #FedCodeList 
	SELECT ListValue
   -- INTO #FedCodeList
    FROM dbo.udt_TallySplit(',', @FedCode)
	
	END

/*
	Created a table to deal with the calculated columns
	for readability with the length of them and the amount of times some are used
*/	


SELECT	
	h_curr.master_client_code																										AS client_code
	, h_curr.master_matter_number																									AS matter_number
	, ISNULL(fin_sum.defence_costs_billed, 0) + ISNULL(fin_sum.wip, 0)																AS ff_revenue_billed
	, ISNULL(fin_sum.fixed_fee_amount, 0) - (ISNULL(fin_sum.defence_costs_billed, 0) + ISNULL(fin_sum.wip, 0))						AS outstanding_ff
	, ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fin_sum.wip, 0) + ISNULL(fin_sum.disbursement_balance, 0)				AS total_billed_unbilled
	, ISNULL(fin_sum.defence_costs_reserve, 0) - 
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fin_sum.wip, 0) + ISNULL(fin_sum.disbursement_balance, 0))			AS os_def_reserve
	, ISNULL(fin_sum.commercial_costs_estimate, 0) -
		(ISNULL(fact_bill_detail_summary.bill_total, 0) + ISNULL(fin_sum.wip, 0) + ISNULL(fin_sum.disbursement_balance, 0))			AS os_costs_est
INTO #finacial_calcs
FROM red_dw.dbo.dim_matter_header_current h_curr 
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary fin_sum
		ON fin_sum.client_code = h_curr.client_code AND fin_sum.matter_number = h_curr.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary fact_bill_detail_summary
		ON fact_bill_detail_summary.master_fact_key = fin_sum.master_fact_key
WHERE h_curr.date_closed_practice_management IS NULL
	AND h_curr.reporting_exclusions <> 1

CREATE INDEX INX_1 ON #finacial_calcs (matter_number) INCLUDE (client_code)



--========================================================================================================================================================================
--  Main report query
--========================================================================================================================================================================



SELECT 
	h_current.master_client_code															AS [Client Code]
	, h_current.master_matter_number														AS [Matter Number]
	, h_current.dim_matter_header_curr_key													AS [Matter Header Current Key]
	, h_current.matter_description															AS [Matter Description]
	, h_current.matter_owner_full_name														AS [Matter Owner]
	, hierarchy_hist.hierarchylevel4														AS [Team]
	, hierarchy_hist.hierarchylevel3														AS [Department]
	, hierarchy_hist.hierarchylevel2														AS [Business Line]
	, hierarchy_hist.worksforname															AS [Fee Earner Team Manager]
	, hierarchy_hist.windowsusername														AS [Windows Username]
	, worktype.work_type_name																AS [Worktype]
	, core_details.present_position															AS [Present Position] 
	, h_current.fee_arrangement																AS [Fee Arrangement]
	, CASE 
		WHEN RTRIM(h_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			ISNULL(fin_sum.fixed_fee_amount, 0)
		ELSE
			NULL
	  END																					AS [Fixed Fee Amount]
	, CASE	
		WHEN RTRIM(h_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			ISNULL(fin_calcs.ff_revenue_billed, 0)
		ELSE
			NULL
	  END																					AS [Total of Revenue Billed (net of VAT) +  WIP]
	, CASE 
		WHEN RTRIM(h_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			ISNULL(fin_calcs.outstanding_ff, 0)
		ELSE 
			NULL
	  END																					AS [Outstanding fixed fee amount]
	, CASE
		WHEN RTRIM(h_current.fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN
			CASE 
				WHEN fin_sum.fixed_fee_amount IS NULL OR fin_sum.fixed_fee_amount = 0 THEN
					'Red'
				WHEN fin_calcs.ff_revenue_billed > (fin_sum.fixed_fee_amount * 0.9) THEN
					'Red'
				WHEN fin_calcs.ff_revenue_billed > (fin_sum.fixed_fee_amount * 0.75) THEN
					'Amber'
				ELSE
					'Green'
			END	
		ELSE
			'N/A'
	  END																					AS [Fixed Fee RAG Status]
	--, ISNULL(fin_sum.defence_costs_reserve, 0)												AS [Defence Costs Reserve]
	, ISNULL(fin_sum.commercial_costs_estimate, 0)											AS [Current Costs Estimate]
	, ISNULL(fin_calcs.total_billed_unbilled, 0)											AS [Total of Total Billed + WIP + Unbilled Disbursements]
	--, CASE
	--	WHEN RTRIM(LOWER(h_current.fee_arrangement)) = 'hourly rate' THEN
	--		ISNULL(fin_calcs.os_def_reserve, 0)	
	--	ELSE 
	--		NULL
	--	END																					AS [Outstanding defence reserve amount]
	--, CASE
	--	WHEN RTRIM(LOWER(h_current.fee_arrangement)) = 'hourly rate' THEN
	--		CASE 
	--			WHEN fin_sum.defence_costs_reserve IS NULL OR fin_sum.defence_costs_reserve = 0 THEN
	--				'Red'
	--			WHEN fin_calcs.total_billed_unbilled > (fin_sum.defence_costs_reserve * 0.9) THEN
	--				'Red'
	--			WHEN fin_calcs.total_billed_unbilled > (fin_sum.defence_costs_reserve * 0.75) THEN
	--				'Amber'
	--			ELSE
	--				'Green'
	--		END
	--	ELSE	
	--		'N/A'
	--  END																					AS [Defence Costs Reserve RAG Status]
	--, ISNULL(fin_calcs.os_costs_est, 0)													AS [Outstanding costs estimate amount]
	--,CASE 
	--	WHEN fin_sum.commercial_costs_estimate IS NULL OR fin_sum.commercial_costs_estimate = 0 THEN
	--		'Red'
	--	WHEN fin_calcs.total_billed_unbilled > (fin_sum.commercial_costs_estimate * 0.9) THEN
	--		'Red'
	--	WHEN fin_calcs.total_billed_unbilled > (fin_sum.commercial_costs_estimate * 0.75) THEN
	--		'Amber'
	--	ELSE
	--		'Green'
	--  END																					AS [Current Costs Estimate RAG Status]
	, ISNULL(fin_sum.defence_costs_billed, 0)												AS [Revenue Billed (net of VAT)]
	, ISNULL(fact_bill_detail_summary.disbursements_billed_exc_vat, 0)						AS [Disbursements Billed (excl VAT)]
	, ISNULL(fact_bill_detail_summary.vat_amount, 0)										AS [VAT]
	, ISNULL(fact_bill_detail_summary.bill_total, 0)										AS [Total Billed]
	, ISNULL(fin_sum.wip, 0)																AS [WIP]
	, ISNULL(fin_sum.disbursement_balance, 0)												AS [Unbilled Disbursements]
	--, outcome.outcome_of_case																AS [Outcome]
--select *
FROM red_dw.dbo.dim_matter_header_current																							AS h_current
	INNER JOIN red_dw.dbo.fact_dimension_main																						AS fact_dim_main
		ON fact_dim_main.dim_matter_header_curr_key = h_current.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history																			AS hierarchy_hist
		ON hierarchy_hist.dim_fed_hierarchy_history_key = fact_dim_main.dim_fed_hierarchy_history_key 
			AND hierarchy_hist.dss_current_flag = 'Y' AND hierarchy_hist.activeud = 1
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype																					AS worktype
		ON worktype.dim_matter_worktype_key = h_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details																				AS core_details
		ON core_details.dim_detail_core_detail_key = fact_dim_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client																					AS detail_client
		ON detail_client.dim_detail_client_key = fact_dim_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary																					AS fin_sum
		ON fin_sum.master_fact_key = fact_dim_main.master_fact_key
	LEFT OUTER JOIN #finacial_calcs																									AS fin_calcs
		ON fin_calcs.client_code = h_current.master_client_code AND fin_calcs.matter_number = h_current.master_matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome																					AS outcome
		ON outcome.dim_detail_outcome_key = fact_dim_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary fact_bill_detail_summary
		ON fact_bill_detail_summary.master_fact_key = fact_dim_main.master_fact_key
WHERE 
	h_current.date_closed_practice_management IS NULL
	AND h_current.reporting_exclusions <> 1
	AND hierarchy_hist.hierarchylevel2 = 'Legal Ops - LTA'
	--AND RTRIM(worktype.work_type_name) <> 'Claims Handling' --this excludes outsource cases (mainly Zurich matters, under 200 non Z matters)
	AND (outcome.outcome_of_case IS NULL OR RTRIM(outcome.outcome_of_case) <> 'Exclude from reports')
	AND RTRIM(LOWER(h_current.fee_arrangement)) = 'fixed fee/fee quote/capped fee'
	--AND (h_current.present_position IS NULL OR RTRIM(h_current.present_position) NOT IN ('Final bill sent - unpaid', 'To be closed/minor balances to be clear'))
	AND hierarchy_hist.dim_fed_hierarchy_history_key IN
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
