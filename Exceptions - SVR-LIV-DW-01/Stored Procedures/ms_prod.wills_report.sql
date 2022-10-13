SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





/* History
Version	  Date		    By				Description
************************************************************************************************ 
1.0	    13/02/2018		Lucy Dickinson	Initial Query for Wills report required for Carole Atkinson to facilitate marketing
										Issues - not all of the initial (from fed artiion) data imported into the udDeedWill has dates
												 wills that didn't have a live matter were just imported with a blank matter / fileid
												 due to people leaving a process	

*/
CREATE PROCEDURE [ms_prod].[wills_report]
AS

		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
 
	SELECT

		dbClient.clNo [client_code]
		,ISNULL(dbFile.fileNo,'No current matter') [matter_number]
		,dbClient.clName [client name]
		,CONCAT(addLine1,' ',addLine2,' ',addLine3,' ',addLine4,' ',addLine5) [client address]
		,addPostcode [client postcode]
		,dwAddress [archive record address]
		,fileType.cdDesc [matter type]
		,udDeedWill.dwArchivedDate [archive date]
		,dbBranch.brName [matter office location]
		,archbr.brName [archive office location]
		,udDeedWill.dwRef [archive ref]
		,dbCodeLookup.cdDesc [archive type]
		,udDeedWill.dwNote [archive notes]
		,archstatus.cdDesc [archive status]
		,udDeedWill.dwDateOfDoc [date of document]
		,dwRemovedDate [date removed]
		,udDeedWill.dwDesc [archive description]
		,udDeedWill.dwHolder [internal individual in possession]
		,udDeedWill.dwRetrieveReq [date retrieved]
		,reasonret.cdDesc [retrieval reason]
		,udDeedWill.dwRetrievalReas
	
	--,udDeedWill.*
	
	FROM MS_Prod.dbo.udDeedWill AS udDeedWill
	Left JOIN MS_Prod.config.dbFile AS dbFile ON  dbFile.fileID = udDeedWill.fileID
	left JOIN MS_Prod.config.dbClient AS dbClient ON dbClient.clID = udDeedWill.clID
	LEFT JOIN MS_Prod.dbo.dbCodeLookup AS dbCodeLookup ON dwType = cdCode AND dbCodeLookup.cdType = 'ARCHTYPE'
	LEFT JOIN MS_prod.dbo.dbCodeLookup AS filetype ON dbFile.fileType = filetype.cdCode AND filetype.cdType = 'FILETYPE'
	LEFT JOIN MS_prod.dbo.dbCodeLookup AS archstatus ON udDeedWill.[Status] = archstatus.cdCode AND archstatus.cdType = 'ARCHSTATUS'
	LEFT JOIN MS_prod.dbo.dbCodeLookup AS reasonret ON udDeedWill.dwRetrievalReas = reasonret.cdCode AND reasonret.cdType = 'ARCHRETREASON'
	left JOIN MS_Prod.dbo.dbBranch AS dbBranch ON dbBranch.brID = dbFile.brID
	Left JOIN MS_Prod.dbo.dbBranch AS archbr ON archbr.brID = udDeedWill.dwOffLocation
	left JOIN MS_Prod.config.dbContact AS dbContact ON dbClient.clDefaultContact=dbContact.contID
	left JOIN MS_Prod.dbo.dbAddress AS dbAddress ON dbContact.contDefaultAddress=dbAddress.addID

	WHERE 
		dwType IN ('ARCH005','ARCH006','ARCH004','ARCH002')
		AND LOWER(udDeedWill.dwHolder) NOT LIKE '%(perm)%' -- this means the will has been permanently removed from archive
		AND (dwRetrievalReas <> 'LIVE' OR dwRetrievalReas IS NULL) -- exclude the old wills where a matter has now become live as the re-archive will be on the new file ref
	ORDER BY udDeedWill.Created ASC 




GO
