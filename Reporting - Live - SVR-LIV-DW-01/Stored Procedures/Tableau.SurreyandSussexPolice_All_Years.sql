SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2019-10-14
Description:		Sussex and Surrey MI to drive the Tableau Dashboards, all years
Current Version:	Initial Create
====================================================
-- ES 2020-05-06 Added new financial year requested by HW
-- ES 2021-06-16 Added DVPO victim postcode with longitudes and latitudes for dvpo map and additional dvpo details for filters on the map
-- ES 2021-06-18 Added policing priority field, joined to the work type lookup table
-- ES 2021-12-02 Amended logic to go back to 2016, requested by BH
====================================================

*/
CREATE PROCEDURE [Tableau].[SurreyandSussexPolice_All_Years]
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
, dim_detail_claim.borough AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations 
, fee_earner_code
, hierarchylevel4hist AS Team
,dbo.PoliceWorkTypes.GroupWorkTypeLookup
,dbo.PoliceWorkTypes.[Policing Priority]
--,bill_total AS [Total Billed to date]
--,fees_total as [Profit Costs to date]
,SUM(Billed.TotalBilled) AS [Total Billed]
,SUM(Billed.ProfitCostsBilled) AS [Profit Costs]
,SUM(Billed.[Disbursements]) AS Disbursements
,Time.[Hours Recorded] AS [HoursCharged]
--,Billed.Disbursementsincvat as [Disbursements Billed (1st April 16 - 31st March 17)]
,TFY [Financial Years]
, dim_detail_advice.dvpo_victim_postcode AS [DVPO Victim Postcode]
, CAST(CAST([DVPO_Victim_Postcode].Latitude AS FLOAT) AS DECIMAL(8,6)) AS [DVPO Victim Postcode Latitude]
, CAST(CAST([DVPO_Victim_Postcode].Longitude AS FLOAT) AS DECIMAL(9,6)) AS [DVPO Victim Postcode Longitude]
, dim_detail_advice.dvpo_number_of_children AS [DVPO Number of Children]
, dim_detail_advice.dvpo_division AS [DVPO Division]
, dim_detail_advice.dvpo_granted AS [DVPO Granted?]
, dim_detail_advice.dvpo_contested AS [DVPO Contested?]
, dim_detail_advice.dvpo_breached AS [DVPO Breached?]
, dim_detail_advice.dvpo_is_first_breach AS [DVPO is First Breach?]
, dim_detail_advice.dvpo_breach_admitted AS [DVPO Breach Admitted]
, dim_detail_advice.dvpo_breach_proved AS [DVPO Breach Proved?]
, dim_detail_advice.dvpo_breach_sentence AS [DVPO Breach Sentence]
, dim_detail_advice.dvpo_breach_sentence_length AS [DVPO Breach Sentence Length]
, dim_detail_advice.dvpo_legal_costs_sought AS [DVPO Legal Costs Sought?]
, dim_detail_advice.dvpo_court_fee_awarded AS [DVPO Court Fee Awarded?]
, dim_detail_advice.dvpo_own_fees_awarded AS [DVPO Own Fees Awarded?]
,[ClientOrder] = CASE WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END 
--into dbo.PoliceExtract
FROM red_dw..fact_dimension_main
LEFT JOIN red_dw..dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
LEFT JOIN red_dw..fact_bill_matter ON fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT JOIN reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.Doogal AS [DVPO_Victim_Postcode] ON [DVPO_Victim_Postcode].Postcode=dim_detail_advice.dvpo_victim_postcode

