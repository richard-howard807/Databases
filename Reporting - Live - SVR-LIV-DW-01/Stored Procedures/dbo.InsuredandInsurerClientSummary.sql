SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-08-29
-- Description:	created to keep track of the report
-- =============================================
CREATE PROCEDURE [dbo].[InsuredandInsurerClientSummary] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
IF object_id('Reporting.dbo.InsuredandInsurerClientSummaryTable') IS NOT NULL DROP TABLE  Reporting.dbo.InsuredandInsurerClientSummaryTable
IF object_id('temdb..#results') IS NOT NULL DROP TABLE  #results


SELECT  
dci.insurerclient_name,
ISNULL(ddc.dst_insured_client_name,dci.insuredclient_name) insuredclient_name,
dc.sector,
dc.segment,
ddcd.insured_sector,
bill_date,
dc.client_name,
dc.client_group_name,
dmwt.work_type_name,
dd.department_name,
dmhc.matter_partner_full_name,
CASE WHEN calendar_date >= '2015-05-01' THEN 1 ELSE 0 END [May_2015_now],
CASE WHEN calendar_date >= '2015-05-01' AND calendar_date <= '2016-04-30' THEN 1 ELSE 0 END [May_2015_April_2016],
CASE WHEN calendar_date >= '2016-05-01' AND calendar_date <= '2017-04-30' THEN 1 ELSE 0 END [May_2016_April_2017],
CASE WHEN calendar_date >= '2017-05-01' AND calendar_date <= '2018-04-30' THEN 1 ELSE 0 END [May_2017_now],
CASE WHEN calendar_date >= '2018-05-01' AND calendar_date <= '2019-04-30' THEN 1 ELSE 0 END [matters_FY2019],
CASE WHEN calendar_date >= '2019-05-01' AND calendar_date <= '2020-04-30' THEN 1 ELSE 0 END [matters_FY2020],
CASE WHEN calendar_date >= '2020-05-01' AND calendar_date <= '2021-04-30' THEN 1 ELSE 0 END [matters_FY2021],


CASE WHEN bill_date >= '2015-05-01' THEN fba.bill_amount ELSE 0 END [May_2015_now_bills],

CASE WHEN bill_date >= '2015-05-01' AND bill_date <= '2016-04-30' THEN fba.bill_amount ELSE 0 END [May_2015_April_2016_bills],
CASE WHEN bill_date >= '2016-05-01' AND bill_date <= '2017-04-30' THEN fba.bill_amount ELSE 0 END [May_2016_April_2017_bills],
CASE WHEN bill_date >= '2017-05-01' AND bill_date <= '2018-04-30' THEN fba.bill_amount ELSE 0 END [May_2017_now_bills],
CASE WHEN bill_date >= '2018-05-01' AND bill_date <= '2019-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2019],
CASE WHEN bill_date >= '2019-05-01' AND bill_date <= '2020-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2020],
CASE WHEN bill_date >= '2020-05-01' AND bill_date <= '2021-04-30' THEN fba.bill_amount ELSE 0 END [bills_FY2021]


INTO #results
FROM red_Dw.dbo.fact_dimension_main fdm 
LEFT JOIN red_Dw.dbo.fact_bill_activity fba ON  fdm.master_fact_key = fba.master_fact_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current dmhc ON dmhc.dim_matter_header_curr_key = fdm.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_date open_date ON open_date.dim_date_key = fdm.dim_open_case_management_date_key
LEFT JOIN red_Dw.dbo.dim_detail_core_details ddcd ON ddcd.dim_detail_core_detail_key = fdm.dim_detail_core_detail_key
LEFT JOIN red_Dw.dbo.dim_client_involvement dci ON dci.dim_client_involvement_key = fdm.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_client dc ON dc.dim_client_key = fdm.dim_client_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype dmwt ON dmwt.dim_matter_worktype_key = dmhc.dim_matter_worktype_key
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history fed ON fed.dim_fed_hierarchy_history_key = fba.dim_fed_hierarchy_history_key  
LEFT JOIN red_Dw.dbo.dim_detail_claim ddc ON fdm.dim_detail_claim_key = ddc.dim_detail_claim_key  
LEFT JOIN red_Dw.dbo.dim_department dd ON dmhc.dim_department_key = dd.dim_department_key  
WHERE (calendar_date >= '2015-05-01' OR fba.bill_date >= '2015-05-01' ) AND (fed.hierarchylevel2hist = 'Legal Ops - Claims' OR dmwt.work_type_name LIKE '%Prof Risk%')
  

 --SELECT * FROM #results WHERE insuredclient_name = 'DHL Services Ltd'

SELECT 
insurerclient_name,
insuredclient_name,
sector,
insured_sector,
client_name,
client_group_name,
segment,
work_type_name,
department_name,
matter_partner_full_name,
SUM(details.May_2015_now) May_2015_now,
SUM(details.May_2015_April_2016) May_2015_April_2016,
SUM(details.May_2016_April_2017) May_2016_April_2017,
SUM(details.May_2017_now) May_2017_now,
SUM(details.matters_FY2020) matters_FY2020,
SUM(details.matters_FY2021) matters_FY2021,

SUM(details.May_2015_now_bills) May_2015_now_bills,
SUM(details.May_2015_April_2016_bills) May_2015_April_2016_bills,
SUM(details.May_2016_April_2017_bills) May_2016_April_2017_bills,
SUM(details.May_2017_now_bills) May_2017_now_bills,
SUM([details].[bills_FY2019]) [bills_FY2019] ,
SUM([details].[matters_FY2019]) [matters_FY2019],
SUM(details.bills_FY2020) bills_FY2020,
SUM(details.bills_FY2021) bills_FY2021

INTO Reporting.dbo.InsuredandInsurerClientSummaryTable
FROM #results details
--WHERE insuredclient_name = 'DHL Services Ltd'
GROUP BY 
insuredclient_name,
client_name,
client_group_name,
insurerclient_name,
segment,
sector,
insured_sector,
work_type_name,
department_name,
matter_partner_full_name
HAVING
SUM(details.May_2015_now) <>0 OR 
SUM(details.May_2015_April_2016) <> 0 OR  
SUM(details.May_2016_April_2017) <> 0 OR 
SUM(details.May_2017_now) <> 0 OR
SUM(details.May_2015_now_bills) <> 0 OR
SUM(details.May_2015_April_2016_bills) <> 0 OR
SUM(details.May_2016_April_2017_bills) <> 0 OR
SUM(details.May_2017_now_bills) <> 0 OR
SUM(details.bills_FY2019) <>0 OR
SUM(details.bills_FY2020) <> 0 OR 
SUM(details.bills_FY2021) <> 0 OR
SUM(details.matters_FY2019) <>0 OR
SUM(details.matters_FY2020) <> 0 OR 
SUM(details.matters_FY2021) <> 0
ORDER BY May_2015_now DESC, insuredclient_name DESC,  insurerclient_name DESC




END
GO
