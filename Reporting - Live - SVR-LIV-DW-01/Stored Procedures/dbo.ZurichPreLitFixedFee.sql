SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

--============================================
-- ES 11-03-2021 #90787, amended some field logic and added key dates
--============================================

CREATE PROCEDURE [dbo].[ZurichPreLitFixedFee]

AS 

BEGIN

SELECT DISTINCT
REPLACE(LTRIM(REPLACE(RTRIM(fact_dimension_main.[master_client_code]), '0', ' ')), ' ', '0') + '-'
+ REPLACE(LTRIM(REPLACE(RTRIM([master_matter_number]), '0', ' ')), ' ', '0') AS [Mattersphere Weightmans Reference],
dim_matter_header_current.matter_description [Matter Description],
dim_matter_header_current.date_opened_case_management [Date Case Opened],
dim_fed_hierarchy_history.name [Case Manager],
dim_fed_hierarchy_history.hierarchylevel4hist [Team],
dim_matter_worktype.work_type_name [Matter Type],
dim_detail_client.zurich_instruction_type [Instruction Type], 
dim_matter_header_current.client_group_name [Client Group Name], 
red_dw.dbo.dim_detail_core_details.proceedings_issued [Proceedings Issued], 
dim_detail_core_details.fixed_fee [Fixed Fee],
dim_detail_finance.output_wip_fee_arrangement [Fee Arrangement], 
fact_bill_detail_summary.bill_total AS [Total Bill Amount - Composite (IncVAT )],
fact_finance_summary.[defence_costs_billed] AS [Revenue Costs Billed],
fact_bill_detail_summary.disbursements_billed_exc_vat AS [Disbursements Billed ],
fact_finance_summary.vat_billed AS [VAT Billed],
fact_finance_summary.wip AS [WIP],
fact_finance_summary.disbursement_balance AS [Unbilled Disbursements],

fact_bill_matter.last_bill_date [Last Bill Date Composite ],
fact_matter_summary_current.[last_time_transaction_date] AS [Date of Last Time Posting]




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





WHERE dim_matter_header_current.client_group_code = '00000001'
AND dim_matter_header_current.date_closed_case_management IS NULL 
AND dim_matter_header_current.reporting_exclusions = 0 
AND (dim_matter_worktype.work_type_name = 'Claims Handling                         ' OR LOWER(dim_detail_client.zurich_instruction_type) LIKE '%outsource%')


END
GO
