SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Jamie Bonner>
-- Create date: <2020-08-25>
-- Description:	<#69392 Zurich Benchmarking Report against other clients>
-- =============================================

CREATE PROCEDURE [dbo].[ZurichBenchmarking]
AS
BEGIN


DECLARE @StartDate AS DATE = CAST(DATEADD(YEAR, -2, DATEADD(DAY, -DATEPART(DAY,GETDATE()) +1, GETDATE())) AS DATE)
DECLARE @EndDate AS DATE = CAST(DATEADD(DAY, -DATEPART(DAY,GETDATE()), GETDATE()) AS DATE)

DROP TABLE IF EXISTS #revenue

SET NOCOUNT ON;
--=====================================================================================================================================================================================
-- Table for Revenue
--=====================================================================================================================================================================================

SELECT 
	fact_bill_activity.client_code
	, fact_bill_activity.matter_number
	, SUM(fact_bill_activity.bill_amount) Revenue
	, CASE 
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			CASE 
				WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																	'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																	'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																	'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																	'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																	'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																	) THEN
					dim_detail_outcome.date_claim_concluded
				ELSE
					NULL
			END
		ELSE	
			dim_detail_outcome.date_costs_settled
	  END																									AS [date_claim_and_costs_finalised]
INTO #revenue
FROM red_dw.dbo.fact_bill_activity
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.client_code = fact_bill_activity.client_code 
			AND dim_matter_header_current.matter_number = fact_bill_activity.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.client_code = dim_matter_header_current.client_code 
			AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
			AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
WHERE 
	CASE 
			WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
				CASE 
					WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																		'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																		'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																		'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																		'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																		'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																		) THEN
						dim_detail_outcome.date_claim_concluded
					ELSE
						NULL
				END
			ELSE	
				dim_detail_outcome.date_costs_settled
	END BETWEEN @StartDate AND @EndDate
	AND RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes'
	AND (dim_detail_core_details.brief_description_of_injury IS NULL OR dim_detail_core_details.brief_description_of_injury NOT LIKE 'D%')
	AND dim_detail_core_details.track IN ('Fast Track', 'Multi Track')
GROUP BY 
	fact_bill_activity.client_code
	, fact_bill_activity.matter_number
	,CASE 
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			CASE 
				WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																	'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																	'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																	'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																	'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																	'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																	) THEN
					dim_detail_outcome.date_claim_concluded
				ELSE
					NULL
			END
		ELSE	
			dim_detail_outcome.date_costs_settled
	  END	

--=====================================================================================================================================================================================
--=====================================================================================================================================================================================


