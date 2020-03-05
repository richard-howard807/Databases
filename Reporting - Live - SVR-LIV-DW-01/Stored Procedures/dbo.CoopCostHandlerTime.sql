SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Jamie Bonner
Created Date:		2020-02-17
Description:		Cost handlers WIP on open Co-op C1001 matters
Ticket:				47206
Current Version:	Initial Create
====================================================
====================================================
*/

CREATE PROCEDURE [dbo].[CoopCostHandlerTime]
AS
	BEGIN
	
	SET NOCOUNT ON
	

--====================================================================================================================================================================================
--	Temp table created to access cost handlers WIP on C1001 matters
--====================================================================================================================================================================================

	DROP TABLE IF EXISTS #costhandlers
	
	SELECT 
		cost_time.master_fact_key
		, cost_time.dim_matter_header_current_key
		, ISNULL(SUM(cost_time.beth_price), 0)												AS [beth_price_wip]
		, ISNULL(SUM(cost_time.brian_collins), 0)											AS [brian_collins_wip]
		, ISNULL(SUM(cost_time.chloe_higham), 0)											AS [chloe_higham_wip]
		, ISNULL(SUM(cost_time.chris_simpson), 0)											AS [chris_simpson_wip]
		, ISNULL(SUM(cost_time.david_bailey_vella), 0)										AS [david_bailey_vella_wip]
		, ISNULL(SUM(cost_time.emma_jeffries), 0)											AS [emma_jeffries_wip]
		, ISNULL(SUM(cost_time.gwen_mensah), 0)												AS [gwen_mensah_wip]
		, ISNULL(SUM(cost_time.iain_stark), 0)												AS [iain_stark_wip]
		, ISNULL(SUM(cost_time.jason_wilkins), 0)											AS [jason_wilkins_wip]
		, ISNULL(SUM(cost_time.john_pennington_jones), 0)									AS [john_pennington_jones_wip]
		, ISNULL(SUM(cost_time.katie_mcmullin), 0)											AS [katie_mcmullin_wip]
		, ISNULL(SUM(cost_time.lewis_fearon), 0)											AS [lewis_fearon_wip]
		, ISNULL(SUM(cost_time.louise_hawkfield), 0)										AS [louise_hawkfield_wip]
		, ISNULL(SUM(cost_time.mark_moriarty), 0)											AS [mark_moriarty_wip]
		, ISNULL(SUM(cost_time.megan_jackson), 0)											AS [megan_jackson_wip]
		, ISNULL(SUM(cost_time.michael_bennett), 0)											AS [michael_bennett_wip]
		, ISNULL(SUM(cost_time.michaela_cheshire), 0)										AS [michaela_cheshire_wip]
		, ISNULL(SUM(cost_time.sarah_evans), 0)												AS [sarah_evans_wip]
		, ISNULL(SUM(cost_time.stephanie_mcbride), 0)										AS [stephanie_mcbride_wip]
		, ISNULL(SUM(cost_time.stuart_naylor), 0)											AS [stuart_naylor_wip]
		, ISNULL(SUM(cost_time.beth_price), 0) +
			ISNULL(SUM(cost_time.brian_collins), 0) +
			ISNULL(SUM(cost_time.chloe_higham), 0) +
			ISNULL(SUM(cost_time.chris_simpson), 0) +
			ISNULL(SUM(cost_time.david_bailey_vella), 0) +
			ISNULL(SUM(cost_time.emma_jeffries), 0) +
			ISNULL(SUM(cost_time.gwen_mensah), 0) +
			ISNULL(SUM(cost_time.iain_stark), 0) +
			ISNULL(SUM(cost_time.jason_wilkins), 0) +
			ISNULL(SUM(cost_time.john_pennington_jones), 0) +
			ISNULL(SUM(cost_time.katie_mcmullin), 0) +
			ISNULL(SUM(cost_time.lewis_fearon), 0) +
			ISNULL(SUM(cost_time.louise_hawkfield), 0) +
			ISNULL(SUM(cost_time.mark_moriarty), 0) +
			ISNULL(SUM(cost_time.megan_jackson), 0) +
			ISNULL(SUM(cost_time.michael_bennett), 0) +
			ISNULL(SUM(cost_time.michaela_cheshire), 0) +
			ISNULL(SUM(cost_time.sarah_evans), 0) +
			ISNULL(SUM(cost_time.stephanie_mcbride), 0) +
			ISNULL(SUM(cost_time.stuart_naylor), 0)											AS [total_costs_wip]
	INTO #costhandlers
	FROM (
			SELECT
				master_fact_key
				, dim_matter_header_current_key
				, CASE	
					WHEN cost_handlers.fed_code = '6114' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [beth_price]
			    , CASE	
					WHEN cost_handlers.fed_code IN ('1924', 'BCO') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [brian_collins]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4877', 'COI') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [chloe_higham]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4348', 'CHS', 'CHS1') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [chris_simpson]														
				, CASE	
					WHEN cost_handlers.fed_code = '6172' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [david_bailey_vella]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4234', 'EPO', 'EPO1', 'EPO2') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [emma_jeffries]
				, CASE	
					WHEN cost_handlers.fed_code IN ('3113', 'GME') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [gwen_mensah]
				, CASE	
					WHEN cost_handlers.fed_code IN ('5113', 'IST') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [iain_stark]
				, CASE	
					WHEN cost_handlers.fed_code IN ('5522', 'WIJ') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [jason_wilkins]
				, CASE	
					WHEN cost_handlers.fed_code = '5386' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [john_pennington_jones]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4878', 'KFI') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [katie_mcmullin]
				, CASE	
					WHEN cost_handlers.fed_code IN ('3662', 'LFO', 'LFO1') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [lewis_fearon]
				, CASE	
					WHEN cost_handlers.fed_code IN ('LOH', '4410') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [louise_hawkfield]
				, CASE	
					WHEN cost_handlers.fed_code IN ('2033', 'MMB') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [mark_moriarty]
				, CASE	
					WHEN cost_handlers.fed_code = '5607' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [megan_jackson]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4270', 'MCB', 'MCB1') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [michael_bennett]
				, CASE	
					WHEN cost_handlers.fed_code = '4846' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [michaela_cheshire]
				, CASE	
					WHEN cost_handlers.fed_code IN ('3401', 'SHC', 'SHC1') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [sarah_evans]
				, CASE	
					WHEN cost_handlers.fed_code IN ('4941', 'SMB') THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [stephanie_mcbride]
				, CASE	
					WHEN cost_handlers.fed_code = '6180' THEN 
						SUM(wip_value)
					ELSE
						0
				  END																	AS [stuart_naylor]
			FROM red_dw.dbo.fact_wip
				LEFT OUTER JOIN (
									SELECT 
										dim_fed_hierarchy_history_key
										, fed_code
									FROM red_dw.dbo.dim_fed_hierarchy_history
									WHERE fed_code IN ('6180','SMB','4941','SHC1','SHC','3401','4846',
													'MCB1','MCB','4270','5607','MMB','1924','6114',
													'2033','4410','LOH','LFO1','LFO','3662','KFI',
													'4878','5386','WIJ','5522','IST','5113','GME',
													'3113','EPO2','EPO1','EPO','4234','6172','CHS1',
													'CHS','4348','COI','4877','BCO'
												   )
								) AS cost_handlers
					ON cost_handlers.dim_fed_hierarchy_history_key = red_dw.dbo.fact_wip.dim_fed_hierarchy_history_key
				LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
					ON dim_matter_header_current.dim_matter_header_curr_key = red_dw.dbo.fact_wip.dim_matter_header_current_key
			WHERE 
				master_client_code = 'C1001'
				AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL
				AND red_dw.dbo.dim_matter_header_current .reporting_exclusions <> 1
			GROUP BY 
				master_fact_key
				, red_dw.dbo.fact_wip.dim_matter_header_current_key
				, cost_handlers.fed_code
			
		) AS cost_time
	GROUP BY
		cost_time.master_fact_key
		, cost_time.dim_matter_header_current_key




