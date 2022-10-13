SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
-- 20170808 LD removed reporting exclusions
-- 20171121 ES amended working days to calendar days, contract changed

CREATE PROCEDURE [dbo].[MIBWorkingDaysSLA]

AS
BEGIN
SET NOCOUNT ON;
SELECT RTRIM(fact_dimension_main.client_code) AS [Client Code]
		, fact_dimension_main.matter_number AS [Matter Number]
		, DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) + 1 AS [Working days from File Opening]
		 , COALESCE(nonda.service_category,dim_detail_client.service_category)  AS [Service Category]
		, CASE WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'DA%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'MOJ%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) <=3 THEN 'Green'
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'DA%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'MOJ%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) =4 THEN 'Amber'
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'DA%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'MOJ%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) >=5 THEN 'Red' 
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Exclusive%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Non%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) <=10 THEN 'Green' 
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Exclusive%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Non%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) <=13 THEN 'Amber'
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Exclusive%' OR COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Non%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) >=14 THEN 'Red'

						WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Super%' ) AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) <=10 THEN 'Green' 
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Super%') AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) <=13 THEN 'Amber'
			WHEN (COALESCE(nonda.service_category,dim_detail_client.service_category) LIKE 'Super%')  AND DATEDIFF(DAY, COALESCE(dim_detail_core_details.date_instructions_received,dim_matter_header_current.date_opened_case_management), GETDATE()) >=14 THEN 'Red'
			ELSE NULL END AS [RAG]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
left JOIN (SELECT mib_claim_number,service_category  FROM red_dw.dbo.fact_dimension_main
LEFT JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_detail_client_key 
WHERE master_client_code = 'M1001' AND [service_category] IS NOT NULL AND LOWER([service_category]) LIKE 'non da cat%') nonda ON nonda.mib_claim_number = dim_detail_client.mib_claim_number
WHERE fact_dimension_main.master_client_code='M1001'
AND date_opened_case_management>='2017-07-01'
AND dim_matter_header_current.reporting_exclusions <> 1

END

GO
GRANT EXECUTE ON  [dbo].[MIBWorkingDaysSLA] TO [ssrs_dynamicsecurity]
GO
