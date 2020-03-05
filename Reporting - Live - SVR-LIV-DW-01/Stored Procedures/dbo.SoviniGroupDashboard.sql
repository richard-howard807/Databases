SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SoviniGroupDashboard]
AS
BEGIN

SELECT dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter Number]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_practice_management AS [Date Closed]
,name AS [Case Manager]
,hierarchylevel4hist AS [Team]
,department_name AS [Department]
,work_type_name AS [Work Type]
,dim_detail_core_details.[date_initial_report_sent] AS [Date Initial Report Sent]
,dim_detail_core_details.[date_instructions_received] AS [Date Instructions Received]
,total_amount_billed AS [Total Billed]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_billed AS [VAT]
,wip AS [WIP]
,ISNULL([Revenue 1 April 2017 - 31 March 2018],0) AS [Revenue 1 April 2017 - 31 March 2018]
,ISNULL([Revenue 1 April 2018 - 31 March 2019],0) AS [Revenue 1 April 2018 - 31 March 2019]
,ISNULL([Revenue 1 April 2019 - 31 March 2020],0) AS [Revenue 1 April 2019 - 31 March 2020]
,ISNULL([Revenue 1 April 2020 - 31 March 2021],0) AS [Revenue 1 April 2020 - 31 March 2021]

FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN red_dw.dbo.dim_department
 ON dim_department.dim_department_key = dim_matter_header_current.dim_department_key
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key 
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.client_code = dim_matter_header_current.client_code
 AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
 LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
 ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
 AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
,SUM(fees_total)  TotalRevenue
,SUM(CASE WHEN bill_date BETWEEN '2017-04-01' AND '2018-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2017 - 31 March 2018]
,SUM(CASE WHEN bill_date BETWEEN '2018-04-01' AND '2019-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2018 - 31 March 2019]
,SUM(CASE WHEN bill_date BETWEEN '2019-04-01' AND '2020-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2019 - 31 March 2020]
,SUM(CASE WHEN bill_date BETWEEN '2020-04-01' AND '2021-03-31' THEN fees_total ELSE NULL END) AS [Revenue 1 April 2020 - 31 March 2021]
FROM red_dw.dbo.fact_bill_matter_detail_summary
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = fact_bill_matter_detail_summary.client_code
 AND dim_matter_header_current.matter_number = fact_bill_matter_detail_summary.matter_number
WHERE client_group_name='Sovini Group'
GROUP BY dim_matter_header_current.client_code
,dim_matter_header_current.matter_number
) AS Revenue
 ON Revenue.client_code = dim_matter_header_current.client_code
 AND Revenue.matter_number = dim_matter_header_current.matter_number
WHERE client_group_name='Sovini Group'
AND (date_closed_practice_management IS NULL OR date_closed_practice_management>'2017-04-01')

ORDER BY dim_matter_header_current.client_code 
,dim_matter_header_current.matter_number


END
GO
