SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


/*
===================================================
===================================================
Author:				Emily Smith
Created Date:		2022-02-03
Description:		Sussex and Surrey MI to drive the Tableau Dashboards, all years
Current Version:	amended previous version as it was duplicating matters based on the financial years
====================================================
--ES 2022-04-04 #141849, added suffolk police
====================================================

*/
CREATE PROCEDURE [Tableau].[SurreyandSussexPolice_All_Years_v2]
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
ELSE work_type_name END AS [Matter Type]
, ISNULL(dim_detail_claim.borough, dim_detail_claim.district) AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations [Police Stations]
, fee_earner_code AS [FEE Eraner Code]
, hierarchylevel4hist AS Team
,ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup,'Other') AS [Matter Type Group]
,dbo.PoliceWorkTypes.[Policing Priority]
,total_amount_bill_non_comp AS [Total Billed]
,fact_finance_summary.defence_costs_billed AS [Revenue]
,fact_finance_summary.disbursements_billed AS Disbursements
,fact_finance_summary.chargeable_minutes_recorded/60 AS [Hours Recorded]
, CASE 	WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
		WHEN CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23'
	ELSE NULL  END AS [Financial Years]
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
,[ClientOrder] = CASE WHEN client_name = 'Suffolk Constabulary' THEN 3
		WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END 
, 'Matter' AS [Level]


FROM red_dw..fact_dimension_main
LEFT JOIN red_dw..dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
--LEFT JOIN red_dw..fact_bill_matter ON fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.Doogal AS [DVPO_Victim_Postcode] ON [DVPO_Victim_Postcode].Postcode=dim_detail_advice.dvpo_victim_postcode
			  
WHERE 
dim_matter_header_current.client_code IN( '00451638','00113147','00817395') 
AND dim_matter_header_current.matter_number <>'ML'
AND CAST(dim_matter_header_current.date_opened_case_management AS DATE) BETWEEN DATEADD(MONTH,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-5,0)) AND DATEADD(MONTH,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
--AND dim_matter_header_current.client_code='00113147'
--and dim_matter_header_current.matter_number = '00000267'
--AND (ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup,'Other') ='Other'
--OR PoliceWorkTypes.[Policing Priority] IS NULL)


UNION

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
ELSE work_type_name END AS [Matter Type]
, ISNULL(dim_detail_claim.borough, dim_detail_claim.district) AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations [Police Stations]
, fee_earner_code AS [FEE Eraner Code]
, hierarchylevel4hist AS Team
,ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup,'Other') AS [Matter Type Group]
,dbo.PoliceWorkTypes.[Policing Priority]
,SUM(fact_bill_matter_detail.bill_total) AS [Total Billed]
,SUM(fact_bill_matter_detail.fees_total) AS [Revenue]
,SUM(ISNULL(fact_bill_matter_detail.hard_costs,0) + ISNULL(fact_bill_matter_detail.soft_costs,0)) AS Disbursements
,NULL AS [Hours Recorded]
, CASE WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
		WHEN CAST(dim_bill_date.bill_date AS DATE) BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23'
	ELSE NULL  END AS [Financial Years]
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
,[ClientOrder] = CASE WHEN client_name = 'Suffolk Constabulary' THEN 3
		WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END
, 'Bill' AS [Level]


FROM red_dw.dbo.fact_bill_matter_detail
INNER JOIN red_dw.dbo.dim_bill_date WITH(NOLOCK) ON fact_bill_matter_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
LEFT JOIN red_dw..fact_dimension_main ON fact_dimension_main.master_fact_key = fact_bill_matter_detail.master_fact_key
LEFT JOIN red_dw..dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
--LEFT JOIN red_dw..fact_bill_matter ON fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.Doogal AS [DVPO_Victim_Postcode] ON [DVPO_Victim_Postcode].Postcode=dim_detail_advice.dvpo_victim_postcode

			  
WHERE 
dim_matter_header_current.client_code IN( '00451638','00113147','00817395') 
AND dim_matter_header_current.matter_number <>'ML'
AND CAST(dim_bill_date.bill_date AS DATE) BETWEEN DATEADD(MONTH,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-5,0)) AND DATEADD(MONTH,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
--AND dim_matter_header_current.client_code='00113147'
--and dim_matter_header_current.matter_number = '00000267'

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
         ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup, 'Other'),
         CASE
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2016-04-01' AND '2017-03-31' THEN
         '2016/17'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2017-04-01' AND '2018-03-31' THEN
         '2017/18'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2018-04-01' AND '2019-03-31' THEN
         '2018/19'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2019-04-01' AND '2020-03-31' THEN
         '2019/20'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2020-04-01' AND '2021-03-31' THEN
         '2020/21'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2021-04-01' AND '2022-03-31' THEN
         '2021/22'
         WHEN CAST(dim_bill_date.bill_date AS DATE)
         BETWEEN '2022-04-01' AND '2023-03-31' THEN
         '2022/23'
         ELSE
         NULL
         END,
         CAST(CAST([DVPO_Victim_Postcode].Latitude AS FLOAT) AS DECIMAL(8, 6)),
         CAST(CAST([DVPO_Victim_Postcode].Longitude AS FLOAT) AS DECIMAL(9, 6)),
         CASE WHEN client_name = 'Suffolk Constabulary' THEN 3
		WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END,
         fact_dimension_main.client_code,
         fact_dimension_main.matter_number,
         dim_matter_header_current.client_name,
         dim_matter_header_current.matter_description,
         dim_matter_header_current.matter_owner_full_name,
         dim_matter_header_current.date_opened_case_management,
         dim_matter_header_current.date_closed_case_management,
         ISNULL(dim_detail_claim.borough, dim_detail_claim.district),
         dim_detail_claim.source_of_instruction,
         dim_detail_advice.surrey_police_stations,
         dim_matter_header_current.fee_earner_code,
         dim_fed_hierarchy_history.hierarchylevel4hist,
         PoliceWorkTypes.[Policing Priority],
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

