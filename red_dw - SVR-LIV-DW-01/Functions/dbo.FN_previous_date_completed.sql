SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[FN_previous_date_completed]
(	
	-- Add the parameters for the function here
	@client_code CHAR(8),
	@matter_number  CHAR(8)
)
RETURNS TABLE 
AS
RETURN 
(
	-- Add the SELECT statement with parameter references here
	SELECT dim_detail_core_details.client_code,dim_detail_core_details.matter_number,

ISNULL(CAST(CAST(dim_detail_core_details.date_completed_1 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_2 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_3 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_4 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_5 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_6 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_7 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_8 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_9 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_10 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_11 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_12 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_13 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_client.date_completed_14 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_15 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_16 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_17 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_18 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_19 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_20 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_21 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_22 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_23 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_24 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_25 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_26 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_27 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_28 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_29 AS DATE) AS VARCHAR),'')
AS all_dates
,
CAST(
SUBSTRING
(
(
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_1 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_2 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_3 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_4 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_5 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_6 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_7 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_8 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_9 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_10 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_11 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_12 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_13 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_client.date_completed_14 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_15 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_16 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_17 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_18 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_19 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_20 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_21 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_22 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_23 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_24 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_25 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_26 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_27 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_28 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_29 AS DATE) AS VARCHAR),'')
) 
,

(LEN
(
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_1 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_2 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_3 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_4 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_5 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_6 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_7 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_8 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_9 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_10 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_11 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_12 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_13 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_client.date_completed_14 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_15 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_16 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_17 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_18 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_19 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_20 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_21 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_22 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_23 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_24 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_25 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_26 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_27 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_28 AS DATE) AS VARCHAR),'')+
ISNULL(CAST(CAST(dim_detail_core_details.date_completed_29 AS DATE) AS VARCHAR),'')
)) 
- 19,10) AS DATETIME) AS [Previous Last Actioned Date],

COALESCE(dim_detail_core_details.[date_completed_29], dim_detail_core_details.[date_completed_28], dim_detail_core_details.[date_completed_27], dim_detail_core_details.[date_completed_26], dim_detail_core_details.[date_completed_25], 
              dim_detail_core_details.[date_completed_24], dim_detail_core_details.[date_completed_23], dim_detail_core_details.[date_completed_22], dim_detail_core_details.[date_completed_21], dim_detail_core_details.[date_completed_20], 
              dim_detail_core_details.[date_completed_19], dim_detail_core_details.[date_completed_18], dim_detail_core_details.[date_completed_17], dim_detail_core_details.[date_completed_16], dim_detail_core_details.[date_completed_15], 
              dim_detail_client.[date_completed_14], dim_detail_core_details.[date_completed_13], dim_detail_core_details.[date_completed_12], dim_detail_core_details.[date_completed_11], dim_detail_core_details.[date_completed_10], 
              dim_detail_core_details.[date_completed_9], dim_detail_core_details.[date_completed_8], dim_detail_core_details.[date_completed_7], dim_detail_core_details.[date_completed_6], dim_detail_core_details.[date_completed_5], 
              dim_detail_core_details.[date_completed_4], dim_detail_core_details.[date_completed_23], dim_detail_core_details.[date_completed_2], dim_detail_core_details.[date_completed_1]) AS [Date Last Action Plan Sent]

FROM dbo.dim_detail_core_details
LEFT OUTER JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.client_code = dim_detail_core_details.client_code AND dim_detail_client.matter_number = dim_detail_core_details.matter_number
WHERE dim_detail_core_details.client_code = @client_code AND dim_detail_core_details.matter_number = @matter_number

)


GO
GRANT SELECT ON  [dbo].[FN_previous_date_completed] TO [omnireader]
GO
