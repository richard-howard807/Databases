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
-- ES 2022-04-04 #141849, added suffolk police
====================================================

*/
CREATE PROCEDURE [Tableau].[SurreyandSussexPolice_CURRENT_YEAR]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED


SELECT 
fact_dimension_main.client_code [Client Code]
, fact_dimension_main.matter_number [Matter Number]
, dim_matter_header_current.client_name AS [Client Name]
, matter_description AS [Matter Description]
, matter_owner_full_name AS [Matter Owner]
, dim_matter_header_current.date_opened_case_management AS [Date Case Opened]
, dim_matter_header_current.date_closed_case_management AS [Date Case Closed]
, CASE WHEN work_type_name = 'PL - Pol - Disclosure' THEN 'Disclosure' 
WHEN work_type_name = 'PL - Pol - Neighbourhood Policing Order' THEN 'Neighbourhood Policing Order'
WHEN work_type_name = 'PL - Pol - Operational Advice' THEN 'Operational Advice'
WHEN work_type_name = 'PL - Pol - DVPO/DVPN' THEN 'DVPO'
WHEN work_type_name = 'PL - Pol - Misconduct/Discipline' THEN 'Misconduct/Discipline'
WHEN work_type_name = 'PL - Pol - Data Deletion' THEN 'Data Deletion'
WHEN work_type_name = 'PL - Pol - FOI/DPA/SA' THEN 'FOI/DPA/SA'
WHEN work_type_name = 'PL - Pol - POCA' THEN 'POCA'
WHEN work_type_name = 'PL - Pol - Firearms Licensing' THEN 'Firearms Licensing'
WHEN work_type_name = 'Education - Policies and procedures' THEN 'Education - Policies and procedures'
WHEN work_type_name = 'PL - Pol - Licensing (Alcohol & Gaming)' THEN 'Licensing (Alcohol & Gaming)'
WHEN work_type_name = 'PL - Pol - Negligence' THEN   'Negligence'                            
WHEN work_type_name = 'PL - Pol - False Imprisonment' THEN 'False Imprisonment'
WHEN work_type_name = 'PL - Pol - Inquests' THEN 'Inquests'
WHEN work_type_name = 'PL - Pol - Trespass (Land and Goods)' THEN 'Trespass (Land and Goods)'
WHEN work_type_name = 'PL - Pol -Mal Proc Arrest/Search Warrant' THEN 'Mal Proc Arrest/Search Warrant'
WHEN work_type_name = 'PL - Pol - Conversion' THEN 'Conversion'
WHEN work_type_name = 'PL - Pol - Public Enquiries' THEN 'Public Enquiries'
WHEN work_type_name LIKE '%Discrimination%' THEN 'Discrimination'
ELSE work_type_name END AS [Work Type]
, ISNULL(dim_detail_claim.borough, dim_detail_claim.district) AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations 
, fee_earner_code
, hierarchylevel4hist AS Team
,dbo.PoliceWorkTypes.GroupWorkTypeLookup
--,bill_total AS [Total Billed to date]
--,fees_total as [Profit Costs to date]
,Billed.TotalBilled AS [Total Billed]
,Billed.ProfitCostsBilled AS [Profit Costs]
,Billed.[Disbursements] AS Disbursements
,tt.HoursCharged
--,Billed.Disbursementsincvat as [Disbursements Billed (1st April 16 - 31st March 17)]

--into dbo.PoliceExtract
FROM red_dw..fact_dimension_main
LEFT JOIN red_dw..dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
LEFT JOIN red_dw..fact_bill_matter ON fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT JOIN reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT


INNER JOIN 
       (           --select * from red_dw..fact_bill_matter_detail where client_code  = '00451638' and matter_number = '00000058'                  
              SELECT
              client_code
              ,dim_matter_header_curr_key
              ,matter_number
              ,SUM(bill_total) AS TotalBilled
              ,SUM(fees_total) AS ProfitCostsBilled
              ,SUM(hard_costs + soft_costs + other_costs ) AS [Disbursements]
              
              FROM red_dw..fact_bill_matter_detail  
			  WHERE  bill_date BETWEEN 
			  (SELECT CASE WHEN cal_month_no BETWEEN 1 AND 4 THEN 
				CAST(CAST(cal_year - 1 AS VARCHAR) + '-04-01'  AS DATETIME)
				WHEN cal_month_no BETWEEN 5 AND 12 THEN 
				CAST(CAST(cal_year AS VARCHAR) + '-04-01'  AS DATETIME) END AS startdate 
				FROM red_dw.dbo.dim_date
				WHERE calendar_date = CAST(GETDATE() - 1 AS DATE)) 
				AND 
				(SELECT CASE WHEN cal_month_no BETWEEN 1 AND 4 THEN 
				CAST(CAST(cal_year AS VARCHAR) + '-03-31'  AS DATETIME)
				WHEN cal_month_no BETWEEN 5 AND 12 THEN 
				CAST(CAST(cal_year + 1 AS VARCHAR) + '-03-31'  AS DATETIME) END AS enddate 
				FROM red_dw.dbo.dim_date
				WHERE calendar_date = CAST(GETDATE() - 1 AS DATE)
				)
			  --DATEADD(month,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE()),0)) and DATEADD(month,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
              
			  AND  client_code IN ( '00451638','00113147','00817395') 
              
              GROUP BY 
              client_code,matter_number, dim_matter_header_curr_key 
              HAVING SUM(bill_total) <>0
       ) AS Billed

       ON fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key

LEFT JOIN (	  SELECT   SUM(minutes_recorded)/60 AS HoursCharged, client_code, matter_number, master_fact_key, client_name --sum(minutes_recorded)/60
			  FROM red_dw.dbo.fact_chargeable_time_activity
			  LEFT JOIN red_dw.dbo.dim_transaction_date ON dim_transaction_date.dim_transaction_date_key = fact_chargeable_time_activity.dim_transaction_date_key
			  INNER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_chargeable_time_activity.dim_matter_header_curr_key
			  WHERE client_code IN  ('00451638','00113147','00817395') 
			  AND dim_transaction_date.transaction_calendar_date  BETWEEN 
			  (SELECT CASE WHEN cal_month_no BETWEEN 1 AND 4 THEN 
				CAST(CAST(cal_year - 1 AS VARCHAR) + '-04-01'  AS DATETIME)
				WHEN cal_month_no BETWEEN 5 AND 12 THEN 
				CAST(CAST(cal_year AS VARCHAR) + '-04-01'  AS DATETIME) END AS startdate 
				FROM red_dw.dbo.dim_date
				WHERE calendar_date = CAST(GETDATE() - 1 AS DATE)) 
				AND 
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
dim_matter_header_current.client_code in( '00451638','00113147','00817395') 
--and date_opened_case_management >= '2016-03-19'
AND dim_matter_header_current.matter_number <>'ML'
--and dim_matter_header_current.matter_number = '00000129'
END



GO
