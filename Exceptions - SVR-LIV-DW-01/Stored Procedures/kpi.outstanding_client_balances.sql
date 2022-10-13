SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO









--SELECT * FROM red_dw.dbo.dim_fed_hierarchy_history WHERE name LIKE 'Adrian%'


/*
	Author:  Lucy Dickinson
	Date:	12/02/2018
	Description:  Webby 292745
	Used Kevins audit.ClientBalanceAlert as a template but this was 
	slightly different as I needed to include the hierarchy in the parameters

*/
CREATE PROCEDURE [kpi].[outstanding_client_balances]
	@FedCodes VARCHAR(MAX)
	,@Level VARCHAR(100)

AS

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

-- For testing purposes
	--DECLARE @FedCodes VARCHAR(max)= '31290,31403,34526,34552,36587,37342,41913,66277,126751,126781,126784,126788,126791,126793,126795,126798,126801,126803,126806,126807,126813,126816,126817'
	--DECLARE @Level VARCHAR(100) = 'Area Managed'
	


	--DECLARE @ListOfFedCodes TABLE
	--(FedCode VARCHAR(max) NOT NULL)

	--INSERT INTO @ListOfFedCodes
	--        ( FedCode )
	

	--SELECT distinct val FROM [dbo].[split_delimited_to_rows] (@FedCodes,',')
	IF OBJECT_ID('tempdb..#FedCodeList') IS NOT NULL   DROP TABLE #FedCodeList

	CREATE TABLE #FedCodeList  (
	ListValue  NVARCHAR(MAX)
	)
	IF @Level  <> 'Individual'
		BEGIN
		PRINT ('not Individual')
	DECLARE @sql NVARCHAR(MAX)

	SET @sql = '
		use red_dw;
		DECLARE @nDate AS DATE = GETDATE()
	
		SELECT DISTINCT
			dim_fed_hierarchy_history_key
		FROM red_Dw.dbo.dim_fed_hierarchy_history 
		WHERE dim_fed_hierarchy_history_key IN ('+@FedCodes+')'


	INSERT INTO #FedCodeList 
	EXEC sp_executesql @sql
		END
	
	
		IF  @Level  = 'Individual'
		BEGIN
		PRINT ('Individual')
		INSERT INTO #FedCodeList 
		SELECT ListValue
		FROM dbo.udt_TallySplit(',', @FedCodes)
	
		END



	--SELECT * FROM @ListOfFedCodes

IF @Level <> 'Firm'
BEGIN
SELECT
[client_code_MS]		= clNo 
,[client_matter_MS]		= fileNo 
,[client_code_FED]		= CASE WHEN udExtFile.FEDCode IS NULL THEN (CASE WHEN ISNUMERIC(dbClient.clno)=1 THEN  RIGHT('00000000' + CONVERT(VARCHAR,dbClient.clno), 8) ELSE CAST(RTRIM(dbClient.clNo)  AS VARCHAR(8)) END) ELSE (CAST(SUBSTRING(RTRIM(udExtFile.FEDCode), 1, CASE WHEN CHARINDEX('-', RTRIM(udExtFile.FEDCode)) > 0 THEN CHARINDEX('-', RTRIM(udExtFile.FEDCode))-1
							ELSE LEN(RTRIM(udExtFile.FEDCode)) END) AS CHAR(8))) END  
,[matter_number_FED]	= CASE WHEN udExtFile.FEDCode IS NULL THEN RIGHT('00000000' + CONVERT(VARCHAR,dbFile.fileno), 8) ELSE CAST(RIGHT(RTRIM(udExtFile.FEDCode),LEN(RTRIM(udExtFile.FEDCode))-CHARINDEX('-',RTRIM(udExtFile.FEDCode)))AS CHAR(8)) END 
,[client_name]			= dbClient.clName 
,[matter_description]	= fileDesc 
,[client_balance]		= ClientBalance
,[last_financial_date]	= [post_date] 
,[days_since_update]	= DATEDIFF(DAY,[post_date],GETDATE()) 
--,[status]				= CASE WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 0 AND 13 THEN 'Lime'
--							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 14  AND 27 THEN 'Orange'
--							WHEN DATEDIFF(d,[post_date], GETDATE()) >= 28 THEN 'Red'
--							WHEN [post_date] IS NULL THEN 'White'
--							END 
,[status]				= CASE WHEN cboCliBalance='BREACH' THEN 'Red'
							WHEN cboCliBalance='NOACTION' THEN 'Lime'
							WHEN cboCliBalance = 'ACTION' THEN 'Orange'
							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 0 AND 14 THEN 'Lime'
							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 15  AND 27 THEN 'Orange'
							WHEN DATEDIFF(d,[post_date], GETDATE()) >= 28 THEN 'Red'
							WHEN [post_date] IS NULL THEN 'White'
							END  --changed per ticket 314191
							,[zero_balance]			= CASE WHEN ClientBalance=0 THEN 'Yes' ELSE 'No' END 
