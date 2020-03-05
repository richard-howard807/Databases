SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgregp
-- Create date: 10/10/2017
-- Description:	created for Ann-Marie for MI managment inforamtion 
-- =============================================
CREATE PROCEDURE [dbo].[CurrentReserveExceptionDetails]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT 
cashdr.client + '/' + cashdr.matter [Client/Matter Number],
cashdr.case_public_desc1 [Matter Description] ,
WT.work_type_code,
WT.work_type_name,
name [case manager],
hierarchylevel4 AS team,
NMI514.case_value as [General damages - misc reserve (current)],
NMI094.case_value as [Past care reserve (current)],
NMI095.case_value as [Past loss of earnings reserve (current)],
NMI093.case_value as [Personal injury reserve (current)],
NMI515.case_value as [Special damages - misc reserve (current)],
WPS008.case_value as [CRU reserve (current)],
NMI097.case_value as [NHS charges reserve (current)],
NMI098.case_value as [Future care reserve (current)],
NMI100.case_value as [Future loss - misc reserve (current)],
NMI099.case_value as [Future loss of earnings reserve (current)],
TRA080.case_value as [Claimant's cost reserve (current)],
TRA076.case_value as [Damages reserve (current)],
TRA078.case_value as [Defence cost reserve (current)],
NMI519.case_value as [Other defendants costs - reserve (current)],
TRA098.case_value as [Total reserve (current)],
TRA027.case_text AS  TRA027
FROM red_dw.dbo.ds_sh_axxia_cashdr  cashdr
LEFT JOIN red_Dw.dbo.dim_matter_header_current header ON client_code = client AND matter_number = matter
LEFT JOIN red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON camatgrp.current_flag = 'Y' and mg_client = client AND 
mg_matter = matter 
LEFT JOIN red_Dw.dbo.dim_matter_worktype WT ON WT.dim_matter_worktype_key = header.dim_matter_worktype_key
LEFT JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_fed_hierarchy_history.dss_current_flag = 'Y' AND dim_fed_hierarchy_history.fed_code = mg_feearn
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI514 on NMI514.current_flag = 'Y' AND NMI514.case_detail_code = 'NMI514' and  NMI514.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI094 on NMI094.current_flag = 'Y' AND NMI094.case_detail_code = 'NMI094' and  NMI094.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI095 on NMI095.current_flag = 'Y' AND NMI095.case_detail_code = 'NMI095' and  NMI095.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI093 on NMI093.current_flag = 'Y' AND NMI093.case_detail_code = 'NMI093' and  NMI093.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI515 on NMI515.current_flag = 'Y' AND NMI515.case_detail_code = 'NMI515' and  NMI515.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  WPS008 on WPS008.current_flag = 'Y' AND WPS008.case_detail_code = 'WPS008' and  WPS008.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI097 on NMI097.current_flag = 'Y' AND NMI097.case_detail_code = 'NMI097' and  NMI097.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI098 on NMI098.current_flag = 'Y' AND NMI098.case_detail_code = 'NMI098' and  NMI098.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI100 on NMI100.current_flag = 'Y' AND NMI100.case_detail_code = 'NMI100' and  NMI100.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI099 on NMI099.current_flag = 'Y' AND NMI099.case_detail_code = 'NMI099' and  NMI099.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA078 on TRA078.current_flag = 'Y' AND TRA078.case_detail_code = 'TRA078' and  TRA078.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI519 on NMI519.current_flag = 'Y' AND NMI519.case_detail_code = 'NMI519' and  NMI519.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA098 on TRA098.current_flag = 'Y' AND TRA098.case_detail_code = 'TRA098' and  TRA098.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA086 on TRA086.current_flag = 'Y' AND TRA086.case_detail_code = 'TRA086' and  TRA086.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA068 on TRA068.current_flag = 'Y' AND TRA098.case_detail_code = 'TRA068' and  TRA068.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  NMI411 ON NMI411.current_flag = 'Y' and NMI411.case_detail_code = 'NMI411' and  NMI411.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA076 on TRA076.current_flag = 'Y' AND TRA076.case_detail_code = 'TRA076' and  TRA076.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA080 on TRA080.current_flag = 'Y' AND TRA080.case_detail_code = 'TRA080' and  TRA080.case_id = cashdr.case_id
Left join red_dw.dbo.ds_sh_axxia_casdet  TRA027 on TRA027.current_flag = 'Y' AND TRA027.case_detail_code = 'TRA027' and  TRA027.case_id = cashdr.case_id
WHERE 
cashdr.current_flag = 'Y' and
 (TRA086.case_date >= '2015-01-01' or TRA086.case_date is null) and isnull(lower(TRA068.case_text),'') <> 'exclude from reports' and date_closed is null and WT.work_type_code not in ( '0032','1143') and lower(NMI411.case_text) like '%dispute%'
AND header.reporting_exclusions = 0
AND (CASE WHEN TRA098.case_value <> (ISNULL(NMI519.case_value, 0) + ISNULL(TRA076.case_value, 0) + ISNULL(TRA080.case_value, 0) + ISNULL(TRA078.case_value, 0)) AND TRA098.case_value IS NOT NULL THEN 1 ELSE 0 END = 1)
 OR (CASE when TRA076.case_value <> (ISNULL(NMI100.case_value, 0) + ISNULL(NMI099.case_value, 0) + ISNULL(NMI098.case_value, 0) + ISNULL(NMI097.case_value, 0) + ISNULL(WPS008.case_value, 0) + ISNULL(NMI095.case_value, 0) + ISNULL(NMI094.case_value, 0) + ISNULL(NMI514.case_value, 0) + ISNULL(NMI515.case_value, 0) + ISNULL(NMI093.case_value, 0)) AND TRA076.case_value IS NOT NULL AND ISNULL(TRA027.case_text, '') <> 'No' AND ISNULL(NMI411.case_text, '') LIKE 'Dispute%' THEN 1 ELSE 0 END = 1)

END
GO
