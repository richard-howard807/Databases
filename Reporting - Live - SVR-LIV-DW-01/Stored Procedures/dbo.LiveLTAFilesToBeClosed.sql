SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Orlagh Kelly 
-- Create date: 04-12-2018
-- Description:	 report to drive the LTA Live files to be closed 

--Opened before 1 June 2018 
--With no time recording since 1 April 2018-- With less than £50 WIP--With 0 balances against bills/disbursements/client account
-- =============================================
CREATE PROCEDURE [dbo].[LiveLTAFilesToBeClosed]
-- Add the parameters for the stored procedure here

AS
BEGIN

    SET NOCOUNT ON;

    -- Insert statements for procedure here
    SELECT RTRIM(fact_dimension_main.client_code) + '/' + fact_dimension_main.matter_number AS [Weightmans Reference],
           RTRIM(dim_matter_header_current.master_client_code) + '-' + dim_matter_header_current.master_client_code AS [Mattershere Weightmans Reference],
		   fact_finance_summary.disbursement_balance,
           CASE
               WHEN fact_dimension_main.dim_open_case_management_date_key <= 20180601
                    AND last_time_transaction_date <= '2018-04-01'
                    AND wip < 50
                    AND
                    (
                        fact_finance_summary.disbursement_balance IS NULL
                        OR fact_finance_summary.disbursement_balance = 0
                    )
                    AND
                    (
                        fact_finance_summary.client_account_balance_of_matter IS NULL
                        OR fact_finance_summary.client_account_balance_of_matter = 0
                    )
                    AND
                    (
                        fact_finance_summary.unpaid_bill_balance IS NULL
                        OR fact_finance_summary.unpaid_bill_balance = 0
                    ) THEN
                   'To Close'
               WHEN fact_dimension_main.dim_open_case_management_date_key <= 20180601
                    AND last_time_transaction_date <= '2018-04-01'
                    AND wip < 50
                    AND
                    (
                        fact_finance_summary.disbursement_balance IS NULL
                        OR fact_finance_summary.disbursement_balance = 0
                    )
                    AND
                    (
                        fact_finance_summary.client_account_balance_of_matter IS NULL
                        OR fact_finance_summary.client_account_balance_of_matter = 0
                    )
                    AND fact_finance_summary.unpaid_bill_balance IS NOT NULL THEN
                   'To Close but bill balance'
               WHEN fact_dimension_main.dim_open_case_management_date_key <= 20180601
                    AND last_time_transaction_date <= '2018-04-01'
                    AND wip < 50
                    AND
                    (
                        fact_finance_summary.disbursement_balance IS NULL
                        OR fact_finance_summary.disbursement_balance = 0
                    )
                    AND fact_finance_summary.client_account_balance_of_matter IS NOT NULL
                    AND
                    (
                        fact_finance_summary.unpaid_bill_balance IS NULL
                        OR fact_finance_summary.unpaid_bill_balance = 0
                    ) THEN
                   'To Close but Client Balance'
               WHEN dim_fed_hierarchy_history.name = 'Property View' THEN
                   'PRV'
               ELSE
                   'Live'
           END AS [Status ],
           matter_description AS [Matter Description ],
           dim_fed_hierarchy_history.name [Case Manger Name],
           dim_fed_hierarchy_history.[worksforname] [Team  Managers Name],
           branch [Office],
           dim_fed_hierarchy_history.hierarchylevel4hist [Team],
           dim_fed_hierarchy_history.hierarchylevel2hist [Department],
           dim_matter_worktype.work_type_name AS [Work Type ],
           dim_client.client_name [Client Name],
           red_dw.dbo.dim_matter_header_current.date_opened_case_management [Open Date ],
           red_dw.dbo.dim_matter_header_current.date_closed_case_management [Closed Date ],
           total_amount_bill_non_comp [Total Bill Amount - Composite (Inc. VAT )],
           defence_costs_billed [Revenue Costs Billed ],
           disbursements_billed [Disbursements Billed ],
           vat_billed [VAT Billed],
           wip [WIP],
           total_unbilled_disbursements_vat AS [Unbilled Disbursements],
           fact_finance_summary.client_account_balance_of_matter [Client Account Balance of Matter],
           fact_matter_summary_current.unpaid_bill_balance [Unpaid Bill Balance ],
           last_bill_date [Last Bill Date],
           last_time_transaction_date [Date of Last time Posting  ]
    FROM red_dw.dbo.fact_dimension_main
        INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
            ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
        INNER JOIN red_dw.dbo.dim_client
            ON dim_client.client_code = fact_dimension_main.client_code
        LEFT OUTER JOIN red_dw.dbo.dim_detail_client
            ON fact_dimension_main.client_code = dim_detail_client.client_code
               AND dim_detail_client.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.dim_matter_header_current
            ON dim_matter_header_current.client_code = fact_dimension_main.client_code
               AND dim_matter_header_current.matter_number = fact_dimension_main.matter_number
        INNER JOIN red_dw.dbo.fact_detail_client
            ON fact_dimension_main.master_fact_key = fact_detail_client.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_client_involvement
            ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
        LEFT OUTER JOIN red_dw.dbo.dim_claimant_thirdparty_involvement
            ON dim_claimant_thirdparty_involvement.dim_claimant_thirdpart_key = fact_dimension_main.dim_claimant_thirdpart_key
        LEFT OUTER JOIN red_dw.dbo.dim_defendant_involvement
            ON dim_defendant_involvement.dim_defendant_involvem_key = fact_dimension_main.dim_defendant_involvem_key
        INNER JOIN red_dw.dbo.fact_finance_summary
            ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome
            ON dim_detail_outcome.client_code = dim_matter_header_current.client_code
               AND dim_detail_outcome.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details
            ON dim_detail_core_details.client_code = dim_matter_header_current.client_code
               AND dim_detail_core_details.matter_number = dim_matter_header_current.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_previous_details
            ON dim_detail_previous_details.client_code = fact_dimension_main.client_code
               AND dim_detail_previous_details.matter_number = fact_dimension_main.matter_number
        LEFT OUTER JOIN red_dw.dbo.dim_detail_hire_details
            ON dim_detail_hire_details.dim_detail_hire_detail_key = fact_dimension_main.dim_detail_hire_detail_key
        LEFT OUTER JOIN red_dw.dbo.fact_detail_recovery_detail
            ON fact_detail_recovery_detail.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
            ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
        LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype
            ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
            ON red_dw.dbo.dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_incident
            ON dim_detail_incident.dim_detail_incident_key = fact_dimension_main.dim_detail_incident_key
        LEFT OUTER JOIN red_dw.dbo.dim_detail_compliance
            ON dim_detail_compliance.dim_detail_compliance_key = fact_dimension_main.dim_detail_compliance_key
    WHERE hierarchylevel2hist LIKE '%LTA%'
          AND dim_matter_header_current.date_closed_practice_management IS NULL
          --AND fact_dimension_main.dim_open_case_management_date_key <= 20180601
          --AND last_time_transaction_date <= '2018-08-01'
          --AND wip < 50
          AND fact_dimension_main.matter_number <> 'ML'
          AND reporting_exclusions <> 1

    --AND
    --(
    --    (
    --        fact_finance_summary.disbursement_balance IS NULL
    --        OR fact_finance_summary.disbursement_balance = 0
    --    )
    --    OR
    --    (
    --        fact_finance_summary.client_account_balance_of_matter IS NULL
    --        OR fact_finance_summary.client_account_balance_of_matter = 0
    --    )
    --    OR
    --    (
    --        fact_finance_summary.unpaid_bill_balance IS NULL
    --        OR fact_finance_summary.unpaid_bill_balance = 0
    --    )
    ;







END;
GO
