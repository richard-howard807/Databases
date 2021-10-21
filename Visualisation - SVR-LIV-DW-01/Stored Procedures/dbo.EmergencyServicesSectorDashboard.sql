SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[EmergencyServicesSectorDashboard]

AS 

BEGIN
SELECT master_client_code + '-'+ master_matter_number AS [Reference]
,matter_description AS [Matter Description]
,name AS [Matter Manager]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,branch_name AS [Office]
,red_dw.dbo.dim_matter_worktype.work_type_name AS [Matter Type]
,bill_amount AS [Revenue]
,dim_bill_date.bill_date AS [Bill Date]
,CASE WHEN ISNULL(dim_client.client_group_name,'')='' THEN dim_client.client_name ELSE dim_client.client_group_name END AS Client
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.fact_bill_activity
 ON fact_bill_activity.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_bill_date
 ON dim_bill_date.bill_date = fact_bill_activity.bill_date
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
WHERE sector='Emergency Services'
AND bill_fin_year >='2019'

END 
GO
