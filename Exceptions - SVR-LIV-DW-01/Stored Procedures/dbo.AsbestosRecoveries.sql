SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-03-31
-- Description:	#94209 Limitation dates for asbestos recoveries
-- =============================================
CREATE PROCEDURE [dbo].[AsbestosRecoveries]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number AS [MatterSphere Client/Matter Number]
	, dim_matter_header_current.matter_description AS [Matter Description]
	, dim_matter_worktype.work_type_name AS [Matter Type]
	, dim_matter_header_current.matter_owner_full_name AS [Matter Owner]
	, dim_detail_core_details.present_position AS [Present Position]
	, dim_detail_outcome.date_claim_concluded AS [Date Claim Concluded]
	, DATEADD(YEAR, 2, dim_detail_outcome.date_claim_concluded) AS [Date Limitation Expires for Recovery]
	, dim_detail_outcome.are_we_pursuing_a_recovery AS [Are we Pursuing a Recovery?]
	, fact_detail_recovery_detail.amount_recovery_sought AS [Amount of Recovery Sought]
	, fact_finance_summary.total_recovery AS [Total Recovered]
	, dim_detail_claim.date_recovery_concluded AS [Date Recovery Concluded]
	, dim_matter_header_current.date_closed_case_management AS [Date Closed]
	, CASE WHEN DATEADD(YEAR, 2, dim_detail_outcome.date_claim_concluded)<GETDATE() THEN 1 ELSE 0 END AS [Expired Recoveries]
	, CASE WHEN DATEADD(YEAR, 2, dim_detail_outcome.date_claim_concluded)>GETDATE() AND DATEDIFF(MONTH, GETDATE(), DATEADD(YEAR, 2, dim_detail_outcome.date_claim_concluded))<=3 THEN 1 ELSE 0 END AS [Recoveries Due Within 3 Months]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key

WHERE dim_matter_header_current.reporting_exclusions=0
AND ISNULL(dim_detail_outcome.outcome_of_case,'')<>'Exclude from reports'
AND dim_detail_outcome.date_claim_concluded IS NOT NULL
AND (dim_detail_core_details.present_position IN ('Claim and costs outstanding','Claim concluded but costs outstanding','Claim and costs concluded but recovery outstanding' )
OR dim_detail_core_details.present_position IS NULL)
AND dim_matter_worktype.work_type_name IN ('Disease - Asbestosis','Disease - Asbestos/Mesothelioma','Disease - Pleural Thickening', 'Disease - Asbestos Related Cancer')

END
GO