UNION

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
ELSE work_type_name END AS [Matter Type]
, ISNULL(dim_detail_claim.borough, dim_detail_claim.district) AS [Borough]
, dim_detail_claim.[source_of_instruction] AS [Source of Instruction]
, surrey_police_stations [Police Stations]
, fee_earner_code AS [FEE Eraner Code]
, hierarchylevel4hist AS Team
,ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup,'Other') AS [Matter Type Group]
,dbo.PoliceWorkTypes.[Policing Priority]
,NULL AS [Total Billed]
,NULL AS [Revenue]
,NULL AS Disbursements
,SUM(fact_all_time_activity.minutes_recorded/60) AS [Hours Recorded]
, CASE WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2016-04-01' AND '2017-03-31' THEN '2016/17'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2017-04-01' AND '2018-03-31' THEN '2017/18'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2018-04-01' AND '2019-03-31' THEN '2018/19'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2019-04-01' AND '2020-03-31' THEN '2019/20'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2020-04-01' AND '2021-03-31' THEN '2020/21'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2021-04-01' AND '2022-03-31' THEN '2021/22'
		WHEN CAST(transaction_calendar_date AS DATE) BETWEEN '2022-04-01' AND '2023-03-31' THEN '2022/23'
	ELSE NULL  END AS [Financial Years]
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
,[ClientOrder] = CASE WHEN client_name = 'Suffolk Constabulary' THEN 3
		WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END
, 'Time' AS [Level]


FROM red_dw.dbo.fact_all_time_activity
INNER JOIN red_dw.dbo.dim_transaction_date ON dim_transaction_date.dim_transaction_date_key = fact_all_time_activity.dim_transaction_date_key
LEFT JOIN red_dw..fact_dimension_main ON fact_dimension_main.master_fact_key = fact_all_time_activity.master_fact_key
LEFT JOIN red_dw..dim_matter_header_current ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw..dim_fed_hierarchy_history ON dim_matter_header_current.fee_earner_code = dim_fed_hierarchy_history.fed_code AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
--LEFT JOIN red_dw..fact_bill_matter ON fact_dimension_main.master_fact_key = fact_bill_matter.master_fact_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT JOIN red_dw.dbo.dim_detail_claim ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
LEFT JOIN red_dw.dbo.dim_detail_advice ON red_dw.dbo.dim_detail_advice.dim_detail_advice_key = fact_dimension_main.dim_detail_advice_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN reporting.[dbo].[PoliceWorkTypes] ON red_dw.dbo.dim_matter_worktype.work_type_name = [dbo].[PoliceWorkTypes].[Work Type] COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN red_dw.dbo.Doogal AS [DVPO_Victim_Postcode] ON [DVPO_Victim_Postcode].Postcode=dim_detail_advice.dvpo_victim_postcode
			  
WHERE 
dim_matter_header_current.client_code IN( '00451638','00113147','00817395') 
AND dim_matter_header_current.matter_number <>'ML'
AND CAST(transaction_calendar_date AS DATE) BETWEEN DATEADD(MONTH,3,DATEADD(yy, DATEDIFF(yy,1,GETDATE())-5,0)) AND DATEADD(MONTH,3,DATEADD(dd,-1,DATEADD(yy, DATEDIFF(yy,0,GETDATE())+1,0)))
--AND dim_matter_header_current.client_code='00113147'
--and dim_matter_header_current.matter_number = '00000267'

GROUP BY  CASE
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
          ISNULL(dbo.PoliceWorkTypes.GroupWorkTypeLookup, 'Other'),
          CASE
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2016-04-01' AND '2017-03-31' THEN
          '2016/17'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2017-04-01' AND '2018-03-31' THEN
          '2017/18'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2018-04-01' AND '2019-03-31' THEN
          '2018/19'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2019-04-01' AND '2020-03-31' THEN
          '2019/20'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2020-04-01' AND '2021-03-31' THEN
          '2020/21'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2021-04-01' AND '2022-03-31' THEN
          '2021/22'
          WHEN CAST(transaction_calendar_date AS DATE)
          BETWEEN '2022-04-01' AND '2023-03-31' THEN
          '2022/23'
          ELSE
          NULL
          END,
          CAST(CAST([DVPO_Victim_Postcode].Latitude AS FLOAT) AS DECIMAL(8, 6)),
          CAST(CAST([DVPO_Victim_Postcode].Longitude AS FLOAT) AS DECIMAL(9, 6)),
          CASE WHEN client_name = 'Suffolk Constabulary' THEN 3
		WHEN client_name = 'Surrey Police' THEN 2
      WHEN client_name = 'Sussex Police' THEN 1 END,
          fact_dimension_main.client_code,
          fact_dimension_main.matter_number,
          dim_matter_header_current.client_name,
          dim_matter_header_current.matter_description,
          dim_matter_header_current.matter_owner_full_name,
          dim_matter_header_current.date_opened_case_management,
          dim_matter_header_current.date_closed_case_management,
          ISNULL(dim_detail_claim.borough, dim_detail_claim.district),
          dim_detail_claim.source_of_instruction,
          dim_detail_advice.surrey_police_stations,
          dim_matter_header_current.fee_earner_code,
          dim_fed_hierarchy_history.hierarchylevel4hist,
          PoliceWorkTypes.[Policing Priority],
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

END
GO
