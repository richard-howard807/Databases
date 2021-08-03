SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[CasualtyInsuredClientReport]

AS 
SELECT DISTINCT
dim_matter_header_current.master_client_code [Client], 
dim_matter_header_current.master_matter_number [Matter],
dim_matter_header_current.client_name [Client Name], 
dim_matter_header_current.matter_description [Description], 
dim_fed_hierarchy_history.name [Name], 
dim_fed_hierarchy_history.hierarchylevel4hist [Team], 
dim_matter_worktype.work_type_name [Work type ], 
dim_matter_header_current.date_opened_case_management [Open Date], 
dim_matter_header_current.date_closed_case_management [Closed Date ], 
dim_client_involvement.insuredclient_name [Insured Client Name] , 
dim_detail_claim.dst_insured_client_name [Reviewed Insured Client Details ], 
dim_detail_core_details.referral_reason [Referral Reason], 
    RTRIM(dim_detail_core_details.present_position) AS [Present Position],
	CASE WHEN zurich_is_the_instruction_a_customer_nomination = 'N' THEN 'No'
	WHEN  zurich_is_the_instruction_a_customer_nomination = 'Y' THEN 'Yes'
	ELSE ''  END AS [Zurich is the instruction a Customer Notifcation], 
	dim_matter_worktype.work_type_group [Work Type Group], 


dim_detail_outcome.outcome_of_case [Outcome of Case ]


FROM 

red_Dw.dbo.fact_dimension_main 
LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.dim_matter_header_curr_key = fact_dimension_main.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_core_details ON dim_detail_core_details.dim_detail_core_detail_key = fact_dimension_main.dim_detail_core_detail_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = fact_dimension_main.dim_fed_hierarchy_history_key
LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_matter_header_curr_key = dim_detail_core_details.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_matter_header_curr_key = dim_detail_client.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo. fact_bill_detail_summary ON fact_bill_detail_summary.master_fact_key = fact_dimension_main.master_fact_key
LEFT JOIN red_dw.dbo.fact_bill_matter ON fact_bill_matter.dim_matter_header_curr_key = dim_detail_client.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_matter_summary_current ON fact_matter_summary_current.dim_client_key = fact_bill_matter.dim_client_key
LEFT JOIN red_dw.dbo.dim_client_involvement ON dim_client_involvement.dim_client_involvement_key = fact_dimension_main.dim_client_involvement_key
LEFT JOIN red_dw.dbo.dim_detail_claim ON dim_detail_claim.dim_matter_header_curr_key = dim_detail_client.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_detail_outcome ON dim_detail_outcome.dim_matter_header_curr_key = dim_detail_claim.dim_matter_header_curr_key


WHERE dim_matter_header_current.date_opened_case_management >= '2017-01-01'
AND dim_fed_hierarchy_history.hierarchylevel3hist IN ('Casualty')
AND dim_matter_header_current.ms_only = 1
AND dim_matter_header_current.reporting_exclusions = 0 
AND ISNULL(dim_detail_outcome.outcome_of_case, '') <> 'Exclude from reports'


ORDER BY dim_matter_header_current.date_opened_case_management asc







GO
