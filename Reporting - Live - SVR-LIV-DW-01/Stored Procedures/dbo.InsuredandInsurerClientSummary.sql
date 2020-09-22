SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-08-29
-- Description:	created to keep track of the report
-- =============================================
CREATE PROCEDURE [dbo].[InsuredandInsurerClientSummary] 
AS

--==========================================================================================================================================================
-- SP that updates the InsuredandInsurerClientSummaryTable is stored in red_dw, dbo.ad_hoc_build_insured_and_insurer_client_summary_table
--==========================================================================================================================================================

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

SELECT  
	dmhc.client_code,
	dmhc.matter_number,
	dci.insurerclient_name,
	ISNULL(ddc.dst_insured_client_name,dci.insuredclient_name) insuredclient_name,
	dc.sector,
	dc.segment,
	ddcd.insured_sector,
	bill_date,
	dc.client_name,
	dc.client_group_name,
	dmwt.work_type_name,
	dd.department_name,
	dmhc.matter_partner_full_name,
	CASE WHEN calendar_date >= '2015-05-01' THEN 1 ELSE 0 END [May_2015_now],
	CASE WHEN calendar_date >= '2015-05-01' AND calendar_date <= '2016-04-30' THEN 1 ELSE 0 END [May_2015_April_2016],
	CASE WHEN calendar_date >= '2016-05-01' AND calendar_date <= '2017-04-30' THEN 1 ELSE 0 END [May_2016_April_2017],
	CASE WHEN calendar_date >= '2017-05-01' AND calendar_date <= '2018-04-30' THEN 1 ELSE 0 END [May_2017_now],
	CASE WHEN calendar_date >= '2018-05-01' AND calendar_date <= '2019-04-30' THEN 1 ELSE 0 END [matters_FY2019],
	CASE WHEN calendar_date >= '2019-05-01' AND calendar_date <= '2020-04-30' THEN 1 ELSE 0 END [matters_FY2020],
	CASE WHEN calendar_date >= '2020-05-01' AND calendar_date <= '2021-04-30' THEN 1 ELSE 0 END [matters_FY2021],


	CASE WHEN bill_date >= '2015-05-01' THEN fba.bill_amount ELSE 0 END [May_2015_now_bills],

	CASE WHEN bill_date >= '2015-05-01' AND bill_date <= '2016-04-30' THEN fba.bill_amount ELSE 0 END [May_2015_April_2016_bills],
	CASE WHEN bill_date >= '2016-05-01' AND bill_date <= '2017-04-30' THEN fba.bill_amount ELSE 0 END [May_2016_April_2017_bills],
	CASE WHEN bill_date >= '2017-05-01' AND bill_date <= '2018-04-30' THEN fba.bill_amount ELSE 0 END [May_2017_now_bills],
	CASE WHEN bill_date >= '2018-05-01' AND bill_date <= '2019-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2019],
	CASE WHEN bill_date >= '2019-05-01' AND bill_date <= '2020-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2020],
	CASE WHEN bill_date >= '2020-05-01' AND bill_date <= '2021-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2021]
INTO #results
FROM red_Dw.dbo.fact_dimension_main fdm 
	LEFT JOIN red_Dw.dbo.fact_bill_activity fba ON  fdm.master_fact_key = fba.master_fact_key
	LEFT JOIN red_Dw.dbo.dim_matter_header_current dmhc ON dmhc.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
	LEFT JOIN red_Dw.dbo.dim_date open_date ON open_date.dim_date_key = fdm.dim_open_case_management_date_key
	LEFT JOIN red_Dw.dbo.dim_detail_core_details ddcd ON ddcd.dim_detail_core_detail_key = fdm.dim_detail_core_detail_key
	LEFT JOIN red_Dw.dbo.dim_client_involvement dci ON dci.dim_client_involvement_key = fdm.dim_client_involvement_key
	LEFT JOIN red_dw.dbo.dim_client dc ON dc.dim_client_key = fdm.dim_client_key
	LEFT JOIN red_Dw.dbo.dim_matter_worktype dmwt ON dmwt.dim_matter_worktype_key = dmhc.dim_matter_worktype_key
	LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = fba.dim_fed_hierarchy_history_key  
	LEFT JOIN red_Dw.dbo.dim_detail_claim ddc ON fdm.dim_detail_claim_key = ddc.dim_detail_claim_key  
	LEFT JOIN red_Dw.dbo.dim_department dd ON dmhc.dim_department_key = dd.dim_department_key  
WHERE (calendar_date >= '2015-05-01' OR fba.bill_date >= '2015-05-01' ) AND (fed.hierarchylevel2hist = 'Legal Ops - Claims' OR dmwt.work_type_name LIKE '%Prof Risk%')
  


--==========================================================================================================================================================
-- Temp table to count number of matters opened for each group of the report
--==========================================================================================================================================================

SELECT
	group_count.groups
	, SUM(group_count.May_2015_now) AS May_2015_now
	, SUM(group_count.May_2015_April_2016) AS May_2015_April_2016
	, SUM(group_count.May_2016_April_2017) AS May_2016_April_2017
	, SUM(group_count.May_2017_now) AS May_2017_now
	, SUM(group_count.matters_FY2019) AS matters_FY2019
	, SUM(group_count.matters_FY2020) AS matters_FY2020
	, SUM(group_count.matters_FY2021) AS matters_FY2021
