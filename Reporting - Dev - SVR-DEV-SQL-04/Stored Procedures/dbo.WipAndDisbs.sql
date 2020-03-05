SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[WipAndDisbs] AS
DECLARE @FinMonth INT SET @FinMonth = 201812

SELECT  
fact_wip_monthly.dim_matter_header_history_key,
dim_fed_hierarchy_history.hierarchylevel2hist as 'business_line',
dim_fed_hierarchy_history.hierarchylevel3hist as 'practice_area',
dim_fed_hierarchy_history.hierarchylevel4hist as 'team',
dim_matter_header_history.client_code,
dim_matter_header_history.matter_number,
dim_matter_header_history.client_name,
dim_matter_header_history.matter_description,
dim_matter_header_history.matter_owner_full_name,
fact_matter_summary.costs_to_date,
last_bill_date,
case when dim_days_banding.daysbanding = '0 - 60 Days' then sum(wip_value)  end as '0 - 60 Days',
case when dim_days_banding.daysbanding = '61 - 90 Days' then sum(wip_value) end as '61 - 90 Days',
case when dim_days_banding.daysbanding = '91 - 180 Days' then sum(wip_value) end as '91 - 180 Days',
case when dim_days_banding.daysbanding = '181 - 270 Days' then sum(wip_value) end as '181 - 270 Days',
case when dim_days_banding.daysbanding = '271 - 360 Days' then sum(wip_value) end as '271 - 360 Days',
case when dim_days_banding.daysbanding = '361 - 720 Days' then sum(wip_value) end as '361 - 720 Days',
case when dim_days_banding.daysbanding = 'Greater than 720 Days' then sum(wip_value) end as 'Greater than 720 Days',
case when dim_days_banding.daysbanding = '<0 Days' then sum(wip_value) end as  '<0 Days',
SUM(wip_value) AS wip_value,
dim_matter_header_history.fixed_fee,
dim_matter_header_history.fixed_fee_amount,
fact_wip_monthly.fee_earner_code,
dim_detail_finance.output_wip_fee_arrangement,
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
							 and fin_month = @FinMonth
left join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary.dim_fed_hierarchy_history_key

where 
wip_month = @FinMonth

group by
fact_wip_monthly.dim_matter_header_history_key,
dim_fed_hierarchy_history.hierarchylevel2hist,
dim_fed_hierarchy_history.hierarchylevel3hist,
dim_fed_hierarchy_history.hierarchylevel4hist,
dim_matter_header_history.dim_mat_head_history_key,
dim_matter_header_history.client_code,
dim_matter_header_history.matter_number,
dim_matter_header_history.client_name,
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
t.matter_description,
t.matter_owner_full_name,
t.costs_to_date,
last_bill_date,
sum([0 - 60 Days]) as [0 - 60 Days],
sum([61 - 90 Days]) as [61 - 90 Days],
sum([91 - 180 Days]) as [91 - 180 Days],
sum([181 - 270 Days]) as [181 - 270 Days],
sum([271 - 360 Days]) as [271 - 360 Days],
sum([361 - 720 Days]) as [361 - 720 Days],
sum([Greater than 720 Days]) as [Greater than 720 Days],
sum([<0 Days]) as [<0 Days],

isnull(sum([0 - 60 Days]), 0) +
isnull(sum([61 - 90 Days]), 0) +
isnull(sum([91 - 180 Days]), 0) +
isnull(sum([181 - 270 Days]), 0) +
isnull(sum([271 - 360 Days]), 0) +
isnull(sum([361 - 720 Days]), 0) +
isnull(sum([Greater than 720 Days]), 0) +
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
t.client_name,
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
fact_matter_summary.matter_number, 
matter_description,
disbursement_balance,
fact_matter_summary.costs_to_date,
last_bill_date,
matter_owner_full_name,
dim_fed_hierarchy_history.hierarchylevel2hist as 'business_line',
dim_fed_hierarchy_history.hierarchylevel3hist as 'practice_area',
dim_fed_hierarchy_history.hierarchylevel4hist as 'team'

INTO #disbs 

FROM
red_dw.dbo.fact_matter_summary 
left join red_dw.dbo.dim_matter_header_history on dim_matter_header_history.dim_mat_head_history_key = fact_matter_summary .dim_matter_header_history_key
left join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_matter_summary.dim_fed_hierarchy_history_key
WHERE 
fin_month = @FinMonth
AND (ISNULL(disbursement_balance, 0) <> 0 OR ISNULL(wip_balance, 0) <> 0)







SELECT COALESCE(w.dim_matter_header_history_key, d.dim_matter_header_history_key) AS 'dim_matter_header_history_key_c', 
COALESCE(w.client_code, d.client_code) AS 'client_code_c',
COALESCE(w.matter_number, d.matter_number) AS 'matteR_number_c',
COALESCE(w.matter_description, d.matter_description) AS 'matteR_description_c',
COALESCE(w.matter_owner_full_name, d.matter_owner_full_name) AS 'matteR_owner_full_name_c',
COALESCE(w.costs_to_date, d.costs_to_date) AS 'costs_to_date_c',
COALESCE(w.last_bill_date, d.last_bill_date) AS 'last_bill_date_c',
COALESCE(w.business_line, d.business_line) AS 'business_line_c',
COALESCE(w.practice_area, d.practice_area) AS 'practice_area_c',
COALESCE(w.team, d.team) AS 'team_c',

w.*, d.disbursement_balance 
INTO #joined
FROM #disbs  d
left JOIN #wip w ON d.dim_matter_header_history_key = w.dim_matter_header_history_key

--INSERT INTO #joined 

--SELECT *, 0 FROM #wip WHERE dim_matter_header_history_key NOT IN (
--SELECT DISTINCT dim_matter_header_history_key FROM #disbs)

/*
--checks 
--DECLARE @FinMonth INT SET @FinMonth = 201712
SELECT SUM([Total Wip]) FROM #joined
SELECT SUM(wip_value) FROM fact_wip_monthly WHERE wip_month = @FinMonth
SELECT SUM(disbursement_balance) FROM #joined
SELECT SUM(disbursement_balance) FROM dbo.fact_matter_summary WHERE fin_month = @FinMonth
*/

SELECT * FROM #joined

DROP TABLE #wip
DROP TABLE #disbs
DROP TABLE #joined




GO
