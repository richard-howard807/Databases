SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [audit].[usp_ClientBalanceReportAlert]

as


SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][AUDIT.usp_ClientBalanceReportAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0

DECLARE @TestEmail AS VARCHAR(MAX)
DECLARE @TestCC AS VARCHAR(MAX)

SET @TestEmail='tracy.doyle@weightmans.com'
SET @TestCC='tracy.doyle@weightmans.com '

DECLARE
	@Client  VARCHAR(8),
	@Matter VARCHAR(8),
	@ClientName VARCHAR(60),
	@MatterDescription VARCHAR(40),
	@FeeEarnerCode VARCHAR(6),
	@USERName VARCHAR(80),
	@UserEmailAddress VARCHAR(95),
	@ClientBalance DECIMAL(13,2),
	@MT_LSTFIN DATETIME,
	@SinceUpdate INT,
	@BCMName VARCHAR(80),
	@BCMEmailAddress VARCHAR(95),
	
	@vSubject varchar(1000),
	@vRecipients varchar(100),
	@cc VARCHAR(100),
	@vBody varchar(max),
	@vImportance VARCHAR(6),
	@vTestEmail VARCHAR(95),
	@toggle INT = 1,
	@returncode INT = 0,
	@SuccessfulEmailCounter INT = 0,
	@FailedEmailCounter INT = 0
	

DECLARE @test AS INT
SET @Test=0
SET @vImportance='HIGH'

IF OBJECT_ID('tempdb..#ClientBalances') IS NOT NULL DROP TABLE #ClientBalances

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
,CASE WHEN @Test=1 THEN @TestEmail ELSE fee.usrEmail END  AS[UserEmailAddress]
,MattIndex
,BCM.usrFullName + ' (' + BCM.usrInits  + ')' AS BCMName
,CASE WHEN @Test=1 THEN @TestEmail ELSE BCM.usrEmail END  AS [BCMEmailAddress]
INTO #ClientBalances
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
WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))
AND (DATEDIFF(DAY,[post_date],GETDATE())) IN (1,28)
--AND ((clno='882745' AND fileno='16')OR (clno='W16924' AND fileno='1'))

	

DECLARE cur CURSOR LOCAL FAST_FORWARD FOR 


SELECT
	[FED Client] AS [Client],
	[Fed Matter] AS [Matter],
	[Client Name] AS [ClientName],
	[Matter Description] AS [MatterDescription],
	FeeEarner AS [FeeEarnerCode],

	CASE WHEN (FeeEarner) IS NULL 
		THEN 'Null User Name in [MS_PROD.dbUsers]'+CHAR(13)+
				'<br><b>Please raise this with IT, and also chase the Case Handler using the Case Handler CODE</b><br>'
		ELSE (FeeEarner) END [USERName],
	CASE WHEN UserEmailAddress IS NULL THEN ((CASE WHEN @test=1 THEN @TestEmail ELSE 'clientcompliance@weightmans.com' END))
		ELSE UserEmailAddress collate database_default END [USEREmailAddress] ,
	[ClientBalance],
	[Last Financial Date] AS [MT_LSTFIN],
	SinceUpdate,
	CASE WHEN (BCMName) IS NULL 
		THEN 'Null BCM Name in [MS_PROD.dbUsers]'+CHAR(13)+
				'<br><b>Please raise this with IT, and also chase the Case Handler using the Case Handler CODE</b><br>'
		ELSE (BCMName) END	[BCMName],
	CASE WHEN BCMEmailAddress IS NULL
		THEN (CASE WHEN @test=1 THEN @TestEmail ELSE 'clientcompliance@weightmans.com' END)

		ELSE (CASE WHEN BCMEmailAddress = 'matthew.williamson@weightmans.com' then	'Janice.Weatherly@Weightmans.com' ELSE BCMEmailAddress END)  END [BCMEmailAddress]
		
		FROM #ClientBalances
