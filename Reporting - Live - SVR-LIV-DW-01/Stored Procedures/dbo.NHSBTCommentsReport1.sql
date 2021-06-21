SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NHSBTCommentsReport1]
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@MatterType AS NVARCHAR(MAX)
,@Status AS NVARCHAR(30)
)
AS
 
BEGIN
IF OBJECT_ID('tempdb..#Department') IS NOT NULL DROP TABLE #Department
IF OBJECT_ID('tempdb..#Team') IS NOT NULL DROP TABLE #Team
IF OBJECT_ID('tempdb..#MatterType') IS NOT NULL DROP TABLE #MatterType
SELECT ListValue INTO #Department FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT ListValue INTO #MatterType FROM Reporting.dbo.[udt_TallySplit]('|', @MatterType)
SELECT DISTINCT clNo +'-' + fileNo AS [MS Reference]
--SELECT clNo +'-' + fileNo AS [MS Reference]
,dim_fed_hierarchy_history.name [Matter Owner]
,dim_matter_header_current.matter_description [Matter Description]
,dim_matter_worktype.work_type_name [Matter Type]
,dim_matter_header_current.fee_arrangement AS [Fee Arrangement]
,SUM(fact_finance_summary.fixed_fee_amount) [Fixed Fee Amount]
,SUM(fact_finance_summary.wip) [WIP]
,SUM(fact_finance_summary.disbursement_balance) AS [Unbilled Disbursements]
, udMICoreGeneral.txtNHSBTPO AS [Purchase Order Number]
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus
,dim_fed_hierarchy_history.hierarchylevel4hist [Team]
FROM MS_Prod.config.dbFile
INNER JOIN red_dw.dbo.dim_matter_header_current
ON ms_fileid=dbFile.fileID
INNER JOIN red_dw.dbo.dim_matter_worktype
ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
inner JOIN red_Dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code AND fact_finance_summary.client_code = dim_matter_header_current.client_code
inner JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--inner JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
--inner JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_matter_header_curr_key = dim_detail_finance.dim_matter_header_curr_key
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #MatterType AS MatterType ON MatterType.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT
INNER JOIN MS_Prod.config.dbClient
ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udNHSBTDate
ON udNHSBTDate.fileID = dbFile.fileID
INNER JOIN MS_Prod.dbo.dbUser
ON filePrincipleID=usrID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral
ON udMICoreGeneral.fileID = dbFile.fileID
WHERE hierarchylevel2hist='Legal Ops - LTA'
AND CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END = ISNULL(@Status,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END)
 
 GROUP BY 
clNo +'-' + fileNo 
--SELECT clNo +'-' + fileNo AS [MS Reference]
,dim_fed_hierarchy_history.name 
,dim_matter_header_current.matter_description 
,dim_matter_worktype.work_type_name 
,dim_matter_header_current.fee_arrangement
--,fact_finance_summary.fixed_fee_amount
--,SUM(fact_finance_summary.wip) [WIP]
--,SUM(fact_finance_summary.disbursement_balance) AS [Unbilled Disbursements]
, udMICoreGeneral.txtNHSBTPO 
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END 
,dim_fed_hierarchy_history.hierarchylevel4hist 
 
ORDER BY  [MS Reference]
END
GO