INNER JOIN 
       (           --select * from red_dw..fact_bill_matter_detail where client_code  = '00451638' and matter_number = '00000058'                  
              SELECT
              client_code
              ,dim_matter_header_curr_key
              ,matter_number
              ,SUM(bill_total) AS TotalBilled
              ,SUM(fees_total) AS ProfitCostsBilled
              ,SUM(hard_costs + soft_costs + other_costs ) AS [Disbursements]
              , CASE WHEN bill_date BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17'
					WHEN bill_date BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
					WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19'
					WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
					WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21'
					WHEN bill_date BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
					ELSE NULL END [TFY]
              FROM red_dw..fact_bill_matter_detail  
			  WHERE  bill_date BETWEEN DATEADD(MONTH,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-5,0)) AND DATEADD(MONTH,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
              AND  client_code IN ( '00451638','00113147') 
              --AND client_code='00451638' AND matter_number='00000190'
              GROUP BY CASE
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
                       WHEN bill_date
                       BETWEEN '2020-04-01' AND '2021-03-31' THEN
                       '2020/21'
                       WHEN bill_date
                       BETWEEN '2021-04-01' AND '2022-03-31' THEN
                       '2021/22'
					   ELSE
                       NULL
                       END,
                       client_code,
                       dim_matter_header_curr_key,
                       matter_number
              HAVING SUM(bill_total) <>0
       ) AS Billed

       ON fact_dimension_main.dim_matter_header_curr_key = Billed.dim_matter_header_curr_key

LEFT OUTER JOIN (SELECT client_code
					, matter_number
					, SUM(minutes_recorded)/60 AS [Hours Recorded]
					, CASE WHEN transaction_calendar_date BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17'
					WHEN transaction_calendar_date BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
					WHEN transaction_calendar_date BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19'
					WHEN transaction_calendar_date BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
					WHEN transaction_calendar_date BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21'
					WHEN transaction_calendar_date BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
					ELSE NULL END AS [FY]
				FROM red_dw.dbo.fact_all_time_activity
				INNER JOIN red_dw.dbo.dim_transaction_date
				ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
				AND transaction_calendar_date BETWEEN DATEADD(MONTH,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-5,0)) AND DATEADD(MONTH,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
				WHERE client_code IN ( '00451638','00113147') 
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
                         WHEN transaction_calendar_date
                         BETWEEN '2020-04-01' AND '2021-03-31' THEN
                         '2020/21'
                         WHEN transaction_calendar_date
                         BETWEEN '2021-04-01' AND '2022-03-31' THEN
                         '2021/22'


                         ELSE
                         NULL
                         END,
                         client_code,
                         matter_number
				) AS [Time] ON Time.client_code = fact_dimension_main.client_code
						 AND Time.matter_number = fact_dimension_main.matter_number
						 AND Time.FY=Billed.TFY

			  
WHERE 
dim_matter_header_current.client_code IN( '00451638','00113147') 
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
         CAST(CAST([DVPO_Victim_Postcode].Latitude AS FLOAT) AS DECIMAL(8, 6)),
         CAST(CAST([DVPO_Victim_Postcode].Longitude AS FLOAT) AS DECIMAL(9, 6)),
         fact_dimension_main.client_code,
         fact_dimension_main.matter_number,
         dim_matter_header_current.client_name,
         dim_matter_header_current.matter_description,
         dim_matter_header_current.matter_owner_full_name,
         dim_matter_header_current.date_opened_case_management,
         dim_matter_header_current.date_closed_case_management,
         dim_detail_claim.borough,
         dim_detail_claim.source_of_instruction,
         dim_detail_advice.surrey_police_stations,
         dim_matter_header_current.fee_earner_code,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         PoliceWorkTypes.GroupWorkTypeLookup,
		 dbo.PoliceWorkTypes.[Policing Priority],
         Time.[Hours Recorded],
         Billed.TFY,
         dim_detail_advice.dvpo_victim_postcode,
         dim_detail_advice.dvpo_number_of_children,
         dim_detail_advice.dvpo_division,
         dim_detail_advice.dvpo_granted,
         dim_detail_advice.dvpo_contested,
         dim_detail_advice.dvpo_breached,
         dim_detail_advice.dvpo_is_first_breach,
         dim_detail_advice.dvpo_breach_admitted,
         dim_detail_advice.dvpo_breach_proved,
         dim_detail_advice.dvpo_breach_sentence,
         dim_detail_advice.dvpo_breach_sentence_length,
         dim_detail_advice.dvpo_legal_costs_sought,
         dim_detail_advice.dvpo_court_fee_awarded,
         dim_detail_advice.dvpo_own_fees_awarded
		 ,CASE WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END 

END



GO
