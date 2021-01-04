SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-08-29
-- Description:	created to keep track of the report
--JL 16-12-2020 #79345 fixed issue with calc for field 'May_2015_now_bills', was incorrect. Added isnull
-- =============================================
CREATE PROCEDURE [dbo].[InsuredandInsurerClientSummary] 
AS

--================================================================================================================================================================================
-- Changed results table to pivot the revenue into fin_year. Added a table to count 
--================================================================================================================================================================================

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF object_id('Reporting.dbo.InsuredandInsurerClientSummaryTable') IS NOT NULL DROP TABLE  Reporting.dbo.InsuredandInsurerClientSummaryTable
IF object_id('temdb..#results') IS NOT NULL DROP TABLE  #results
IF object_id('temdb..#groups_count') IS NOT NULL DROP TABLE  #groups_count


--==========================================================================================================================================================
-- temp table for revenue of each case
--==========================================================================================================================================================

SELECT *
INTO #results
FROM (
		SELECT 
			fact_bill_activity.client_code
			, fact_bill_activity.matter_number
			, dim_bill_date.bill_fin_year
			, SUM(fact_bill_activity.bill_amount) Revenue
		--select top 100 *
		FROM red_dw.dbo.fact_bill_activity
			INNER JOIN red_dw.dbo.dim_bill_date 
				ON fact_bill_activity.dim_bill_date_key=dim_bill_date.dim_bill_date_key
		WHERE 
			dim_bill_date.bill_fin_year BETWEEN 2015 AND 2021
		GROUP BY 
			fact_bill_activity.client_code
			, fact_bill_activity.matter_number
			, dim_bill_date.bill_fin_year
		) x
		PIVOT
		(
			SUM(Revenue)
			FOR	bill_fin_year IN ([2016],[2017],[2018],[2019],[2020],[2021])
		) p

--==========================================================================================================================================================
-- Temp table to count number of matters opened for each group of the report
--==========================================================================================================================================================

SELECT 
	dim_matter_header_current.client_code
	, dim_matter_header_current.matter_number
	, 1						AS [May_2015_now]
	, CASE 
		WHEN dim_date.fin_year = 2016 THEN
			1
		ELSE
			0
		END										AS [May_2015_April_2016]
	, CASE 
		WHEN dim_date.fin_year = 2017 THEN
			1
		ELSE
			0
		END										AS [May_2016_April_2017]
	, CASE 
		WHEN dim_date.fin_year = 2018 THEN
			1
		ELSE
			0
		END										AS [May_2017_now]
	, CASE 
		WHEN dim_date.fin_year = 2019 THEN
			1
		ELSE
			0
		END										AS [matters_FY2019]
	, CASE 
		WHEN dim_date.fin_year = 2020 THEN
			1
		ELSE
			0
		END										AS [matters_FY2020]
	, CASE 
		WHEN dim_date.fin_year = 2021 THEN
			1
		ELSE
			0
		END										AS [matters_FY2021]

INTO #groups_count
FROM red_dw.dbo.fact_dimension_main 
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date = dim_matter_header_current.date_opened_practice_management
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
WHERE
	dim_date.fin_year >= 2016 AND 
	(dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' OR dim_matter_worktype.work_type_name LIKE '%Prof Risk%')


--=====================================================================================================================================================================
-- Main query
--=====================================================================================================================================================================

SELECT 
	dim_client_involvement.insurerclient_name
	, ISNULL(dim_client_involvement.insuredclient_name, dim_detail_claim.dst_insured_client_name)	AS insuredclient_name
	, dim_client.sector
	, dim_detail_core_details.insured_sector
	, dim_client.client_name
	, dim_client.client_group_name
	, dim_client.segment
	, dim_matter_worktype.work_type_name
	, dim_department.department_name
	, dim_matter_header_current.matter_partner_full_name
	, SUM(#groups_count.May_2015_now)	AS May_2015_now
	, SUM(#groups_count.May_2015_April_2016)	AS May_2015_April_2016
	, SUM(#groups_count.May_2016_April_2017) AS May_2016_April_2017
	, SUM(#groups_count.May_2017_now)	AS May_2017_now
	, SUM(#groups_count.matters_FY2019) AS matters_FY2019
	, SUM(#groups_count.matters_FY2020) AS matters_FY2020
	, SUM(#groups_count.matters_FY2021) AS matters_FY2021

	, ISNULL(SUM(#results.[2016]),0) +						 
		ISNULL(SUM(#results.[2017]),0) +
		ISNULL(SUM(#results.[2018]),0) +
		ISNULL(SUM(#results.[2019]),0) +
		ISNULL(SUM(#results.[2020]),0) +
		ISNULL(SUM(#results.[2021]),0) 			AS May_2015_now_bills
	, SUM(#results.[2016]) AS May_2015_April_2016_bills
	, SUM(#results.[2017]) AS May_2016_April_2017_bills
	, SUM(#results.[2018]) AS May_2017_now_bills
	, SUM(#results.[2019]) AS [bills_FY2019] 
	, SUM(#results.[2020]) AS bills_FY2020
	, SUM(#results.[2021]) AS bills_FY2021
INTO Reporting.dbo.InsuredandInsurerClientSummaryTable
FROM red_dw.dbo.fact_dimension_main
	INNER JOIN red_dw.dbo.dim_matter_header_current
		ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
		ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
	LEFT OUTER JOIN red_dw.dbo.dim_client
		ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
	LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
		ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
		ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
	LEFT OUTER JOIN red_dw.dbo.dim_department
		ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
	LEFT OUTER JOIN #results
		ON #results.client_code = dim_matter_header_current.client_code
			AND #results.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN #groups_count	
		ON #groups_count.client_code = dim_matter_header_current.client_code
			AND #groups_count.matter_number = dim_matter_header_current.matter_number
WHERE 
	(dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' OR dim_matter_worktype.work_type_name LIKE '%Prof Risk%')
	AND dim_matter_header_current.reporting_exclusions <> 1
	AND dim_matter_header_current.master_client_code <> '30645'
GROUP BY 
	dim_client_involvement.insurerclient_name
	, ISNULL(dim_client_involvement.insuredclient_name, dim_detail_claim.dst_insured_client_name)
	, dim_client.sector
	, dim_client.segment
	, dim_detail_core_details.insured_sector
	, dim_client.client_name
	, dim_client.client_group_name
	, dim_client.segment
	, dim_matter_worktype.work_type_name
	, dim_department.department_name
	, dim_matter_header_current.matter_partner_full_name
HAVING	
	SUM(#groups_count.May_2015_now)	<> 0 OR 
	SUM(#groups_count.May_2015_April_2016)	<> 0 OR 	
	SUM(#groups_count.May_2016_April_2017) 	<> 0 OR 
	SUM(#groups_count.May_2017_now)	<> 0 OR 	
	SUM(#groups_count.matters_FY2019)	<> 0 OR  
	SUM(#groups_count.matters_FY2020)	<> 0 OR 
	SUM(#groups_count.matters_FY2021)	<> 0 OR  
	SUM(#results.[2016]) +						 
		SUM(#results.[2017]) +
		SUM(#results.[2018]) +
		SUM(#results.[2019]) +
		SUM(#results.[2020]) +
		SUM(#results.[2021])	<> 0 OR  			
	SUM(#results.[2016])	<> 0 OR  
	SUM(#results.[2017])	<> 0 OR  
	SUM(#results.[2018])	<> 0 OR  
	SUM(#results.[2019])	<> 0 OR   
	SUM(#results.[2020])	<> 0 OR  
	SUM(#results.[2021])	<> 0 


END

GO
