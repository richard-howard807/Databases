SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 10/09/2018
-- Description:	This code was initially in the report Kevin created but I have moved to a stored procedure
--				because the parameters don't appear to work within the report although the sql is correct
--				
-- =============================================
CREATE  PROCEDURE [dataservices].[InconsistantHandler]
	@Department NVARCHAR(500)
	,@Team		NVARCHAR(500)
	,@FeeEarner NVARCHAR (500)
AS

	
	-- For testing purposes
	--DECLARE @Department NVARCHAR(200) = 'Casualty'
	--DECLARE @Team NVARCHAR(200) = 'All'
	--DECLARE @FeeEarner NVARCHAR(200) ='All'



	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Department = 'All'  SET @Department = NULL
	IF @Team = 'All' SET @Team = NULL
	IF @FeeEarner = 'All' SET @FeeEarner = NULL

	
	SELECT mg_client,mg_matter,mg_descrn
,mg_feearn AS [Fed Case Manager]
,dim_fed_hierarchy_history.name AS [Fed Name]
,dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
,usrAlias AS [MS Case Manager]
,MSTeam.name AS [MS Name]
,MSTeam.hierarchylevel3hist AS [MS Department]
FROM axxia01.dbo.camatgrp
INNER JOIN axxia01.dbo.cashdr
 ON mg_client=client AND mg_matter=matter
INNER JOIN  red_dw.dbo.dim_fed_hierarchy_history 
 ON mg_feearn=dim_fed_hierarchy_history.fed_code collate database_default AND dim_fed_hierarchy_history.dss_current_flag='Y'
LEFT OUTER JOIN (SELECT udExtFile.FEDCode,usrAlias FROM MS_Prod.config.dbFile
INNER JOIN MS_Prod.dbo.udExtFile 
 ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_Prod.dbo.dbUser
 ON filePrincipleID=dbUser.usrID) AS MS
  ON RTRIM(mg_client)+'-'+RTRIM(mg_matter)=FEDCode collate database_default
LEFT JOIN  red_dw.dbo.dim_fed_hierarchy_history AS MSTeam 
 ON usrAlias=MSTeam.fed_code collate database_default AND MSTeam.dss_current_flag='Y'
WHERE mg_datcls IS NULL

AND matter <>'ML'
AND client  NOT IN ('00030645','00453737','95000C')
AND mg_feearn  <> usrAlias collate database_default
AND MSTeam.hierarchylevel3hist =ISNULL(@Department,MSTeam.hierarchylevel3hist)
AND MSTeam.hierarchylevel4hist=ISNULL(@Team,MSTeam.hierarchylevel4hist)
AND usrAlias=ISNULL(@FeeEarner,usrAlias)



ORDER BY dim_fed_hierarchy_history.hierarchylevel3hist





GO
