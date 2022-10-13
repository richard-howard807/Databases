SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE PROCEDURE [CommercialRecoveries].[BMWOldNewContract] --EXEC [CommercialRecoveries].[BMWOldNewContract] '2019-10-01','2019-10-30','Old'
(@StartDate  AS DATE
,@EndDate  AS  DATE
,@Contract AS   NVARCHAR(10)
)
AS
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2019-10-01'
--SET @EndDate='2019-10-30'

--DECLARE @Contract AS NVARCHAR(10)
--SET @Contract='New'


IF @Contract='Old'


BEGIN

SELECT clNo +'-' + fileNo AS [Ref]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS Created
,ISNULL(Ref.assocRef,txtCliRef) AS [Agreement No]	
,NULL AS [Invoice No]	
,Defendant AS [Customer Name]	
,CASE WHEN cboCatDesc='7' THEN 'Fixed Fees' 
WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%' THEN 'Court Fees' 
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' THEN 'Disbursements' END   AS [Category]
,CASE WHEN cboCatDesc='7' THEN 'Fixed Fees Total' 
WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%'  THEN 'Court Fees Total' 
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE' THEN 'Disbursements Inc VAT Total'
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN 'Disbursements Exc VAT Total'
 END   AS [CategoryX]	
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE' THEN 'Agent Fees & Charges Inc VAT'
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN 'Agent Fees & Charges Exc VAT' ELSE  REPLACE(txtItemDesc,'Not Added - ','') END AS [Type]	
,CASE WHEN cboDefended='N' THEN 'No' END AS [Defended]	
,CASE WHEN cboJudgement='N' THEN 'No' WHEN cboJudgement='Y' THEN 'Yes' END  AS [Judgment]	
,curOffice AS [Cost exc VAT]
,CASE WHEN cboCatDesc='7'  THEN curOffice ELSE 0 END AS FixedFeeAmount	
,CASE WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%' THEN curOffice ELSE 0 END AS CourtFee
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE'  THEN curOffice ELSE 0 END  AS DisbursementsIncVAT
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN curOffice ELSE 0 END AS DisbursementsExcVAT
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Bill Date]
,usrFullName AS [EA]
,cboCatDesc
 FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.dbUser
 ON filePrincipleID=dbUser.usrID
LEFT OUTER JOIN (SELECT fileID, assocRef FROM ms_prod.config.dbAssociates
WHERE assocType='CLIENT'
AND assocRef IS NOT NULL) AS Ref
 ON Ref.fileID = dbFile.fileID
WHERE (

(CRSystemSourceID  LIKE '22135-%' OR clNo='FW22135')
OR (CRSystemSourceID  LIKE '22613-%' OR clNo='FW22613')
OR (CRSystemSourceID  LIKE '28617-%' OR clNo='W15335')
OR (CRSystemSourceID  LIKE '30010-%' OR clNo='FW22135')
OR clNo IN ('FW22352','341077')
)
AND cboCatDesc  IN ('7','1','0')
AND fileType='2038'
AND ISNULL(cboDefended,'N')='N'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dbFile.Created),103)<'2016-08-01'

END 

ELSE 


BEGIN
SELECT clNo +'-' + fileNo AS [Ref]
,[red_dw].[dbo].[datetimelocal](dbFile.Created) AS Created
,ISNULL(Ref.assocRef,txtCliRef) AS [Agreement No]	
,NULL AS [Invoice No]	
,Defendant AS [Customer Name]	
,CASE WHEN cboCatDesc='7' THEN 'Fixed Fees' 
WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%' THEN 'Court Fees' 
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' THEN 'Disbursements' END   AS [Category]
,CASE WHEN cboCatDesc='7' THEN 'Fixed Fees Total' 
WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%'  THEN 'Court Fees Total' 
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE' THEN 'Disbursements Inc VAT Total'
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN 'Disbursements Exc VAT Total'
 END   AS [CategoryX]	
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE' THEN 'Agent Fees & Charges Inc VAT'
WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN 'Agent Fees & Charges Exc VAT' ELSE  REPLACE(txtItemDesc,'Not Added - ','') END AS [Type]	
,CASE WHEN cboDefended='N' THEN 'No' END AS [Defended]	
,CASE WHEN cboJudgement='N' THEN 'No' WHEN cboJudgement='Y' THEN 'Yes' END  AS [Judgment]	
,curOffice AS [Cost exc VAT]
,CASE WHEN cboCatDesc='7'  THEN curOffice ELSE 0 END AS FixedFeeAmount	
,CASE WHEN cboCatDesc IN ('1','0') AND UPPER(txtItemDesc) LIKE '%COURT%' THEN curOffice ELSE 0 END AS CourtFee
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='VATABLE'  THEN curOffice ELSE 0 END  AS DisbursementsIncVAT
,CASE WHEN cboCatDesc IN ('1','0') AND NOT UPPER(txtItemDesc) LIKE '%COURT%' AND cboVATCat='NONVATABLE' THEN curOffice ELSE 0 END AS DisbursementsExcVAT
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Bill Date]
,usrFullName AS [EA]
,cboCatDesc
 FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRCore ON udCRCore.fileID = dbFile.fileID
LEFT OUTER JOIN (SELECT fileID,contName AS [Defendant] FROM [MS_PROD].config.dbAssociates
INNER JOIN [MS_PROD].dbo.udExtAssociate
 ON udExtAssociate.assocID = dbAssociates.assocID
INNER JOIN [MS_PROD].config.dbContact
 ON dbContact.contID = dbAssociates.contID
WHERE assocType='DEFENDANT'
AND cboDefendantNo='1') AS Defendant
 ON Defendant.fileID = dbFile.fileID
LEFT OUTER JOIN [MS_PROD].dbo.udCRAccountInformation
 ON udCRAccountInformation.fileID = dbFile.fileID
 LEFT OUTER JOIN [MS_PROD].dbo.dbUser
 ON filePrincipleID=dbUser.usrID
LEFT OUTER JOIN (SELECT fileID, assocRef FROM ms_prod.config.dbAssociates
WHERE assocType='CLIENT'
AND assocRef IS NOT NULL) AS Ref
 ON Ref.fileID = dbFile.fileID
WHERE (

(CRSystemSourceID  LIKE '22135-%' OR clNo='FW22135')
OR (CRSystemSourceID  LIKE '22613-%' OR clNo='FW22613')
OR (CRSystemSourceID  LIKE '28617-%' OR clNo='W15335')
OR (CRSystemSourceID  LIKE '30010-%' OR clNo='FW22135')
OR clNo IN ('FW22352','341077')
)
AND cboCatDesc  IN ('7','1','0')
AND fileType='2038'
AND ISNULL(cboDefended,'N')='N'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dbFile.Created),103)>='2016-08-01'

END

END
GO
