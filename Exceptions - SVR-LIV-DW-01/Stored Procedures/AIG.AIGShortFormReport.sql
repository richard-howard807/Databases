SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-06-06
-- Description:	for AIG ebilling handler budgets
-- =============================================
CREATE PROCEDURE [AIG].[AIGShortFormReport]
(
@FeeEarner AS VARCHAR(MAX)
,@Team AS VARCHAR(MAX)
)
AS
BEGIN

SELECT ListValue  INTO #FeeEarnerList FROM 	dbo.udt_TallySplit(',', @FeeEarner)
SELECT ListValue  INTO #Team FROM 	dbo.udt_TallySplit(',', @Team)

SELECT AIGShortFormData.*,CASE WHEN ApportionedCases.client_code IS NOT NULL THEN 'Yes' ELSE 'No' END AS [Apportioned defence costs] FROM AIGShortFormData WITH (NOLOCK)
--INNER JOIN dim_matter_header_current ON  AIGShortFormData.Client = dim_matter_header_current
INNER JOIN #FeeEarnerList AS FedCode ON FedCode.ListValue COLLATE database_default = AIGShortFormData.FedCode COLLATE database_default
INNER JOIN #Team AS Team ON Team.ListValue COLLATE database_default = AIGShortFormData.Team COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN 
(
SELECT DISTINCT  fact_bill_activity.client_code,fact_bill_activity.matter_number 
FROM red_Dw.dbo.fact_bill_activity WITH (NOLOCK)
LEFT JOIN red_Dw.dbo.dim_client WITH (NOLOCK) ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE client_group_code = '00000013'
AND ISNUMERIC(RIGHT(RTRIM(bill_number),2))<>1
AND bill_number <>'a'
AND bill_number NOT LIKE 'V%'
) AS ApportionedCases
 ON AIGShortFormData.client=client_code AND AIGShortFormData.matter=matter_number 
END



GO
