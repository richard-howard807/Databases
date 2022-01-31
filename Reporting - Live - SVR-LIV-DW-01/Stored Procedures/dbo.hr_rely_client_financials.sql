SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

---- =============================================
---- Author:		Jamie Bonner
---- Create date:	2022-01-28
---- Description:	Financial data for clients with an HR Rely matter 
---- =============================================


CREATE PROCEDURE [dbo].[hr_rely_client_financials]
(
@report_date NVARCHAR(10)
)
as

--DECLARE @report_date AS NVARCHAR(10) = 'fin_year'
DECLARE @current_fin_year AS DATE = (SELECT MIN(dim_date.calendar_date) FROM red_dw.dbo.dim_date WHERE dim_date.current_fin_year = 'Current')

DROP TABLE IF EXISTS #hr_rely_clients
DROP TABLE IF EXISTS #chargeable_hours
DROP TABLE IF EXISTS #billed_hours
DROP TABLE IF EXISTS #revenue
/*
Gets the latest full year of for the clients start_date when there are multiple e.g. W16189/4 has date 2021-01-01, W16189/7 has 2022-01-01
We would need the 2021 data as of writing this report in Jan 2022, When there's a 3rd matter added in 2023 it would pick the 2022 date.
*/ 
SELECT 
	all_data.client_code
	, all_data.dim_client_key
	, IIF(@report_date = 'fin_year', @current_fin_year, all_data.start_date) AS start_date
	, dim_date.dim_date_key
INTO #hr_rely_clients
FROM (
		SELECT 
			dim_matter_header_current.client_code
			, dim_client.client_name
			, dim_client.dim_client_key
			, dim_detail_client.start_date
			--, dim_date.dim_date_key
			, ROW_NUMBER() OVER(PARTITION BY dim_matter_header_current.client_code ORDER BY dim_detail_client.start_date  DESC) AS rw	
		FROM red_dw.dbo.dim_matter_header_current
			INNER JOIN red_dw.dbo.dim_detail_client
				ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			--INNER JOIN red_dw.dbo.dim_date
			--	ON dim_date.calendar_date = CAST(dim_detail_client.start_date AS DATE)
			INNER JOIN red_dw.dbo.dim_client
				ON dim_client.client_code = dim_matter_header_current.client_code
		WHERE	
			dim_detail_client.start_date IS NOT NULL
			AND dim_matter_header_current.master_client_code <> '30645'
	) AS all_data
	INNER JOIN red_dw.dbo.dim_date
		ON dim_date.calendar_date =  IIF(@report_date = 'fin_year', @current_fin_year, all_data.start_date)
WHERE
	all_data.rw = 1


--====================================================================================================================================================================
SELECT 
	fact_billable_time_activity.dim_matter_header_curr_key,
    fact_billable_time_activity.dim_orig_posting_date_key, 
	fact_costs_rates.staff_cost_rate,
	fact_costs_rates.other_costs_rate,
	fact_costs_rates.total_cost_rate,
	fact_costs_rates.establishment_cost_rate,
    SUM(fact_billable_time_activity.minutes_recorded / 60) AS chargeable_hours,
    fact_costs_rates.staff_cost_rate * SUM(fact_billable_time_activity.minutes_recorded) / 60 AS chargeable_hours_staff_cost_rate, 
    fact_costs_rates.other_costs_rate * SUM(fact_billable_time_activity.minutes_recorded) / 60 AS chargeable_hours_other_cost_rate, 
    fact_costs_rates.total_cost_rate * SUM(fact_billable_time_activity.minutes_recorded) / 60 AS chargeable_hours_total_cost_rate, 
    fact_costs_rates.establishment_cost_rate * SUM(fact_billable_time_activity.minutes_recorded) / 60 AS chargeable_hours_establishment_cost_rate        
INTO #chargeable_hours
FROM  red_dw.dbo.fact_billable_time_activity
INNER JOIN #hr_rely_clients ON fact_billable_time_activity.dim_client_key = #hr_rely_clients.dim_client_key
inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_billable_time_activity.dim_fed_hierarchy_history_key
INNER JOIN red_dw.dbo.dim_date ON dim_date.dim_date_key = fact_billable_time_activity.dim_orig_posting_date_key
LEFT OUTER JOIN red_dw.dbo.fact_costs_rates ON fact_costs_rates.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
                    and fact_costs_rates.fin_year = dim_date.fin_year AND fact_costs_rates.fin_month_no = dim_date.fin_month_no
