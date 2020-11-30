SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[InternalWeightmansInstructions]

AS 

BEGIN

SELECT DISTINCT
       dim_matter_header_current.client_code AS [Client Code ],
       dim_matter_header_current.matter_number [Matter Number ],
       matter_description [Matter Description],
      dim_fed_hierarchy_history.name [Fee Earner Name],
       dim_client.client_partner_name,
       CASE
           WHEN red_dw.dbo.dim_fed_hierarchy_history.hierarchylevel2hist LIKE '%LTA%' THEN
               'LTA'
           ELSE
               'Claims'
       END AS [LTA or Claims? ],
       --hierarchylevel2hist
       workphone AS [Telephone],
       fact_matter_summary_current.date_opened_case_management [File Open Date ],
       fact_matter_summary_current.last_time_transaction_date [Last Correspondence Date ],
       defence_costs_billed [Revenue ],
       fact_matter_summary_current.time_billed [Total Time Billed ],
	    total_amount_billed [Total Amount Billed -new],
		vat_billed [Vat Billed ],
       -- fact_bill_detail_summary.disbursements_billed_exc_vat ,
       fact_matter_summary_current.unbilled_time [Unbilled Time],
       disbursements_billed [Disbursements Billed ],
       total_unbilled_disbursements_vat [Unbilled Disbursements ],
       fee_estimate [Fee Estimate],
       dim_detail_claim.comments [Comments],
       -- [Comments] , 
       CASE
           WHEN dim_matter_header_current.date_closed_case_management IS NOT NULL THEN
               'Closed'
           ELSE
               'Open'
       END AS [Status]
FROM red_dw.dbo.fact_dimension_main
    LEFT OUTER JOIN red_dw.dbo.dim_matter_header_current
        ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
    LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
        ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
    LEFT OUTER JOIN red_dw.dbo.fact_finance_summary
        ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.dim_detail_claim
        ON dim_detail_claim.dim_detail_claim_key = fact_dimension_main.dim_detail_claim_key
    LEFT OUTER JOIN red_dw.dbo.dim_client
        ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
    LEFT OUTER JOIN red_dw.dbo.dim_employee
        ON dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
    LEFT OUTER JOIN red_dw.dbo.fact_detail_paid_detail
        ON fact_dimension_main.master_fact_key = fact_detail_paid_detail.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current
        ON fact_matter_summary_current.master_fact_key = fact_dimension_main.master_fact_key
    LEFT OUTER JOIN red_dw.dbo.fact_bill_detail_summary
        ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key

    LEFT OUTER JOIN red_dw.dbo.dim_detail_client
        ON dim_detail_client.dim_detail_client_key = fact_dimension_main.dim_client_key

WHERE --dim_matter_header_current.client_code = 'W00001'
    dim_matter_header_current.client_code IN ( '00047354')
	--, '00251359', 'W00001', '00006930' )
	

    --dim_matter_header_current.client_code = '00047354'
    --AND dim_matter_header_current.matter_number IN ('00000123', '00000138', '00000139')


    --      dim_matter_header_current.date_closed_case_management >= @nDate
    AND dim_matter_header_current.date_closed_case_management IS NULL
	AND dim_matter_header_current.matter_number <> 'ML';

END
GO
