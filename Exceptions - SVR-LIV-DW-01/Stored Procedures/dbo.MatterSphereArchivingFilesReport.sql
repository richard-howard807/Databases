SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		sgrego
-- Create date: 2018-08-09
-- Description:	built for Sarah Calvert to show archive files ticket -328257  
-- =============================================
CREATE PROCEDURE [dbo].[MatterSphereArchivingFilesReport]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
SELECT 
CAST(ISNULL(LEFT(ds_sh_ms_udextfile.fedcode , CHARINDEX('-', ds_sh_ms_udextfile.fedcode ) - 1),
CASE WHEN ISNUMERIC(ds_sh_ms_dbclient.clno) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR,ds_sh_ms_dbclient.clno), 8) ELSE CAST(RTRIM(ds_sh_ms_dbclient.clno)  AS VARCHAR(8)) END) AS VARCHAR(8))
 client_code,
    CAST(ISNULL(RIGHT(ds_sh_ms_udextfile.fedcode, LEN(ds_sh_ms_udextfile.fedcode) - CHARINDEX('-', ds_sh_ms_udextfile.fedcode)), 
CASE WHEN ISNUMERIC(ds_sh_ms_dbfile.fileno) = 1 THEN RIGHT('00000000' + CONVERT(VARCHAR,ds_sh_ms_dbfile.fileno), 8) ELSE CAST(RTRIM(ds_sh_ms_dbfile.fileno) AS VARCHAR(8)) END) AS VARCHAR(8))
 matter_number,
matter_owner.usrfullname,
filedesc,
ds_sh_ms_dbbranch.brdescription,
ds_sh_ms_dbfile.created,
ds_sh_ms_dbfile.fileclosed,
dwtype,
red_dw.dbo.get_ms_code_lkup_val('ARCHSTATUS',ds_sh_ms_uddeedwill.status) status,
CASE WHEN ds_sh_ms_uddeedwill.dwtype = 'ARCH001' AND status NOT IN ('PFC','CP','IMP','TRANSLIV') THEN 'Y' ELSE 'N' END archive
FROM red_dw.dbo.ds_sh_ms_uddeedwill
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbclient ON ds_sh_ms_dbclient.clid = ds_sh_ms_uddeedwill.clid
LEFT JOIN red_dw.dbo.ds_sh_ms_dbfile ON ds_sh_ms_dbfile.fileid = ds_sh_ms_uddeedwill.fileid
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbuser createby ON createby.usrid = ds_sh_ms_uddeedwill.createdby
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbuser dwauther ON dwauther.usrid = ds_sh_ms_uddeedwill.dwauthby
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbuser matter_owner ON matter_owner.usrid = ds_sh_ms_dbfile.fileprincipleid
LEFT JOIN red_Dw.dbo.ds_sh_ms_dbbranch ON  dwofflocation = ds_sh_ms_dbbranch.brid
LEFT JOIN red_Dw.dbo.ds_sh_ms_udextfile ON ds_sh_ms_udextfile.fileid = ds_sh_ms_dbfile.fileid
WHERE filetype = '1092' AND dwtype = 'ARCH001'
END
GO
