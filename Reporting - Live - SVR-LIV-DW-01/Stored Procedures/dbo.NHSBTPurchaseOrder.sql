SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE  PROCEDURE [dbo].[NHSBTPurchaseOrder]
(

@Team AS NVARCHAR(MAX)
,@Name AS NVARCHAR(MAX)
,@Open AS NVARCHAR(MAX)
)

AS


BEGIN

----IF OBJECT_ID('tempdb..#Open') IS NOT NULL   DROP TABLE #Open
IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
IF OBJECT_ID('tempdb..#Name') IS NOT NULL   DROP TABLE #Name

----SELECT ListValue  INTO #Open FROM Reporting.dbo.[udt_TallySplit]('|', @Open)
--SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
--SELECT ListValue  INTO #Name FROM Reporting.dbo.[udt_TallySplit]('|', @Name)

SELECT clNo +'-' + fileNo AS [MS Reference]
,dim_fed_hierarchy_history.name [Matter Owner]
,dim_matter_header_current.matter_description [Matter Description]
,dim_matter_worktype.work_type_name [Matter Type]
,   RTRIM(ISNULL(dim_detail_finance.[output_wip_fee_arrangement], 0)) AS [Fee Arrangement]
,fact_finance_summary.fixed_fee_amount [Fixed Fee Amount]
,fact_finance_summary.wip [WIP]
,fact_finance_summary.disbursement_balance AS [Unbilled Disbursements]
, udMICoreGeneral.txtNHSBTPO	AS [Purchase Order Number]	-- #98541 
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus

,dim_detail_client.[fee_arrangement] [Fee Arrangement other ]
,fact_detail_paid_detail.[output_wip_contingent_wip] [WIP Contingent]
,fact_detail_paid_detail.[output_wip_hourly_rate] [WIP Hourly Rate]
,fact_detail_paid_detail.[output_wip_other_tbc_wip] [WIP TBC ]
,fact_detail_paid_detail.[output_wip_fixed_fee_value] [WIP FF Value]
,fact_detail_paid_detail.[output_wip_balance] [WIP Balance]
,fact_detail_paid_detail.[output_wip_total_output_wip][WIP Total Output]
,dim_detail_finance.[output_wip_fee_arrangement] [WIP Fee Arrangment]
--,fileDesc AS [Property]
--,NULL AS Instruction
--,usrFullName AS [Solicitor Dealing]
--,NULL AS [NHSBT Contact]

--,dteDateInstRec AS [Date of instruction]
--,dteNHSBTReport 
--,CONVERT(CHAR(4), dteNHSBTReport, 100) + CONVERT(CHAR(4), dteNHSBTReport, 120) AS [Period]
--,MONTH(dteNHSBTReport) AS MonthNumber
--,YEAR(dteNHSBTReport) AS YearNumber
--,txtNHSBTCom  AS Notes
,hierarchylevel2hist AS Division
,hierarchylevel3hist AS Department
,hierarchylevel4hist AS Team


FROM MS_Prod.config.dbFile
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=dbFile.fileID
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key
 LEFT JOIN red_dw.dbo.dim_detail_finance ON dim_detail_finance.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.fact_finance_summary ON fact_finance_summary.client_code = dim_matter_header_current.client_code 
AND fact_finance_summary.matter_number = dim_matter_header_current.matter_number
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
 LEFT JOIN red_dw.dbo.fact_detail_paid_detail ON fact_detail_paid_detail.dim_matter_header_curr_key = dim_detail_finance.dim_matter_header_curr_key
 LEFT JOIN red_dw.dbo.dim_detail_client ON dim_detail_client.dim_matter_header_curr_key = dim_detail_finance.dim_matter_header_curr_key
----INNER JOIN #Open AS Open  ON Open.ListValue COLLATE DATABASE_DEFAULT = FileStatus COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #Name AS Name ON Name.ListValue   COLLATE DATABASE_DEFAULT = dim_fed_hierarchy_history.name COLLATE DATABASE_DEFAULT
INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udNHSBTDate
 ON udNHSBTDate.fileID = dbFile.fileID
INNER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = dbFile.fileID
WHERE dim_matter_worktype.work_type_name <> 'Property View'


AND hierarchylevel2hist='Legal Ops - LTA'

END

GO
