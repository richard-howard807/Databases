SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-12-29
-- Description: #83619 new report to track investigation time recorded on Zurich matters
-- =============================================
CREATE PROCEDURE [dbo].[Zurich_investigation_tracker]

(
	@Department AS VARCHAR(MAX)
	, @Team AS VARCHAR(MAX)
	, @MatterOwner AS VARCHAR(MAX)
)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- For testing
--DECLARE @Department AS VARCHAR(MAX) = 'Casualty'
--		, @Team AS VARCHAR(MAX) = 'Casualty Birmingham'
--		, @MatterOwner AS VARCHAR(MAX) = 'Saul Burton|Kulvinder Clare|Will Clay|Suresh Memi'

IF OBJECT_ID('tempdb..#department') IS NOT NULL DROP TABLE #department
IF OBJECT_ID('tempdb..#team') IS NOT NULL DROP TABLE #team
IF OBJECT_ID('tempdb..#matter_owner') IS NOT NULL DROP TABLE #matter_owner
IF OBJECT_ID('tempdb..#investigation_time') IS NOT NULL DROP TABLE #investigation_time
IF OBJECT_ID('tempdb..#total_hours') IS NOT NULL DROP TABLE #total_hours


SELECT udt_TallySplit.ListValue  INTO #department FROM 	dbo.udt_TallySplit('|', @Department)
SELECT udt_TallySplit.ListValue  INTO #team FROM 	dbo.udt_TallySplit('|', @Team)
SELECT udt_TallySplit.ListValue  INTO #matter_owner FROM 	dbo.udt_TallySplit('|', @MatterOwner)

--==================================================================================================================================================================================================
-- Table to gather all investigation/investigation travel time 
--==================================================================================================================================================================================================
SELECT 
	dim_matter_header_current.dim_matter_header_curr_key
	, CASE 
		WHEN fact_all_time_activity.time_activity_code = '0024' OR fact_all_time_activity.time_activity_code = '0030' THEN
			'investigation'
		ELSE
			'other'
	  END				AS [time_type]
	, dim_all_time_activity.unbilled_record
	, dim_all_time_activity.billed_record
	, SUM(fact_all_time_activity.wipamt)	AS [investigation_amount]
	, SUM(fact_all_time_activity.wiphrs)		AS [investigation_hours]
INTO #investigation_time
--SELECT dim_all_time_activity.*
FROM red_dw.dbo.fact_all_time_activity
	INNER JOIN red_dw.dbo.dim_all_time_activity
		ON dim_all_time_activity.dim_all_time_activity_key = fact_all_time_activity.dim_all_time_activity_key
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.client_code = fact_all_time_activity.client_code
			AND dim_matter_header_current.matter_number = fact_all_time_activity.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.client_code = dim_matter_header_current.client_code
			AND dim_detail_client.matter_number = dim_matter_header_current.matter_number
WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'Z1001'
	--AND dim_matter_header_current.master_matter_number = '52361'
	AND dim_all_time_activity.transaction_type NOT IN ('Non Billable', 'Non Chargeable Time', 'Written Off', 'Written Off Transaction')
	AND (dim_detail_client.zurich_data_admin_closure_date IS NULL OR dim_detail_client.zurich_data_admin_closure_date >= '2020-01-01')
	AND RTRIM(dim_matter_header_current.client_code) NOT IN ('Z00002', 'Z00004', 'Z00012', 'Z00014', 'Z00018', 'Z00021', '00012506', '00040657', '00169487', '00169490')
GROUP BY
	GROUPING SETS
	(
	(
		dim_matter_header_current.dim_matter_header_curr_key
		, CASE 
			WHEN fact_all_time_activity.time_activity_code = '0024' OR fact_all_time_activity.time_activity_code = '0030' THEN
				'investigation'
			ELSE
				'other'
		  END
		, dim_all_time_activity.unbilled_record
		, dim_all_time_activity.billed_record
	)
	, 
	(
		dim_matter_header_current.dim_matter_header_curr_key
		, dim_all_time_activity.unbilled_record
		, dim_all_time_activity.billed_record
	)
	)