,[fee_earner_name]		= fee.usrFullName + ' (' + fee.usrInits  + ')' 
,[user_email_address]	= fee.usrEmail 
,[department]			= [Practice Area] 
,[team]					= Team	
,[division]				= Teams.hierarchylevel2
,[matt_index]			= MattIndex
,[manager_name]			= BCM.usrFullName + ' (' + BCM.usrInits  + ')'
,[manager_email]		= BCM.usrEmail 				
,[fee_earner]			= fee.usrInits	
-- below added per Ticket 296230 
,CASE WHEN cboCliBalance='BREACH' THEN 'Breach' 
WHEN cboCliBalance='NOACTION' THEN 'No Action Required'   
WHEN cboCliBalance='ACTION' THEN 'Action Required' End cboCliBalance
,txtCommentCli	 txtCommentsCli
,dteLastReview
,ISNULL(FileReferences.insurerclient_reference,FileReferences.client_reference)	AS insurerclient_reference	
				
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
		,LAG(ZeroBalance, 1,0) OVER (PARTITION BY MattIndex ORDER BY [post_date])  AS PositiveBalance
		FROM 
		(

		SELECT      MattIndex AS MattIndex
					,tb.amount AS ClientBalance
					,COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) [post_date]
					,SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING) AS running_sales_amount   
					,CASE WHEN (SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING))=0 THEN 1 ELSE 0 END AS ZeroBalance
			
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
	INNER JOIN MS_Prod.config.dbFile	ON AllClientBalances.MattIndex=dbFile.fileExtLinkID
	INNER JOIN MS_Prod.config.dbClient	ON dbFile.clID=dbClient.clID
	INNER JOIN MS_PROD.dbo.udExtFile	ON dbFile.fileID=udExtFile.fileID
	INNER JOIN MS_PROD.dbo.dbUser fee	ON fee.usrID = dbFile.filePrincipleID
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_history ON fee.usrInits = dim_fed_hierarchy_history.fed_code COLLATE DATABASE_DEFAULT
	AND dss_current_flag='Y'
	INNER JOIN #FedCodeList filter ON  dim_fed_hierarchy_history.dim_fed_hierarchy_history_key = filter.ListValue
	INNER JOIN MS_PROD.dbo.dbUser BCM ON BCM.usrID = dbFile.fileresponsibleID
	LEFT OUTER JOIN (SELECT fed_code
							,hierarchylevel2,hierarchylevel3 AS [Practice Area]
							,hierarchylevel4 AS [Team]
						FROM red_dw.dbo.dim_fed_hierarchy_current
						WHERE dss_current_flag='Y') AS Teams
	 ON fee.usrInits=Teams.fed_code COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN (
	SELECT ms_fileid,insuredclient_reference,ISNULL(insurerclient_reference,insuredclient_reference) AS insurerclient_reference,client_reference FROM red_dw.dbo.dim_client_involvement
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_client_involvement.client_code
 AND dim_matter_header_current.matter_number = dim_client_involvement.matter_number) AS FileReferences
  ON dbFile.fileID=FileReferences.ms_fileid
	WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))
	AND Teams.hierarchylevel2 IN ('Legal Ops - Claims','Legal Ops - LTA')
		AND Teams.fed_code NOT IN ('5182','5214','5246','6023','6102','6302','6437'
,'1610','1809','5594','5820','5848','6138','4611') -- Exclude Com Rec users requested by James Holman 16.09.20

END
ELSE
BEGIN
SELECT DISTINCT
[client_code_MS]		= clNo 
,[client_matter_MS]		= fileNo 
,[client_code_FED]		= CASE WHEN udExtFile.FEDCode IS NULL THEN (CASE WHEN ISNUMERIC(dbClient.clno)=1 THEN  RIGHT('00000000' + CONVERT(VARCHAR,dbClient.clno), 8) ELSE CAST(RTRIM(dbClient.clNo)  AS VARCHAR(8)) END) ELSE (CAST(SUBSTRING(RTRIM(udExtFile.FEDCode), 1, CASE WHEN CHARINDEX('-', RTRIM(udExtFile.FEDCode)) > 0 THEN CHARINDEX('-', RTRIM(udExtFile.FEDCode))-1
							ELSE LEN(RTRIM(udExtFile.FEDCode)) END) AS CHAR(8))) END  