WHERE [SinceUpdate]   IN ('1','28')
AND UserEmailAddress IS NOT NULL
AND  [FED Client] NOT IN ('00380241','CB001','U00002')
AND RTRIM([FED Client]) + '.' +  RTRIM([Fed Matter])  NOT  IN
(
'00787558.00000001','00787558.00000002','00787559.00000001'
,'00787559.00000002','00787560.00000001','00787560.00000002'
,'00787561.00000001','00787561.00000002','00774596.00000001'
,'00774963.00000001','00736504.00000002','P00012.00009999'
,'00193048.00000001','00157454.00000001','00157453.00000004'
,'00723152.00000001','00723193.00000001','P00008.00009999'
,'00693103.00000001','00636684.00000001','00328150.00000003'
,'00455667.00000001','00531048.00000001'
) -- Exclusions Asked for by Angela Jamlett 21.09.16

OPEN cur 
FETCH NEXT from cur INTO 
	@Client,
	@Matter,
	@ClientName,
	@MatterDescription,
	@FeeEarnerCode,
	@USERName,
	@UserEmailAddress,
	@ClientBalance,
	@MT_LSTFIN,
	@SinceUpdate,
	@BCMName,
	@BCMEmailAddress
WHILE @@FETCH_STATUS = 0 
BEGIN 
SET @vSubject = ''
SET @vBody = ''
SET @cc = ''
SET @vRecipients = @UserEmailAddress

--SET @vSubject = '[CLIENT BALANCE ALERT] '+@ClientName+', "'+@MatterDescription+'", ClientBalance = £'+CAST(@ClientBalance AS VARCHAR)+', Since Update (Days):'+CAST(@SinceUpdate AS VARCHAR)

SET @vSubject = '[CLIENT BALANCE ALERT: '
				+CAST(@SinceUpdate AS VARCHAR)+' Day],'
				+'[CLIENT:'+@Client+'],'
				+'[MATTER:'+@Matter+'],'
				+'[CLIENT BALANCE: £'+CAST(@ClientBalance AS VARCHAR)+']'

--SET @vSubject = '**TEST ALERT** '+@vSubject


SET @vBody = '<font size="2" face= "Lucida Sans Unicode">'
+'Case Handler:'+ @FeeEarnerCode
+'<p>'
--+'Please consider immediately whether we have the client''s express instructions to retain this money any longer.<br>'
--+'If we do not, please return it with appropriate interest straightaway.'+'<br>'

IF @SinceUpdate IN (1, 28)
BEGIN


SET @vBody ='<font size="2" face= "Lucida Sans Unicode">You have a positive client balance on the file identified above for' + ' ' + CAST(@SinceUpdate AS VARCHAR(2)) + ' day(s) <p> Please consider / follow the steps below<html><body>'    


--SET @vBody = @vBody + '<p><p><p><p><p>1	If the funds are on a <b>live</b> file (and 2 – 8 below do not apply) you are not required to do anything.  Please disregard further alerts about the balance unless circumstances change.'
--SET @vBody = @vBody + '<p>2	If the balance is for <b>payment of an invoice</b>, please send a signed transfer to “Legal Cashier” for processing.'
--SET @vBody = @vBody + '<p>3	If the balance is an <b>overpayment</b> please refund immediately or obtain authority from client to retain the funds.  If you obtain authority to retain funds please forward confirmation to Tracy Doyle.'
--SET @vBody = @vBody + '<p>4	If you believe funds are posted to <b>incorrect file</b>, please email Legal Cashier to investigate. '
--SET @vBody = @vBody + '<p>5 If the balance relates to an <b>out of date cheque</b>, please make enquires with the client/recipient as to why cheque has not been presented before issuing a further one.  Please consider returning funds by BACS.  If the balance of the out of the date cheque is under £10.00 please contact Tracy Doyle to consider transfer to charity account.'
--SET @vBody = @vBody + '<p>6 If the balance is on a <b>substantially complete file</b> or there has been <b>no activity for three months</b>, please return/deal with funds.  If there is a reason for holding monies, please provide a copy email/letter to Tracy Doyle confirming to client how much we are holding, why and for how long to comply with Solicitors Accounts Rules.'
--SET @vBody = @vBody + '<p>7 If the balance is under £10.00 for <b>Zurich</b>, <b>MIB</b>, <b>AIG</b> or <b>BDW</b>, please email Tracy Doyle who will transfer to small balances accounts for these clients.'
--SET @vBody = @vBody + '<p>8 If the balance is under £5.00, please do not draw a cheque, contact Tracy Doyle who will advise on possible transfer to <b>charity</b> account or advise on refunding client.'

