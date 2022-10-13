SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:      steven Gregory
-- Create date: 21/02/2018
-- Description: to get multiple case details information
-- =============================================
-- LD 20180625 Added Claims Handler
-- ES 20201102 Added tskActive logic, requested by Jake Whewell
-- ============================================
CREATE PROCEDURE [NHSLA].[health_billing_report]
(
@DateFrom AS DATE,
@DateTo AS DATE,
@Team AS NVARCHAR(MAX),
@FedCode AS NVARCHAR(MAX)
)
AS
BEGIN
DROP TABLE IF EXISTS #Team
SELECT ListValue  INTO #Team FROM Reporting.dbo.[udt_TallySplit]('|', @Team)
DROP TABLE IF EXISTS #FedCode
SELECT ListValue  INTO #FedCode FROM Reporting.dbo.[udt_TallySplit]('|', @FedCode)



     -- SET NOCOUNT ON added to prevent extra result sets from
     -- interfering with SELECT statements.
     SET NOCOUNT ON;



SELECT DISTINCT 
dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS matter
,hierarchylevel4hist AS  team
,name
,tskCompleted AS  activity_date
,tskID AS  activity_seq
,curFixCapFee [fixed_fee]
,dim_detail_health.[nhs_scheme]  COLLATE DATABASE_DEFAULT AS Scheme
,dim_detail_health.[nhs_instruction_type] COLLATE DATABASE_DEFAULT AS [Instruction TYPE]
,date_instructions_received AS  [date of instruction]
,CASE WHEN cboTypeOfBill='TYPEBILL3' THEN 'Stage 1 interim'
WHEN cboTypeOfBill='TYPEBILL4' THEN 'Stage 2 interim (now transferring to HR)'
WHEN cboTypeOfBill='TYPEBILL2' THEN 'Final bill'
WHEN cboTypeOfBill='TYPEBILL1' THEN 'Disbursement only bill' END COLLATE DATABASE_DEFAULT  AS  [Type of bill]
,CASE WHEN cboIsThisA='ISTHIS3' THEN  'Hourly rate bill'
WHEN cboIsThisA='ISTHIS2' THEN  'Fixed fee'
WHEN cboIsThisA='ISTHIS1' THEN  'Capped fee' END COLLATE DATABASE_DEFAULT AS [Fixed capped or hourly rate]
,CASE WHEN cboFixCapBill='FIXCAP2' THEN 'N/A - hourly rate'
WHEN cboFixCapBill='FIXCAP3' THEN 'On top of fixed/capped fee'
WHEN cboFixCapBill='FIXCAP1' THEN 'Included within fixed/capped fee'
WHEN cboFixCapBill='FIXCAP4' THEN 'Other - see notes' END COLLATE DATABASE_DEFAULT AS [Disbs included or in addition to FF]
, fed_code COLLATE DATABASE_DEFAULT AS  mg_feearn
,CASE WHEN  cboTypeOfBill='TYPEBILL3' THEN dim_detail_core_details.[date_defence_served] ELSE NULL END [Date defence filed (If stage 1)]
,txtNotesAdd COLLATE DATABASE_DEFAULT AS [Notes]
,tskDesc COLLATE DATABASE_DEFAULT AS  activity_desc
,dbUser.usrFullName AS [Who ran the activity?]
,updatedby.usrFullName AS [Who ran the activity? - updated by]
,dim_client_involvement.insurerclient_name COLLATE DATABASE_DEFAULT AS [Claims Handler]
,'MS' AS [Systems]
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK) 
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) 
 ON dbtasks.fileID=ms_fileid 
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) ON fed_code=fee_earner_code COLLATE DATABASE_DEFAULT
AND dss_current_flag='Y'
INNER JOIN #FedCode fedcodes ON fedcodes.ListValue COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
INNER JOIN #Team team ON team.ListValue COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

LEFT OUTER JOIN red_dw.dbo.dim_detail_core_details WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_detail_core_details.client_code
 AND dim_matter_header_current.matter_number=dim_detail_core_details.matter_number
LEFT OUTER JOIN red_dw.dbo.dim_detail_health WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_detail_health.client_code
 AND dim_matter_header_current.matter_number=dim_detail_health.matter_number
LEFT OUTER JOIN MS_Prod.dbo.udClaimsA WITH(NOLOCK)
 ON ms_fileid=udClaimsA.fileID
LEFT OUTER JOIN red_dw.dbo.dim_client_involvement WITH(NOLOCK)
 ON dim_matter_header_current.client_code=dim_client_involvement.client_code
 AND dim_matter_header_current.matter_number=dim_client_involvement.matter_number 
 
 LEFT JOIN MS_Prod.dbo.dbUser
ON dbUser.usrID = dbTasks.tskCompletedBy

 LEFT JOIN MS_Prod.dbo.dbUser updatedby
ON updatedby.usrID = dbTasks.UpdatedBy 

WHERE tskType='MILESTONE' 


AND (LOWER(tskDesc) LIKE '%nhsr stage 1/final bill request%' OR dbTasks.tskDesc = 'NHSR GPI Final Bill Request')
AND CONVERT(DATE,tskCompleted,103) BETWEEN @DateFrom AND @DateTo
AND tskComplete=1
AND dim_matter_header_current.client_code NOT IN ('00030645','95000C','00453737') 

AND dbTasks.tskActive=1

END





GO
