SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		steven Gregory
-- Create date: 21/02/2018
-- Description:	to get multiple case details information
-- =============================================
CREATE PROCEDURE [NHSLA].[health_billing_report]
(
@DateFrom AS DATE,
@DateTo as DATE,
@Team as nvarchar(MAX),
@FedCode as NVARCHAR(Max)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
 cashdr.client,
 cashdr.matter,
 fed.hierarchylevel4hist team,
 fed.name,
 casact.activity_date,
 casact.activity_seq,
 NHS255.case_value [fixed_fee],
 NHS039.case_text Scheme,
 NHS216.case_text [Instruction TYPE],
 TRA094.case_date [date of instruction],
 NHS251.case_text [Type of bill],
 NHS254.case_text [Fixed capped or hourly rate],
 NHS252.case_text [Disbs included or in addition to FF],
 CASE WHEN  RTRIM(NHS251.case_text) = 'Stage 1 interim' THEN FRA054.case_date ELSE null END [Date defence filed (If stage 1)],
 NHS253.case_text [Notes],
 activity_desc
FROM red_Dw.dbo.ds_sh_axxia_casact casact WITH (NOLOCK)
LEFT JOIN red_Dw.dbo.ds_sh_axxia_cashdr cashdr WITH (NOLOCK) ON cashdr.case_id = casact.case_id AND cashdr.current_flag = 'Y'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_camatgrp camatgrp  WITH (NOLOCK) ON camatgrp.current_flag = 'Y' AND camatgrp.mg_client = cashdr.client AND camatgrp.mg_matter = cashdr.matter
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history fed ON fed.fed_code = camatgrp.mg_feearn AND fed.dss_current_flag = 'Y'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS039 WITH (NOLOCK) ON NHS039.case_id = casact.case_id AND NHS039.current_flag = 'Y' AND NHS039.case_detail_code = 'NHS039'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS216 WITH (NOLOCK) ON NHS216.case_id = casact.case_id AND NHS216.current_flag = 'Y' AND NHS216.case_detail_code = 'NHS216'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet TRA094 WITH (NOLOCK) ON TRA094.case_id = casact.case_id AND TRA094.current_flag = 'Y' AND TRA094.case_detail_code = 'TRA094'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS251 WITH (NOLOCK) ON NHS251.case_id = casact.case_id AND NHS251.current_flag = 'Y' AND NHS251.case_detail_code = 'NHS251'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS254 WITH (NOLOCK) ON NHS254.case_id = casact.case_id AND NHS254.current_flag = 'Y' AND NHS254.case_detail_code = 'NHS254'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS252 WITH (NOLOCK) ON NHS252.case_id = casact.case_id AND NHS252.current_flag = 'Y' AND NHS252.case_detail_code = 'NHS252'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet FRA054 WITH (NOLOCK) ON FRA054.case_id = casact.case_id AND FRA054.current_flag = 'Y' AND FRA054.case_detail_code = 'FRA054'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS253 WITH (NOLOCK) ON NHS253.case_id = casact.case_id AND NHS253.current_flag = 'Y' AND NHS253.case_detail_code = 'NHS253'
LEFT JOIN red_Dw.dbo.ds_sh_axxia_casdet NHS255 WITH (NOLOCK) ON NHS255.case_id = casact.case_id AND NHS255.current_flag = 'Y' AND NHS255.case_detail_code = 'NHS255'
inner join [dbo].[split_delimited_to_rows] (@FedCode,',') fedcodes ON fedcodes.val COLLATE DATABASE_DEFAULT = fed.fed_code COLLATE DATABASE_DEFAULT
inner join [dbo].[split_delimited_to_rows] (@Team,',') team ON team.val COLLATE DATABASE_DEFAULT = fed.hierarchylevel4hist COLLATE DATABASE_DEFAULT
WHERE 
 casact.activity_date >= @DateFrom AND casact.activity_date <= @DateTo and
casact.current_flag = 'Y' and casact.activity_code = 'NHSA0850' AND casact.tran_done IS NULL
AND casact.p_a_marker = 'a' AND 
--casact.activity_desc = 'ADM: Commence NHSR stage 1/final bill request' 
casact.activity_desc like 'ADM: Commence NHSR stage 1%' AND 
cashdr.client NOT IN ('00030645','95000C','00453737') 

ORDER BY cashdr.client, cashdr.matter

END
GO
