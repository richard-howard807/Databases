SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[RMG_Royal_Mail_File_Closure_Report]

(
@CloseDateFrom AS DATE, 
@CloseDateTo AS date
)

AS 

/* Testing*/
--DECLARE 
--@CloseDateFrom AS DATE = GETDATE() -300, 
--@CloseDateTo AS DATE = GETDATE()

SELECT 

[Client Matter] = fact_dimension_main.master_client_code +'-'+master_matter_number,
[Date Opened] = CAST(date_opened_case_management AS DATE),
[Date Closed] = CAST(date_closed_case_management AS DATE),
[Matter Owner] = name,
[Team] = hierarchylevel4hist,
[Department] = hierarchylevel3hist,
[Case Description] = matter_description,
[BE Number] = dim_detail_property.[be_number],
[BE Name] = dim_detail_property.[be_name], 
[Case Classification] = dim_detail_property.[case_classification], 
[Completion Date] = CAST(dim_detail_property.[completion_date] AS DATE), 
[Tracker ID] = dim_detail_property.[client_case_reference],
[Fees Billed] = fact_finance_summary.defence_costs_billed_composite ,
[Invoice Number] =    --– if multiple invoices, please list
 STUFF(
             (SELECT ',' + bill_number
              FROM red_dw.dbo.fact_bill 
              WHERE fact_bill.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
              AND bill_number <> 'PURGE' 
			  GROUP BY bill_number
			  ORDER BY bill_number
			  FOR XML PATH (''))
             , 1, 1, '') 

FROM 

red_dw.dbo.fact_dimension_main
JOIN red_dw.dbo.dim_matter_header_current
ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
JOIN red_dw.dbo.dim_client
ON dim_client.dim_client_key = fact_dimension_main.dim_client_key
JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_detail_property
ON dim_detail_property.dim_detail_property_key = fact_dimension_main.dim_detail_property_key
LEFT JOIN red_dw.dbo.fact_finance_summary
ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key

WHERE 1 = 1 
AND dim_client.[client_group_name] = 'Royal Mail'

--Department = Real Estate, plus the Property Litigation team
AND (TRIM(hierarchylevel4hist) IN ('Property Litigation' ) OR TRIM(hierarchylevel3hist) = 'Real Estate' )

AND CAST(date_closed_case_management AS DATE) BETWEEN @CloseDateFrom AND @CloseDateTo

AND reporting_exclusions = 0
GO
