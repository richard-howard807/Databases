SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE proc [dbo].[stage_case_life_02_cases] as
truncate table stage_case_life_02
insert into stage_case_life_02

SELECT
c.client_group,
client_code,
matter_number,
date_open,
date_closed,
date_last_time_recorded,
date_last_bill,
work_type,
work_type_group,
d.calendar_date as time_recorded_date,
DATEDIFF(dd, date_open, d.calendar_date) time_days_elapsed,
num_bills

FROM stage_case_life_01_case c

CROSS JOIN (select calendar_date from red_dw.dbo.dim_date) d
where d.calendar_date >= c.date_open and d.calendar_date <= c.date_closed

GO
