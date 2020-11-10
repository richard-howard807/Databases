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
CREATE PROCEDURE [ms_prod].[wills_archive_report]
AS

		SET TRAN ISOLATION LEVEL READ UNCOMMITTED
 
	SELECT

		dim_matter_header_current.client_code [client_code]
		,ISNULL(dbFile.fileNo,'No current matter') [matter_number]
		, dim_matter_header_current.matter_description [Matter Description]
		, dim_matter_worktype.work_type_name [Matter Type]
		, dim_matter_header_current.date_opened_case_management [Open Date]
		,dim_matter_header_current.date_closed_case_management [Closed Date]
		, dteDateOfWill  [Date of Will]                  
,cboAnyTrust  [Any Trust?]                   
,cboTrustType   [Trust]                
,cboForeignElem   [Any Foreign Element?]            
,cboBusnsAssets     [Any Business Assets?]            
,cboLstPowerAtto   [Is there a lasting powers of Attorney?]          
,cboLstPowAtType  [Type]        
,cboLifetimeSett   [Lifetime Settlement made?]             
,cboWMPartnrExec       [Is there a Weightmans partner as executor?]  
,cboWMAppntExec     [Is Weightmans appointed as executor?]    
,lbxExecutors     [Executors]                

	
	--,udDeedWill.*
	
	FROM
	
	--MS_Prod.dbo.udDeedWill AS udDeedWill
 MS_Prod.config.dbFile AS dbFile 
	--left JOIN MS_Prod.config.dbClient AS dbClient ON dbClient.clID = udDeedWill.clID
	--LEFT JOIN MS_Prod.dbo.dbCodeLookup AS dbCodeLookup ON dwType = cdCode AND dbCodeLookup.cdType = 'ARCHTYPE'
	--LEFT JOIN MS_prod.dbo.dbCodeLookup AS filetype ON dbFile.fileType = filetype.cdCode AND filetype.cdType = 'FILETYPE'
	--LEFT JOIN MS_prod.dbo.dbCodeLookup AS archstatus ON udDeedWill.[Status] = archstatus.cdCode AND archstatus.cdType = 'ARCHSTATUS'
	--LEFT JOIN MS_prod.dbo.dbCodeLookup AS reasonret ON udDeedWill.dwRetrievalReas = reasonret.cdCode AND reasonret.cdType = 'ARCHRETREASON'
	left JOIN MS_Prod.dbo.dbBranch AS dbBranch ON dbBranch.brID = dbFile.brID
	--Left JOIN MS_Prod.dbo.dbBranch AS archbr ON archbr.brID = udDeedWill.dwOffLocation
	--left JOIN MS_Prod.config.dbContact AS dbContact ON dbClient.clDefaultContact=dbContact.contID
	--left JOIN MS_Prod.dbo.dbAddress AS dbAddress ON dbContact.contDefaultAddress=dbAddress.addID
	LEFT JOIN ms_prod.dbo.udMIWillsArchive ON udMIWillsArchive.fileid = dbFile.fileID
	LEFT JOIN red_Dw.dbo.dim_matter_header_current ON dim_matter_header_current.ms_fileid = dbFile.fileID
	LEFT JOIN red_dw.dbo.dim_matter_worktype ON dim_matter_worktype.dim_matter_worktype_key = dim_matter_header_current.dim_matter_worktype_key

	WHERE 

	dim_matter_worktype.work_type_name = 'Wills Archive                           '
		--dwType IN ('ARCH005','ARCH006','ARCH004','ARCH002')
		--AND 
		--LOWER(udDeedWill.dwHolder) NOT LIKE '%(perm)%' -- this means the will has been permanently removed from archive
		--AND (dwRetrievalReas <> 'LIVE' OR dwRetrievalReas IS NULL) -- exclude the old wills where a matter has now become live as the re-archive will be on the new file ref
	--AND 
	--dbFile.fileID = '5092686'
	
	
	




GO
