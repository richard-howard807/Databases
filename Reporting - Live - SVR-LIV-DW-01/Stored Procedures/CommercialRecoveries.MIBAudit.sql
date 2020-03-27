SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










--435
--253


CREATE PROCEDURE [CommercialRecoveries].[MIBAudit]
	AS
BEGIN
SELECT 
MIB_ClaimNumber
,CAST(MatterCode AS NVARCHAR(MAX)) AS MatterCode
,AccountDescription
,DateOpened
,uddetail.ud_field##1 AS [Number of weeks from LBA to 1st telephone contact with defendant]
,uddetail.ud_field##2 AS [Address]
,uddetail.ud_field##3 AS [Best contact No]
,uddetail.ud_field##4 AS [Home ownership]
,uddetail.ud_field##5 AS [Other debts/creditors info]
,uddetail.ud_field##6 AS [Was the defendant insured?]
,uddetail.ud_field##7 AS [Payment arrangement/settlement]
,uddetail.ud_field##8 AS [Contact made with Defendant by telephone]
,uddetail.ud_field##9 AS [Reasonable attempts made]
,uddetail.ud_field##10 AS [Appropriate letters sent out]
,uddetail.ud_field##11 AS [Google search completed]
,uddetail.ud_field##12 AS [Insolvency search completed]
,uddetail.ud_field##13 AS [Director search completed]
,uddetail.ud_field##14 AS [Social Media search completed]
,uddetail.ud_field##15 AS [Land Registry Search completed]
,uddetail.ud_field##16 AS [Closure of account? Or retained for agreed reason]
,uddetail.ud_field##17 AS [Quality of decision making]
,uddetail.ud_field##18 AS [Clarity of history notes]
,uddetail.ud_field##19 AS [Notice of issue sent to Defendant2]
,uddetail.ud_field##20 AS [Notice of issue sent to Defendant]
,uddetail.ud_field##21 AS [Client notified of Proceedings]
,uddetail.ud_field##22 AS [Proceedings issued]
,uddetail.ud_field##23 AS [What Settlement was offered]
,TRY_CAST(uddetail.ud_field##24 AS DATETIME) AS [Date of Audit]
,uddetail.ud_field##24  AS Dates
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END [Placement]

FROM Vfile_Streamlined.dbo.uddetail
INNER JOIN VFile_Streamlined.dbo.AccountInformation
 ON uddetail.mt_int_code=AccountInformation.mt_int_code
LEFT OUTER JOIN VFile_Streamlined.dbo.ClientScreens ON uddetail.mt_int_code=ClientScreens.mt_int_code
 LEFT JOIN (
			SELECT mt_int_code, ud_field##28 AS [ADA28] 
			FROM [Vfile_streamlined].dbo.uddetail
			WHERE uds_type='ADA'
			) AS ADA ON uddetail.mt_int_code=ADA.mt_int_code
WHERE uds_type='MDC'
AND uddetail.ud_field##24 <>''
AND uddetail.ud_field##24 <>'1900-01-01'
AND AccountInformation.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)

UNION