SELECT 
	dim_matter_header_current.master_client_code + '.' + dim_matter_header_current.master_matter_number		AS [MS Reference]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)								AS [Date Opened]							
	, CASE	
		WHEN dim_matter_header_current.client_group_name = '' THEN
			dim_matter_header_current.client_name
		ELSE
			COALESCE(dim_matter_header_current.client_group_name, dim_matter_header_current.client_name)
	  END																									AS [Client Group Name]
	, dim_client_involvement.insurerclient_reference														AS [Client Reference]
	, dim_matter_header_current.matter_description															AS [Matter Description]
	, RTRIM(dim_matter_worktype.work_type_name)																AS [Work Type]
	, RTRIM(dim_matter_worktype.work_type_group)															AS [Work Type Group]
	, RTRIM(dim_detail_finance.output_wip_fee_arrangement)													AS [Fee Arrangement]
	, dim_matter_header_current.matter_owner_full_name														AS [Handler Name]
	, dim_fed_hierarchy_history.hierarchylevel4hist															AS [Handler Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist															AS [Handler Department]
	, dim_fed_hierarchy_history.hierarchylevel2hist															AS [Handler Division]
	, dim_employee.locationidud																				AS [Handler Office]
	, RTRIM(dim_detail_core_details.proceedings_issued)														AS [Proceedings Issued]
	, RTRIM(dim_detail_core_details.referral_reason)														AS [Referral Reason]
	, dim_detail_core_details.brief_description_of_injury													AS [Injury]
	, dim_detail_core_details.track																			AS [Court Track]
	, 1																										AS [Case Count]
	, RTRIM(dim_detail_core_details.delegated)																AS [Delegated]
	, CASE	
		WHEN RTRIM(dim_detail_core_details.delegated) = 'Yes' THEN
			1
		ELSE
			0
	  END																									AS [Delegated Count]
	, dim_detail_outcome.outcome_of_case																	AS [Outcome of Case]
	, CAST(dim_detail_outcome.date_claim_concluded AS DATE)													AS [Date Claim Concluded]
	, CAST(dim_detail_outcome.date_costs_settled AS DATE)													AS [Date Costs Settled]
	, CAST(CASE 
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			CASE 
				WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																	'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																	'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																	'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																	'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																	'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																	) THEN
					dim_detail_outcome.date_claim_concluded
				ELSE
					NULL
			END
		ELSE	
			dim_detail_outcome.date_costs_settled
	  END AS DATE)																								AS [Date Claim & Costs Finalised]
	, CASE 
		WHEN (CASE 
				WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
					CASE 
						WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																			'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																			'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																			'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																			'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																			'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																			) THEN
							dim_detail_outcome.date_claim_concluded
						ELSE
							NULL
					END
				ELSE	
					dim_detail_outcome.date_costs_settled
			END) < DATEADD(MONTH, 12, @StartDate) THEN
			CAST(FORMAT(@StartDate, 'd', 'en-gb') AS NVARCHAR(10)) + ' to ' + CAST(FORMAT(DATEADD(DAY, -1, DATEADD(MONTH, 12, @StartDate)), 'd', 'en-gb') AS NVARCHAR(10))
		ELSE
			CAST(FORMAT(DATEADD(DAY, +1, DATEADD(MONTH, -12, @EndDate)), 'd', 'en-gb') AS NVARCHAR(10)) + ' to ' + CAST(FORMAT(@EndDate, 'd', 'en-gb') AS NVARCHAR(10))
	  END																									AS [Time Period Finalised]
	, CASE 
		WHEN (CASE 
				WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
					CASE 
						WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																			'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																			'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																			'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																			'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																			'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																			) THEN
							dim_detail_outcome.date_claim_concluded
						ELSE
							NULL
					END
				ELSE	
					dim_detail_outcome.date_costs_settled
			END) < DATEADD(MONTH, 12, @StartDate) THEN
			'R12 Previous'
		ELSE
			'R12'
	  END							AS [Rolling 12 Months]																								
	, DATEDIFF(DAY, dim_matter_header_current.date_opened_practice_management, CASE 
		WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
			CASE 
				WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																	'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																	'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																	'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																	'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																	'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																	) THEN
					dim_detail_outcome.date_claim_concluded
				ELSE
					NULL
			END
		ELSE	
			dim_detail_outcome.date_costs_settled
	  END)																									AS [Cycle Time]											
	, fact_finance_summary.damages_reserve																	AS [Damages Reserve]
	, ISNULL(CASE
        WHEN fact_finance_summary.[damages_paid] IS NULL
            AND fact_detail_paid_detail.[general_damages_paid] IS NULL
            AND fact_detail_paid_detail.[special_damages_paid] IS NULL
            AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
            NULL
        ELSE
			(
				CASE
					WHEN fact_finance_summary.[damages_paid] IS NULL THEN
				(ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
				+ ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
				)
				ELSE
					fact_finance_summary.[damages_paid]
				END
			)
      END, 0)																											AS [Total Damages]
	, ISNULL(COALESCE(fact_finance_summary.personal_injury_paid, fact_detail_paid_detail.general_damages_paid), 0)		AS [General Damages]
	, ISNULL(CASE
        WHEN fact_finance_summary.[damages_paid] IS NULL
            AND fact_detail_paid_detail.[general_damages_paid] IS NULL
            AND fact_detail_paid_detail.[special_damages_paid] IS NULL
            AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
            NULL
        ELSE
			(
				CASE
					WHEN fact_finance_summary.[damages_paid] IS NULL THEN
				(ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
				+ ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
				)
				ELSE
					fact_finance_summary.[damages_paid]
				END
			)
      END - COALESCE(fact_finance_summary.personal_injury_paid, fact_detail_paid_detail.general_damages_paid), 0)		AS [Special Damages]
	, ISNULL(fact_detail_paid_detail.total_tp_costs_paid, 0)															AS [Claimants Costs Paid]
	, ISNULL(#revenue.Revenue, 0)																						AS [Own Costs]
	, ISNULL(fact_finance_summary.disbursements_billed, 0)																AS [Own Disbursements]
	, ISNULL(CASE
        WHEN fact_finance_summary.[damages_paid] IS NULL
            AND fact_detail_paid_detail.[general_damages_paid] IS NULL
            AND fact_detail_paid_detail.[special_damages_paid] IS NULL
            AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
            NULL
        ELSE
			(
				CASE
					WHEN fact_finance_summary.[damages_paid] IS NULL THEN
				(ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
				+ ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
				)
				ELSE
					fact_finance_summary.[damages_paid]
				END
			)
      END, 0) + ISNULL(fact_detail_paid_detail.total_tp_costs_paid, 0) + ISNULL(#revenue.Revenue, 0) + 	ISNULL(fact_finance_summary.disbursements_billed, 0)				AS [Total Case Costs]
	, CASE
		WHEN ISNULL(CASE
						WHEN fact_finance_summary.[damages_paid] IS NULL
							AND fact_detail_paid_detail.[general_damages_paid] IS NULL
							AND fact_detail_paid_detail.[special_damages_paid] IS NULL
							AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
							NULL
						ELSE
							(
								CASE
									WHEN fact_finance_summary.[damages_paid] IS NULL THEN
								(ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
								+ ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
								)
								ELSE
									fact_finance_summary.[damages_paid]
								END
							)
					  END, 0) + fact_detail_paid_detail.total_tp_costs_paid = 0 THEN
			1
		ELSE
			0
	 END																						AS [Win Count]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
		ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
		ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN #revenue
		ON #revenue.client_code = dim_matter_header_current.client_code
			AND #revenue.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_employee
		ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
WHERE
	CASE 
			WHEN dim_detail_outcome.date_costs_settled IS NULL THEN
				CASE 
					WHEN RTRIM(dim_detail_outcome.outcome_of_case) IN (
																		'Discontinued', 'Discontinued  - pre-lit', 'Discontinued - Indemnified by third party',
																		'Discontinued - Pre-Lit', 'Discontinued - indemnified by 3rd party', 'Discontinued - indemnified by third party',
																		'Discontinued - post lit with no costs order', 'Discontinued - post-lit with costs order', 'Discontinued - post-lit with no costs order',
																		'Discontinued - pre lit no costs order', 'Discontinued - pre-lit', 'STRUCK OUT', 'Struck Out', 'Struck out', 'Won', 'Won At Trial',
																		'Won at Trial', 'Won at trial', 'discontinued - pre-lit', 'struck out', 'won at trial'
																		) THEN
						dim_detail_outcome.date_claim_concluded
					ELSE
						NULL
				END
			ELSE	
				dim_detail_outcome.date_costs_settled
	END	BETWEEN @StartDate AND @EndDate
	AND dim_matter_header_current.reporting_exclusions <> 1
	AND (dim_detail_client.zurich_instruction_type IS NULL 
			OR RTRIM(dim_detail_client.zurich_instruction_type) NOT IN ('Outsource - Coats', 'Outsource - HAVS', 'Outsource - Mesothelioma', 'Outsource - NIHL'))
	AND RTRIM(dim_matter_worktype.work_type_group) IN ('EL', 'Motor', 'PL All')
	AND RTRIM(dim_detail_core_details.proceedings_issued) = 'Yes'
	AND (dim_detail_core_details.brief_description_of_injury IS NULL OR dim_detail_core_details.brief_description_of_injury NOT LIKE 'D%')
	AND RTRIM(dim_detail_core_details.referral_reason) IN ('Dispute on Liability', 'Dispute on liability', 'Dispute on liability and quantum', 'Dispute on quantum')                                          
	AND (fact_finance_summary.damages_reserve IS NULL OR fact_finance_summary.damages_reserve <= 100000)
	AND ISNULL(CASE
					WHEN fact_finance_summary.[damages_paid] IS NULL
						AND fact_detail_paid_detail.[general_damages_paid] IS NULL
						AND fact_detail_paid_detail.[special_damages_paid] IS NULL
						AND fact_detail_paid_detail.[cru_paid] IS NULL THEN
						NULL
					ELSE
						(
							CASE
								WHEN fact_finance_summary.[damages_paid] IS NULL THEN
							(ISNULL(fact_detail_paid_detail.[general_damages_paid], 0)
							+ ISNULL(fact_detail_paid_detail.[special_damages_paid], 0) + ISNULL(fact_detail_paid_detail.[cru_paid], 0)
							)
							ELSE
								fact_finance_summary.[damages_paid]
							END
						)
				 END, 0) <= 100000
	AND dim_detail_core_details.track IN ('Fast Track', 'Multi Track')
	AND ISNULL(dim_detail_core_details.injury_type_code, '') <> 'A00                                                         '

END


GO
