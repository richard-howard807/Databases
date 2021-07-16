SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NHSBTCommentsReport]
(
@Department AS NVARCHAR(MAX)
,@Team AS NVARCHAR(MAX)
,@MatterType AS NVARCHAR(MAX)
)

AS


BEGIN

IF OBJECT_ID('tempdb..#Department') IS NOT NULL   DROP TABLE #Department
IF OBJECT_ID('tempdb..#Team') IS NOT NULL   DROP TABLE #Team
IF OBJECT_ID('tempdb..#MatterType') IS NOT NULL   DROP TABLE #MatterType

SELECT ListValue  INTO #Department FROM Reporting.dbo.[udt_TallySplit]('|', @Department)
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
SELECT ListValue  INTO #MatterType FROM Reporting.dbo.[udt_TallySplit]('|', @MatterType)

SELECT clNo +'-' + fileNo AS [MS Reference]
,fileDesc AS [Property]
,NULL AS Instruction
,usrFullName AS [Solicitor Dealing]
,NULL AS [NHSBT Contact]
, udMICoreGeneral.txtNHSBTPO	AS [Purchase Order Number]	-- #98541 
,dteDateInstRec AS [Date of instruction]
,dteNHSBTReport 
,CONVERT(CHAR(4), dteNHSBTReport, 100) + CONVERT(CHAR(4), dteNHSBTReport, 120) AS [Period]
,MONTH(dteNHSBTReport) AS MonthNumber
,YEAR(dteNHSBTReport) AS YearNumber
,txtNHSBTCom  AS Notes
,hierarchylevel2hist AS Division
,hierarchylevel3hist AS Department
,hierarchylevel4hist AS Team
,CASE WHEN date_closed_case_management IS NULL THEN 'Open' ELSE 'Closed' END AS FileStatus
,dim_instruction_type.[instruction_type] [Instruction Type]
,dim_detail_health.[completion_date] [Completion Date]
,dim_detail_health.[contacts_initials] [Contact Initials]
, CASE WHEN 	DATEDIFF(DAY, dim_detail_health.completion_date, GETDATE()) > 90 THEN 1 WHEN 

DATEDIFF(DAY, dim_matter_header_current.date_closed_case_management, GETDATE()) > 90 THEN 1 ELSE 0 end
[elapsed]


FROM MS_Prod.config.dbFile
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON ms_fileid=dbFile.fileID
INNER JOIN red_dw.dbo.dim_matter_worktype
 ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

 LEFT JOIN red_dw.dbo.dim_detail_health ON dim_detail_health.dim_matter_header_curr_key = dim_matter_header_current.dim_matter_header_curr_key
LEFT JOIN red_dw.dbo.dim_instruction_type ON dim_instruction_type.dim_instruction_type_key = dim_matter_header_current.dim_instruction_type_key
INNER JOIN red_dw.dbo.dim_fed_hierarchy_history
 ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT AND dss_current_flag='Y'
INNER JOIN #Department AS Department  ON Department.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel3hist COLLATE DATABASE_DEFAULT
INNER JOIN #Team AS Team ON Team.ListValue   COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT
INNER JOIN #MatterType AS MatterType ON MatterType.ListValue   COLLATE DATABASE_DEFAULT = work_type_name COLLATE DATABASE_DEFAULT

INNER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udNHSBTDate
 ON udNHSBTDate.fileID = dbFile.fileID
INNER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN MS_Prod.dbo.udMICoreGeneral
 ON udMICoreGeneral.fileID = dbFile.fileID
WHERE hierarchylevel2hist='Legal Ops - LTA'

END

GO
