SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE  PROC [audit].[usp_ClientBalanceReportAlert]

AS


SET NOCOUNT ON
DECLARE @log VARCHAR(MAX)
SET @log = '[START][AUDIT.usp_ClientBalanceReportAlert][StartTime:'+CONVERT(VARCHAR(20),GETDATE(),13)+']'
DECLARE @cnt INT = 0

DECLARE @TestEmail AS VARCHAR(MAX)
DECLARE @TestCC AS VARCHAR(MAX)

SET @TestEmail='kevin.hansen@weightmans.com'
SET @TestCC='kevin.hansen@weightmans.com '

DECLARE
	@Client  VARCHAR(8),
	@Matter VARCHAR(8),
	@MSClient AS NVARCHAR(50),
	@MSMatter AS NVARCHAR(50),
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
,BCM.usrFullName	 AS BCMName
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
	 WHERE COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) <>'2019-05-25' --this code will be commented in when the bank account change happens 
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
--INNER JOIN MS_PROD.dbo.dbUser BCM on BCM.usrID = dbFile.fileresponsibleID
INNER JOIN 
(
	SELECT 
		fed_code
		, hierarchylevel2
		, hierarchylevel3 AS [Practice Area]
		, hierarchylevel4 AS [Team]
		, worksforname AS usrFullName
		, worksforemail AS [usrEmail]
	FROM red_dw.dbo.dim_fed_hierarchy_history
		INNER JOIN red_dw.dbo.dim_employee
			ON  dim_employee.dim_employee_key = dim_fed_hierarchy_history.dim_employee_key
	WHERE 
		dss_current_flag='Y' 
		AND activeud=1 
) AS BCM on BCM.fed_code COLLATE DATABASE_DEFAULT = fee.usrAlias
WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))
AND (DATEDIFF(DAY,[post_date],GETDATE())) IN (1,21)
--AND (DATEDIFF(DAY,[post_date],GETDATE())) =21
--AND ((clno='882745' AND fileno='16')OR (clno='W16924' AND fileno='1'))
--AND dbFile.fileID IN (5019495,5071100)
	

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
	,[MS Client] AS MSClient
	,[MS Matter] AS MSMatter
		FROM #ClientBalances
WHERE [SinceUpdate]   IN (1,21)
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
	@BCMEmailAddress,
	@MSClient,
	@MSMatter
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
				+'[MS CLIENT:'+@MSClient+'],'
				+'[MS MATTER:'+@MSMatter+'],'
				+'[CLIENT BALANCE: £'+CAST(@ClientBalance AS VARCHAR)+']'

--SET @vSubject = '**TEST ALERT** '+@vSubject


SET @vBody = '<font size="2" face= "Lucida Sans Unicode">'
+'Case Handler:'+ @FeeEarnerCode
+'<p>'
--+'Please consider immediately whether we have the client''s express instructions to retain this money any longer.<br>'
--+'If we do not, please return it with appropriate interest straightaway.'+'<br>'

IF @SinceUpdate =1
BEGIN


SET @vBody ='<font size="2" face= "Lucida Sans Unicode"><b>1 day notification</b> of a positive client balance<html><body>'    

SET @vBody = @vBody + '<p><p><p><p><p>1	If you are required to <b>hold funds for a specific reason</b>, please reply to this email explaining why and update the Client Balance Review screen - in Mattersphere/Navigation pane/Compliance. You will receive an automated alert at 21 days which you can ignore.'
SET @vBody = @vBody + '<p>2	Otherwise the Solicitors Accounts Rules 25 November 2019 say that you must: "ensure that client money is returned promptly to the client, or the third party for whom the money is held, as soon as there is no longer any proper reason to hold those funds".'
SET @vBody = @vBody + '<p>3 If the balance is for <b>payment of an invoice</b>, please email a transfer to Legal Cashier.'
SET @vBody = @vBody + '<p>4 If the balance is an <b>overpayment</b>, please refund (preferably by bacs) within 14 days.'
SET @vBody = @vBody + '<p>5 If the balance relates to an <b>out of date cheque</b>, please make telephone or e-mail enquiries as to why cheque has not been presented and obtain bank details to return by bacs. If cheque is under &pound;10 please email Tracy Doyle to transfer to charity.'
SET @vBody = @vBody + '<p>6 If the balance is under &pound;10.00 to <b>Zurich</b>, <b>MIB</b>, <b>AIG</b> or <b>BDW</b>, please email Tracy Doyle who will transfer to small balance account for these clients.'
SET @vBody = @vBody + '<p>If your Day 1 alert relates to a cheque receipt, you will not be able to request payment out until this has cleared (7 days from receipt of cheque). You can check clear date in 3E by clicking on the amount of the client balance and scrolling across to Clear Date.'
SET @vBody = @vBody + '<p>If you are receiving alerts and are no longer the Case Manager or Team Manager, please amend personnel in Mattersphere to ensure alerts are emailed to the correct recipient.<p>If you have any queries, contact Tracy Doyle, Risk & Compliance.'
END


