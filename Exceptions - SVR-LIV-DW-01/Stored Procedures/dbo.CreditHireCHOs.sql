SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:           <Beth Wilson>
-- Create date: <1/12/22>
-- Description:      <#177824>
-- =============================================
CREATE PROCEDURE [dbo].[CreditHireCHOs] 
       -- Add the parameters for the stored procedure here

AS
BEGIN
       -- SET NOCOUNT ON added to prevent extra result sets from
       -- interfering with SELECT statements.
       SET NOCOUNT ON;

    -- Insert statements for procedure here
       SELECT dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [reference] 
, dim_matter_header_current.matter_description AS [Matter Description]
, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
, dim_detail_core_details.incident_date AS [Incident Date] 
,fact_detail_paid_detail.hire_claimed AS [Hire Claimed]
, fact_detail_paid_detail.amount_hire_paid AS [Hire Paid] 
, dim_detail_hire_details.hire_start_date AS [Hire Start Date]
, dim_detail_hire_details.hire_end_date AS [Hire End Date]
, dim_detail_hire_details.other AS [CHO Other] 
, dim_detail_hire_details.cho_postcode AS [CHO Postcode] 
,dim_matter_header_current.date_opened_case_management AS [Date Opened] 
, Doogal.Latitude AS [CHO Latitude]
, Doogal.Longitude AS [CHO Longitude]
FROM red_dw.dbo.fact_dimension_main
INNER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
INNER JOIN red_dw.dbo.dim_detail_hire_details
ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
INNER JOIN red_dw.dbo.dim_detail_core_details 
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key 
INNER JOIN red_dw.dbo.fact_detail_paid_detail 
ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key 
LEFT JOIN red_dw.dbo.Doogal ON dim_detail_hire_details.cho_postcode = Doogal.Postcode

WHERE dim_matter_header_current.reporting_exclusions = 0
AND dim_detail_hire_details.other IS NOT NULL 

END
GO
