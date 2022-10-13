SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2020-10-19
-- Description:	#59678 New report - Fee Arrangement Summary (HSD & TMs) 
-- =============================================

CREATE PROCEDURE [dbo].[fee_arrangement_summary]
(
	@department AS VARCHAR(MAX)
	, @team AS VARCHAR(MAX)
	, @case_handler AS VARCHAR(MAX)
)
AS

--DECLARE @department AS VARCHAR(MAX) = 'Casualty'
--	, @team AS VARCHAR(MAX) = 'Casualty Liverpool 1|Casualty Liverpool 2'
--	, @case_handler AS VARCHAR(MAX) = 'D9245ECD-6089-4969-901B-DF100354AFE8|67FBDB1C-4457-44C9-89FC-D321B699C2C9'

BEGIN

SET NOCOUNT ON;

IF OBJECT_ID('tempdb..#department') IS NOT NULL DROP TABLE #department
IF OBJECT_ID('tempdb..#team') IS NOT NULL DROP TABLE #team
IF OBJECT_ID('tempdb..#case_handler') IS NOT NULL DROP TABLE #case_handler
IF OBJECT_ID('tempdb..#pivoted_revenue') IS NOT NULL DROP TABLE #pivoted_revenue
IF OBJECT_ID('tempdb..#aggregations') IS NOT NULL DROP TABLE #aggregations

SELECT udt_TallySplit.ListValue  INTO #department FROM 	dbo.udt_TallySplit('|', @department)
SELECT udt_TallySplit.ListValue  INTO #team FROM 	dbo.udt_TallySplit('|', @team)
SELECT udt_TallySplit.ListValue  INTO #case_handler FROM 	dbo.udt_TallySplit('|', @case_handler)



--===============================================================================================================
-- create dynamic column headings for the pivot
--===============================================================================================================
DECLARE @date_columns NVARCHAR(MAX)

SELECT @date_columns = COALESCE(@date_columns + ',[' + CONVERT(NVARCHAR, pv.bill_fin_quarter, 106) + ']', '[' + CONVERT(NVARCHAR, pv.bill_fin_quarter, 106) + ']')
FROM (
		SELECT DISTINCT 
			dim_bill_date.bill_fin_quarter
		FROM red_dw.dbo.dim_bill_date
		WHERE 
			dim_bill_date.bill_fin_year BETWEEN YEAR(GETDATE()) AND YEAR(GETDATE())+1
	) AS pv
ORDER BY pv.bill_fin_quarter


--===============================================================================================================

CREATE TABLE #pivoted_revenue(
	client_code VARCHAR(8),
	matter_number VARCHAR(8),
	fee_arrangement VARCHAR(10),
	quarter_1_prv_fy FLOAT,
	quarter_2_prv_fy FLOAT,
	quarter_3_prv_fy FLOAT,
	quarter_4_prv_fy FLOAT,
	quarter_1_fy FLOAT,
	quarter_2_fy FLOAT,
	quarter_3_fy FLOAT,
	quarter_4_fy FLOAT
)

--=================================================================================================================
-- dynamic query to insert dynamic dates into temp table, avoiding the need to update the query each year
--=================================================================================================================
DECLARE @pivoted_query NVARCHAR(MAX)


