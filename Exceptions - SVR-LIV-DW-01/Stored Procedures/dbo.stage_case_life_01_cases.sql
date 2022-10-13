SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[stage_case_life_01_cases] as
truncate table stage_case_life_01_case
insert into stage_case_life_01_case
select 
ISNULL(case when c.client_group_name = '' then null else c.client_group_name end, 'Individual') as client_group,
m.client_code,
m.matter_number,
m.date_opened_practice_management as date_open,
m.date_closed_practice_management as date_closed,
fms.last_time_transaction_date,
fms.last_bill_date,
wt.work_type_name as 'work_type',
wtg.[group] as work_type_group,
isnull(fms.number_bills_matter, 0) num_bills

from
red_dw.dbo.fact_all_time_activity t

inner join red_dw.dbo.dim_matter_header_current m on t.dim_matter_header_curr_key = m.dim_matter_header_curr_key
inner join red_dw.dbo.fact_matter_summary_current fms on fms.dim_matter_header_curr_key = t.dim_matter_header_curr_key
inner join red_dw.dbo.dim_fed_hierarchy_history f on f.dim_fed_hierarchy_history_key = fms.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_date d on d.dim_date_key	= t.dim_transaction_date_key
inner join red_dw.dbo.dim_client c on c.dim_client_key = t.dim_client_key
inner join red_dw.dbo.dim_matter_worktype wt on wt.dim_matter_worktype_key = m.dim_matter_worktype_key
left join Reporting.dbo.work_type_group wtg on wtg.work_type = wt.work_type_name collate database_default

where
f.hierarchylevel3hist = 'Motor'
--and d.fin_year >= 2016
--and d.fin_year <= 2018
and m.date_opened_practice_management >= '2015-05-01' and m.date_opened_practice_management < '2018-05-01' 
and m.date_closed_practice_management is not null
--and isnull(c.client_group_name, 'Individual') in ('A S Watson group', 'Royal Mail', 'Punch Group', 'Co-operative insurance', 'Individual')
and isactive = 1
and t.reporting_exclusions = 0



group by 
ISNULL(case when c.client_group_name = '' then null else c.client_group_name end, 'Individual'),
m.client_code,
m.matter_number,
m.date_opened_practice_management,
m.date_closed_practice_management,
fms.last_time_transaction_date,
fms.last_bill_date,
wt.work_type_name,
wtg.[group],
isnull(fms.number_bills_matter, 0)

GO
