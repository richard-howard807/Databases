SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2018-06-05
Description:		Surrey and Sussex Police CURRENT POLICE FY MI to drive the Tableau Dashboards
Current Version:	Initial Create
====================================================
-- ES 11/02/2019 - changed date parameters to be dynamic over years
====================================================

*/
CREATE PROCEDURE [Tableau].[SurreyandSussexPolice_CURRENT_YEAR]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


select 
fact_dimension_main.client_code [Client Code]
, fact_dimension_main.matter_number [Matter Number]
, dim_matter_header_current.client_name AS [Client Name]
, matter_description AS [Matter Description]
, matter_owner_full_name AS [Matter Owner]
, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
, case when work_type_name = 'PL - Pol - Disclosure' then 'Disclosure' 
when work_type_name = 'PL - Pol - Neighbourhood Policing Order' then 'Neighbourhood Policing Order'
when work_type_name = 'PL - Pol - Operational Advice' then 'Operational Advice'
when work_type_name = 'PL - Pol - DVPO/DVPN' then 'DVPO'
when work_type_name = 'PL - Pol - Misconduct/Discipline' then 'Misconduct/Discipline'
when work_type_name = 'PL - Pol - Data Deletion' then 'Data Deletion'
when work_type_name = 'PL - Pol - FOI/DPA/SA' then 'FOI/DPA/SA'
when work_type_name = 'PL - Pol - POCA' then 'POCA'
when work_type_name = 'PL - Pol - Firearms Licensing' then 'Firearms Licensing'
when work_type_name = 'Education - Policies and procedures' then 'Education - Policies and procedures'
when work_type_name = 'PL - Pol - Licensing (Alcohol & Gaming)' then 'Licensing (Alcohol & Gaming)'
when work_type_name = 'PL - Pol - Negligence' then   'Negligence'                            
when work_type_name = 'PL - Pol - False Imprisonment' then 'False Imprisonment'
when work_type_name = 'PL - Pol - Inquests' then 'Inquests'
when work_type_name = 'PL - Pol - Trespass (Land and Goods)' then 'Trespass (Land and Goods)'
when work_type_name = 'PL - Pol -Mal Proc Arrest/Search Warrant' then 'Mal Proc Arrest/Search Warrant'
when work_type_name = 'PL - Pol - Conversion' then 'Conversion'
when work_type_name = 'PL - Pol - Public Enquiries' then 'Public Enquiries'
when work_type_name like '%Discrimination%' then 'Discrimination'
else work_type_name end AS [Work Type]
, dim_detail_claim.borough AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations 
, fee_earner_code
, hierarchylevel4hist AS Team
,dbo.PoliceWorkTypes.GroupWorkTypeLookup
--,bill_total AS [Total Billed to date]
--,fees_total as [Profit Costs to date]
,Billed.TotalBilled as [Total Billed]
,Billed.ProfitCostsBilled as [Profit Costs]
,Billed.[Disbursements] AS Disbursements
,tt.HoursCharged
--,Billed.Disbursementsincvat as [Disbursements Billed (1st April 16 - 31st March 17)]

--into dbo.PoliceExtract
from red_dw..fact_dimension_main
left join red_dw..dim_matter_header_current on fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
left join red_dw..dim_fed_hierarchy_history on dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code and dim_fed_hierarchy_history.dss_current_flag = 'Y'
left join red_dw..fact_bill_matter on fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
left join red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
left join red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
left join red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
left join reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT


inner join 
       (           --select * from red_dw..fact_bill_matter_detail where client_code  = '00451638' and matter_number = '00000058'                  
              select
              client_code
              ,dim_matter_header_curr_key
              ,matter_number
              ,sum(bill_total) as TotalBilled
              ,sum(fees_total) as ProfitCostsBilled
              ,sum(hard_costs + soft_costs + other_costs ) as [Disbursements]
              
              from red_dw..fact_bill_matter_detail  
			  where  bill_date between 
			  (select case when cal_month_no between 1 and 4 then 
				cast(cast(cal_year - 1 as varchar) + '-04-01'  as datetime)
				when cal_month_no between 5 and 12 then 
				cast(cast(cal_year as varchar) + '-04-01'  as datetime) end as startdate 
				from red_dw.dbo.dim_date
				where calendar_date = cast(getdate() - 1 as date)) 
				and 
				(select case when cal_month_no between 1 and 4 then 
				cast(cast(cal_year as varchar) + '-03-31'  as datetime)
				when cal_month_no between 5 and 12 then 
				cast(cast(cal_year + 1 as varchar) + '-03-31'  as datetime) end as enddate 
				from red_dw.dbo.dim_date
				where calendar_date = cast(getdate() - 1 as date)
				)
			  --DATEADD(month,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE()),0)) and DATEADD(month,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
              
			  and  client_code in ( '00451638','00113147') 
              
              group by 
              client_code,matter_number, dim_matter_header_curr_key 
              having sum(bill_total) <>0
       ) as Billed

       on fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key

left join (	  select   sum(minutes_recorded)/60 as HoursCharged, client_code, matter_number, master_fact_key, client_name --sum(minutes_recorded)/60
			  FROM red_dw.dbo.fact_chargeable_time_activity
			  left join red_dw.dbo.dim_transaction_date ON dim_transaction_date.dim_transaction_date_key = fact_chargeable_time_activity.dim_transaction_date_key
			  inner join red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
			  where client_code in  ('00451638','00113147') 
			  and dim_transaction_date.transaction_calendar_date  between 
			  (select case when cal_month_no between 1 and 4 then 
				cast(cast(cal_year - 1 as varchar) + '-04-01'  as datetime)
				when cal_month_no between 5 and 12 then 
				cast(cast(cal_year as varchar) + '-04-01'  as datetime) end as startdate 
				from red_dw.dbo.dim_date
				where calendar_date = cast(getdate() - 1 as date)) 
				and 
				(select case when cal_month_no between 1 and 4 then 
				cast(cast(cal_year as varchar) + '-03-31'  as datetime)
				when cal_month_no between 5 and 12 then 
				cast(cast(cal_year + 1 as varchar) + '-03-31'  as datetime) end as enddate 
				from red_dw.dbo.dim_date
				where calendar_date = cast(getdate() - 1 as date)
				)
			   Group by client_code, matter_number, master_fact_key, client_name  ) tt
	on tt.master_fact_key=fact_dimension_main.master_fact_key
WHERE 
dim_matter_header_current.client_code in( '00451638','00113147') 
--and date_opened_case_management >= '2016-03-19'
AND dim_matter_header_current.matter_number <>'ML'
--and dim_matter_header_current.matter_number = '00000129'
END



GO
