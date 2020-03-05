SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create proc [SBC\sparke01].[mcs_by_client] as

declare @Client varchar(500)
declare @Simulations int 
declare @Weeks int

set @Client = 'Royal & Sun Alliance'
set @Simulations = 500
set @Weeks = 52

declare @tbl_Week table ([week] int)
insert into @tbl_Week ([week])

--weeks
SELECT DISTINCT number
FROM master..spt_values
WHERE number BETWEEN 1 AND @Weeks

declare @tbl_Matters table ([matter] int)
insert into @tbl_Matters ([matter])

--matters
SELECT DISTINCT number
FROM master..spt_values
WHERE number BETWEEN 1 AND @Simulations

-- joined
declare @tbl_Joined table ([matter] int, [week] int)
insert into @tbl_Joined ([matter], [week])
select [matter], [week] from @tbl_Matters, @tbl_Week

--matter count
declare @MatterCount decimal(10,2) 
set @MatterCount = (

select 
count(distinct fact_dimension_main.master_fact_key) as 'total_matters_in_period' 
from red_dw.dbo.fact_dimension_main 
inner join red_dw.dbo.dim_date dim_open_date on dim_open_date.dim_date_key = fact_dimension_main.dim_open_practice_management_date_key 
inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key 
inner join red_dw.dbo.dim_client on dim_client.dim_client_key = fact_dimension_main.dim_client_key 
where hierarchylevel2hist = 'Legal Ops - Claims' 
and dim_open_date.calendar_date >= '2015-05-01' and dim_open_date.calendar_date < '2017-05-01' 
and dim_client.client_group_name = 'Royal & Sun Alliance'
)

declare @tbl_Prob table ([week] int , [prob] decimal(10,2), [mean] int, [stdev] int) 
insert into @tbl_Prob ([week], [prob], [mean], [stdev])


--main 
select 
datediff(dd, dim_open_date.calendar_date, dim_bill_date.calendar_date) / 7 as 'week_after_opened', 
count(fact_bill_activity.bill_amount) / @MatterCount 'prob_of_bill',
AVG(fact_bill_activity.bill_amount) as 'mean',
STDEV(fact_bill_activity.bill_amount) as 'stdev'

from
red_dw.dbo.fact_dimension_main 

left join red_dw.dbo.fact_bill_activity on fact_dimension_main.master_fact_key = fact_bill_activity.master_fact_key  
inner join red_dw.dbo.fact_finance_summary on fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key 
left join red_dw.dbo.dim_date dim_bill_date on dim_bill_date.dim_date_key = fact_bill_activity.dim_bill_date_key 
inner join red_dw.dbo.dim_date dim_open_date on dim_open_date.dim_date_key = fact_dimension_main.dim_open_practice_management_date_key 
inner join red_dw.dbo.dim_fed_hierarchy_history on dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key 
inner join red_dw.dbo.dim_detail_outcome on dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key 
inner join red_dw.dbo.dim_client on dim_client.dim_client_key = fact_dimension_main.dim_client_key 
where hierarchylevel2hist = 'Legal Ops - Claims' 
and dim_open_date.calendar_date >= '2015-05-01' and dim_open_date.calendar_date < '2017-05-01' 
and fact_bill_activity.bill_amount between -10000 and 10000 
and datediff(dd, dim_open_date.calendar_date, dim_bill_date.calendar_date) / 7 <= 104
and dim_client.client_group_name = 'Royal & Sun Alliance'

group by 
datediff(dd, dim_open_date.calendar_date, dim_bill_date.calendar_date) / 7

order by 1


select j.[matter], j.[week], 
isnull(p.[prob], 0) as 'prob', 
isnull(p.[mean], 0) as 'mean', 
isnull(p.[stdev], 0) as 'stdev' 

from @tbl_Joined j
left join @tbl_Prob p on j.[week] = p.[week]
GO