SET @pivoted_query = '
				INSERT INTO #pivoted_revenue
				SELECT * 
				FROM
				(
					SELECT 
						dim_matter_header_current.client_code
						, dim_matter_header_current.matter_number
						, CASE
							WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = ''Fixed Fee/Fee Quote/Capped Fee'' THEN 
								''Fixed Fee''
							WHEN RTRIM(LOWER(dim_detail_finance.output_wip_fee_arrangement)) LIKE ''hourly%'' THEN 
								''Hourly''
							ELSE
								''Other''
						  END		AS fee_arrangement
						, dim_bill_date.bill_fin_quarter bill_fin_quarter
						, SUM(fact_bill_activity.bill_amount) Revenue
					FROM red_dw.dbo.fact_dimension_main
						INNER JOIN red_dw.dbo.fact_bill_activity
							ON fact_bill_activity.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
						INNER JOIN red_dw.dbo.dim_bill_date 
							ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
						INNER JOIN red_dw.dbo.dim_matter_header_current
							ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
						LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
							ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
						INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
							ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
					WHERE 
						dim_bill_date.bill_fin_year BETWEEN YEAR(GETDATE()) AND YEAR(GETDATE())+1
						AND dim_fed_hierarchy_history.hierarchylevel2hist = ''Legal Ops - Claims''
					GROUP BY 
						dim_matter_header_current.client_code
						, dim_matter_header_current.matter_number
						, CASE
							WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = ''Fixed Fee/Fee Quote/Capped Fee'' THEN 
								''Fixed Fee''
							WHEN RTRIM(LOWER(dim_detail_finance.output_wip_fee_arrangement)) LIKE ''hourly%'' THEN 
								''Hourly''
							ELSE
								''Other''
						  END
						, bill_fin_quarter
				) x
				PIVOT
				(
					SUM(Revenue)
					FOR bill_fin_quarter IN (' + @date_columns + ')
				) p
'
 

EXEC sys.sp_executesql @pivoted_query



