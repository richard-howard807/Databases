SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/*
===================================================
===================================================
Author:				Julie Loughlin
Created Date:		2022-10-12
Description:		Markerstudy Costs Settled by Costs Unit #169488
Current Version:	Initial Create
====================================================
====================================================

*/
CREATE PROCEDURE [dbo].[Markerstudy_Costs]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;



WITH CTE
AS (SELECT dim_matter_header_current.master_client_code + '-' + dim_matter_header_current.master_matter_number AS [MS Client/Matter Reference],
           matter_description,
           red_dw.dbo.dim_detail_outcome.date_claimants_costs_received AS [Date Costs Received],
           date_costs_settled AS [Date Costs Settled],
		   DATEDIFF(DAY,date_claimants_costs_received,date_costs_settled  ) AS [Days taken to settle],
           CASE
               WHEN fact_finance_summary.tp_total_costs_claimed < '50000' THEN
                   'Y'
               ELSE
                   'N'
           END AS [Delegated (upto £50k)],
           red_dw.dbo.fact_finance_summary.tp_total_costs_claimed AS [Total Claimed],
           red_dw.dbo.fact_finance_summary.claimants_costs_paid [Total Paid],
		   red_dw.dbo.fact_finance_summary.tp_total_costs_claimed- red_dw.dbo.fact_finance_summary.claimants_costs_paid AS [£Savings],
           red_dw.dbo.fact_detail_claim.damages_paid_by_client AS [Damages Paid],
           red_dw.dbo.dim_detail_core_details.proceedings_issued AS [Claim Litigated?],
           cost_handler,
           --atterOwner.fed_code
           matter_owner_full_name AS [Matter Owner],
           fact_finance_summary.[minutes_recorded_cost_handler],
           fact_finance_summary.[time_charge_value_cost_handler]

    FROM red_dw.dbo.dim_matter_header_current
        INNER JOIN red_dw.dbo.fact_dimension_main WITH (NOLOCK)
            ON fact_dimension_main.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH (NOLOCK)
            ON dim_detail_outcome.dim_detail_outcome_key = fact_dimension_main.dim_detail_outcome_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current WITH (NOLOCK)
            ON fact_matter_summary_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_instruction_type WITH (NOLOCK)
            ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
        LEFT OUTER JOIN red_dw.dbo.fact_finance_summary WITH (NOLOCK)
            ON fact_finance_summary.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_claim WITH (NOLOCK)
            ON fact_detail_claim.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
        LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    WHERE red_dw.dbo.dim_matter_header_current.master_client_code IN ( 'C1001', 'W24438' )
          --AND dim_matter_header_current.master_client_code+'-'+dim_matter_header_current.master_matter_number = 'W24438-69'
          AND red_dw.dbo.dim_matter_header_current.date_closed_practice_management IS NULL
          AND red_dw.dbo.dim_matter_header_current.reporting_exclusions <> 1
          AND
          (
              red_dw.dbo.dim_detail_outcome.outcome_of_case IS NULL
              OR RTRIM(LOWER(red_dw.dbo.dim_detail_outcome.outcome_of_case)) <> 'exclude from reports'
          )
          AND red_dw.dbo.dim_fed_hierarchy_history.cost_handler = 1)
SELECT CTE.[MS Client/Matter Reference],
       CTE.matter_description,
	   CTE.[Matter Owner],
	   CTE.cost_handler,
       CTE.[Date Costs Received],
       CTE.[Date Costs Settled],
       CTE.[Days taken to settle],
       CTE.[Delegated (upto £50k)],
       CTE.[Total Claimed],
       CTE.[Total Paid],
       CTE.[£Savings],
       CTE.[Total Claimed] / CTE.[£Savings] AS [% Savings],
       CTE.[Damages Paid],
       CTE.[Claim Litigated?]
FROM CTE;

END 
GO
