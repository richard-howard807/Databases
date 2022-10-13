SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[MSToFEDDifferentOwners]
AS
BEGIN
SELECT mg_client AS Client
,mg_matter AS Matter ,mg_descrn   AS [Matter Description]
,mg_feearn AS [Fed Case Manager]
,FED.name As [Fed Name]
,FED.hierarchylevel2hist AS [FED Division]
,FED.hierarchylevel3hist AS [FED Department]
,FED.hierarchylevel4hist AS [FED Team]
,usrAlias AS [MS Case Manager]
,MSFE.name AS [MS Name]
,MSFE.hierarchylevel2hist AS [MS Division]
,MSFE.hierarchylevel3hist AS [MS Department]
,MSFE.hierarchylevel4hist AS [MS Team]
FROM axxia01.dbo.camatgrp
INNER JOIN axxia01.dbo.cashdr
ON mg_client=client AND mg_matter=matter
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history  AS  FED 
 ON mg_feearn=FED.fed_code collate database_default AND FED.dss_current_flag='Y'

LEFT OUTER JOIN (SELECT udExtFile.FEDCode,usrAlias,usrFullName FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.dbo.udExtFile 
 ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_Prod.dbo.dbUser
ON filePrincipleID=dbUser.usrID) AS MS
  ON RTRIM(mg_client)+'-'+RTRIM(mg_matter)=FEDCode collate database_default
LEFT  JOIN  red_dw.dbo.dim_fed_hierarchy_history  AS  MSFE 
 ON usrAlias=MSFE.fed_code collate database_default AND MSFE.dss_current_flag='Y'

 WHERE mg_datcls IS NULL

AND matter <>'ML'
AND client  NOT IN ('00030645','00453737','95000C')
AND mg_feearn  <> usrAlias collate database_default

END
GO
