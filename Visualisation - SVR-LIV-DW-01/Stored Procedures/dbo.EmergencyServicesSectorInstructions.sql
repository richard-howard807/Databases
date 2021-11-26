SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[EmergencyServicesSectorInstructions]

AS 

BEGIN 

SELECT master_client_code + '-'+ master_matter_number AS [Reference]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,name AS [Matter Manager]
,hierarchylevel2hist AS [Division]
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,branch_name AS [Office]
,ISNULL(dbo.EmergencyServicesCategorisation.Categorisation,'Operational Advice') AS [Matter Type]
,CASE WHEN ISNULL(dim_client.client_group_name,'')='' THEN dim_client.client_name ELSE dim_client.client_group_name END AS Client
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_client
 ON dim_client.client_code = dim_matter_header_current.client_code
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN dbo.EmergencyServicesCategorisation 
 ON RTRIM(work_type_name)=EmergencyServicesCategorisation.[Mattersphere Matter Type] COLLATE DATABASE_DEFAULT

WHERE sector='Emergency Services'
AND date_opened_case_management>='2017-05-01'

END
GO
