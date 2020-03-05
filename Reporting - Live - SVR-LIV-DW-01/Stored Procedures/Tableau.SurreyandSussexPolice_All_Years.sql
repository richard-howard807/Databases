SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2019-10-14
Description:		Claims Division MI to drive the Tableau Dashboards, all years
Current Version:	Initial Create
====================================================
====================================================

*/
Create PROCEDURE [Tableau].[SurreyandSussexPolice_All_Years]
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
,SUM(Billed.TotalBilled) as [Total Billed]
,SUM(Billed.ProfitCostsBilled) as [Profit Costs]
,SUM(Billed.[Disbursements]) AS Disbursements
,Time.[Hours Recorded] AS [HoursCharged]
--,Billed.Disbursementsincvat as [Disbursements Billed (1st April 16 - 31st March 17)]
,TFY [Financial Years]

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
              , CASE WHEN bill_date BETWEEN '2016-04-01' and '2017-03-31' THEN '2016/17'
					WHEN bill_date BETWEEN '2017-04-01' and '2018-03-31' THEN '2017/18'
					WHEN bill_date BETWEEN '2018-04-01' and '2019-03-31' THEN '2018/19'
					WHEN bill_date BETWEEN '2019-04-01' and '2020-03-31' THEN '2019/20'
					ELSE NULL END [TFY]
              from red_dw..fact_bill_matter_detail  
			  WHERE  bill_date between DATEADD(month,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-3,0)) and DATEADD(month,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
              and  client_code in ( '00451638','00113147') 
              --AND client_code='00451638' AND matter_number='00000190'
              group BY CASE
                       WHEN bill_date
                       BETWEEN '2016-04-01' AND '2017-03-31' THEN
                       '2016/17'
                       WHEN bill_date
                       BETWEEN '2017-04-01' AND '2018-03-31' THEN
                       '2017/18'
                       WHEN bill_date
                       BETWEEN '2018-04-01' AND '2019-03-31' THEN
                       '2018/19'
                       WHEN bill_date
                       BETWEEN '2019-04-01' AND '2020-03-31' THEN
                       '2019/20'
                       ELSE
                       NULL
                       END,
                       client_code,
                       dim_matter_header_curr_key,
                       matter_number
              having sum(bill_total) <>0
       ) as Billed

       on fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT client_code
					, matter_number
					, SUM(minutes_recorded)/60 AS [Hours Recorded]
					, CASE WHEN transaction_calendar_date BETWEEN '2016-04-01' and '2017-03-31' THEN '2016/17'
					WHEN transaction_calendar_date BETWEEN '2017-04-01' and '2018-03-31' THEN '2017/18'
					WHEN transaction_calendar_date BETWEEN '2018-04-01' and '2019-03-31' THEN '2018/19'
					WHEN transaction_calendar_date BETWEEN '2019-04-01' and '2020-03-31' THEN '2019/20'
					ELSE NULL END AS [FY]
				FROM red_dw.dbo.fact_all_time_activity
				INNER JOIN red_dw.dbo.dim_transaction_date
				ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
				AND transaction_calendar_date BETWEEN DATEADD(month,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-3,0)) and DATEADD(month,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
				WHERE client_code in ( '00451638','00113147') 
				GROUP BY CASE
                         WHEN transaction_calendar_date
                         BETWEEN '2016-04-01' AND '2017-03-31' THEN
                         '2016/17'
                         WHEN transaction_calendar_date
                         BETWEEN '2017-04-01' AND '2018-03-31' THEN
                         '2017/18'
                         WHEN transaction_calendar_date
                         BETWEEN '2018-04-01' AND '2019-03-31' THEN
                         '2018/19'
                         WHEN transaction_calendar_date
                         BETWEEN '2019-04-01' AND '2020-03-31' THEN
                         '2019/20'
                         ELSE
                         NULL
                         END,
                         client_code,
                         matter_number
				) AS [Time] ON Time.client_code = fact_dimension_main.client_code
						 AND Time.matter_number = fact_dimension_main.matter_number
						 AND Time.FY=Billed.TFY

			  
WHERE 
dim_matter_header_current.client_code in( '00451638','00113147') 
--and date_opened_case_management >= '2016-03-19'
AND dim_matter_header_current.matter_number <>'ML'
--AND dim_matter_header_current.client_code='00451638'
--and dim_matter_header_current.matter_number = '00000190'

GROUP BY CASE
         WHEN work_type_name = 'PL - Pol - Disclosure' THEN
         'Disclosure'
         WHEN work_type_name = 'PL - Pol - Neighbourhood Policing Order' THEN
         'Neighbourhood Policing Order'
         WHEN work_type_name = 'PL - Pol - Operational Advice' THEN
         'Operational Advice'
         WHEN work_type_name = 'PL - Pol - DVPO/DVPN' THEN
         'DVPO'
         WHEN work_type_name = 'PL - Pol - Misconduct/Discipline' THEN
         'Misconduct/Discipline'
         WHEN work_type_name = 'PL - Pol - Data Deletion' THEN
         'Data Deletion'
         WHEN work_type_name = 'PL - Pol - FOI/DPA/SA' THEN
         'FOI/DPA/SA'
         WHEN work_type_name = 'PL - Pol - POCA' THEN
         'POCA'
         WHEN work_type_name = 'PL - Pol - Firearms Licensing' THEN
         'Firearms Licensing'
         WHEN work_type_name = 'Education - Policies and procedures' THEN
         'Education - Policies and procedures'
         WHEN work_type_name = 'PL - Pol - Licensing (Alcohol & Gaming)' THEN
         'Licensing (Alcohol & Gaming)'
         WHEN work_type_name = 'PL - Pol - Negligence' THEN
         'Negligence'
         WHEN work_type_name = 'PL - Pol - False Imprisonment' THEN
         'False Imprisonment'
         WHEN work_type_name = 'PL - Pol - Inquests' THEN
         'Inquests'
         WHEN work_type_name = 'PL - Pol - Trespass (Land and Goods)' THEN
         'Trespass (Land and Goods)'
         WHEN work_type_name = 'PL - Pol -Mal Proc Arrest/Search Warrant' THEN
         'Mal Proc Arrest/Search Warrant'
         WHEN work_type_name = 'PL - Pol - Conversion' THEN
         'Conversion'
         WHEN work_type_name = 'PL - Pol - Public Enquiries' THEN
         'Public Enquiries'
         WHEN work_type_name LIKE '%Discrimination%' THEN
         'Discrimination'
         ELSE
         work_type_name
         END,
         fact_dimension_main.client_code,
         fact_dimension_main.matter_number,
         client_name,
         matter_description,
         matter_owner_full_name,
         date_opened_case_management,
         date_closed_case_management,
         borough,
         source_of_instruction,
         surrey_police_stations,
         fee_earner_code,
         hierarchylevel4hist,
         GroupWorkTypeLookup,
         Time.[Hours Recorded],
         Billed.TFY

END



GO