SELECT 
txtClaimRef AS MIB_ClaimNumber
,CRSystemSourceID AS MatterCode
,fileDesc AS AccountDescription
,[red_dw].[dbo].[datetimelocal](dbfile.Created) AS DateOpened
,Weeks.cdDesc AS [Number of weeks from LBA to 1st telephone contact with defendant]
,CASE WHEN cboAddress IN ('Y','YES') THEN 'Yes' WHEN cboAddress IN ('N','NO') THEN 'No'  END AS [Address]
,CASE WHEN cboBestCont IN ('Y','YES') THEN 'Yes' WHEN cboBestCont IN ('N','NO') THEN 'No'  END  AS [Best contact No]
,CASE WHEN cboHomeOwn IN ('Y','YES') THEN 'Yes' WHEN cboHomeOwn IN ('N','NO') THEN 'No'  END  AS [Home ownership]
,CASE WHEN cboOthDebtCred IN ('Y','YES') THEN 'Yes' WHEN cboOthDebtCred IN ('N','NO') THEN 'No'  END  AS [Other debts/creditors info]
,CASE WHEN cboWasDefIns IN ('Y','YES') THEN 'Yes' WHEN cboWasDefIns IN ('N','NO') THEN 'No'  END AS [Was the defendant insured?]
,CASE WHEN cboPayArrSet IN ('Y','YES') THEN 'Yes' WHEN cboPayArrSet IN ('N','NO') THEN 'No'  END  AS [Payment arrangement/settlement]
,CASE WHEN cboContMaDef IN ('Y','YES') THEN 'Yes' WHEN cboContMaDef IN ('N','NO') THEN 'No'  END  AS [Contact made with Defendant by telephone]
,CASE WHEN cboResAttem IN ('Y','YES') THEN 'Yes' WHEN cboResAttem IN ('N','NO') THEN 'No'  END  AS [Reasonable attempts made]
,CASE WHEN cboAppLetSen='YES' THEN 'Yes'  WHEN cboAppLetSen='NO' THEN 'No' WHEN cboAppLetSen='NA' THEN 'N/A' END AS [Appropriate letters sent out]
,CASE WHEN cboGoogleSea='YES' THEN 'Yes'  WHEN cboGoogleSea='NO' THEN 'No' WHEN cboGoogleSea='NA' THEN 'N/A' END  AS [Google search completed]
,CASE WHEN cboInsolvSearch='YES' THEN 'Yes'  WHEN cboInsolvSearch='NO' THEN 'No' WHEN cboInsolvSearch='NA' THEN 'N/A' END  AS [Insolvency search completed]
,CASE WHEN cboDirectComp='YES' THEN 'Yes'  WHEN cboDirectComp='NO' THEN 'No' WHEN cboDirectComp='NA' THEN 'N/A' END  AS [Director search completed]
,CASE WHEN cboSocialMedia='YES' THEN 'Yes'  WHEN cboSocialMedia='NO' THEN 'No' WHEN cboSocialMedia='NA' THEN 'N/A' END  AS [Social Media search completed]
,CASE WHEN cboLanRegSea='YES' THEN 'Yes'  WHEN cboLanRegSea='NO' THEN 'No' WHEN cboLanRegSea='NA' THEN 'N/A' END  AS [Land Registry Search completed]
,CASE WHEN cboClosAccRet='YES' THEN 'Yes'  WHEN cboClosAccRet='NO' THEN 'No' WHEN cboClosAccRet='NA' THEN 'N/A' END  AS [Closure of account? Or retained for agreed reason]


,CASE WHEN cboQualOfDec='AD' THEN 'Adequate' WHEN cboQualOfDec='IN' THEN 'Inadequate'  END AS [Quality of decision making]
,CASE WHEN cboClarityHist='AD' THEN 'Adequate' WHEN cboClarityHist='IN' THEN 'Inadequate'  END AS [Clarity of history notes]
,CASE WHEN cboNotOfIssDef2='AD' THEN 'Adequate' WHEN cboNotOfIssDef2='IN' THEN 'Inadequate'  END  AS [Notice of issue sent to Defendant2]

,CASE WHEN cboNotOfIssDef='YES' THEN 'Yes' WHEN cboNotOfIssDef='NO' THEN 'No' WHEN cboNotOfIssDef='NA' THEN 'N/A' END  AS [Notice of issue sent to Defendant]

,CASE WHEN cboCliNotPro='YES' THEN 'Yes' WHEN cboCliNotPro='NO' THEN 'No' WHEN cboCliNotPro='NA' THEN 'N/A' END  AS [Client notified of Proceedings]
,CASE WHEN cboProcIss ='Y' THEN 'Yes' WHEN cboProcIss='N' THEN 'No' END  AS [Proceedings issued]
,CASE WHEN cboWhatSettOf='YES' THEN 'Yes' WHEN cboWhatSettOf='NO' THEN 'No' WHEN cboWhatSettOf='NA' THEN 'N/A' END AS [What Settlement was offered]
,CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dteAudit),103) AS  [Date of Audit]
,NULL  AS Dates
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END [Placement]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM [MS_PROD].dbo.dbCodeLookup WHERE cdType='LBAWEEKS') AS Weeks
 ON cboNumofWeek=Weeks.cdCode
WHERE clNo='M1001'
AND fileType='2038'
AND dteAudit <>''
AND ISNULL(CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dteAudit),103),'1900-01-01') <>'1900-01-01'

END
GO
