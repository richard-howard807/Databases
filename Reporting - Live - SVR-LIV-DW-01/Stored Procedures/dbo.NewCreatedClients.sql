SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[NewCreatedClients]  --EXEC [dbo].[NewCreatedClients] '2019-03-11','2019-03-20'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT dim_client.client_code AS ClientNumber
,RTRIM(red_dw.dbo.dim_client.client_name) AS ClientName
,red_dw.dbo.dim_client.client_partner_name AS [Partner Name]
,hierarchylevel3hist AS [Partner PracticeArea]
,hierarchylevel4hist AS [Partner Team]
,red_dw.dbo.dim_fed_hierarchy_history.worksforname AS [Partner BCM]
,Matters.[name] AS [Case Handler Name]
,Matters.worksforname AS [Case Handler BCM]
,red_dw.dbo.dim_client.open_date AS [Date Client Created]
,1 AS NumberOpened
,branch AS  Office
,client_group_code AS cl_clgrp
,client_group_name AS cl_clname
,red_dw.dbo.dim_client.client_partner_name AS cl_part
,CASE WHEN hierarchylevel3hist IN ('Real Estate','Property','Corporate','Commercial Glasgow','X Mace and Jones') THEN 1 ELSE 0 END  AS Filter
FROM red_dw.dbo.dim_client
INNER JOIN (SELECT DISTINCT client_code,fee_earner_code,[name],case_id,worksforname
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 WHERE matter_number IN ('00000001')
 ) AS Matters
ON dim_client.client_code=Matters.client_code	
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON client_partner_code=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'

 WHERE red_dw.dbo.dim_client.open_date BETWEEN @StartDate AND @EndDate
--AND red_dw.dbo.dim_client.client_code NOT LIKE 'P%'
AND red_dw.dbo.dim_client.client_code <> 'NCI7'
AND client_name NOT LIKE '%error%'
AND client_name NOT LIKE '%ERROR%'
AND client_name NOT LIKE '%do not%'
AND client_name NOT LIKE '%DO NOT%'
AND client_name NOT LIKE 'EMP%'
AND UPPER(client_name) NOT LIKE '%TEST%'
END
GO
