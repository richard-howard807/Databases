SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[AIBusinessSource]
AS
BEGIN

--Business Source Data
SELECT DISTINCT dim_client.client_code AS [Client Code]
	, CASE WHEN segment='Individuals' THEN 'Individual Client' ELSE dim_client.client_name END AS [Client Name]
	, segment AS [Segment]
	, sector AS [Sector]
	, client_partner_name AS [Client Partner]
	, hierarchylevel3hist AS [Department]
	, ISNULL(referrer_type,'No Business Source') AS [Business Source]
	, business_source_name AS [Business Source Description]
	, dim_client.open_date AS [Date Opened]
	, Revenue.Revenue
	--, *
	
FROM red_dw.dbo.dim_client 
--LEFT OUTER JOIN (SELECT client_code
--	, matter_number
--	, ROW_NUMBER() OVER ( PARTITION BY client_code ORDER BY matter_number,dim_matter_header_history.dss_version) AS [Row Number]
--	, dim_matter_header_history.fee_earner_code
--FROM red_dw.dbo.dim_matter_header_history
--WHERE dim_matter_header_history.matter_number<>'ML'
--AND dim_matter_header_history.matter_number<>'00000000'
--AND dim_matter_header_history.matter_number<>'00000001'
--) AS [firstmatter] ON firstmatter.client_code = dim_client.client_code
--AND firstmatter.[Row Number]=1
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_client.client_partner_code=dim_fed_hierarchy_history.fed_code
AND dim_client.open_date BETWEEN dim_fed_hierarchy_history.dss_start_date AND dim_fed_hierarchy_history.dss_end_date
LEFT OUTER JOIN (SELECT dim_client_key, SUM(bill_amount) AS Revenue
FROM red_dw.dbo.fact_bill_activity
WHERE fact_bill_activity.source_system_id<>14
GROUP BY fact_bill_activity.dim_client_key
) AS [Revenue] ON [Revenue].dim_client_key=dim_client.dim_client_key

WHERE dim_client.open_date >='2015-05-01'
AND NOT client_code LIKE 'I%'

END
GO