SET @vBody = @vBody + '<p><p><p><p><p>1	If the balance is on a <b>substantially complete file</b> or there has been <b>no activity for three months</b>, please return/deal with funds.  If there is a reason for holding monies, please provide a copy email/letter to Tracy Doyle confirming to client how much we are holding, why and for how long to comply with Solicitors Accounts Rules.'
SET @vBody = @vBody + '<p>2	If the funds are on a <b>live</b> file (and 3 – 8 below do not apply) you are not required to do anything.  Please disregard further alerts about the balance unless circumstances change.'
SET @vBody = @vBody + '<p>3	If the balance is for <b>payment of an invoice</b>, please send a signed transfer to “Legal Cashier” for processing.'
SET @vBody = @vBody + '<p>4 If the balance is an <b>overpayment</b> please refund immediately or obtain authority from client to retain the funds.  If you obtain authority to retain funds please forward confirmation to Tracy Doyle.'
SET @vBody = @vBody + '<p>5 If you believe funds are posted to <b>incorrect file</b>, please email Legal Cashier to investigate. '
SET @vBody = @vBody + '<p>6 If the balance relates to an <b>out of date cheque</b>, please make enquires with the client/recipient as to why cheque has not been presented before issuing a further one.  Please consider returning funds by BACS.  If the balance of the out of the date cheque is under £10.00 please contact Tracy Doyle to consider transfer to charity account.'
SET @vBody = @vBody + '<p>7 If the balance is under £10.00 for <b>Zurich</b>, <b>MIB</b>, <b>AIG</b> or <b>BDW</b>, please email Tracy Doyle who will transfer to small balances accounts for these clients.'
SET @vBody = @vBody + '<p>8 If the balance is under £5.00, please do not draw a cheque, contact Tracy Doyle who will advise on possible transfer to <b>charity</b> account or advise on refunding client.'

SET @vBody = @vBody + '<p>If your Day 1 alert relates to a cheque receipt, please be aware you will not be able to request a cheque to pay funds out until this has cleared (7 days from receipt of cheque).  You can check “clear date” in 3E by clicking on the amount of the client balance and scrolling across to Clear Date.'


SET @vBody = @vBody + '<p>'
SET @vBody = @vBody + '<p>'
SET @vBody = @vBody + '<p>Spreadsheets of all balances will be sent regularly to all Heads of Service Delivery and Team Managers highlighting any breaches or overpayments for them to follow up.'
SET @vBody = @vBody + '<p>'
SET @vBody = @vBody + '<p>If you are receiving alerts and you are no longer the Case Manager or Team Manager please amend personnel in Mattersphere to ensure alerts are emailed to the correct recipient.'
SET @vBody = @vBody + '<p>'
SET @vBody = @vBody + '<p>If you have any queries please contact Tracy Doyle in Risk & Compliance on Extension 133364.'


