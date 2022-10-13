SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[stage_case_life_03] as
truncate table case_life
insert into case_life

select 
stage_case_life_02.client_group,
stage_case_life_02.client_code,
stage_case_life_02.matter_number,
stage_case_life_02.client_code + '-' + stage_case_life_02.matter_number as client_matter,
stage_case_life_02.date_open,
stage_case_life_02.date_closed,
stage_case_life_02.date_last_time_recorded,
stage_case_life_02.work_type,
stage_case_life_02.work_type_group,
stage_case_life_02.time_recorded_date,
stage_case_life_02.date_last_bill,
stage_case_life_02.time_days_elapsed,
num_bills,
ISNULL(stage_case_life_01_time.minutes_recorded, 0) minutes_recorded

from 
stage_case_life_02

left join stage_case_life_01_time on stage_case_life_01_time.client_code = stage_case_life_02.client_code 
								 and stage_case_life_01_time.matter_number = stage_case_life_02.matter_number
								 and stage_case_life_01_time.time_days_elapsed = stage_case_life_02.time_days_elapsed 

		 
GO
