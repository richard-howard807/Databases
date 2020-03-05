SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[stage_case_life_01_times] as
truncate table stage_case_life_01_time
insert into stage_case_life_01_time
select 
ISNULL(c.client_group_name, 'Individual') as client_group,
m.client_code,
m.matter_number,
case when DATEDIFF(dd, m.date_opened_practice_management,  d.calendar_date) < 0 then 0
else DATEDIFF(dd, m.date_opened_practice_management,  d.calendar_date) end as 'time_days_elapsed',
sum(minutes_recorded) minutes_recorded

from
red_dw.dbo.fact_all_time_activity t

inner join red_dw.dbo.dim_matter_header_current m on t.dim_matter_header_curr_key = m.dim_matter_header_curr_key
inner join red_dw.dbo.fact_matter_summary_current fmsc on t.dim_matter_header_curr_key = fmsc.dim_matter_header_curr_key
inner join red_dw.dbo.dim_fed_hierarchy_history f on f.dim_fed_hierarchy_history_key = fmsc.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_date d on d.dim_date_key	= t.dim_transaction_date_key
inner join red_dw.dbo.dim_client c on c.dim_client_key = t.dim_client_key
inner join red_dw.dbo.dim_all_time_activity dt on dt.dim_all_time_activity_key = t.dim_all_time_activity_key

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
ISNULL(c.client_group_name, 'Individual'),
m.client_code,
m.matter_number,
DATEDIFF(dd, m.date_opened_practice_management,  d.calendar_date)
GO
