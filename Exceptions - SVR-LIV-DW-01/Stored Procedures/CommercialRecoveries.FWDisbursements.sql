SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












CREATE PROCEDURE [CommercialRecoveries].[FWDisbursements]
(
@StartDate AS DATE
,@EndDate AS DATE
,@Client AS NVARCHAR(100)
)
AS
BEGIN

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2019-11-01'
--SET @EndDate='2019-11-27'
--DECLARE @Client AS NVARCHAR(MAX)
--SET @Client='LCC - Housing Benefit & Sundry Income'


SELECT * FROM (
SELECT txtCliRef AS [Client Account No]
,[red_dw].[dbo].[datetimelocal](dtePosted) AS [Date Added]
,txtBranchNum AS [Branch No]
,clNo +'-' + fileNo AS [F&W Reference]
,CASE WHEN CRSystemSourceID LIKE '33694-%'  OR Clno='W15374'THEN 'CarCashPoint Limited'
WHEN CRSystemSourceID LIKE '33746-%'  OR clno='W15410' THEN 'The Borough Council of Dudley'
WHEN CRSystemSourceID LIKE '30535-%' OR clNo='FW27456' THEN 'Stratford On Avon District Council' 
WHEN CRSystemSourceID LIKE '323223-%'  OR CRSystemSourceID LIKE '32469-%' OR Clno='W15354' THEN 'Basildon Borough Council' 
WHEN CRSystemSourceID LIKE '34485-%' OR clno='W15495' THEN 'M.K.M Building Supplies Limited'
WHEN (cboLeedsCC='LC2' ) THEN 'LCC - Section 146'
WHEN (cboLeedsCC='LC1' ) THEN 'LCC - Business Rates'
WHEN (CRSystemSourceID LIKE '3600-%' OR clno='W15471' OR cboLeedsCC='LC3' ) AND txtCliRef LIKE '8%' THEN 'LCC - Council Tax'
WHEN (CRSystemSourceID LIKE '3600-%' OR clno='W15471' OR cboLeedsCC='LC3') AND txtCliRef NOT LIKE '8%'  AND txtCliRef NOT LIKE 'EN%' THEN 'LCC - Housing Benefit & Sundry Income'
WHEN (CRSystemSourceID  LIKE '31991-%' OR cboLeedsCC='LC2' ) THEN 'LCC - Section 146'
WHEN (CRSystemSourceID  LIKE '31991-%' OR cboLeedsCC='LC1' ) THEN 'LCC - Business Rates'
WHEN (CRSystemSourceID  LIKE '35153-%' OR clNo='707938') THEN 'NHS'
WHEN CRSystemSourceID LIKE '35163-%'  OR clno='W17055' THEN 'Energas'
--WHEN CRSystemSourceID LIKE '13329-%' AND ISNULL(txtCliRef,'')<>'8GB' AND ISNULL(txtCliRef,'')<>'9GB' THEN 'UPS Exc COD'
--WHEN CRSystemSourceID LIKE '13329-%' AND (ISNULL(txtCliRef,'')='8GB' OR ISNULL(txtCliRef,'')='9GB') THEN 'UPS Inc COD' 
 



END AS [Client]
,Defendant.Defendant AS [Defendants Name]
,txtItemDesc AS [Description]
,curOffice AS [Costs To Date]
,curVAT AS [Vat]
,ISNULL(curOffice,0)+ ISNULL(curVAT,0) AS [Total]
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
WHERE cboCatDesc IN ('0','1')
AND CONVERT(DATE,[red_dw].[dbo].[datetimelocal](dtePosted),103) BETWEEN @StartDate AND @EndDate
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
) AS MainData
WHERE MainData.Client=@Client








END
GO
