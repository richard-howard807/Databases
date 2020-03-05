SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2019-04-02
-- Description:	Segment Billing for Local & Central Government sector
-- =============================================
CREATE PROCEDURE 	[dbo].[SegmentBillingLocalCentralGovernment]
-- Add the parameters for the stored procedure here
	@DateFrom AS datetime,
	@DateTo AS datetime
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT 
dim_matter_header_current.client_name,
dim_matter_header_current.client_code,
dim_matter_header_current.matter_number,
matter_description,
matter_owner_full_name,
hierarchylevel4hist team,
work_type_name,
work_type_group,
CASE WHEN  work_type_group  IN ('Other','Prof Risk','LMT','Healthcare','Health and Safety','Education','Regulatory','EPI','Litigation - Commercial','Family & Private Client','Real Estate','Corp-Comm') THEN 1 ELSE 0 END work_type_filter,
SUM(bill_amount)  bill_amount
FROM red_dw.dbo.fact_dimension_main
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_Dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.fact_bill_activity ON fact_bill_activity.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_client ON dim_client.dim_client_key = fact_bill_activity.dim_client_key
WHERE bill_date BETWEEN @DateFrom AND @DateTo  AND ISNULL(sector,'') = 'Local & Central Government'
GROUP BY 
dim_matter_header_current.client_name,
dim_matter_header_current.client_code,
dim_matter_header_current.matter_number,
matter_description,
matter_owner_full_name,
hierarchylevel4hist,
work_type_name,
work_type_group
END



GO