END 



		

		
SET @vBody = @vBody +'<br>'
+'<p>'+
'Client: '+ @Client+'<br>'+
'Matter: '+ @Matter+'<br>'+
'Client Name: '+ @ClientName+'<br>'+
'Matter Description: '+ @MatterDescription+'<br>'+
--'Case Handler Code: '+ @FeeEarnerCode+'<br>'+
'Case Handler Name: '+@USERName+'<br>'+
'Case Handler Email Address: '+@UserEmailAddress+'<br>'+
'Client Balance: £' + CAST(@ClientBalance AS VARCHAR)+'<br>'+
'MT_LSTFIN: '+convert(varchar(11),@MT_LSTFIN,13)+'<br>'+
'Days Since Update: '+CAST(@SinceUpdate AS VARCHAR)+'<br>'+
'Team Manager Name: '+@BCMName+'<br>'+
'Team Manager Email Address: '+@BCMEmailAddress + '<p><p>'
--'Report link:<br>'
--+'<a href="http://sql2008svr/Reports/Pages/Report.aspx?ItemPath=/LIVE/Audit+Reports/Client+Balances+Alert" target="_blank">'
--+'http://sql2008svr/Reports/Pages/Report.aspx?ItemPath=/LIVE/Audit+Reports/Client+Balances+Alert'
--+'<a/>'
--+'<p>'
--+'<b>This is a system generated email. Please do not reply.</b>'

--test prints
--PRINT 'vSubject'+@vSubject
--print '@vBody'+@vBody
--IF @toggle = 1

	BEGIN

	IF  @SinceUpdate = 28
		BEGIN --main email to BCM, cc'd to Sue, and FEE EARNER
		--SET @vRecipients = @BCMEmailAddress
		SET @vRecipients = @UserEmailAddress
		--SET @cc = 'sue.cartwright@Weightmans.com;Tracy.Doyle@Weightmans.com;clientcompliance@weightmans.com'
		SET @cc = (CASE WHEN @test=1 THEN @TestCC ELSE 'clientcompliance@weightmans.com' END)
		--SET @cc = @UserEmailAddress +';'+@cc
		SET @cc = @BCMEmailAddress +';'+@cc
		--SET @cc = @vTestEmail+';'+@vTestEmail

		END


IF @SinceUpdate = 1
BEGIN

SET @cc = null

END 
			
	SET @returncode = -1

	EXEC @returncode = msdb.dbo.sp_send_dbmail 
	@profile_name = 'Client Compliance',

	--@recipients=@vTestEmail,
	@recipients = @vRecipients,--@UserEmailAddress,
	@copy_recipients = @cc,

	@subject= @vSubject,
	@body=@vBody,
	@importance = @vImportance,
	@body_format = 'HTML'
	
	SET @SuccessfulEmailCounter = @SuccessfulEmailCounter + (CASE WHEN @returncode = 0 THEN 1 ELSE 0 END)
	SET @FailedEmailCounter = @FailedEmailCounter + (CASE WHEN @returncode = 0 THEN 0 ELSE 1 END)
	
	END
--SET @toggle = 0

FETCH NEXT FROM cur INTO
	@Client,
	@Matter,
	@ClientName,
	@MatterDescription,
	@FeeEarnerCode,
	@USERName,
	@UserEmailAddress,
	@ClientBalance,
	@MT_LSTFIN,
	@SinceUpdate,
	@BCMName,
	@BCMEmailAddress
END 
CLOSE cur 
DEALLOCATE cur 

SET @log = @log+'<br>'+CHAR(13)+ '[AUDIT.usp_ClientBalanceReportAlert] Successful Emails Sent: '+CAST(@SuccessfulEmailCounter AS VARCHAR)
SET @log = @log+'<br>'+CHAR(13)+ '[AUDIT.usp_ClientBalanceReportAlert] Failed Emails Sent: '+CAST(@FailedEmailCounter AS VARCHAR)
SET @log = @log+'<br>'+CHAR(13)+ '[END  ][AUDIT.usp_ClientBalanceReportAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'

PRINT @log

SET @vSubject = 'AUDIT.usp_ClientBalanceReportAlert LOG:'+CONVERT(VARCHAR(20),GETDATE(),13)
	EXEC @returncode = msdb.dbo.sp_send_dbmail 
	@profile_name = 'Client Compliance',

	@recipients= 'david.abram@weightmans.com;stephen.daffern@weightmans.com;kevin.hansen@weightmans.com',  --@vTestEmail,
	@subject= @vSubject,
	@body=@log,
	@importance = @vImportance,
	@body_format = 'HTML'
	



SET NOCOUNT OFF
GO
