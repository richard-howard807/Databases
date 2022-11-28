SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [CommercialRecoveries].[BMWCCJData]
(
@Client  AS NVARCHAR(MAX)
,@StartDate AS DATE
,@EndDate AS DATE
)
AS 

BEGIN 
--DECLARE @Client AS NVARCHAR(MAX)
--SET @Client='BMW'

--DECLARE @StartDate AS DATE
--DECLARE @EndDate AS DATE
--SET @StartDate='2020-08-01'
--SET @EndDate='2020-09-03'

SELECT AllData.[Client number],
       AllData.[Matter number],
       AllData.[Matter description],
       AllData.Description,
       AllData.[Date Added],
       AllData.cboCatDesc,
       AllData.cboItemCode
FROM 
(
SELECT clNo AS [Client number]
,fileNo AS [Matter number]
,fileDesc AS [Matter description]
,txtItemDesc AS [Description]-- - Solicitor costs – entry of judgment – amount
,red_dw.dbo.datetimelocal(dtePosted) AS [Date Added]-- was added to Mattersphere
,cboCatDesc
,cboItemCode
FROM [MS_PROD].config.dbFile
INNER JOIN [MS_PROD].config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN [MS_PROD].dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
INNER JOIN [MS_PROD].dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
WHERE (CASE WHEN clNo IN ('FW30085','FW22135') THEN 'BMW' 
WHEN clNo='341077' THEN 'Land Rover'
WHEN clNo='FW22352' THEN 'Rover'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22275%' THEN 'MG'
WHEN clNo='FW22135' OR CRSystemSourceID LIKE '22222%' THEN 'R&B'
WHEN clNo='FW22613' THEN 'Mini'
WHEN clNo='W15335' THEN 'Alphera'
WHEN clNo IN ('W20110','FW23557') THEN 'Alphabet' 
END)=@Client
--AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103) BETWEEN @StartDate AND @EndDate
AND cboItemCode='SOLEJ'
AND bitReversalTrans=0
) AS AllData
WHERE CONVERT(DATE,AllData.[Date Added],103) BETWEEN @StartDate AND @EndDate

END
GO