--====================================================================================================================================================================================
-- Main query
--====================================================================================================================================================================================

	SELECT  
		RTRIM(red_dw.dbo.dim_matter_header_current.master_client_code) 
			+ ' ' + red_dw.dbo.dim_matter_header_current.master_matter_number						AS [Client and Matter Number]
		, red_dw.dbo.dim_matter_header_current.matter_owner_full_name								AS [Matter Owner]
		, red_dw.dbo.dim_matter_header_current.matter_description									AS [Matter Description]
		, CAST(red_dw.dbo.dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
		, CAST(red_dw.dbo.dim_detail_outcome.date_claim_concluded AS DATE)							AS [Date Claim Concluded]
		, CAST(red_dw.dbo.dim_detail_outcome.date_costs_settled AS DATE)							AS [Date Costs Settled]
		, red_dw.dbo.dim_matter_header_current.present_position										AS [Present Position]
		, CAST(red_dw.dbo.fact_matter_summary_current.last_bill_date AS DATE)						AS [Date of Last Bill]
		, CAST(red_dw.dbo.fact_matter_summary_current.last_time_transaction_date AS DATE)			AS [Date of Last Time Transaction]
		, ISNULL(beth_price_wip, 0)																	AS [Beth Price WIP]
		, ISNULL(brian_collins_wip, 0)																AS [Brian Collins WIP]
		, ISNULL(chloe_higham_wip, 0)																AS [Chloe Higham WIP]
		, ISNULL(chris_simpson_wip, 0)																AS [Chris Simpson WIP]
		, ISNULL(david_bailey_vella_wip, 0)															AS [David Bailey Vella WIP]
		, ISNULL(emma_jeffries_wip, 0)																AS [Emma Jeffries WIP]
		, ISNULL(gwen_mensah_wip, 0)																AS [Gwen Mensah WIP]
		, ISNULL(iain_stark_wip, 0)																	AS [Iain Stark WIP]
		, ISNULL(jason_wilkins_wip, 0)																AS [Jason Wilkins WIP]
		, ISNULL(john_pennington_jones_wip, 0)														AS [John Pennington Jones WIP]
		, ISNULL(katie_mcmullin_wip, 0)																AS [Katie McMullin WIP]
		, ISNULL(lewis_fearon_wip, 0)																AS [Lewis Fearon WIP]
		, ISNULL(louise_hawkfield_wip, 0)															AS [Louise Hawkfield WIP]
		, ISNULL(mark_moriarty_wip, 0)																AS [Mark Moriarty WIP]
		, ISNULL(megan_jackson_wip, 0)																AS [Megan Jackson WIP]
		, ISNULL(michael_bennett_wip, 0)															AS [Michael Bennett WIP]
		, ISNULL(michaela_cheshire_wip, 0)															AS [Michaela Cheshire WIP]
		, ISNULL(sarah_evans_wip, 0)																AS [Sarah Evans WIP]
		, ISNULL(stephanie_mcbride_wip, 0)															AS [Stephanie McBride WIP]
		, ISNULL(stuart_naylor_wip, 0)																AS [Stuart Naylor WIP]
		, ISNULL(total_costs_wip, 0)																AS [Total Costs WIP]
	FROM 
		red_dw.dbo.dim_matter_header_current 
		INNER JOIN red_dw.dbo.fact_dimension_main
			ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
		INNER JOIN red_dw.dbo.dim_detail_outcome
			ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
		INNER JOIN red_dw.dbo.fact_matter_summary_current
			ON fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
		LEFT OUTER JOIN #costhandlers
			ON #costhandlers.master_fact_key = fact_dimension_main.master_fact_key
	WHERE 
		red_dw.dbo.dim_matter_header_current.master_client_code = 'C1001'
		AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL
		AND red_dw.dbo.dim_matter_header_current .reporting_exclusions <> 1
		AND (red_dw.dbo.dim_detail_outcome.outcome_of_case IS NULL OR RTRIM(LOWER(red_dw.dbo.dim_detail_outcome.outcome_of_case)) <> 'exclude from reports')
	
	
END
GO
