SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[WipAndDisbs] @FinMonth VARCHAR(50) 

as

/*
RH 21-07-2020 - Fixed Fee arrangmentent on files with no WIP

*/

--DECLARE  @FinMonth VARCHAR(20) = '2021-03 (Jul-2020)'

--[dbo].[WipAndDisbs] '2019-07 (Nov-2018)'


SELECT  
fact_wip_monthly.dim_matter_header_history_key,
dim_fed_hierarchy_history.hierarchylevel2hist as 'business_line',
dim_fed_hierarchy_history.hierarchylevel3hist as 'practice_area',
dim_fed_hierarchy_history.hierarchylevel4hist as 'team',
dim_matter_header_history.client_code,
dim_matter_header_history.matter_number,
dim_matter_header_history.master_client_code + '-' + dim_matter_header_history.master_matter_number as '3e_matter_number',
dim_matter_header_history.client_name,
segment,
sector,
dim_matter_header_history.matter_description,
dim_matter_header_history.matter_owner_full_name,
fact_matter_summary.costs_to_date,
last_bill_date,
case when dim_days_banding.daysbanding = '0 - 30 Days' then sum(wip_value)  end as '0 - 30 Days',
case when dim_days_banding.daysbanding = '31 - 90 days' then sum(wip_value) end as '31 - 90 days',
case when dim_days_banding.daysbanding = 'Greater than 90 Days' then sum(wip_value) end as 'Greater than 90 Days',
case when dim_days_banding.daysbanding = '<0 Days' then sum(wip_value) end as  '<0 Days',
SUM(wip_value) AS wip_value,
dim_matter_header_history.fixed_fee,
dim_matter_header_history.fixed_fee_amount,
fact_wip_monthly.fee_earner_code,
output_wip_fee_arrangement AS output_wip_fee_arrangement,
--fact_finance_summary.fixed_fee_amount,
dim_detail_finance.output_wip_percentage_complete

into #temp

from
red_dw.dbo.fact_wip_monthly

left join red_dw.dbo.fact_dimension_main on fact_dimension_main.master_fact_key = fact_wip_monthly.master_fact_key
left join red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
left join red_dw.dbo.dim_detail_finance on dim_detail_finance.dim_detail_finance_key = fact_dimension_main.dim_detail_finance_key
left join red_dw.dbo.dim_matter_header_history on dim_matter_header_history.dim_mat_head_history_key = fact_wip_monthly.dim_matter_header_history_key
left join red_dw.dbo.dim_days_banding on dim_days_banding.dim_days_banding_key = fact_wip_monthly.dim_days_banding_key
LEFT join red_dw.dbo.fact_matter_summary on fact_matter_summary.client_code = dim_matter_header_history.client_code 
							 AND fact_matter_summary.matter_number = dim_matter_header_history.matter_number 
							 and fin_month = (select  fin_month from red_dw.dbo.dim_date
												WHERE fin_period =@FinMonth
												AND fin_day_in_month = 1)
left join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
where 
--wip_month = @FinMonth
 wip_month=(select  fin_month from red_dw.dbo.dim_date
				WHERE fin_period =@FinMonth
				AND fin_day_in_month = 1)
group by
fact_wip_monthly.dim_matter_header_history_key,
dim_fed_hierarchy_history.hierarchylevel2hist,
dim_fed_hierarchy_history.hierarchylevel3hist,
dim_fed_hierarchy_history.hierarchylevel4hist,
dim_matter_header_history.dim_mat_head_history_key,
dim_matter_header_history.client_code,
dim_matter_header_history.matter_number,
dim_matter_header_history.master_client_code + '-' + dim_matter_header_history.master_matter_number,
dim_matter_header_history.client_name,
segment,
sector,
dim_matter_header_history.matter_description,
dim_matter_header_history.matter_owner_full_name,
fact_matter_summary.costs_to_date,
dim_matter_header_history.fixed_fee,
dim_matter_header_history.fixed_fee_amount,
dim_days_banding.daysbanding,
last_bill_date,
fact_wip_monthly.fee_earner_code,
dim_detail_finance.output_wip_fee_arrangement,
dim_detail_finance.output_wip_percentage_complete



select 
t.dim_matter_header_history_key,
business_line,
practice_area,
team,
t.client_code,
t.matter_number,
t.client_name,
t.segment,
t.sector,
t.[3e_matter_number],
t.matter_description,
t.matter_owner_full_name,
t.costs_to_date,
last_bill_date,
sum([0 - 30 Days]) as [0 - 30 Days],
sum([31 - 90 days]) as [31 - 90 days],
sum([Greater than 90 Days]) as [Greater than 90 Days],
sum([<0 Days]) as [<0 Days],

isnull(sum([0 - 30 Days]), 0) +
isnull(sum([31 - 90 days]), 0) +
isnull(sum([Greater than 90 Days]), 0) +
isnull(sum([<0 Days]) , 0) as [Total Wip],

fixed_fee,
fixed_fee_amount,
fee_earner_code,
output_wip_fee_arrangement,
output_wip_percentage_complete

INTO #wip
from #temp t

group BY
t.dim_matter_header_history_key,
business_line,
practice_area,
team,
t.client_code,
t.matter_number,
t.[3e_matter_number],
t.client_name,
t.segment,
t.sector,
t.matter_description,
t.matter_owner_full_name,
t.costs_to_date,
fixed_fee,
fixed_fee_amount,
last_bill_date,
fee_earner_code,
output_wip_fee_arrangement,
output_wip_percentage_complete

drop table #temp

