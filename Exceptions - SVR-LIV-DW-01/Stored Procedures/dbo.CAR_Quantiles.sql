SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [dbo].[CAR_Quantiles] as

select
rtrim(fact_dimension_main.client_code) + '-' + fact_dimension_main.matter_number as 'matter',
year(dim_detail_outcome.date_claim_concluded) as 'year',
dim_matter_worktype.work_type_group,
fact_detail_reserve_detail.damages_reserve

from
red_dw.dbo.fact_dimension_main

inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
inner join red_dw.dbo.dim_detail_outcome on dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
inner join red_dw.dbo.dim_matter_header_current on dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
inner join red_dw.dbo.dim_matter_worktype on dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
inner join red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
inner join red_dw.dbo.dim_client on dim_client.dim_client_key = fact_dimension_main.dim_client_key
inner join red_dw.dbo.fact_detail_reserve_detail on fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
inner join red_dw.dbo.fact_detail_elapsed_days on fact_detail_elapsed_days.master_fact_key = fact_dimension_main.master_fact_key
inner join red_dw.dbo.dim_detail_core_details on dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_outcome_key
inner join red_dw.dbo.dim_employee on dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key

where 
hierarchylevel2hist = 'Legal Ops - Claims'
and dim_detail_outcome.date_claim_concluded >= '2017-01-01'
and isnull(dim_detail_outcome.date_claim_concluded, getdate()) <= getdate() --lots of bad data i.e. closed in the year 5072
and dim_matter_worktype.work_type_code != '0032'
and exclude_from_reports = 0
and datediff(day, date_opened_case_management, date_claim_concluded) >= 0
and lower(dim_detail_outcome.outcome_of_case) not in ('exclude from reports', 'returned to client')
and isnull(dim_fed_hierarchy_history.jobtitle, '') != ''
and fact_detail_reserve_detail.damages_reserve is not null
GO