WHERE (fact_billable_time_activity.minutes_recorded <> 0)
	AND dim_date.dim_date_key >= (SELECT MIN(#hr_rely_clients.dim_date_key) FROM #hr_rely_clients)
GROUP by 
fact_billable_time_activity.dim_matter_header_curr_key
, fact_billable_time_activity.dim_orig_posting_date_key
, fact_costs_rates.staff_cost_rate
, fact_costs_rates.other_costs_rate
, fact_costs_rates.total_cost_rate
, fact_costs_rates.establishment_cost_rate

--====================================================================================================================================================================

select fact_bill_billed_time_activity.dim_client_key, fact_bill_billed_time_activity.dim_gl_date_key, fact_bill_billed_time_activity.dim_matter_header_curr_key, sum(fact_bill_billed_time_activity.minutes_recorded)/60 Billed_Hours
INTO #billed_hours
FROM red_dw.dbo.fact_bill_billed_time_activity
INNER JOIN #hr_rely_clients ON #hr_rely_clients.dim_client_key = fact_bill_billed_time_activity.dim_client_key

WHERE 1 = 1
	--AND dim_matter_header_current.master_client_code = 'W15481'
	--AND dim_matter_header_current.matter_number = '00000066'
	AND fact_bill_billed_time_activity.dim_gl_date_key >=  (SELECT MIN(#hr_rely_clients.dim_date_key) FROM #hr_rely_clients)
group BY fact_bill_billed_time_activity.dim_client_key, fact_bill_billed_time_activity.dim_gl_date_key
        , fact_bill_billed_time_activity.dim_matter_header_curr_key

--====================================================================================================================================================================

select fact_bill_activity.dim_gl_date_key, fact_bill_activity.dim_matter_header_curr_key, sum(fact_bill_activity.bill_amount) Revenue
INTO #revenue
FROM red_dw.dbo.fact_bill_activity
INNER JOIN #hr_rely_clients ON #hr_rely_clients.dim_client_key = fact_bill_activity.dim_client_key
WHERE fact_bill_activity.dim_gl_date_key >=  (SELECT MIN(#hr_rely_clients.dim_date_key) FROM #hr_rely_clients)
group by fact_bill_activity.dim_gl_date_key
        , fact_bill_activity.dim_matter_header_curr_key
--====================================================================================================================================================================



--select 
--		dim_matter_header_current.ms_fileid
--       , dim_fed_hierarchy_history.hierarchylevel4hist Department
--       , dim_matter_worktype.work_type_group 
--       , dim_matter_worktype.work_type_name
--       , dim_matter_header_current.master_client_code
--       , dim_matter_header_current.client_group_name
--	   , dim_matter_header_current.client_name
--       , dim_client.client_group_partner
--       , dim_client.sector
--       , dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number Weightmans_Ref
--	   , dim_matter_header_current.dim_matter_header_curr_key
--       , dim_matter_header_current.matter_description
--       , hr_rely_clients.start_date
--       , sum(CH.chargeable_hours) Chargeable_Hours
--       , sum(BH.Billed_Hours) Billed_Hours
--       , sum(Revenue) Revenue
--	   , SUM(CH.chargeable_hours_staff_cost_rate)	AS chargeable_hours_staff_cost_rate
--	   , SUM(CH.chargeable_hours_other_cost_rate)	AS chargeable_hours_other_cost_rate
--	   , SUM(CH.chargeable_hours_total_cost_rate)	AS chargeable_hours_total_cost_rate
--	   , SUM(CH.chargeable_hours_establishment_cost_rate)	AS chargeable_hours_establishment_cost_rate
SELECT 
	dim_matter_header_current.client_name
	, dim_matter_header_current.master_client_code
	, dim_matter_worktype.work_type_name
	, dim_client.sector
	, hr_rely_clients.start_date
	, ISNULL(sum(CH.chargeable_hours), 0) Chargeable_Hours
    , ISNULL(sum(BH.Billed_Hours), 0) Billed_Hours
    , ISNULL(sum(Revenue), 0) Revenue
	, ISNULL(SUM(CH.chargeable_hours_staff_cost_rate), 0)	AS chargeable_hours_staff_cost_rate
	, ISNULL(SUM(CH.chargeable_hours_other_cost_rate), 0)	AS chargeable_hours_other_cost_rate
	, ISNULL(SUM(CH.chargeable_hours_total_cost_rate), 0)	AS chargeable_hours_total_cost_rate
	, ISNULL(SUM(CH.chargeable_hours_establishment_cost_rate), 0)	AS chargeable_hours_establishment_cost_rate
from red_dw.dbo.dim_matter_header_current
INNER JOIN #hr_rely_clients hr_rely_clients
	ON hr_rely_clients.client_code = dim_matter_header_current.client_code
inner join red_dw.dbo.dim_client on dim_matter_header_current.client_code = dim_client.client_code
inner join red_dw.dbo.dim_matter_worktype on dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
inner join red_dw.dbo.fact_dimension_main on fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
--left outer join dbo.dim_detail_client on dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
left outer join red_dw.dbo.dim_date on dim_date.calendar_date >= hr_rely_clients.start_date and dim_date.calendar_date <= dateadd(yyyy, 1, hr_rely_clients.start_date)

left outer JOIN #chargeable_hours CH 
		ON CH.dim_orig_posting_date_key= dim_date.dim_date_key and CH.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

left outer join #billed_hours BH on BH.dim_gl_date_key = dim_date.dim_date_key and BH.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key

left outer join #revenue Revenue on Revenue.dim_gl_date_key = dim_date.dim_date_key and Revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--ensures only clients where work has been done on the hr rely matter during the time period
INNER JOIN (
			SELECT DISTINCT 
				dim_client.dim_client_key	
			FROM red_dw.dbo.dim_matter_header_current
				INNER JOIN red_dw.dbo.dim_detail_client
					ON dim_detail_client.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
				INNER JOIN red_dw.dbo.dim_client
					ON dim_client.client_code = dim_matter_header_current.client_code
				LEFT OUTER JOIN #billed_hours
					ON #billed_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
				LEFT OUTER JOIN #revenue
					ON #revenue.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
				LEFT OUTER JOIN #chargeable_hours	
					ON #chargeable_hours.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
			WHERE	
				dim_detail_client.start_date IS NOT NULL
				AND dim_matter_header_current.master_client_code <> '30645'
			GROUP BY	
				dim_client.dim_client_key
			HAVING	
				ISNULL(sum(#chargeable_hours.chargeable_hours), 0) + ISNULL(sum(#billed_hours.Billed_Hours), 0) + ISNULL(sum(#revenue.Revenue),0) >0
			) AS billed_rely_matters
	ON billed_rely_matters.dim_client_key = dim_client.dim_client_key

WHERE 1 = 1 
	AND RTRIM(dim_matter_worktype.work_type_group) = 'EPI'
	--AND dim_matter_header_current.master_client_code = 'W15483'
	--AND dim_detail_client.start_date is not null -- HR rely only clients
	--and dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number = 'W20265/7'          
	--and dim_matter_header_current.dim_matter_header_curr_key = 1352284
group by 
	--dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number
	--	, dim_matter_header_current.dim_matter_header_curr_key
 --      , dim_matter_header_current.ms_fileid
 --      , dim_fed_hierarchy_history.hierarchylevel4hist
 --      , dim_matter_worktype.work_type_group
 --      , dim_matter_worktype.work_type_name
 --      , dim_matter_header_current.master_client_code
 --      , dim_matter_header_current.client_group_name
	--   , dim_matter_header_current.client_name
 --      , dim_client.client_group_partner
 --      , dim_client.sector
 --      , dim_matter_header_current.matter_description
 --      , hr_rely_clients.start_date
	   dim_matter_header_current.client_name
	, dim_matter_header_current.master_client_code
	, dim_matter_worktype.work_type_name
	, dim_client.sector
	, hr_rely_clients.start_date
HAVING	
	ISNULL(sum(CH.chargeable_hours), 0) + ISNULL(sum(BH.Billed_Hours), 0) + ISNULL(sum(Revenue),0) >0
ORDER BY
	dim_matter_header_current.client_name




GO
