SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










CREATE PROCEDURE [CommercialRecoveries].[MIBNewBatch] 
--[CommercialRecoveries].[MIBNewBatch] '2016'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT DateOpened
,Title + ' '  + Forename + ' ' + Surname AS Short_name,MIB_ClaimNumber
,MIB_ClaimNumber2
,OriginalBalance
,CurrentBalance
,CASE WHEN MilestoneCode='COMP' THEN 'Closed' ELSE 'Open' END AS FileStatus
    ,CLO_ClosureCode
    ,CLO_ClosureReason
	,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END AS [ADA28]
,'VF' AS FileSource
FROM VFile_Streamlined.dbo.AccountInformation
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON AccountInformation.mt_int_code=ClientScreens.mt_int_code
LEFT OUTER JOIN (SELECT * FROM VFile_Streamlined.dbo.DebtorInformation WHERE ContactType='Primary Debtor') AS Debtor
 ON AccountInformation.mt_int_code=Debtor.mt_int_code
LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON AccountInformation.mt_int_code=ADA.mt_int_code
WHERE ClientName IN ('MIB Review File','MIB')
AND AccountInformation.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)
AND (
DateOpened BETWEEN @StartDate AND @EndDate
OR CLO_ClosedDate BETWEEN @StartDate AND @EndDate
)

UNION

SELECT dbFile.Created AS DateOpened
,ISNULL(txtShortName,ISNULL(Associates.contTitle,'') + ' '  + ISNULL(Associates.contChristianNames,'') + ' ' + ISNULL(Associates.contSurname,''))AS Short_name
,txtClaimRef AS MIB_ClaimNumber
,txtClaNum21 AS MIB_ClaimNumber2
,curOriginalBal AS OriginalBalance
,curCurrentBal AS CurrentBalance
,CASE WHEN fileClosed IS NOT NULL THEN 'Closed' ELSE 'Open' END AS FileStatus
    ,txtClosureCode AS CLO_ClosureCode
    ,txtClosureRea AS CLO_ClosureReason
	,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END AS [ADA28]
,'MS' AS FileSource
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT DISTINCT fileID,contTitle,contChristianNames,contSurname FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
INNER JOIN [MS_PROD].dbo.dbContactIndividual
 ON dbContactIndividual.contID = dbContact.contID
LEFT OUTER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
 WHERE assocType='DEFENDANT'
 AND cboDefendantNo='1') AS Associates
  ON Associates.fileID = dbFile.fileID
WHERE clNo='M1001'
AND fileType='2038'
AND (
CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dbFile.Created),103) BETWEEN @StartDate AND @EndDate
OR COALESCE([red_dw].[dbo].[datetimelocal](dteClosedDate),[red_dw].[dbo].[datetimelocal](fileClosed)) BETWEEN @StartDate AND @EndDate)



END
GO
