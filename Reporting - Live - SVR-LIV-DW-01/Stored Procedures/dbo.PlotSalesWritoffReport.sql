SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[PlotSalesWritoffReport]

AS  

BEGIN

SELECT 
dim_matter_header_curr_key
,CONVERT(DATE,GETDATE(),103) AS [DateRan]
,dim_matter_header_current.client_code AS [Client]
,dim_matter_header_current.matter_number AS [Matter]
,matter_owner_full_name AS [Fee Earner Name]
,completion_date AS [Completion Date]
,ISNULL(WIP,0) AS [Unbilled WIP Amount]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_detail_property
ON dim_detail_property.client_code = dim_matter_header_current.client_code
AND dim_detail_property.matter_number = dim_matter_header_current.matter_number
LEFT OUTER JOIN 
(
SELECT dim_matter_header_current_key AS dim_matter_header_current_key,SUM(wip_value) AS WIP FROM red_dw.dbo.fact_wip
GROUP BY dim_matter_header_current_key
) AS WIP
 ON  dim_matter_header_current.dim_matter_header_curr_key=WIP.dim_matter_header_current_key
WHERE completion_date IS NOT NULL
AND CONVERT(DATE,completion_date,103) BETWEEN 
CONVERT(DATE,DATEADD(DAY,-1,GETDATE()),103) AND  CONVERT(DATE,GETDATE(),103)

END
GO
