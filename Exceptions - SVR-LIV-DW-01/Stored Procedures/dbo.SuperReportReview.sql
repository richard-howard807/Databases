SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[SuperReportReview]
(
@Division AS NVARCHAR(1000)
)
AS
BEGIN
SELECT 
dim_matter_header_current.client_code AS client                                    
,dim_matter_header_current.client_name AS [Client Name]
,dim_fed_hierarchy_history.display_name AS [Matter  Fee Earner]
,dim_matter_header_current.matter_partner_full_name AS [Matter Partner]
,dim_matter_header_current.matter_description AS [Description]
,wip AS [wip]      
,fact_finance_summary.disbursement_balance AS [Disb Bal]
,ISNULL(wip,0) + ISNULL(fact_finance_summary.disbursement_balance,0) AS [WIP + Disbs]
,dim_matter_header_current.date_opened_practice_management AS [Date Opened]
,last_time_transaction_date AS [Last Time]
,last_bill_date AS [Last Bill]
,fact_finance_summary.client_account_balance_of_matter As [Client Balance]
,fact_finance_summary.unpaid_bill_balance AS [Unpaid Bills]
,final_bill_date AS [Final Bill]
,portal_status As [Portal Status]
,dim_detail_client.[fee_arrangement] AS [Fee Arrangement (Type)]
,fact_finance_summary.[fixed_fee_amount] AS [Fee Arrangement (Value)]
,dim_detail_finance.[output_wip_percentage_complete]AS [Fee Arrangement (Percentage Completion)]
,ISNULL(ExceptionTotal,0) AS [Total MI Exceptions]
,dim_detail_core_details.[present_position] AS [Present Position]
,dim_detail_core_details.[proceedings_issued] As [Proceedings Issued]
,DATEDIFF(DAY,dim_matter_header_current.date_opened_practice_management,COALESCE(dim_detail_outcome.[date_claim_concluded],GETDATE())) AS [Elapsed Days – Open]
,dim_detail_core_details.[date_initial_report_sent] AS [Initial Report]
,dim_detail_outcome.[date_claim_concluded] As [Date Claim Concluded]
,dim_detail_outcome.[date_costs_settled] AS [Date Costs Concluded]
FROM red_dw.dbo.dim_matter_header_current
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK) 
 ON dim_matter_header_current.fee_earner_code=fed_code collate database_default AND dss_current_flag='Y'
LEFT  JOIN red_dw.dbo.fact_dimension_main  WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=fact_dimension_main.client_code 
 AND dim_matter_header_current.matter_number=fact_dimension_main.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary  WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=fact_finance_summary.client_code AND dim_matter_header_current.matter_number=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current  WITH(NOLOCK) 
 ON dim_matter_header_current.client_code=fact_matter_summary_current.client_code 
 AND dim_matter_header_current.matter_number=fact_matter_summary_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client
 ON dim_matter_header_current.client_code=dim_client.client_code
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK) 
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_outcome WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_outcome_key=dim_detail_outcome.dim_detail_outcome_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_client WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_client_key=dim_detail_client.dim_detail_client_key

LEFT OUTER JOIN (SELECT   case_id
                           ,SUM(ExceptionCount) AS ExceptionTotal
                           ,SUM(CriticalCount) AS CriticalTotal
                   FROM     ( SELECT    ex.case_id
                                       ,1 AS ExceptionCount
                                       ,CAST(ISNULL(ex.critical, 0) AS INT) AS CriticalCount
                                       ,LEFT(flink.detailsused,
                                             LEN(flink.detailsused)
                                             - CHARINDEX(',',
                                                         flink.detailsused)) AS MainDetail
                                       ,COALESCE(df.alias, f.fieldname) AS FieldName
                              FROM      red_dw.dbo.fact_exceptions_update ex WITH(NOLOCK) 
                              INNER JOIN red_dw.dbo.ds_sh_exceptions_fields f 
                                        ON ex.exceptionruleid = f.fieldid
                                           AND f.dss_current_flag = 'Y'
                              INNER JOIN red_dw.dbo.ds_sh_exceptions_dataset_fields df WITH(NOLOCK)
                                        ON f.fieldid = df.fieldid
                                           AND df.dss_current_flag = 'Y'
                              LEFT JOIN red_dw.dbo.ds_sh_exceptions_fields flink WITH(NOLOCK)
                                        ON f.linkedfieldid = flink.fieldid
                                           AND flink.dss_current_flag = 'Y'
                              WHERE     df.datasetid = ex.datasetid
                              AND duplicate_flag=0
                                        AND ( df.datasetid IN (
                                              SELECT d.datasetid
FROM red_dw.dbo.ds_sh_exceptions_datasets d WITH(NOLOCK) where d.dss_current_flag = 'Y' 
                                            ))
                           
                            ) exceptions
                   GROUP BY case_id) AS Exceptions
                    ON dim_matter_header_current.case_id=exceptions.case_id

WHERE dim_matter_header_current.date_closed_practice_management IS NULL
AND hierarchylevel2hist=@Division
AND  dim_matter_header_current.matter_number <>'ML'
AND dim_matter_header_current.client_code  NOT IN ('00030645','00453737','95000C','P00016')


END
GO