--===============================================================================================================
-- Table to deal with bringing the counts and revenue together, they will be used in the final table to work out averages
--===============================================================================================================
--DROP TABLE IF EXISTS #aggregations
SELECT 
	dim_fed_hierarchy_history.employeeid
	, CASE
		WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			'Fixed Fee'
		WHEN RTRIM(LOWER(dim_detail_finance.output_wip_fee_arrangement)) LIKE 'hourly%' THEN 
			'Hourly'
		ELSE
			'Other'
	  END						AS fee_arrangment
	, SUM(CASE		
			WHEN dim_matter_header_current.date_closed_practice_management IS NULL 
				AND (dim_detail_core_details.present_position IS NULL OR RTRIM(dim_detail_core_details.present_position) NOT IN ('Final bill due - claim and costs concluded', 'Final bill sent - unpaid', 'To be closed/minor balances to be clear')) THEN
				1
			ELSE
				0
		   END)						AS [count_os_matters]
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_1_prv_fy, 0) + ISNULL(#pivoted_revenue.quarter_2_prv_fy, 0) + ISNULL(#pivoted_revenue.quarter_3_prv_fy, 0)
				+ ISNULL(#pivoted_revenue.quarter_4_prv_fy, 0) > 0 THEN
                1
			ELSE
				0
		   END)						AS [total_prev_yr_bill_count]
	,  SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_1_fy, 0) + ISNULL(#pivoted_revenue.quarter_2_fy, 0) + ISNULL(#pivoted_revenue.quarter_3_fy, 0)
				+ ISNULL(#pivoted_revenue.quarter_4_fy, 0) > 0 THEN
                1
			ELSE
				0
		   END)						AS [total_curr_yr_bill_count]
	, SUM(ISNULL(#pivoted_revenue.quarter_1_prv_fy, 0)) + SUM(ISNULL(#pivoted_revenue.quarter_2_prv_fy, 0))
		+ SUM(ISNULL(#pivoted_revenue.quarter_3_prv_fy, 0)) + SUM(ISNULL(#pivoted_revenue.quarter_4_prv_fy, 0))		AS [total_billed_prev_fy]
	, SUM(ISNULL(#pivoted_revenue.quarter_1_fy, 0)) + SUM(ISNULL(#pivoted_revenue.quarter_2_fy, 0))
		+ SUM(ISNULL(#pivoted_revenue.quarter_3_fy, 0)) + SUM(ISNULL(#pivoted_revenue.quarter_4_fy, 0))				AS [total_billed_curr_fy]
	, SUM(ISNULL(#pivoted_revenue.quarter_1_prv_fy, 0))		AS q1_prev_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_1_prv_fy, 0) > 0 THEN
				1
			ELSE
				0
		  END)								AS q1_prev_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_2_prv_fy, 0))		AS q2_prev_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_2_prv_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)				AS q2_prev_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_3_prv_fy, 0))		AS q3_prev_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_3_prv_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)			AS q3_prev_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_4_prv_fy, 0))		AS q4_prev_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_4_prv_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)			AS q4_prev_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_1_fy, 0))			AS q1_curr_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_1_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)				AS q1_curr_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_2_fy, 0))			AS q2_curr_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_2_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)				AS q2_curr_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_3_fy, 0))			AS q3_curr_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_3_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)				AS q3_curr_fy_count
	, SUM(ISNULL(#pivoted_revenue.quarter_4_fy, 0))			AS q4_curr_fy
	, SUM(CASE
			WHEN ISNULL(#pivoted_revenue.quarter_4_fy, 0) > 0 THEN
				1
			ELSE
				0
		   END)				AS q4_curr_fy_count
INTO #aggregations
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_finance
		ON dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN #pivoted_revenue
		ON #pivoted_revenue.client_code COLLATE DATABASE_DEFAULT = dim_matter_header_current.client_code	
			AND #pivoted_revenue.matter_number COLLATE DATABASE_DEFAULT = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	INNER JOIN #department
		ON #department.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel3hist
	INNER JOIN #team
		ON #team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
WHERE 1 = 1
	--AND dim_fed_hierarchy_history.employeeid = '08F353A2-4600-43D8-A9AC-216EA9525DA8'
	AND dim_matter_header_current.reporting_exclusions = 0
	AND dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims'
GROUP BY
	dim_fed_hierarchy_history.employeeid
	, CASE
		WHEN RTRIM(dim_detail_finance.output_wip_fee_arrangement) = 'Fixed Fee/Fee Quote/Capped Fee' THEN 
			'Fixed Fee'
		WHEN RTRIM(LOWER(dim_detail_finance.output_wip_fee_arrangement)) LIKE 'hourly%' THEN 
			'Hourly'
		ELSE
			'Other'
	  END

--===========================================================================================================================
-- Main query
--===========================================================================================================================

SELECT	
	dim_fed_hierarchy_history.name						AS [Handler Name]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, dim_fed_hierarchy_history.hierarchylevel3hist		AS [Department]
	, dim_fed_hierarchy_history.worksforname			
	-- Counts
	, ISNULL(fixed_fee_agg.count_os_matters, 0) + ISNULL(hourly_agg.count_os_matters, 0) + ISNULL(other_agg.count_os_matters, 0)	AS [Total No. of Outstanding Matters]
	, ISNULL(fixed_fee_agg.count_os_matters, 0)		AS [No. of Outstanding Fixed Fee Matters]
	, ISNULL(hourly_agg.count_os_matters, 0)			AS [No. of Outstanding Hourly Rate Matters]
	, ISNULL(other_agg.count_os_matters, 0)			AS [No. of Outstanding Matters (Other Fee Arrangements)]
	-- Total billed
	, ISNULL(fixed_fee_agg.total_billed_prev_fy, 0) + ISNULL(hourly_agg.total_billed_prev_fy, 0) + ISNULL(other_agg.total_billed_prev_fy, 0)	AS [Total Billed Previous FY]
	, ISNULL(fixed_fee_agg.total_billed_curr_fy, 0) + ISNULL(hourly_agg.total_billed_curr_fy, 0) + ISNULL(other_agg.total_billed_curr_fy, 0)	AS [Total Billed Current FY YTD]
	-- Fixed fee total billed & % of total
	, ISNULL(fixed_fee_agg.total_billed_prev_fy, 0)				AS [Total Billed on Fixed Fee Matters Prev FY]
	, CASE	
		WHEN ISNULL(fixed_fee_agg.total_billed_prev_fy, 0) = 0 THEN
			0
		ELSE
			ROUND(ISNULL(fixed_fee_agg.total_billed_prev_fy, 0)	/ (ISNULL(fixed_fee_agg.total_billed_prev_fy, 0) + ISNULL(hourly_agg.total_billed_prev_fy, 0) + ISNULL(other_agg.total_billed_prev_fy, 0)), 2)
	  END   AS [% Total Billed for Previous FY from Fixed Fee Matters]
	, ISNULL(fixed_fee_agg.total_billed_curr_fy, 0)				AS [Total Billed on Fixed Fee Matters Curr FY]
	, CASE	
		WHEN ISNULL(fixed_fee_agg.total_billed_curr_fy, 0) = 0 THEN
			0
		ELSE
			ROUND(ISNULL(fixed_fee_agg.total_billed_curr_fy, 0)	/ (ISNULL(fixed_fee_agg.total_billed_curr_fy, 0) + ISNULL(hourly_agg.total_billed_curr_fy, 0) + ISNULL(other_agg.total_billed_curr_fy, 0)), 2)
	  END   AS [% Total Billed for Current FY from Fixed Fee Matters]
	-- Hourly rate total billed & % of total
	, ISNULL(hourly_agg.total_billed_prev_fy, 0)				AS [Total Billed on Hourly Rate Matters Prev FY]
	, CASE	
		WHEN ISNULL(hourly_agg.total_billed_prev_fy, 0) = 0 THEN
			0
		ELSE
			ROUND(ISNULL(hourly_agg.total_billed_prev_fy, 0)	/ (ISNULL(fixed_fee_agg.total_billed_prev_fy, 0) + ISNULL(hourly_agg.total_billed_prev_fy, 0) + ISNULL(other_agg.total_billed_prev_fy, 0)), 2)
	  END														AS [% Total Billed for Previous FY from Hourly Rate Matters]
	, ISNULL(hourly_agg.total_billed_curr_fy, 0)				AS [Total Billed on Hourly Rate Matters Curr FY]
	, CASE	
		WHEN ISNULL(hourly_agg.total_billed_curr_fy, 0) = 0 THEN
			0
		ELSE
			ROUND(ISNULL(hourly_agg.total_billed_curr_fy, 0)	/ (ISNULL(fixed_fee_agg.total_billed_curr_fy, 0) + ISNULL(hourly_agg.total_billed_curr_fy, 0) + ISNULL(other_agg.total_billed_curr_fy, 0)), 2)
	  END														AS [% Total Billed for Current FY from Hourly Rate Matters]
	-- Fixed fee quarterly average 
	-- previous fin year
	, CASE
		WHEN ISNULL(fixed_fee_agg.q1_prev_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q1_prev_fy / fixed_fee_agg.q1_prev_fy_count, 2)
		ELSE
			0
	  END				AS [Average Fixed Fee Billed Q1 Previous FY]
	, CASE
		WHEN ISNULL(fixed_fee_agg.q2_prev_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q2_prev_fy / fixed_fee_agg.q2_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q2 Previous FY]
	, CASE
		WHEN ISNULL(fixed_fee_agg.q3_prev_fy_count, 0) > 0 THEN	
			ROUND(fixed_fee_agg.q3_prev_fy / fixed_fee_agg.q3_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q3 Previous FY]
	, CASE	
		WHEN ISNULL(fixed_fee_agg.q4_prev_fy_count, 0) > 0 THEN	
			ROUND(fixed_fee_agg.q4_prev_fy / fixed_fee_agg.q4_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q4 Previous FY]
	--current fin year
	, CASE
		WHEN ISNULL(fixed_fee_agg.q1_curr_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q1_curr_fy / fixed_fee_agg.q1_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q1 Current FY]
	, CASE	
		WHEN ISNULL(fixed_fee_agg.q2_curr_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q2_curr_fy / fixed_fee_agg.q2_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q2 Current FY]
	, CASE	
		WHEN ISNULL(fixed_fee_agg.q3_curr_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q3_curr_fy / fixed_fee_agg.q3_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q3 Current FY]
	, CASE
		WHEN ISNULL(fixed_fee_agg.q4_curr_fy_count, 0) > 0 THEN
			ROUND(fixed_fee_agg.q4_curr_fy / fixed_fee_agg.q4_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Fixed Fee Billed Q4 Current FY]
	-- Hourly rate quarterly average
	-- Previous fin year
	, CASE 
		WHEN ISNULL(hourly_agg.q1_prev_fy_count, 0) > 0 THEN
			ROUND(hourly_agg.q1_prev_fy / hourly_agg.q1_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q1 Previous FY]
	, CASE	
		WHEN ISNULL(hourly_agg.q2_prev_fy_count, 0) > 0 THEN
			ROUND(hourly_agg.q2_prev_fy / hourly_agg.q2_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q2 Previous FY]
	, CASE	
		WHEN ISNULL(hourly_agg.q3_prev_fy_count, 0) > 0 THEN
			ROUND(hourly_agg.q3_prev_fy / hourly_agg.q3_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q3 Previous FY]
	, CASE
		WHEN ISNULL(hourly_agg.q4_prev_fy_count, 0) > 0 THEN	
			ROUND(hourly_agg.q4_prev_fy / hourly_agg.q4_prev_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q4 Previous FY]
	-- Current fin year
	, CASE
		WHEN ISNULL(hourly_agg.q1_curr_fy_count, 0) > 0 THEN	
			ROUND(hourly_agg.q1_curr_fy / hourly_agg.q1_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q1 Current FY]
	, CASE
		WHEN ISNULL(hourly_agg.q2_curr_fy_count, 0) > 0 THEN	
			ROUND(hourly_agg.q2_curr_fy / hourly_agg.q2_curr_fy_count, 2)
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q2 Current FY]
	, CASE	
		WHEN ISNULL(hourly_agg.q3_curr_fy_count, 0) > 0 THEN
			ROUND(hourly_agg.q3_curr_fy / hourly_agg.q3_curr_fy_count, 2) 
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q3 Current FY]
	, CASE	
		WHEN ISNULL(hourly_agg.q4_curr_fy_count, 0) > 0 THEN	
			ROUND(hourly_agg.q4_curr_fy / hourly_agg.q4_curr_fy_count, 0) 
		ELSE
			0
	  END			AS [Average Hourly Rate Billed Q4 Current FY]
FROM red_dw.dbo.dim_fed_hierarchy_history 
	LEFT OUTER JOIN #aggregations fixed_fee_agg
		ON fixed_fee_agg.employeeid = dim_fed_hierarchy_history.employeeid
			AND fixed_fee_agg.fee_arrangment = 'Fixed Fee'
	LEFT OUTER JOIN #aggregations AS hourly_agg
		ON hourly_agg.employeeid = dim_fed_hierarchy_history.employeeid
			AND hourly_agg.fee_arrangment = 'Hourly'
	LEFT OUTER JOIN #aggregations AS other_agg
		ON other_agg.employeeid = dim_fed_hierarchy_history.employeeid
			AND other_agg.fee_arrangment = 'Other'
	INNER JOIN #department
		ON #department.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel3hist
	INNER JOIN #team
		ON #team.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.hierarchylevel4hist
	INNER JOIN #case_handler
		ON #case_handler.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.employeeid
WHERE 1 = 1
	AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
	AND dim_fed_hierarchy_history.activeud = 1
	--AND emp_hierarchy.employeeid = '65C19016-2173-4B97-B539-5CBFE2334F91'
	AND (ISNULL(fixed_fee_agg.count_os_matters, 0) + ISNULL(hourly_agg.count_os_matters, 0) + ISNULL(other_agg.count_os_matters, 0) > 0 OR
		ISNULL(fixed_fee_agg.total_prev_yr_bill_count, 0) + ISNULL(hourly_agg.total_prev_yr_bill_count, 0) + ISNULL(other_agg.total_prev_yr_bill_count, 0) > 0 OR
        ISNULL(fixed_fee_agg.total_curr_yr_bill_count, 0) + ISNULL(hourly_agg.total_curr_yr_bill_count, 0) + ISNULL(other_agg.total_curr_yr_bill_count, 0) > 0)
ORDER BY
	Department
	, Team
	, [Handler Name]


END


GO
