SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO



-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 30/11/2017
-- Description:	Returning the Notes field from Mattersphere to replace Present Position description in the RMG reports
-- =============================================
CREATE PROCEDURE [royalmail].[get_matter_notes]
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
	,dbFile.fileExternalNotes fileExternalNotes
	,ISNULL(udExtFile.FEDCode,clno + '-' + RIGHT('0000000'+RTRIM(dbFile.fileNo),8)) FEDCode
	
     --ISNULL(dbFile.fileExternalNotes,udCodeLookup.cdDesc) fileExternalNotes   

	FROM MS_Prod.config.dbFile dbFile 
	INNER JOIN MS_Prod.config.dbClient dbClient ON dbClient.clID = dbFile.clID
	INNER JOIN MS_Prod.dbo.udMIClientASW udMIClientASW ON udMIClientASW.fileID = dbFile.fileID
	INNER JOIN MS_Prod.dbo.udExtFile udExtFile ON udExtFile.fileID = dbFile.fileID
	LEFT JOIN MS_Prod.dbo.dbCodeLookup udCodeLookup ON udCodeLookup.cdType = 'PRESENTPOSITION' AND udCodeLookup.cdCode = udMIClientASW.txtPresPosASW 
	WHERE  dbFile.fileNo <> 'ML'
	--AND DATALENGTH(dbFile.fileExternalNotes) >0 
	AND dbFile.fileClosed IS NULL 
	AND dbClient.clNo IN ('P00010','P00011','P00012','P00020','P00021','P00022','W15762','R1001')
		     
	


GO
