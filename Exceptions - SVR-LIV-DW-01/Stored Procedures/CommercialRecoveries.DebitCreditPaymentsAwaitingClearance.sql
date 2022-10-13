SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [CommercialRecoveries].[DebitCreditPaymentsAwaitingClearance]

AS
BEGIN
SELECT clNo,fileNo,fileDesc,clName,red_dw.dbo.datetimelocal(dtePosted) AS dtePosted
,txtItemDesc
,curClient AS [Amount]
,txtPayorPaye AS [Payee/Payor]
,txtReference AS [Payment Reference]
,txtWorldPayID AS [WorldPayOD]
,cdDesc AS [Payment Type]
FROM ms_prod.config.dbFile
INNER JOIN ms_prod.config.dbClient
 ON dbClient.clID = dbFile.clID
INNER JOIN MS_Prod.dbo.udCRLedgerSL
 ON udCRLedgerSL.fileID = dbFile.fileID
LEFT OUTER JOIN MS_Prod.dbo.udExtFile
 ON udExtFile.fileID = dbFile.fileID
 LEFT OUTER JOIN MS_Prod.dbo.dbUser
  ON MS_Prod.dbo.udCRLedgerSL.usrID=dbuser.usrid
LEFT OUTER JOIN MS_Prod.dbo.udCRCore
 ON udCRCore.fileID = dbFile.fileID

LEFT OUTER JOIN ms_prod.dbo.dbCodeLookup
 ON cboPayType=cdCode  AND cdType='PAYTYPEALL'

WHERE cboCatDesc IN ('6')
AND CONVERT(DATE,red_dw.dbo.datetimelocal(dtePosted),103)>'2020-02-29'
AND cboPayType IN ('PAY001','PAY002')
AND clNo <>'30645'

END
GO
