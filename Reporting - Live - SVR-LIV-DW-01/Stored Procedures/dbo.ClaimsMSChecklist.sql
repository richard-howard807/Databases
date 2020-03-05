SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/*
		Author: Kevin Hansen
		Date Created: ??
		
		==============
		1.1 LD 20180910 Amended to exclude other work types from turning yellow in the report
*/



CREATE PROCEDURE [dbo].[ClaimsMSChecklist]
AS
BEGIN


DELETE FROM dbo.ClaimsMSChecklistData
WHERE CurrentWeek=datepart(ww, getdate())
AND CurrentYear =datepart(YEAR, getdate()) 

INSERT INTO dbo.ClaimsMSChecklistData
(
client 
,[matter number]
,[matter description]
,[matter owner]
,[dim_fed_hierarchy_history_key]
,[leaver]
,[team]
,[department]
,[Client Name]
,[date opened]
,[date closed]
,[work type code]
,[work type] 
,[fee arrangement]
,[referral reason] 
,[present position] 
,[profit costs billed]
,[total billed]
,[date of last bill]
,[date of last time record]
,[wip]
,[unbilled disbursements]
,[Unpaid bill balance]
,[client balance]
,[MI exception number]
,RedLogic
,WorktypeException
,InsertDate
,CurrentWeek
,CurrentYear
)

SELECT 
client AS client 
,matter AS [matter number]
,mg_descrn AS [matter description]
,name AS [matter owner]
,dim_fed_hierarchy_history.dim_fed_hierarchy_history_key
,leaver AS [leaver]
,hierarchylevel4hist AS [team]
,hierarchylevel3hist AS [department]
,dim_client.client_name AS [Client Name]
,date_opened  AS [date opened]
,date_closed AS [date closed]
,work_type_code AS [work type code]
,work_type_name AS [work type] 
,output_wip_fee_arrangement AS [fee arrangement]
,referral_reason AS [referral reason] 
,dim_detail_core_details.present_position AS [present position] 
,defence_costs_billed AS [profit costs billed]
,total_amount_billed AS [total billed]
,last_bill_date AS [date of last bill]
,last_time_transaction_date AS [date of last time record]
,wip AS [wip]
,fact_finance_summary.disbursement_balance AS [unbilled disbursements]
,fact_finance_summary.unpaid_bill_balance AS [Unpaid bill balance]
,fact_finance_summary.client_account_balance_of_matter AS [client balance]
,ISNULL(ExceptionTotal,0) AS [MI exception number]
,CASE WHEN 
DATEDIFF(MONTH,last_time_transaction_date ,GETDATE())>3 AND 
ISNULL(fact_finance_summary.disbursement_balance,0)=0 AND 
ISNULL(fact_finance_summary.unpaid_bill_balance,0)=0 AND 
ISNULL(fact_finance_summary.client_account_balance_of_matter,0)=0  AND 
[wip] <50 AND ISNULL(ExceptionTotal,0)=0
 THEN 1 ELSE 0 END AS RedLogic

,CASE WHEN work_type_code  LIKE '12%'
		OR work_type_code  LIKE '13%'
		OR work_type_code  LIKE '14%'
		OR work_type_code  LIKE '15%'
		OR work_type_code  IN ('0034','0032')
		-- LD 10/09/2018 added the additional as per AM Ticket 335393
		OR work_type_code IN ('0003','0004'    
					,'0005','0006','0011','0013' 
					,'0016','0017','0022','0023','0026'    
					,'0028','0029','1024','1025' 
					,'1111','1112','1113','1145'
					,'1146')


 THEN 0 ELSE 1  END  AS WorktypeException
 
,CONVERT(DATE,GETDATE(),103) AS InsertDate
,DATEPART(ww, GETDATE()) AS CurrentWeek
,DATEPART(YEAR, GETDATE()) AS CurrentYear
FROM axxia01.dbo.cashdr WITH(NOLOCK)
INNER JOIN axxia01.dbo.camatgrp  WITH(NOLOCK) 
 ON client=mg_client AND matter=mg_matter
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history  WITH(NOLOCK) 
 ON mg_feearn=fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
LEFT  JOIN red_dw.dbo.fact_dimension_main  WITH(NOLOCK) 
 ON client=fact_dimension_main.client_code 
 AND matter=fact_dimension_main.matter_number
LEFT JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK)
 ON fact_dimension_main.client_code=dim_matter_header_current.client_code
 AND fact_dimension_main.matter_number=dim_matter_header_current.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_finance_summary  WITH(NOLOCK) 
 ON client=fact_finance_summary.client_code AND matter=fact_finance_summary.matter_number
LEFT OUTER JOIN red_dw.dbo.fact_matter_summary_current  WITH(NOLOCK) 
 ON client=fact_matter_summary_current.client_code 
 AND matter=fact_matter_summary_current.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_client  WITH(NOLOCK) 
 ON client=dim_client.client_code
LEFT OUTER JOIN red_dw.dbo.dim_matter_worktype WITH(NOLOCK) 
 ON dim_matter_header_current.dim_matter_worktype_key=dim_matter_worktype.dim_matter_worktype_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_finance WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_finance_key=dim_detail_finance.dim_detail_finance_key
LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON fact_dimension_main.dim_detail_core_detail_key=dim_detail_core_details.dim_detail_core_detail_key
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
FROM red_dw.dbo.ds_sh_exceptions_datasets d WITH(NOLOCK) WHERE d.dss_current_flag = 'Y' 
AND datasetid=202
                                            ))
                           
                            ) exceptions
                   GROUP BY case_id) AS Exceptions
                    ON dim_matter_header_current.case_id=exceptions.case_id

WHERE mg_datcls IS NULL
AND hierarchylevel2hist='Legal Ops - Claims'
AND  mg_matter <>'ML'
AND mg_client  NOT IN ('00030645','00453737','95000C','P00016')

END

GO
