SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[NHSBTCommentsReport1_test]-- 'Corp-Comm|Litigation|Real Estate', 'Commercial National|Property Ltigation|Real Estate Liverpool','Edwina Farrell','Open'
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

SELECT DISTINCT 
clNo +'-' + fileNo AS [MS Reference]
--SELECT clNo +'-' + fileNo AS [MS Reference]
,dim_fed_hierarchy_history.name [Matter Owner]
,dim_matter_header_current.matter_description [Matter Description]
,dim_matter_worktype.work_type_name [Matter Type]
,dim_matter_header_current.fee_arrangement AS [Fee Arrangement]
,fact_finance_summary.fixed_fee_amount [Fixed Fee Amount]
,fact_finance_summary.wip [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
, udMICoreGeneral.txtNHSBTPO AS [Purchase Order Number]
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus
,dim_fed_hierarchy_history.hierarchylevel3hist
,dim_fed_hierarchy_history.hierarchylevel4hist [Team]

--,dim_detail_client.[fee_arrangement] [Fee Arrangement other ]
--,fact_detail_paid_detail.[output_wip_contingent_wip] [WIP Contingent]
--,fact_detail_paid_detail.[output_wip_hourly_rate] [WIP Hourly Rate]
--,fact_detail_paid_detail.[output_wip_other_tbc_wip] [WIP TBC ]
--,fact_detail_paid_detail.[output_wip_fixed_fee_value] [WIP FF Value]
--,fact_detail_paid_detail.[output_wip_balance] [WIP Balance]
--,fact_detail_paid_detail.[output_wip_total_output_wip][WIP Total Output]
--,dim_detail_finance.[output_wip_fee_arrangement] [WIP Fee Arrangment]


FROM MS_Prod.config.dbFile
INNER JOIN red_dw.dbo.dim_matter_header_current ON ms_fileid=dbFile.fileID
INNER JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN MS_Prod.config.dbClient ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udNHSBTDate ON udNHSBTDate.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral ON udMICoreGeneral.fileID = dbFile.fileID
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code 
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
INNER JOIN #Department AS Department ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #MatterType AS MatterType ON MatterType.ListValue COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT


WHERE hierarchylevel2hist='Legal Ops - LTA'
AND CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END = ISNULL(@Status,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END)
 
--and
 --dim_matter_header_current.client_code = '00707938' AND dim_matter_header_current.matter_number = '00001390'


-- GROUP BY
--clNo +'-' + fileNo 
----SELECT clNo +'-' + fileNo AS [MS Reference]
--,dim_fed_hierarchy_history.name 
--,dim_matter_header_current.matter_description 
--,dim_matter_worktype.work_type_name 
--,dim_matter_header_current.fee_arrangement
----,fact_finance_summary.fixed_fee_amount
----,SUM(fact_finance_summary.wip) [WIP]
----,SUM(fact_finance_summary.disbursement_balance) AS [Unbilled Disbursements]
--, udMICoreGeneral.txtNHSBTPO 
--,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END 
--,dim_fed_hierarchy_history.hierarchylevel4hist 
 
ORDER BY  [MS Reference]
END

--SELECT * FROM red_dw.dbo.dim_detail_client
GO
