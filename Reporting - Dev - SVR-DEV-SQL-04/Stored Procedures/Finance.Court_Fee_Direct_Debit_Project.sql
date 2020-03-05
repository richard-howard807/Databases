SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		steven gregory
-- Create date: 17/11/2017
-- Description:	Bring back all matters that are asscoiated to the refrence 
-- =============================================
CREATE PROCEDURE [Finance].[Court_Fee_Direct_Debit_Project]
(
@Ref AS NVARCHAR(100)
)
AS



SELECT distinct
dbaddress.addline1,
dbaddress.addline2,
dbaddress.addline3,
dbaddress.addline4,
dbaddress.addline5,
dbaddress.addpostcode,
cont.contname,
ass.assoctype,
ass.assocsalut,
ass.assocref,
ass.assocheading,
ass.assocaddressee,
ass.assocactive,
dbclient.clno,
dbfile.fileno,
dbfile.fileclosed,
dbfile.created,
dbfile.filedesc,
feeearner.usrfullname feeearner,
fed.hierarchylevel4hist team,
dbclient.clname
FROM red_Dw.dbo.ds_sh_ms_dbassociates ass
LEFT JOIN  red_Dw.dbo.ds_sh_ms_dbcontact cont ON cont.contid = ass.contid
LEFT JOIN red_dw.dbo.ds_sh_ms_dbfile dbfile ON dbfile.fileid = ass.fileid
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbclient dbclient ON dbclient.clid = dbfile.clid
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbuser createdby  ON createdby.usrid = cont.createdby
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbuser feeearner ON feeearner.usrid = dbfile.fileprincipleid
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history fed ON feeearner.usrinits = fed.fed_code AND fed.dss_current_flag = 'Y' AND fed.activeud = 1
LEFT JOIN red_dw.dbo.ds_sh_ms_dbaddress dbaddress ON dbaddress.addid = contdefaultaddress
WHERE LOWER(ass.assocref) like '%'+LOWER(@Ref)+'%' AND conttypecode = 'COURT'
AND assocactive = 1 

UNION 

SELECT distinct
fmsaddr.fm_addli1,
fmsaddr.fm_addli2,
fmsaddr.fm_addli3,
fmsaddr.fm_addli4,
'',
fmsaddr.fm_poscod,
cl_clname,
capac.capacity_desc,
fm_salute,
reference,
cl_namkey,
fm_addree,
1,
client,
matter,
date_closed,
date_opened,
case_public_desc1,
fed.name,
fed.hierarchylevel4hist,
cl_clname
FROM red_dw.dbo.ds_sh_axxia_invol invol
LEFT JOIN red_dw.dbo.ds_sh_axxia_caclient caclient ON caclient.current_flag = 'Y' and  invol.entity_code =  cl_accode 
LEFT JOIN red_dw.dbo.ds_sh_axxia_kdclicon kdclicon ON kdclicon.kc_client = cl_accode 
LEFT JOIN red_dw.dbo.ds_sh_axxia_fmsaddr fmsaddr ON fmsaddr.current_flag = 'Y' and fm_addnum = kc_addrid 
LEFT JOIN red_dw.dbo.ds_sh_artiion_capac capac ON capac.capacity_code = invol.capacity_code 
LEFT JOIN red_dw.dbo.ds_sh_axxia_cashdr cashdr ON  cashdr.current_flag = 'Y' and cashdr.case_id = invol.case_id 
LEFT JOIN red_dw.dbo.ds_sh_axxia_camatgrp camatgrp ON camatgrp.current_flag = 'Y' and client = mg_client AND mg_matter = matter  
LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history fed ON  fed_code = mg_feearn AND fed.dss_current_flag = 'Y' AND fed.activeud = 1 
WHERE invol.current_flag = 'Y' and  reference IS NOT NULL AND LOWER(reference) like '%'+LOWER(@Ref)+'%' AND invol.capacity_code IN ('TRA00016','TRA00024')   


GO
