SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 04/04/2022
-- Description:	#141323 Initial Create for Hastings Costs Settlements recommendations

--JL added in child detail 
-- =============================================
CREATE PROCEDURE [dbo].[HastingsCostsSettlement] --EXEC [dbo].[HastingsCostsSettlement]'20120101',  '20220401'
    -- Add the parameters for the stored procedure here
    @DateFrom AS DATE,
    @DATETo AS DATE
AS
BEGIN
    -- SET NOCOUNT ON added to prevent extra result sets from
    -- interfering with SELECT statements.
    SET NOCOUNT ON;

    SELECT

        --, dim_matter_header_current.matter_description  AS [Matter Description]
        [HASTINGS CLAIM REFERENCE] = COALESCE(insurerclient_reference, client_reference),
        dim_detail_core_details.[clients_claims_handler_surname_forename] AS [Hastings lloss Handler],
        dim_matter_header_current.master_client_code + '/' + dim_matter_header_current.master_matter_number AS [Supplier Reference],
        dim_fed_hierarchy_history.[name] AS [Supplier Handler],
        dim_detail_client.[hastings_policyholder_last_name] AS [Policy Holder Name],
        '' AS [Third Party Name],
        dim_detail_core_details.[incident_date] AS [Date of Accident],
        dim_detail_outcome.[date_claimants_costs_received] AS [Date of Costs Received],
        '' AS [Date of Supplier Advice],
        COALESCE(dim_detail_claim.dst_claimant_solicitor_firm, dim_detail_claim.dst_claimant_solicitor_firm) AS [Third Party Solicitor Firm],
        dim_detail_claim.[hastings_jurisdiction] AS [Jurisdiction],
        dim_detail_core_details.[proceedings_issued] AS [Litigated],
        fact_finance_summary.[tp_total_costs_claimed] AS [Total Third Party Solicitors Costs Claimed],
        '' AS [Max Recommened Offer],
        '' AS [Potential Saving %],
        fact_detail_reserve_detail.[claimant_costs_reserve_current] AS [Recommeded Total Third Party Solicitors Costs Reserve],
        fact_finance_summary.[defence_costs_reserve] AS [Recommeded Own Costs Reserve],
        dim_detail_outcome.[date_claimants_costs_received],
		dim_parent_detail1.[hastings_date_of_suppliers_costs_advice],
		dim_parent_detail1.[hastings_max_recommended_costs_offer]

    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
            ON fact_detail_paid_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON fact_dimension_main.dim_detail_client_key = dim_detail_client.dim_detail_client_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_reserve_detail
            ON fact_detail_reserve_detail.master_fact_key = fact_dimension_main.master_fact_key
 LEFT JOIN
    (
        SELECT DISTINCT
               MAX(fact_child_detail.[hastings_max_recommended_costs_offer]) AS [hastings_max_recommended_costs_offer],
               MAX(dim_child_detail.[hastings_date_of_suppliers_costs_advice]) AS [hastings_date_of_suppliers_costs_advice],
               dim_child_detail.client_code,
               dim_child_detail.matter_number
        FROM red_dw.dbo.dim_parent_detail
            LEFT JOIN red_dw.dbo.dim_child_detail
                ON dim_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key
            LEFT JOIN red_dw.dbo.fact_child_detail
                ON fact_child_detail.dim_parent_key = dim_parent_detail.dim_parent_key

        --WHERE dim_child_detail.client_code = '00004908' --AND dim_child_detail.matter_number = '00000006'	-- 4908/6

        GROUP BY dim_child_detail.client_code,
                 dim_child_detail.matter_number
    ) AS dim_parent_detail1
        ON dim_parent_detail1.client_code = fact_dimension_main.client_code
           AND dim_parent_detail1.matter_number = fact_dimension_main.matter_number
 

    WHERE dim_matter_header_current.client_code = '00004908'
          AND dim_matter_header_current.reporting_exclusions = 0
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'
          AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from Reports'
          AND dim_matter_header_current.matter_number <> 'ML';
--AND  dim_detail_outcome.[date_claimants_costs_received] between @DateFrom and @DateTo
END;
GO
