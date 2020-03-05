SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE	 PROCEDURE [CommercialRecoveries].[MIBRetentionFiles]		
--EXEC [VisualFiles].[MIBRetentionFiles] '2016-03-01','2016-03-25','MIB'
(
@StartDate AS DATE
,@EndDate AS DATE
,@Placement AS NCHAR(50)
,@ClientName AS NVARCHAR(25)
)
AS
BEGIN
SELECT  MIB_ClaimNumber AS ClaimNumber ,
        AccountInfo.DateOpened AS DateImported ,
        MIB_DefendantTitle + ' ' + MIB_DefendantForeName + ''
        + MIB_DefendantMiddleName + ' ' + MIB_DefendantSurname AS DefendantName ,
        CurrentBalance AS Balance ,
        RetentionReason AS RetentionReason,
        PaymentArrangementNextDate AS NextPaymentDate
		,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END  AS [ADA28]
FROM    VFile_Streamlined.dbo.AccountInformation AS AccountInfo
        INNER JOIN VFile_Streamlined.dbo.ClientScreens AS Clients ON AccountInfo.mt_int_code = Clients.mt_int_code
        INNER JOIN ( SELECT mt_int_code AS mt_int_code ,
                            RTRIM(ud_field##2) AS RetentionReason,
                            CONVERT(DATE,RTRIM(ud_field##3),103) AS DateRetained
                     FROM   VFile_Streamlined.dbo.uddetail
                     WHERE  uds_type = 'MIR'
                            AND ud_field##1 = 'Yes'
                   ) AS Retention ON AccountInfo.mt_int_code = Retention.mt_int_code
		LEFT JOIN (
					SELECT mt_int_code, ud_field##28 AS [ADA28] 
					FROM [Vfile_streamlined].dbo.uddetail
					WHERE uds_type='ADA'
				   ) AS ADA ON AccountInfo.mt_int_code=ADA.mt_int_code
WHERE   ClientName = @ClientName
        AND  DateRetained BETWEEN @StartDate AND @EndDate
        AND CLO_ClosedDate IS NULL
		AND AccountInfo.mt_int_code NOT IN (SELECT SourceSystemID FROM VFile_Streamlined.dbo.VFToMSMattersSuccess)
		AND (CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Defendant' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'Defendant' END)=@Placement
UNION

SELECT  txtClaimRef AS ClaimNumber
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS DateImported
,ISNULL(txtDefTitle,'') + ' ' + ISNULL(txtDefFor,'') + ''
+ ISNULL(txtDefMid,'') + ' ' + ISNULL(txtDefSur,'') AS DefendantName 
,curCurrentBal AS Balance
,cdDesc AS RetentionReason
,[red_dw].[dbo].[datetimelocal](dteParArrNext) AS NextPaymentDate
,CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END  AS [ADA28]
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
LEFT OUTER JOIN [MS_PROD].dbo.udCRClientScreens
 ON udCRClientScreens.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT cdCode,cdDesc FROM [MS_PROD].dbo.dbCodeLookup WHERE cdType='RETENTION') AS Reason
 ON cboRetReason=Reason.cdCode
WHERE clNo='M1001'
AND fileType='2038'
AND [red_dw].[dbo].[datetimelocal](dteRetained) BETWEEN @StartDate AND @EndDate 
AND dteClosedDate IS NULL
AND cboWeRetain='Y'
AND CASE WHEN cboPlacement='ARBITRATION' THEN 'Arbitration'
			WHEN cboPlacement='CLAIMANT' THEN 'Claimant'
			WHEN cboPlacement='DEFENDANT' THEN 'Defendant'
			WHEN cboPlacement='INSURER' THEN 'Insurer'  ELSE 'Missing' END=@Placement
END




GO