,[matter_number_FED]	= CASE WHEN udExtFile.FEDCode IS NULL THEN RIGHT('00000000' + CONVERT(VARCHAR,dbFile.fileno), 8) ELSE CAST(RIGHT(RTRIM(udExtFile.FEDCode),LEN(RTRIM(udExtFile.FEDCode))-CHARINDEX('-',RTRIM(udExtFile.FEDCode)))AS CHAR(8)) END 
,[client_name]			= dbClient.clName 
,[matter_description]	= fileDesc 
,[client_balance]		= ClientBalance
,[last_financial_date]	= [post_date] 
,[days_since_update]	= DATEDIFF(DAY,[post_date],GETDATE()) 
--,[status]				= CASE WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 0 AND 13 THEN 'Lime'
--							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 14  AND 27 THEN 'Orange'
--							WHEN DATEDIFF(d,[post_date], GETDATE()) >= 28 THEN 'Red'
--							WHEN [post_date] IS NULL THEN 'White'
--							END 
,[status]				= CASE WHEN cboCliBalance='BREACH' THEN 'Red'
							WHEN cboCliBalance='NOACTION' THEN 'Lime'
							WHEN cboCliBalance = 'ACTION' THEN 'Orange'
							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 0 AND 14 THEN 'Lime'
							WHEN DATEDIFF(d, [post_date], GETDATE()) BETWEEN 15  AND 27 THEN 'Orange'
							WHEN DATEDIFF(d,[post_date], GETDATE()) >= 28 THEN 'Red'
							WHEN [post_date] IS NULL THEN 'White'
							END  --changed per ticket 314191
							 							
							
,[zero_balance]			= CASE WHEN ClientBalance=0 THEN 'Yes' ELSE 'No' END 
,[fee_earner_name]		= fee.usrFullName + ' (' + fee.usrInits  + ')' 
,[user_email_address]	= fee.usrEmail 
,[department]			= [Practice Area] 
,[team]					= Team	
,[division]				= hierarchylevel2
,[matt_index]			= MattIndex
,[manager_name]			= BCM.usrFullName + ' (' + BCM.usrInits  + ')'
,[manager_email]		= BCM.usrEmail 				
,[fee_earner]			= fee.usrInits	
-- below added per Ticket 296230 
,CASE WHEN cboCliBalance='BREACH' THEN 'Potential Breach' 
WHEN cboCliBalance='NOACTION' THEN 'No Action Required'   
WHEN cboCliBalance='ACTION' THEN 'Action Required' END cboCliBalance
,txtCommentCli	txtCommentsCli
,dteLastReview	
--,FileReferences.insuredclient_reference
,ISNULL(FileReferences.insurerclient_reference,FileReferences.client_reference)	AS insurerclient_reference
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
		,LAG(ZeroBalance, 1,0) OVER (PARTITION BY MattIndex ORDER BY [post_date])  AS PositiveBalance
		FROM 
		(

		SELECT      MattIndex AS MattIndex
					,tb.amount AS ClientBalance
					,COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) [post_date]
					,SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING) AS running_sales_amount   
					,CASE WHEN (SUM(tb.amount) OVER (PARTITION BY MattIndex ORDER BY (COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate)) ROWS UNBOUNDED PRECEDING))=0 THEN 1 ELSE 0 END AS ZeroBalance
			
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
	INNER JOIN MS_Prod.config.dbFile	ON AllClientBalances.MattIndex=dbFile.fileExtLinkID
	INNER JOIN MS_Prod.config.dbClient	ON dbFile.clID=dbClient.clID
	INNER JOIN MS_PROD.dbo.udExtFile	ON dbFile.fileID=udExtFile.fileID
	INNER JOIN MS_PROD.dbo.dbUser fee	ON fee.usrID = dbFile.filePrincipleID
	INNER JOIN MS_PROD.dbo.dbUser BCM ON BCM.usrID = dbFile.fileresponsibleID
	LEFT OUTER JOIN (SELECT fed_code,hierarchylevel2,hierarchylevel3 AS [Practice Area]
	,hierarchylevel4 AS [Team]
	FROM red_dw.dbo.dim_fed_hierarchy_current
	WHERE dss_current_flag='Y') AS Teams
	 ON fee.usrInits=fed_code COLLATE DATABASE_DEFAULT
	LEFT OUTER JOIN (
	SELECT ms_fileid,insuredclient_reference,ISNULL(insurerclient_reference,insuredclient_reference) AS insurerclient_reference,client_reference FROM red_dw.dbo.dim_client_involvement
INNER JOIN red_dw.dbo.dim_matter_header_current
 ON dim_matter_header_current.client_code = dim_client_involvement.client_code
 AND dim_matter_header_current.matter_number = dim_client_involvement.matter_number) AS FileReferences
  ON dbFile.fileID=FileReferences.ms_fileid
	WHERE (ClientBalance <> 0 OR (ClientBalance=0 AND CONVERT(DATE,[post_date],103)=CONVERT(DATE,GETDATE(),103)))
	AND Teams.hierarchylevel2 IN ('Legal Ops - Claims','Legal Ops - LTA')
		AND Teams.fed_code NOT IN ('5182','5214','5246','6023','6102','6302','6437'
,'1610','1809','5594','5820','5848','6138') -- Exclude Com Rec users requested by James Holman 16.09.20

END








GO
