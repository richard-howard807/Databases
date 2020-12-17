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
     -- SET NOCOUNT ON added to prevent extra result sets from
     -- interfering with SELECT statements.
     SET NOCOUNT ON;

    -- Insert statements for procedure here
   
--SELECT 
--cashdr.client,
--cashdr.matter,
--hierarchylevel4hist AS  team ,
--name,
--casact.activity_date,
--casact.activity_seq,
--NHS255.case_value [fixed_fee],
--NHS039.case_text Scheme,
--NHS216.case_text [Instruction TYPE],
--TRA094.case_date [date of instruction],
--NHS251.case_text [Type of bill],
--NHS254.case_text [Fixed capped or hourly rate],
--NHS252.case_text [Disbs included or in addition to FF],

--camatgrp.mg_feearn,
--CASE WHEN  RTRIM(NHS251.case_text) = 'Stage 1 interim' THEN FRA054.case_date ELSE NULL END [Date defence filed (If stage 1)],
--NHS253.case_text [Notes],
--activity_desc,
--Reporting.dbo.ufn_Coalesce_CapacityDetails_nameonly(cashdr.case_id,'TRA00002')As [Claims Handler],
--'FED' AS [Systems]
--FROm axxia01.dbo.casact
--INNER JOIN axxia01.dbo.cashdr
-- ON casact.case_id=cashdr.case_id
--INNER JOIN axxia01.dbo.camatgrp
-- ON client=mg_client AND matter=mg_matter
--LEFT JOIN axxia01.dbo.casdet NHS039 WITH (NOLOCK) ON NHS039.case_id = casact.case_id AND NHS039.case_detail_code = 'NHS039'
--LEFT JOIN axxia01.dbo.casdet NHS216 WITH (NOLOCK) ON NHS216.case_id = casact.case_id AND NHS216.case_detail_code = 'NHS216'
--LEFT JOIN axxia01.dbo.casdet TRA094 WITH (NOLOCK) ON TRA094.case_id = casact.case_id AND TRA094.case_detail_code = 'TRA094'
--LEFT JOIN axxia01.dbo.casdet NHS251 WITH (NOLOCK) ON NHS251.case_id = casact.case_id AND NHS251.case_detail_code = 'NHS251'
--LEFT JOIN axxia01.dbo.casdet NHS254 WITH (NOLOCK) ON NHS254.case_id = casact.case_id AND NHS254.case_detail_code = 'NHS254'
--LEFT JOIN axxia01.dbo.casdet NHS252 WITH (NOLOCK) ON NHS252.case_id = casact.case_id AND NHS252.case_detail_code = 'NHS252'
--LEFT JOIN axxia01.dbo.casdet FRA054 WITH (NOLOCK) ON FRA054.case_id = casact.case_id AND  FRA054.case_detail_code = 'FRA054'
--LEFT JOIN axxia01.dbo.casdet NHS253 WITH (NOLOCK) ON NHS253.case_id = casact.case_id AND NHS253.case_detail_code = 'NHS253'
--LEFT JOIN axxia01.dbo.casdet NHS255 WITH (NOLOCK) ON NHS255.case_id = casact.case_id AND NHS255.case_detail_code = 'NHS255'
--LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
-- ON mg_feearn=fed_code collate database_default AND dss_current_flag='Y'
--INNER JOIN [dbo].[split_delimited_to_rows] (@FedCode,',') fedcodes ON fedcodes.val COLLATE DATABASE_DEFAULT = mg_feearn COLLATE DATABASE_DEFAULT
--INNER JOIN [dbo].[split_delimited_to_rows] (@Team,',') team ON team.val COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT


--WHERE 
--casact.activity_date BETWEEN @DateFrom AND @DateTo
--AND casact.activity_code = 'NHSA0850' 
--AND casact.tran_done IS NULL
--AND casact.p_a_marker = 'a'  
--AND casact.activity_desc LIKE 'ADM: Commence NHSR stage 1%' 
--AND cashdr.client NOT IN ('00030645','95000C','00453737') 

--UNION 

SELECT DISTINCT 
dim_matter_header_current.client_code AS client
,dim_matter_header_current.matter_number AS matter
,hierarchylevel4hist AS  team
,name
,tskCompleted AS  activity_date
,tskID AS  activity_seq
,curFixCapFee [fixed_fee]
,dim_detail_health.[nhs_scheme]  collate database_default AS Scheme
,dim_detail_health.[nhs_instruction_type] collate database_default AS [Instruction TYPE]
,date_instructions_received AS  [date of instruction]
,CASE WHEN cboTypeOfBill='TYPEBILL3' THEN 'Stage 1 interim'
WHEN cboTypeOfBill='TYPEBILL4' THEN 'Stage 2 interim (now transferring to HR)'
WHEN cboTypeOfBill='TYPEBILL2' THEN 'Final bill'
WHEN cboTypeOfBill='TYPEBILL1' THEN 'Disbursement only bill' END collate database_default  AS  [Type of bill]
,CASE WHEN cboIsThisA='ISTHIS3' THEN  'Hourly rate bill'
WHEN cboIsThisA='ISTHIS2' THEN  'Fixed fee'
WHEN cboIsThisA='ISTHIS1' THEN  'Capped fee' END collate database_default AS [Fixed capped or hourly rate]
,CASE WHEN cboFixCapBill='FIXCAP2' THEN 'N/A - hourly rate'
WHEN cboFixCapBill='FIXCAP3' THEN 'On top of fixed/capped fee'
WHEN cboFixCapBill='FIXCAP1' THEN 'Included within fixed/capped fee'
WHEN cboFixCapBill='FIXCAP4' THEN 'Other - see notes' END collate database_default AS [Disbs included or in addition to FF]
, fed_code collate database_default AS  mg_feearn
,CASE WHEN  cboTypeOfBill='TYPEBILL3' THEN dim_detail_core_details.[date_defence_served] ELSE NULL END [Date defence filed (If stage 1)]
,txtNotesAdd collate database_default AS [Notes]
,tskDesc collate database_default AS  activity_desc
,dim_client_involvement.insurerclient_name collate database_default As [Claims Handler]
,'MS' AS [Systems]
FROM MS_Prod.dbo.dbTasks WITH(NOLOCK) 
INNER JOIN red_dw.dbo.dim_matter_header_current WITH(NOLOCK) 
 ON dbtasks.fileID=ms_fileid 
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history WITH(NOLOCK) on fed_code=fee_earner_code collate database_default
AND dss_current_flag='Y'
INNER JOIN [dbo].[split_delimited_to_rows] (@FedCode,',') fedcodes ON fedcodes.val COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT
INNER JOIN [dbo].[split_delimited_to_rows] (@Team,',') team ON team.val COLLATE DATABASE_DEFAULT = hierarchylevel4hist COLLATE DATABASE_DEFAULT

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
 
WHERE tskType='MILESTONE' 


AND (LOWER(tskDesc) LIKE '%nhsr stage 1/final bill request%' OR dbTasks.tskDesc = 'NHSR GPI Final Bill Request')
AND CONVERT(DATE,tskCompleted,103) BETWEEN @DateFrom AND @DateTo
AND tskComplete=1
AND dim_matter_header_current.client_code NOT IN ('00030645','95000C','00453737') 

AND dbTasks.tskActive=1

END



GO
