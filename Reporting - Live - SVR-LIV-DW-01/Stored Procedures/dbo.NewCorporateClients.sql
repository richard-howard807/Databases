SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[NewCorporateClients] --EXEC  [dbo].[NewCorporateClients]  '2019-02-18','2019-02-19'
(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
SELECT
clNo as 'Client Code'
,clName as 'Client Name'
,cltypeCode as 'Client Type'
,client_group_code as 'Client Group'
,dbClient.created as 'Date Opened'
,CreditLimit			 as 'CreditLimit'
,ClientBalance			 as 'ClientBalance'
 FROM MS_PROD.config.dbClient 
 INNER JOIN TE_3E_Prod.dbo.Client
 ON MS_Prod.config.dbClient.clextID=ClientIndex
INNER JOIN red_dw.dbo.dim_client
 ON clNo=client_code COLLATE DATABASE_DEFAULT
LEFT OUTER JOIN (SELECT 
clNo AS [MS Client]
,SUM(ClientBalance) AS ClientBalance
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
	 --WHERE COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) <>'2019-03-06' this code will be commented in when the bank account change happens 
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
GROUP BY clNo
) AS ClientBalance
 ON MS_Prod.config.dbClient.clNo=ClientBalance.[MS Client]

WHERE CONVERT(DATE,Created,103) BETWEEN @StartDate AND @EndDate
AND cltypeCode NOT IN ('1','JOINT')
	
END
GO