INTO #groups_count
FROM (
		SELECT 
			--dim_matter_header_current.client_code
			--, dim_matter_header_current.matter_number
			ISNULL(dim_client_involvement.insurerclient_name,'') +
			ISNULL(dim_client_involvement.insuredclient_name,'') +
			ISNULL(dim_client.sector,'') +
			ISNULL(dim_detail_core_details.insured_sector,'') +
			ISNULL(dim_client.client_name,'') +
			ISNULL(dim_client.client_group_name,'') +
			ISNULL(dim_client.segment,'') +
			ISNULL(dim_matter_worktype.work_type_name,'') +
			ISNULL(dim_department.department_name,'') +
			ISNULL(dim_matter_header_current.matter_partner_full_name,'') AS [groups]
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


		FROM red_dw.dbo.fact_dimension_main 
			INNER JOIN red_dw.dbo.dim_matter_header_current
				ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
			INNER JOIN red_dw.dbo.dim_date
				ON dim_date.calendar_date = dim_matter_header_current.date_opened_practice_management
			INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
				ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
			LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
				ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
			LEFT JOIN red_Dw.dbo.dim_detail_core_details 
				ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
			LEFT JOIN red_Dw.dbo.dim_client_involvement 
				ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
			LEFT JOIN red_dw.dbo.dim_client
				ON dim_client.dim_client_key = fact_dimension_main.dim_client_key 
			LEFT JOIN red_Dw.dbo.dim_detail_claim 
				ON fact_dimension_main.dim_detail_claim_key = dim_detail_claim.dim_detail_claim_key  
			LEFT JOIN red_Dw.dbo.dim_department
				ON dim_matter_header_current.dim_department_key = dim_department.dim_department_key  
		WHERE
			dim_date.fin_year >= 2016 AND 
			(dim_fed_hierarchy_history.hierarchylevel2hist = 'Legal Ops - Claims' OR dim_matter_worktype.work_type_name LIKE '%Prof Risk%')
	) AS group_count
GROUP BY 
	group_count.groups

--========================================================================================================================================================================



SELECT *
INTO Reporting.dbo.InsuredandInsurerClientSummaryTable
FROM (
		SELECT 
		details.insurerclient_name,
		details.insuredclient_name,
		details.sector,
		details.insured_sector,
		details.client_name,
		details.client_group_name,
		details.segment,
		details.work_type_name,
		details.department_name,
		details.matter_partner_full_name,
		ISNULL(#groups_count.May_2015_now, 0)	AS May_2015_now,
		ISNULL(#groups_count.May_2015_April_2016, 0)	AS May_2015_April_2016,
		ISNULL(#groups_count.May_2016_April_2017, 0) AS May_2016_April_2017,
		ISNULL(#groups_count.May_2017_now, 0)	AS May_2017_now,
		ISNULL(#groups_count.matters_FY2019, 0) AS matters_FY2019,
		ISNULL(#groups_count.matters_FY2020, 0) AS matters_FY2020,
		ISNULL(#groups_count.matters_FY2021, 0) AS matters_FY2021,

		SUM(details.May_2015_now_bills) May_2015_now_bills,
		SUM(details.May_2015_April_2016_bills) May_2015_April_2016_bills,
		SUM(details.May_2016_April_2017_bills) May_2016_April_2017_bills,
		SUM(details.May_2017_now_bills) May_2017_now_bills,
		SUM([details].[bills_FY2019]) [bills_FY2019] ,
		SUM(details.bills_FY2020) bills_FY2020,
		SUM(details.bills_FY2021) bills_FY2021
		FROM #results details
			LEFT OUTER JOIN #groups_count								
				ON #groups_count.groups = ISNULL(details.insurerclient_name,'') +
											ISNULL(details.insuredclient_name,'') +
											ISNULL(details.sector,'') +
											ISNULL(details.insured_sector,'') +
											ISNULL(details.client_name,'') +
											ISNULL(details.client_group_name,'') +
											ISNULL(details.segment,'') +
											ISNULL(details.work_type_name,'') +
											ISNULL(details.department_name,'') +
											ISNULL(details.matter_partner_full_name,'')

		GROUP BY 
		insuredclient_name,
		client_name,
		client_group_name,
		insurerclient_name,
		segment,
		sector,
		insured_sector,
		work_type_name,
		department_name,
		matter_partner_full_name,
		#groups_count.May_2015_now,
		#groups_count.May_2015_April_2016,
		#groups_count.May_2016_April_2017,
		#groups_count.May_2017_now,
		#groups_count.matters_FY2019,
		#groups_count.matters_FY2020,
		#groups_count.matters_FY2021
		) AS total_data
WHERE	
	total_data.May_2015_now <> 0 OR 
	total_data.May_2015_April_2016 <> 0 OR 
	total_data.May_2016_April_2017 <> 0 OR 
	total_data.May_2017_now <> 0 OR
	total_data.matters_FY2019 <> 0 OR
	total_data.matters_FY2020 <> 0 OR
	total_data.matters_FY2021 <> 0 OR
	total_data.May_2015_now_bills <> 0 OR 
	total_data.May_2015_April_2016_bills <> 0 OR
	total_data.May_2016_April_2017_bills <> 0 OR
	total_data.May_2017_now_bills <> 0 OR
	total_data.matters_FY2019 <> 0 OR 
	total_data.bills_FY2020 <> 0 OR
	total_data.bills_FY2021 <> 0
ORDER BY May_2015_now DESC, insuredclient_name DESC,  insurerclient_name DESC




END
GO
