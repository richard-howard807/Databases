SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [CommercialRecoveries].[MIBWriteOffsNew]	
 --[CommercialRecoveries].[MIBWriteOffsNew]	'2019-12-01','2019-12-31'		
    @StartDate	DATE	
,	@EndDate	DATE    
AS 

SELECT
Clients.MIB_ClaimNumber									             AS [File]
,name AS [Fee Earner]
,SOLADM.ADM_NameOfDebtorOnLetter									     AS Def_Name
,CLO_ClosureCode AS W_O_Code	,	AccountInfo.CLO_ClosedDate								             AS Date_File_Closed
,	AccountInfo.CurrentBalance						                     AS Amount
,   AccountInfo.DateOpened           AS DatePlaced
,CLO_ClosureCode
,CLO_ClosureReason
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END [Placement]
--,ISNULL(ADA.ADA28,'No') AS [ADA28]
FROM  [VFile_streamlined].dbo.Accountinformation AS AccountInfo
 INNER JOIN [VFile_streamlined].dbo.ClientScreens AS Clients
    ON   AccountInfo.mt_int_code = Clients.mt_int_code 
 INNER JOIN [VFile_streamlined].dbo.SOLADM AS SOLADM
    ON   AccountInfo.mt_int_code = SOLADM.mt_int_code
 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON Accountinfo.mt_int_code=ADA.mt_int_code
    	
    	LEFT OUTER JOIN VFile_Streamlined.dbo.fee ON  RIGHT(level_fee_earner,3)=fee_earner	
    WHERE	AccountInfo.FileStatus = 'COMP'
      AND ClientName LIKE '%MIB%'
      AND AccountInfo.CLO_ClosedDate		BETWEEN  @StartDate AND @EndDate
      AND AccountInfo.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)
 UNION
 
 SELECT  txtClaimRef    AS [File]
,usrFullName AS [Fee Earner]
,ISNULL(txtNameonDeb,Defendant) AS Def_Name
,txtClosureCode AS W_O_Code	
,[red_dw].[dbo].[datetimelocal](dteClosedDate) AS Date_File_Closed
,curCurrentBal  AS Amount
,[red_dw].[dbo].[datetimelocal](dbfile.Created) AS DatePlaced
,txtClosureCode AS CLO_ClosureCode
,txtClosureRea AS CLO_ClosureReason
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END [Placement]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRSOLADM
 ON udCRSOLADM.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbUser
 ON filePrincipleID=usrID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN MS_PROD.config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
WHERE clNo='M1001'
AND fileType='2038'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](fileClosed),103) BETWEEN @StartDate AND @EndDate 
GO
