SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-08-19
-- Description:	#68408, Request a new report - Last Time Posting 30+ Days
			--Healthcare want more governance around fee earners moving cases forward and completing outcome MI asap 
			--so can you please create a new report that will list cases that haven’t been worked on in over 30 days. 
-- =============================================
CREATE PROCEDURE [nhs].[LastTimePosting]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT dim_matter_header_current.master_client_code+'-'+master_matter_number AS [MatterSphere Ref]
	, matter_description AS [Case Description]
	, matter_owner_full_name AS [Case Manager]
	, hierarchylevel4hist AS [Team]
	, nhs_type_of_instruction_billing AS [Instruction Type]
	, nhs_expected_settlement_date AS [Expected Settlement Date]
	, last_time_transaction_date AS [Date of Last Time Posting]
	, DATEDIFF(DAY,last_time_transaction_date, GETDATE()) AS [Number of Days Since Last Time Posting]
	, is_this_a_linked_file AS [Is this a Linked Matter?]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_health
ON dim_detail_health.dim_detail_health_key = fact_dimension_main.dim_detail_health_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key

WHERE dim_matter_header_current.master_client_code='N1001'
AND date_claim_concluded IS NULL
AND dim_matter_header_current.date_closed_case_management IS NULL
AND (referral_reason LIKE 'Dispute%' OR referral_reason LIKE 'Infant Approval%')
AND DATEDIFF(DAY,last_time_transaction_date, GETDATE())>30

ORDER BY [Number of Days Since Last Time Posting] DESC

END
GO