SELECT
dim_matter_header_history_key,
fact_matter_summary.client_code,
dim_matter_header_history.client_name,
segment,
sector,
fact_matter_summary.matter_number, 
dim_matter_header_history.master_client_code + '-' + dim_matter_header_history.master_matter_number as '3e_matter_number',
matter_description,
disbursement_balance,
fact_matter_summary.costs_to_date,
last_bill_date,
matter_owner_full_name,
dim_fed_hierarchy_history.hierarchylevel2hist as 'business_line',
dim_fed_hierarchy_history.hierarchylevel3hist as 'practice_area',
dim_fed_hierarchy_history.hierarchylevel4hist as 'team',
output_wip_fee_arrangement AS output_wip_fee_arrangement,
fixed_fee,
fixed_fee_amount

INTO #disbs 

FROM
red_dw.dbo.fact_matter_summary 
left join red_dw.dbo.dim_matter_header_history on dim_matter_header_history.dim_mat_head_history_key = fact_matter_summary .dim_matter_header_history_key
left join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_matter_summary.dim_client_key
left join red_dw.dbo.dim_detail_finance on dim_detail_finance.client_code = fact_matter_summary.client_code AND  dim_detail_finance.matter_number = fact_matter_summary.matter_number
WHERE 
fin_month =(select  fin_month from red_dw.dbo.dim_date
				WHERE fin_period =@FinMonth
				AND fin_day_in_month = 1)
AND (ISNULL(disbursement_balance, 0) <> 0 OR ISNULL(wip_balance, 0) <> 0)





SELECT COALESCE(w.dim_matter_header_history_key, d.dim_matter_header_history_key) AS 'dim_matter_header_history_key_c', 
COALESCE(w.client_code, d.client_code) AS 'client_code_c',
COALESCE(w.client_name, d.client_name) AS 'client_name_c',
COALESCE(w.segment, d.segment) AS 'segment_c',
COALESCE(w.sector, d.sector) AS 'sector_c',
COALESCE(w.matter_number, d.matter_number) AS 'matter_number_c',
COALESCE(w.[3e_matter_number], d.[3e_matter_number]) AS '3e_matter_number_c',
COALESCE(w.matter_description, d.matter_description) AS 'matter_description_c',
COALESCE(w.matter_owner_full_name, d.matter_owner_full_name) AS 'matter_owner_full_name_c',
COALESCE(w.costs_to_date, d.costs_to_date) AS 'costs_to_date_c',
COALESCE(w.last_bill_date, d.last_bill_date) AS 'last_bill_date_c',
COALESCE(w.business_line, d.business_line) AS 'business_line_c',
COALESCE(w.practice_area, d.practice_area) AS 'practice_area_c',
COALESCE(w.team, d.team) AS 'team_c',
COALESCE(w.output_wip_fee_arrangement, d.output_wip_fee_arrangement) output_wip_fee_arrangement,
w.dim_matter_header_history_key,
w.business_line,
w.practice_area,
w.team,
w.client_code,
w.matter_number,
w.client_name,
w.segment,
w.sector,
w.[3e_matter_number],
w.matter_description,
w.matter_owner_full_name,
w.costs_to_date,
w.last_bill_date,
w.[0 - 30 Days],
w.[31 - 90 days],
w.[Greater than 90 Days],
w.[<0 Days],
w.[Total Wip],
COALESCE(w.fixed_fee, d.fixed_fee) fixed_fee,
COALESCE(w.fixed_fee_amount, d.fixed_fee_amount) fixed_fee_amount,
w.fee_earner_code,
w.output_wip_percentage_complete, d.disbursement_balance 
INTO #joined
FROM #disbs  d
left JOIN #wip w ON d.dim_matter_header_history_key = w.dim_matter_header_history_key




SELECT 
client_code_c [Client],
matter_number_c [Matter],
[3e_matter_number_c] [3e Matter Number],
client_name_c [Client Name],
segment_c [Segment],
sector_c [Sector],
matter_description_c [Matter Desc],
business_line_c [Division],
practice_area_c [Department],
team_c [Team],
matter_owner_full_name_c [Matter Owner],
last_bill_date_c [Last Bill Date],
SUM(ISNULL([0 - 30 Days], 0)) [0 - 30 Days],
SUM(ISNULL([31 - 90 days], 0)) [31 - 90 days],
SUM(ISNULL([Greater than 90 Days], 0)) [Greater than 90 Days],
SUM(ISNULL([<0 Days], 0)) [<0 Days],
SUM(ISNULL([Total Wip], 0)) [Total Wip],
MAX(ISNULL(disbursement_balance, 0)) [Disb Balance],
MAX(ISNULL(costs_to_date_c, 0)) [Revenue],
output_wip_fee_arrangement [Fee Arrangement],
MAX(fixed_fee_amount) AS [Fixed Fee Amount],
output_wip_percentage_complete [Percentage Complete]

FROM #joined

GROUP BY
client_code_c,
matter_number_c,
[3e_matter_number_c],
client_name_c,
segment_c,
sector_c,
matter_description_c,
business_line_c,
practice_area_c,
team_c,
matter_owner_full_name_c,
last_bill_date_c,
output_wip_fee_arrangement,
output_wip_percentage_complete

DROP TABLE #wip
DROP TABLE #disbs
DROP TABLE #joined




GO
GRANT EXECUTE ON  [dbo].[WipAndDisbs] TO [SBC\rmccab]
GO
GRANT EXECUTE ON  [dbo].[WipAndDisbs] TO [SBC\SQL - FinanceSystems]
GO
