SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Kevin Hansen>
-- Create date: <30.11.2022>
-- Description:	NHS Live Matters Test
-- =============================================
CREATE PROCEDURE [dbo].[NHSLiveMattersTest]
(
@Start AS DATE
,@EndDate AS DATE
)
	
AS
BEGIN

SELECT master_client_code +'-'+master_matter_number AS [Weightmans Ref]
,matter_description AS [Matter Description]
,date_opened_case_management AS [Date Opened]
,date_closed_case_management AS [Date Closed]
,name AS MatterOwner 
,matter_owner_full_name
,fed_code
,hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,total_amount_billed AS [TotalBilled]
,defence_costs_billed AS [Revenue]
,disbursements_billed AS [Disbursements]
,vat_billed AS [Vat]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
 ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
WHERE master_client_code='N1001' 
AND date_closed_case_management IS NULL
AND CONVERT(DATE,date_opened_case_management,103) BETWEEN @Start AND @EndDate

END
GO
