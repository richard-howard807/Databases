SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[InsuredClientSummary]

AS 

BEGIN

DROP TABLE IF EXISTS dbo.InsuredClientSummaryData;




SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Weightmans Client/Matter No]
	, dim_matter_header_current.master_client_code+'-'+master_matter_number AS [MatterSphere Client/Matter No]
	, matter_description AS [Matter Description]
	, work_type_name AS [Work Type]
	, date_opened_case_management AS [Date Opened]
	, date_closed_case_management AS [Date Closed]
	, name AS [Case Manager]
	, hierarchylevel4hist AS [Team]
	, hierarchylevel3hist AS [Department]
	, dim_client.client_group_name AS [Client Group]
	, dim_client.client_name AS [Client Name]
	, sector AS [Client Sector]
	, segment AS [Client Segment]
	, insuredclient_name AS [Insured Client Name]
	, dim_detail_claim.[dst_insured_client_name] AS [Insured Client Name (DS)]
	, dim_detail_claim.[dst_insured_client_name] AS [DST Insured Client Name]
	, dim_detail_core_details.[insured_sector] AS [Insured Client Sector]
	, CASE WHEN segment='Insurance' THEN dim_detail_core_details.[insured_sector] ELSE sector END AS [Client/Insured Client Sector]
	, dim_detail_core_details.[present_position] AS [Present Position]
	, fact_finance_summary.[total_reserve] AS [Total Reserve (TRA076 + TRA080 + NMI519 + TRA078)]
	, total_amount_billed AS [Total Billed]
	, wip AS [WIP]
    ,Revenue2015.[Revenue 2015/2016] AS [Revenue 2015/2016]
	,Revenue2016.[Revenue 2016/2017] AS [Revenue 2016/2017]
	,Revenue2017.[Revenue 2017/2018] AS [Revenue 2017/2018]
	,Revenue2018.[Revenue 2018/2019] AS [Revenue 2018/2019]
	,Revenue2019.[Revenue 2019/2020] AS [Revenue 2019/2020]
INTO dbo.InsuredClientSummaryData
FROM(SELECT dim_matter_header_curr_key FROM red_dw.dbo.dim_matter_header_current
WHERE reporting_exclusions=0
AND (date_closed_case_management IS NULL  OR date_closed_case_management>='2015-05-01')) AS Filtered
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.dim_matter_header_curr_key = Filtered.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_matter_worktype
	 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
	 INNER JOIN red_dw.dbo.dim_client
	  ON dim_client.client_code = dim_matter_header_current.client_code
	LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
	 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
	LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
	 ON dim_detail_claim.client_code = dim_matter_header_current.client_code
	 AND dim_detail_claim.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
	 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
	 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
	 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
	 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
	 ON dim_client_involvement.client_code = dim_matter_header_current.client_code
	 AND dim_client_involvement.matter_number = dim_matter_header_current.matter_number
	LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2015/2016]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2015/2016]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2015-05-01' AND '2016-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2015
 ON dim_matter_header_current.client_code=Revenue2015.client_code
AND dim_matter_header_current.matter_number=Revenue2015.matter_number

LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2016/2017]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2016/2017]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2016-05-01' AND '2017-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2016
 ON dim_matter_header_current.client_code=Revenue2016.client_code
AND dim_matter_header_current.matter_number=Revenue2016.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2017/2018]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2017/2018]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2017-05-01' AND '2018-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2017
 ON dim_matter_header_current.client_code=Revenue2017.client_code
AND dim_matter_header_current.matter_number=Revenue2017.matter_number


LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2018/2019]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2018/2019]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2018-05-01' AND '2019-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2018
 ON dim_matter_header_current.client_code=Revenue2018.client_code
AND dim_matter_header_current.matter_number=Revenue2018.matter_number

LEFT OUTER JOIN 
(
SELECT fact_bill_detail.client_code,fact_bill_detail.matter_number
,SUM(fact_bill_detail.bill_total_excl_vat) AS [Revenue 2019/2020]
,SUM(fact_bill_detail.workhrs) AS [Hours Billed 2019/2020]
FROM red_dw.dbo.fact_bill_detail
INNER JOIN red_dw.dbo.dim_bill_date
 ON fact_bill_detail.dim_bill_date_key=dim_bill_date.dim_bill_date_key
 WHERE dim_bill_date.bill_date BETWEEN '2019-05-01' AND '2020-04-30'
AND charge_type='time'
GROUP BY fact_bill_detail.client_code,fact_bill_detail.matter_number
) AS Revenue2019
 ON dim_matter_header_current.client_code=Revenue2019.client_code
AND dim_matter_header_current.matter_number=Revenue2019.matter_number

END 
GO
