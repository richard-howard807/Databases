SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 17/11/2017
-- Description:	Returning the Notes field from Mattersphere to replace Present Position description the ASW reports
-- =============================================
CREATE PROCEDURE [asw].[get_matter_notes]
AS



	--SELECT CASE WHEN ISNUMERIC(dbclient.clNo) = 1 AND ISNUMERIC(dbFile.fileNo) = 1 
	--			THEN RIGHT('0000000' + dbClient.clNo,8) + '-'+ RIGHT('0000000' + dbFile.fileNo,8)
	--			ELSE dbClient.clNo + '-' + dbFile.fileNo END client_matter
	SELECT 
	dbClient.clNo + '-' + dbFile.fileNo client_matter
	,dbFile.fileID 
	,dbFile.clID 
	,clNo
	,fileNo
	,dbFile.fileDesc 
	,dbFile.fileStatus 
	,dbFile.fileClosed 
	,ISNULL(dbFile.fileExternalNotes,udCodeLookup.cdDesc) fileExternalNotes
           

	FROM MS_Prod.config.dbFile dbFile 
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = dbFile.clID
	INNER JOIN MS_Prod.dbo.udMIClientASW udMIClientASW ON udMIClientASW.fileID = dbFile.fileID
	INNER JOIN MS_Prod.dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
	LEFT JOIN MS_Prod.dbo.dbCodeLookup udCodeLookup ON udCodeLookup.cdType = 'PRESENTPOSITION' AND udCodeLookup.cdCode = udMIClientASW.txtPresPosASW 
	WHERE dbClient.clNo IN ('787558','787559','787560','787561')
	--AND DATALENGTH(dbFile.fileExternalNotes) >0 



GO
