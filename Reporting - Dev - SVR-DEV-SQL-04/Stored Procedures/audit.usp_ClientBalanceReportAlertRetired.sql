SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [audit].[usp_ClientBalanceReportAlertRetired]

as


SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][AUDIT.usp_ClientBalanceReportAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0

DECLARE @TestEmail AS VARCHAR(MAX)
DECLARE @TestCC AS VARCHAR(MAX)

SET @TestEmail='tracy.doyle@weightmans.com'
SET @TestCC='tracy.doyle@weightmans.com'

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




DECLARE cur CURSOR LOCAL FAST_FORWARD FOR 


SELECT
	[FED Client] AS [Client],
	[Fed Matter] AS [Matter],
	[Client Name] AS [ClientName],
	[Matter Description] AS [MatterDescription],
	FeeEarner AS [FeeEarnerCode],

	CASE WHEN (FeeEarner) IS NULL 
		THEN 'Null User Name in [MS_PROD.dbUsers]'+CHAR(13)+
				'<br><b>Please raise this with IT, and also chase the FEE EARNER using the FEE EARNER CODE</b><br>'
		ELSE (FeeEarner) END [USERName],
	CASE WHEN UserEmailAddress IS NULL THEN ((CASE WHEN @test=1 THEN @TestEmail ELSE 'clientcompliance@weightmans.com' END))
		ELSE UserEmailAddress collate database_default END [USEREmailAddress] ,
	[ClientBalance],
	[Last Financial Date] AS [MT_LSTFIN],
	SinceUpdate,
	CASE WHEN (BCMName) IS NULL 
		THEN 'Null BCM Name in [MS_PROD.dbUsers]'+CHAR(13)+
				'<br><b>Please raise this with IT, and also chase the FEE EARNER using the FEE EARNER CODE</b><br>'
		ELSE (BCMName) END	[BCMName],
	CASE WHEN BCMEmailAddress IS NULL
		THEN (CASE WHEN @test=1 THEN @TestEmail ELSE 'clientcompliance@weightmans.com' END)

		ELSE (CASE WHEN BCMEmailAddress = 'matthew.williamson@weightmans.com' then	'Janice.Weatherly@Weightmans.com' ELSE BCMEmailAddress END)  END [BCMEmailAddress]
		
		FROM #ClientBalances
WHERE [SinceUpdate]   IN ('14','28')
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
+'Fee Earner:'+ @FeeEarnerCode
+'<p>'
--+'Please consider immediately whether we have the client''s express instructions to retain this money any longer.<br>'
--+'If we do not, please return it with appropriate interest straightaway.'+'<br>'

IF @SinceUpdate = 14
BEGIN
IF object_id('tempdb..#Temp') IS NOT NULL DROP TABLE #Temp

CREATE TABLE #Temp 
( 
  [Area]  [varchar](MAX),
  [Guidance Note]  [varchar](MAX)
)


INSERT INTO #Temp
SELECT '(1) Can the balance be paid against', ('(a) A bill '+'*' + '(b) A non-Vatable disbursement (eg Land Registry fees/Court fees)'+'*'  +'*' + 'Please prepare an interledger transfer form and have it autorised and sent to finance for processing' )
UNION ALL
SELECT '(2) Is the balance an overpayment?','Please return the funds (via cheque/BACS) immediately to the payee.'
UNION ALL
SELECT '(3) Is the balance recovered costs/DWP payment?','Please account immediately to the client by:-' +'*' + '(a) Requesting a payment to the client' +'*' + '(b) Preparing a bill to enable us to recoup costs out of monies recovered'
UNION ALL
SELECT '(4) Is the balance less than £1.00?','Please forward this email to Risk and Compliance (Client Balance Compliance) who will transfer the balance to our charity account and obtain COLP approval.'
UNION ALL
SELECT '(5) Is the balance between £1.00- £10.00 and owing to','(a) AIG/Chartis' +'*' + '(b) AON/ACS' +'*' + '(c) BAI' +'*' + '(d) Capita (Chester Street Insurance Holdings) Limited' +'*' + '(e) Merseyside Police' +'*' + '(f) MIB' +'*' + '(g) Zurich' + '*' + 'Please forward this email to Risk and Compliance (Client Balance Compliance) who will transfer the balance to the small balances accounts held for' +' kkk ' + 'these clients only' +' aaax ' + 'and obtain COLP approval.'

UNION ALL
SELECT '(6)If none of the above is applicable, is this matter live or substantially complete?','(a) Live means the accounts/case plan shows activity within the previous 3 months. If there is a valid reason for holding the monies, no action is required at this stage although the file will be diarised by Risk and Compliance to check the position at a future date.' +'*' + '(b) Substantially complete means the accounts/case plan does not show activity for the previous 3 months.  In this event a letter must be sent to the client confirming:-' +'*' +  '(i) that we still hold their money'+'*' +  '(ii) why we still hold their money' +'*' +  '(iii) how much money are we holding' +'*' + '(iv) how long we expect to hold their money' +'*' +'A copy of this written correspondence' +' kkk ' + 'must '+' aaax ' +'be sent to Risk and Compliance (Client Balance Compliance) who will retain a copy for production to our external auditors.'

DECLARE @xml NVARCHAR(MAX)


SET @xml = CAST(( SELECT [Area] AS 'td','',[Guidance Note] AS 'td',''
FROM  #Temp --ORDER BY Rank 
FOR XML PATH('tr'), ELEMENTS ) AS NVARCHAR(MAX))


SET @vBody ='<font size="2" face= "Lucida Sans Unicode">You have had a positive client balance on the file identified above for 14 days <p> Please consider follow the steps below<html><body><H3>The Client Balance Clearance Matrix</H3>
<table border = 1>'    


SET @vBody = @vBody + REPLACE(REPLACE(REPLACE(@xml,'*','<p>'),'kkk','<b><u>'),'aaax','</b></u>') +'</table></body></html>If you have investigated the client balance and believe it does not fall into the categories listed above, numbers (1)-(6), please contact Risk and Compliance (Client Balance Compliance) immediately.<p>Failure to deal with this balance may result in your balance scorecard being affected.<p><b>THIS IS A SYSTEM GENERATED EMAIL.</b>'
END


IF @SinceUpdate = 56 
		BEGIN
		--SET @vBody = @vBody +'If you do not action this you will receive another reminder at 56 days'
		--									  +' and thereafter the Compliance team will start chasing you.<br>'
				SET @vBody = @vBody + '<b>' +'IF YOU HAVE DEALT WITH THIS BALANCE BY WRITING TO THE CLIENT AND PROVIDING R&C (EML: CLIENT BALANCE COMPLIANCE) WITH A COPY OF YOUR LETTER SO THAT THERE IS NO BREACH OF THE SOLICITORS ACCOUNTS RULES, PLEASE DISREGARD THIS EMAIL.'+ '</b>'
+'<p>'
+ '<b>' +'IF HOWEVER YOU HAVE NOT DEALT WITH THIS BALANCE, PLEASE READ ON. ' + '</b>'
+'<p>'
+'You have had a positive client balance on the file identified above for 56 days.  These 56 day emails are being sent during the transitional period 16/03/15 - 10/04/15 following which time, the alerts will move to the revised method of dealing with client balances.  You will then only receive notification of a client balance at 1 day, 14 days and then 28 days prior to further action being considered.'
+'<p>'
+'After 10/04/15, 56 day alerts will no longer be sent as Weightmans LLP deem the appropriate timescale to deal with client balances, in order to comply with the Solicitors Accounts Rules, as 14 days.'
+'<p>'
+'Please deal with this balance immediately.  If you need advice, please contact R&C (Angela Hamlett, ext 133353 or Tracy Doyle, ext 133364).'
+'<p>'
+ '<b>' +'THIS IS A SYSTEM GENERATED EMAIL.' + '</b>'
		END
		
IF @SinceUpdate = 28
		BEGIN
		SET @vBody = @vBody + '<b>' +'IF YOU HAVE DEALT WITH THIS BALANCE BY WRITING TO THE CLIENT AND PROVIDING R&C (EML: CLIENT BALANCE COMPLIANCE) WITH A COPY OF YOUR LETTER SO THAT THERE IS NO BREACH OF THE SOLICITORS ACCOUNTS RULES, PLEASE DISREGARD THIS EMAIL.'+ '</b>'
+'<p>'
+ '<b>' +'IF THIS MATTER REMAINS LIVE (THE ACCOUNTS/CASE PLAN SHOWS ACTIVITY WITHIN THE PREVIOUS 3 MONTHS) PLEASE DISREGARD THIS EMAIL.  THE FILE WILL BE DIARISED BY RISK AND COMPLIANCE TO CHECK THE POSITION AT A FUTURE DATE.' + '</b>'
+'<p>'
+ '<b>' +'IF HOWEVER YOU HAVE NOT DEALT WITH THIS BALANCE, PLEASE READ ON. ' + '</b>'
+'<p>'
+'You have had a positive client balance on the file identified above for 28 days.'
+'<p>'
+'You have received this email as you have not dealt with the client balance despite two previous notifications:'
+'<p>'
+'(1) On receipt of the balance – the 1 day alert'
+'<p>'
+'(2)	On receipt of the 14 day alert'
+'<p>'
+'You are now in breach of the Solicitors Accounts Rules because:'		
+'<p>'
+'(3)	You have not dealt with the balance promptly '
+'<p>'
+'(4) You have not notified Risk and Compliance (Client Balance Compliance) of the reason for holding the balance and provided a copy of the written correspondence to the client confirming this (as detailed in the automatically generated email sent to you when the balance reached 14 days).'
+'<p>'
+'Please deal with this balance immediately.  If you need advice, please contact R&C (Angela Hamlett, ext 133353 or Tracy Doyle, ext 133364).'
+'<p>'
+ '<b>' +'THIS IS A SYSTEM GENERATED EMAIL.' + '</b>'

END
		
SET @vBody = @vBody +'<br>'
+'<p>'+
'Client: '+ @Client+'<br>'+
'Matter: '+ @Matter+'<br>'+
'Client Name: '+ @ClientName+'<br>'+
'Matter Description: '+ @MatterDescription+'<br>'+
--'Fee Earner Code: '+ @FeeEarnerCode+'<br>'+
'Fee Earner Name: '+@USERName+'<br>'+
'Fee Earner Email Address: '+@UserEmailAddress+'<br>'+
'Client Balance: £' + CAST(@ClientBalance AS VARCHAR)+'<br>'+
'MT_LSTFIN: '+convert(varchar(11),@MT_LSTFIN,13)+'<br>'+
'Days Since Update: '+CAST(@SinceUpdate AS VARCHAR)+'<br>'+
'BCM Name: '+@BCMName+'<br>'+
'BCM Email Address: '+@BCMEmailAddress + '<p><p>'
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

	IF @SinceUpdate = 56 OR @SinceUpdate = 28
		BEGIN --main email to BCM, cc'd to Sue, and FEE EARNER
		--SET @vRecipients = @BCMEmailAddress
		SET @vRecipients = @UserEmailAddress
		--SET @cc = 'sue.cartwright@Weightmans.com;Tracy.Doyle@Weightmans.com;clientcompliance@weightmans.com'
		SET @cc = (CASE WHEN @test=1 THEN @TestCC ELSE 'clientcompliance@weightmans.com' END)
		--SET @cc = @UserEmailAddress +';'+@cc
		SET @cc = @BCMEmailAddress +';'+@cc
		--SET @cc = @vTestEmail+';'+@vTestEmail

		END


IF @SinceUpdate = 14
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
