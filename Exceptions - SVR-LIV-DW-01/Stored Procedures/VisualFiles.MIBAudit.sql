SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [VisualFiles].[MIBAudit]
	AS
BEGIN
SELECT 
MIB_ClaimNumber
,MatterCode
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
,uddetail.ud_field##24 AS [Date of Audit]
,CASE WHEN [ADA28]='Recovery from Claimant' THEN 'Recovery from Claimant'
WHEN [ADA28]  IN ('2nd Placement','Yes') THEN 'Second Placement' 
WHEN  ISNULL(ADA.ADA28,'No') IN ('','No','1st Placement') THEN 'First Placement' END [Placement]

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

END
GO
