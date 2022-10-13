SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE PROCEDURE [VisualFiles].[MIBRetentionFiles]		--EXEC [VisualFiles].[MIBRetentionFiles] '2016-03-01','2016-03-25','MIB'
(
@StartDate AS DATE
,@EndDate AS DATE
,@ClientName AS VARCHAR(25)
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
		,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END  AS [ADA28]
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
END



GO