--==================================================================================================================================================================================================
-- Main query
--==================================================================================================================================================================================================
SELECT 
	dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [Client/Matter Number]
	, dim_matter_header_current.matter_description							AS [Matter Description]
	, dim_fed_hierarchy_history.name						AS [Matter Owner]
	, dim_fed_hierarchy_history.hierarchylevel4hist							AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist							AS [Department]
	, CAST(dim_matter_header_current.date_opened_practice_management AS DATE)		AS [Date Opened]
	, CAST(dim_matter_header_current.date_closed_practice_management AS DATE)		AS [Date Closed]
	, CAST(dim_detail_client.zurich_data_admin_closure_date	AS DATE)					AS [Date Closed Off The Data]
	, IIF(dim_detail_client.zurich_data_admin_closure_date IS NULL, 'Open', 'Closed')		AS [Open/Closed Flag]
	, dim_matter_worktype.work_type_name												AS [Work Type]
	, dim_matter_worktype.work_type_group									AS [Work Type Group]
	, dim_detail_core_details.zurich_line_of_business						AS [Zurich Line of Business]
	, dim_detail_core_details.injury_type_code + ' - ' + dim_detail_core_details.injury_type								AS [Injury Type]
	, CASE
		WHEN dim_detail_core_details.injury_type_code LIKE 'D%' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			'Disease FT'
		WHEN dim_detail_core_details.injury_type_code LIKE 'D%' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			'Disease MT'
		WHEN dim_detail_core_details.zurich_line_of_business = 'EMP' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			'EL FT'
		WHEN dim_detail_core_details.zurich_line_of_business = 'EMP' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			'EL MT'
		WHEN dim_detail_core_details.zurich_line_of_business = 'PUB' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			'PL FT'
		WHEN dim_detail_core_details.zurich_line_of_business = 'PUB' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			'PL MT'
		ELSE
			NULL
	 END						AS [KPI Type]
	, dim_detail_finance.output_wip_fee_arrangement																		AS [Fee Arrangement]
	, fact_finance_summary.fixed_fee_amount																				AS [Fixed Fee Amount]
	, fact_detail_reserve_detail.damages_reserve																		AS [Current Damages Reserve]
	, dim_detail_core_details.track																						AS [Weightmans Track]
	, IIF(dim_detail_core_details.zurich_track = 'Fast track', 'FAS', 'MUL')											AS [Zurich Track]
	, dim_detail_core_details.zurich_referral_reason																	AS [Referral Reason]
	, dim_detail_core_details.present_position																			AS [Present Position]

	, ISNULL(investigation_wip.investigation_hours, 0)																	AS [WIP Hours Recorded Under 24 and 30 Investigation Codes]
	, ISNULL(investigation_wip.investigation_amount, 0)																	AS [WIP Value Recorded Under 24 and 30 Investigation Codes]
	, ISNULL(total_wip_hours.investigation_hours, 0)																			AS [Total WIP Hours]
	, ISNULL(fact_finance_summary.wip, 0)																				AS [Total WIP]

	, ISNULL(investigation_revenue.investigation_hours, 0)																AS [Hours Billed Under 24 and 30 Investigation Codes]
	, ISNULL(investigation_revenue.investigation_amount, 0)																AS [Revenue Billed Under 24 and 30 Investigation Codes]
	, ISNULL(total_billed_hours.investigation_hours, 0)																			AS [Total Revenue Hours]
	, ISNULL(fact_finance_summary.defence_costs_billed, 0)																AS [Total Revenue Billed]

	, ISNULL(investigation_wip.investigation_hours, 0) + ISNULL(investigation_revenue.investigation_hours, 0)			AS [Total Investigation Hours]
	, ISNULL(investigation_wip.investigation_amount, 0) + ISNULL(investigation_revenue.investigation_amount, 0)			AS [Total WIP and Revenue Billed as Investigation]
	, ISNULL(total_wip_hours.investigation_hours, 0) + ISNULL(total_billed_hours.investigation_hours, 0)								AS [Total WIP and Revenue hours]
	, ISNULL(fact_finance_summary.wip, 0) + ISNULL(fact_finance_summary.defence_costs_billed, 0)						AS [Total WIP and Revenue For All Time]
	, CASE
		WHEN dim_detail_core_details.injury_type_code LIKE 'D%' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			4615
		WHEN dim_detail_core_details.injury_type_code LIKE 'D%' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			8468
		WHEN dim_detail_core_details.zurich_line_of_business = 'EMP' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			1321
		WHEN dim_detail_core_details.zurich_line_of_business = 'EMP' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			6000
		WHEN dim_detail_core_details.zurich_line_of_business = 'PUB' AND dim_detail_core_details.zurich_track = 'Fast track' THEN
			1650
		WHEN dim_detail_core_details.zurich_line_of_business = 'PUB' AND dim_detail_core_details.zurich_track <> 'Fast track' THEN
			5500
		ELSE
			NULL
	 END				AS [Panel Average]
	 , 1		AS [count]
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history 
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
		ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
		ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
	LEFT OUTER JOIN	red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_client
		ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.client_code = dim_matter_header_current.client_code
			AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN #investigation_time AS investigation_wip
		ON investigation_wip.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND investigation_wip.unbilled_record = 1
				AND investigation_wip.time_type = 'investigation'
	LEFT OUTER JOIN #investigation_time AS investigation_revenue
		ON investigation_revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND investigation_revenue.billed_record = 1
				AND investigation_revenue.time_type = 'investigation'
	LEFT OUTER JOIN #investigation_time AS total_wip_hours
		ON total_wip_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND total_wip_hours.unbilled_record = 1
				AND total_wip_hours.time_type IS  NULL
	LEFT OUTER JOIN #investigation_time AS total_billed_hours
		ON total_billed_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			AND total_billed_hours.billed_record = 1
				AND total_billed_hours.time_type IS NULL
	INNER JOIN #department
		ON #department.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel3hist
	INNER JOIN #team
		ON #team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
	INNER JOIN #matter_owner
		ON #matter_owner.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name

