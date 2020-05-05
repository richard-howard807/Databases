SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-05-04
-- Description:	New report for Armour recovery files, 57421
-- =============================================
CREATE PROCEDURE [dbo].[ArmourWIP]

AS
BEGIN
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	SET NOCOUNT ON;

SELECT RTRIM(dim_matter_header_current.client_code)+'-'+dim_matter_header_current.matter_number AS [Client/Matter Ref]
	, matter_description AS [Matter Description]
	, matter_owner_full_name AS [Matter Owner]
	, date_opened_case_management AS [Date Opened]
	, proceedings_issued AS [Proceedings Issued]
	, date_claim_concluded AS [Date Claim Concluded]
	, total_recovery AS [Total Recovered]
	, wip AS [WIP]
	, WIP.[WIP - Susan Carville]
	, WIP.[WIP - Ian Young]
	, WIP.[WIP - Andrew Sutton]
	, WIP.[WIP - Laura Moore]
	, WIP.[WIP - Chris Ball]
	, WIP.[WIP - Other]
	, defence_costs_billed AS [Revenue]
	, client_account_balance_of_matter AS [Client Balance]

FROM red_dw.dbo.fact_dimension_main
LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

LEFT OUTER JOIN (SELECT client
	, matter
	, SUM(wip_minutes) wip_minutes
	, SUM(wip_value) wip_value
	, SUM(CASE WHEN name ='Susan Carville' THEN wip_value ELSE NULL END) AS [WIP - Susan Carville]
	, SUM(CASE WHEN name ='Ian Young' THEN wip_value ELSE NULL END) AS [WIP - Ian Young]
	, SUM(CASE WHEN name ='Andrew Sutton' THEN wip_value ELSE NULL END) AS [WIP - Andrew Sutton]
	, SUM(CASE WHEN name ='Laura Moore' THEN wip_value ELSE NULL END) AS [WIP - Laura Moore]
	, SUM(CASE WHEN name ='Chris Ball' THEN wip_value ELSE NULL END) AS [WIP - Chris Ball]
	, SUM(CASE WHEN NOT (name IN ('Susan Carville','Ian Young','Andrew Sutton','Laura Moore','Chris Ball')) THEN wip_value ELSE NULL END) AS [WIP - Other]
FROM red_dw.dbo.fact_wip
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_wip.dim_fed_hierarchy_history_key
WHERE client='00752920'
AND matter_owner='1856'
GROUP BY client,
         matter) AS WIP 
		 ON dim_matter_header_current.client_code=WIP.client AND dim_matter_header_current.matter_number=WIP.matter

WHERE dim_matter_header_current.master_client_code='752920'
AND reporting_exclusions=0
AND matter_owner_full_name='Sam Gittoes'

END
GO
