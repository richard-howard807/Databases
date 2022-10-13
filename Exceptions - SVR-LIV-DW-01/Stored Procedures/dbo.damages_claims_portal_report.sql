SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Jamie Bonner
-- Create date: 2022-09-13
-- Description:	Ticket #167333 New report
-- =============================================

CREATE PROCEDURE [dbo].[damages_claims_portal_report]

AS
BEGIN

SET NOCOUNT ON

SELECT 
	dim_fed_hierarchy_history.name		AS [Fee Earner]
	, dim_fed_hierarchy_history.hierarchylevel4hist		AS [Team]
	, dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number		AS [MS Reference]
	, dim_matter_header_current.matter_description			AS [Matter Description]
	, dim_detail_claim.caseman_number				AS [CaseMan Ref Data Field]
	, count_court_ref.reference				AS [CaseMan Ref County Court Associate]
FROM red_dw.dbo.dim_matter_header_current
	INNER JOIN red_dw.dbo.fact_dimension_main
		ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
		ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
	INNER JOIN red_dw.dbo.dim_detail_claim
		ON dim_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
	LEFT OUTER JOIN (
				SELECT DISTINCT
					dim_involvement_full.client_code
					, dim_involvement_full.matter_number
					--, dim_involvement_full.name
					, dim_involvement_full.reference
					, dim_involvement_full.is_active
				FROM red_dw.dbo.dim_involvement_full
				WHERE
					dim_involvement_full.capacity_code = 'COURT'
					AND dim_involvement_full.is_active = 1
					AND (LOWER(dim_involvement_full.name) LIKE '%county court%'
						OR LOWER(dim_involvement_full.name) LIKE '%ccmcc%')
					AND dim_involvement_full.reference IS NOT NULL
				) AS count_court_ref
		ON count_court_ref.client_code = dim_matter_header_current.client_code
			AND count_court_ref.matter_number = dim_matter_header_current.matter_number
WHERE
	dim_matter_header_current.reporting_exclusions = 0
	AND dim_detail_claim.damages_claims_portal = 'Yes'
	AND dim_matter_header_current.date_closed_case_management IS NULL
ORDER BY
	[MS Reference]

END
GO