IF @SinceUpdate =21
BEGIN


SET @vBody ='<font size="2" face= "Lucida Sans Unicode"><b>21 day notification</b> of a positive client balance<html><body>'    
SET @vBody = @vBody + '<p><b>IF THE FUNDS ARE PROPERLY HELD AND YOU RESPONDED TO DAY 1 ALERT - IGNORE THIS EMAIL</b>'
SET @vBody = @vBody + '<p><p>1 If you are required to <b>hold funds for a specific reason</b>, please reply to this email explaining why and update the Client Balance Review screen - in Mattersphere/Navigation pane/Compliance.'
SET @vBody = @vBody + '<p>2 Otherwise under the Solicitors Accounts Rules 25 November 2019 you must: <i>"ensure that client money is returned promptly to the <u>client</u>, or the third party for whom the money is held, as soon as there is no longer any proper reason to hold those funds"</i>.'
SET @vBody = @vBody + '<p>3 If the balance is for <b>payment of an invoice</b>, please email a transfer to Legal Cashier.'
SET @vBody = @vBody + '<p>4 If the balance is an <b>overpayment</b>, please refund (preferably by bacs) immediately. '
SET @vBody = @vBody + '<p>5 If the balance relates to an <b>out of date cheque</b>, please make telephone or e-mail enquiries as to why cheque has not been presented and obtain bank details to return by bacs. If cheque is under &pound;10.00 please email Tracy Doyle to transfer to charity.'
SET @vBody = @vBody + '<p>6 If the balance is under &pound;10.00 to <b>Zurich</b>, <b>MIB</b>, <b>AIG</b> or <b>BDW</b>, please email Tracy Doyle who will transfer to small balance account for these clients.'
SET @vBody = @vBody + '<p>Spreadsheet of balances will be sent monthly to Team Manager, HSD and Director.'
SET @vBody = @vBody + '<p>If you have any queries, contact Tracy Doyle, Risk & Compliance.'
END 
		

		
SET @vBody = @vBody +'<br>'
+'<p>'+
'Client: '+ @Client+'<br>'+
'Matter: '+ @Matter+'<br>'+
'MS Client: '+ @MSClient+'<br>'+
'MS Matter: '+ @MSMatter+'<br>'+
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

	IF  @SinceUpdate = 21
		BEGIN --main email to BCM, cc'd to Sue, and FEE EARNER
		--SET @vRecipients = @BCMEmailAddress
		SET @vRecipients = @UserEmailAddress
		--SET @cc = 'sue.cartwright@Weightmans.com;kevin.hansen@weightmans.com;clientcompliance@weightmans.com'
		SET @cc = (CASE WHEN @test=1 THEN @TestCC ELSE 'clientcompliance@weightmans.com' END)
		--SET @cc = @UserEmailAddress +';'+@cc
		SET @cc = @BCMEmailAddress +';'+@cc
		--SET @cc = @vTestEmail+';'+@vTestEmail

		END


IF @SinceUpdate = 1
BEGIN

SET @cc = null

END 
PRINT @cc			
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
	@BCMEmailAddress,
	@MSClient,
	@MSMatter
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

	@recipients= 'kevin.hansen@weightmans.com',  --@vTestEmail,
	@subject= @vSubject,
	@body=@log,
	@importance = @vImportance,
	@body_format = 'HTML'
	



SET NOCOUNT OFF
GO
