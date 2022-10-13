SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




-- =============================================
-- Author:		Steven Gregory
-- Create date: 08/02/2018
-- Description:	Returning the Notes field from Mattersphere to replace Present Position description in the Real Estate reports
-- =============================================
CREATE PROCEDURE [Real_Estate].[get_matter_notes]
AS

	SELECT 
	dbClient.clNo + '-' + dbFile.fileNo client_matter
	,dbFile.fileID 
	,dbFile.clID 
	,clNo
	,fileNo
	,dbFile.fileDesc 
	,dbFile.fileStatus 
	,dbFile.fileClosed 
	,dbFile.fileExternalNotes fileExternalNotes
	,ISNULL(udExtFile.FEDCode,clno + '-' + RIGHT('0000000'+RTRIM(dbFile.fileNo),8)) FEDCode
	
     --ISNULL(dbFile.fileExternalNotes,udCodeLookup.cdDesc) fileExternalNotes   

	FROM MS_Prod.config.dbFile dbFile 
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = dbFile.clID
	INNER JOIN MS_Prod.dbo.udMIClientASW udMIClientASW ON udMIClientASW.fileID = dbFile.fileID
	INNER JOIN MS_Prod.dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
	LEFT JOIN MS_Prod.dbo.dbCodeLookup udCodeLookup ON udCodeLookup.cdType = 'PRESENTPOSITION' AND udCodeLookup.cdCode = udMIClientASW.txtPresPosASW 
	LEFT JOIN MS_Prod.dbo.dbUser ON dbFile.filePrincipleID = dbUser.usrID
	LEFT JOIN red_Dw.dbo.dim_fed_hierarchy_history ON dbUser.usrInits COLLATE DATABASE_DEFAULT = fed_code COLLATE DATABASE_DEFAULT AND dss_current_flag = 'Y' AND activeud = 1
	WHERE  dbFile.fileNo <> 'ML'
	AND dbFile.fileClosed IS NULL 
	AND (hierarchylevel4hist = 'Real Estate Liverpool 2' OR name ='Janine Clare')
	AND name <> 'Chris Lewis' AND name <> 'Property View'
		     

			
			
GO
