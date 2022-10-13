SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[StalkingProtectionOrders]
AS
BEGIN

SELECT 
dim_matter_header_current.client_code AS Client
,dim_matter_header_current.matter_number AS Matter
,dim_matter_header_current.client_name AS [Client Name]
,matter_owner_full_name AS [Weightmans fee earner]
,matter_description AS [Matter description]
,date_opened_case_management AS [date opened]
,date_closed_case_management AS [Date closed]
,[Revenue 2018/2019]
,[Revenue 2019/2020]
,[Revenue 2020/2021]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN (SELECT client_name,dim_matter_header_current.matter_number
,SUM(CASE WHEN dim_bill_date.bill_date BETWEEN '2018-05-01' AND '2019-04-30' THEN bill_amount ELSE NULL END) AS [Revenue 2018/2019]
,SUM(CASE WHEN dim_bill_date.bill_date BETWEEN '2019-05-01' AND '2020-04-30' THEN bill_amount ELSE NULL END) AS [Revenue 2019/2020]
,SUM(CASE WHEN dim_bill_date.bill_date BETWEEN '2020-05-01' AND '2021-04-30' THEN bill_amount ELSE NULL END) AS [Revenue 2020/2021]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.fact_bill_activity
 ON fact_bill_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.dim_bill_date_key = fact_bill_activity.dim_bill_date_key
WHERE work_type_name='PL - Pol - Stalking Protection Order' AND
dim_bill_date.bill_date >='2018-05-01'
GROUP BY client_name,dim_matter_header_current.matter_number) AS Revenue
 ON Revenue.client_name = dim_matter_header_current.client_name
 AND Revenue.matter_number = dim_matter_header_current.matter_number
WHERE work_type_name='PL - Pol - Stalking Protection Order'



END 

GO
