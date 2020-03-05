SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [audit].[ClientBalanceAlert]
AS
BEGIN
SELECT 
clNo AS [MS Client]
,fileNo AS [MS Matter]
,CASE WHEN udExtFile.FEDCode is null THEN (CASE WHEN ISNUMERIC(dbClient.clno)=1 THEN  RIGHT('00000000' + CONVERT(VARCHAR,dbClient.clno), 8) ELSE CAST(RTRIM(dbClient.clNo)  AS VARCHAR(8)) END) ELSE (CAST(SUBSTRING(RTRIM(udExtFile.FEDCode), 1, CASE WHEN CHARINDEX('-', RTRIM(udExtFile.FEDCode)) > 0 THEN CHARINDEX('-', RTRIM(udExtFile.FEDCode))-1
ELSE LEN(RTRIM(udExtFile.FEDCode)) END) AS CHAR(8))) END  AS [FED Client] 
,CASE WHEN udExtFile.FEDCode is null THEN RIGHT('00000000' + CONVERT(VARCHAR,dbFile.fileno), 8) ELSE CAST(RIGHT(RTRIM(udExtFile.FEDCode),LEN(RTRIM(udExtFile.FEDCode))-CHARINDEX('-',RTRIM(udExtFile.FEDCode)))AS CHAR(8)) END  AS [FED Matter]
,dbClient.clName AS [Client Name]
,fileDesc AS [Matter Description]
,ClientBalance
,[post_date] AS [Last Financial Date]
,DATEDIFF(DAY,[post_date],GETDATE()) AS [SinceUpdate]
,CASE WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 0 AND 13 THEN '0To13'
WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 14  AND 27 THEN '14To27'
                 WHEN DATEDIFF(d,[post_date], GETDATE()) BETWEEN 28 AND 365 THEN '28to1Year'
                 WHEN DATEDIFF(d, [post_date], GETDATE()) > 365 THEN 'YearPlus'
                 WHEN [post_date] IS NULL THEN 'Never Worked On'
            END AS FilterTable
            ,CASE WHEN ClientBalance=0 THEN 'Yes' ELSE 'No' END AS ZeroBalance
,fee.usrFullName + ' (' + fee.usrInits  + ')' AS FeeEarner
,fee.usrEmail AS[UserEmailAddress]
,[Practice Area]
,Team
,hierarchylevel2
,MattIndex
,BCM.usrFullName + ' (' + BCM.usrInits  + ')' AS BCMName
,BCM.usrEmail AS [BCMEmailAddress]
FROM 
(SELECT MattIndex,SUM(ClientBalance) AS ClientBalance 
,COALESCE(MAX(CASE WHEN  PositiveBalance=1  THEN  [post_date] ELSE NULL END)
,MIN([post_date])) AS [post_date] 
FROM 
(
SELECT MattIndex
,ClientBalance
,[post_date]
,running_sales_amount
,ZeroBalance
,LAG(ZeroBalance, 1,0) OVER (partition by MattIndex ORDER BY [post_date])  AS PositiveBalance
FROM 
(

SELECT      MattIndex AS MattIndex
            ,tb.amount AS ClientBalance
			,COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) [post_date]
			,sum(tb.amount) over (partition by MattIndex order by (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) rows unbounded preceding) as running_sales_amount   
			,CASE WHEN (sum(tb.amount) over (partition by MattIndex order by (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) rows unbounded preceding))=0 THEN 1 ELSE 0 END AS ZeroBalance
			
     FROM [TE_3E_Prod].[dbo].[TrustBalance] tb
     INNER JOIN [TE_3E_Prod].[dbo].Matter matter ON tb.matter = matter.MattIndex
     INNER JOIN [TE_3E_Prod].[dbo].Client client ON matter.Client = client.ClientIndex
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustDisbursement] disb ON tb.trustdisbursement = disb.trustdsbmtindex 
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustDisbursementType] tdt ON tdt.code = disb.trustdisbursementtype
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustCheck] tc ON disb.TrustCheck = tc.TrustChkIndex 
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceiptDetail] receiptdetail ON receiptdetail.[TrustRcptDetIndex] = tb.trustreceiptdetail 
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceipt] receipt ON receipt.trustrcptindex = receiptdetail.trustreceipt
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustReceiptType] receipttype ON receipt.trustreceipttype = receipttype.code
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustAdjustment] adjustment ON adjustment.trustadjindex = tb.trustadjustment 
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustAdjType] adjustmenttype ON adjustment.trustadjtype = adjustmenttype.code
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransferDetail] transferdetail ON tb.trusttransferdetail = transferdetail.TrustTransferDetIndex
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransfer] transfers ON transfers.trusttrsfindex = transferdetail.TrustTransfer  
     LEFT JOIN [TE_3E_Prod].[dbo].[TrustTransferType] transfertype ON transfers.trusttransfertype = transfertype.code
     LEFT JOIN [TE_3E_Prod].[dbo].[BankAcct] bank ON tb.BankAcctTrust = bank.BankAcctIndex
     --WHERE MattIndex='2170011'
) AS AllData
) AS Transactions
GROUP BY MattIndex
) AS AllClientBalances
INNER JOIN MS_Prod.config.dbFile
 ON AllClientBalances.MattIndex=dbFile.fileExtLinkID
INNER JOIN MS_Prod.config.dbClient
 ON dbFile.clID=dbClient.clID
INNER JOIN MS_PROD.dbo.udExtFile
 ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_PROD.dbo.dbUser fee on fee.usrID = dbFile.filePrincipleID
INNER JOIN MS_PROD.dbo.dbUser BCM on BCM.usrID = dbFile.fileresponsibleID
LEFT OUTER JOIN (SELECT fed_code,hierarchylevel2,hierarchylevel3 AS [Practice Area]
,hierarchylevel4 AS [Team]
FROM red_dw.dbo.dim_fed_hierarchy_current
WHERE dss_current_flag='Y') AS Teams
 ON fee.usrInits=fed_code collate database_default

WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))

END


GO