WHERE 1 = 1
	AND dim_matter_header_current.master_client_code = 'Z1001'
	AND RTRIM(dim_matter_header_current.client_code) NOT IN ('Z00002', 'Z00004', 'Z00012', 'Z00014', 'Z00018', 'Z00021', '00012506', '00040657', '00169487', '00169490') 
	AND dim_matter_header_current.client_code + dim_matter_header_current.matter_number NOT IN ('Z00006  00000053', 'Z00006  00000134', 'Z00006  00000174', 'Z00006  00000176', 
																								'Z00006  00000197', 'Z00006  00000262', 'Z00006  00000264', 'Z00006  00000269')
	AND	dim_matter_header_current.reporting_exclusions = 0
	AND ISNULL(dim_detail_client.zurich_data_admin_exclude_from_reports, 'No') = 'No'
	AND (dim_detail_client.zurich_data_admin_closure_date IS NULL OR dim_detail_client.zurich_data_admin_closure_date >= '2020-01-01')
	AND LOWER(ISNULL(dim_detail_client.zurich_instruction_type, '')) NOT LIKE '%outsource%'
	AND ISNULL(dim_detail_claim.cit_claim, 'No') = 'No'
	AND dim_detail_core_details.injury_type_code <> 'A00'
	AND dim_detail_core_details.zurich_line_of_business IN ('EMP', 'PUB')
	AND dim_detail_core_details.zurich_track IN ('Fast track', 'Multi track')
	AND RTRIM(dim_detail_core_details.zurich_referral_reason) IN ('LIA', 'LIQ', 'LIM', 'QUA')
	AND (ISNULL(investigation_wip.investigation_amount, 0) > 0  OR ISNULL(investigation_revenue.investigation_amount, 0) > 0)

ORDER BY
	dim_matter_header_current.date_opened_practice_management

END	
GO
