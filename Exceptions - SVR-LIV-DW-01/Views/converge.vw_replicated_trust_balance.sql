SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










/*
-- LD 20160809 Created this to replace dim and fact tables in the interim
-- LD 20160908 Amended gl_date to use the new sequence of gl_dates

Version History
********************
Version		Date		Detail
1.1			2016-08-24	I have added in a number of additional fields required 
1.2			2016-09-16	Added isdeposit
1.3			2016-12-19 Added a few more fields
*/

CREATE VIEW [converge].[vw_replicated_trust_balance] 
AS
SELECT			
				'3e' + CAST(tb.TrustBalanceIndex AS VARCHAR(20)) [sequence_number]
				,tb.TrustTransferDetail
				
				,TrustTransfer
				,tb.TrustDisbursement
				,tb.TrustAdjustment
				,tb.TrustReceiptDetail
				,matter.AltNumber [client_matter_number]
				,ISNULL(matter.LoadNumber,matter.AltNumber) [legacy_client_matter_number]
				,client.AltNumber [client]
				,tb.TrustBalanceIndex
				,ISNULL(RIGHT(RTRIM(matter.LoadNumber),8),RIGHT(RTRIM(matter.AltNumber),8)) [matter] 
				,CASE WHEN tb.[postsource] = 'TRSTDISB' THEN 'PAYMENT'
					 WHEN tb.[postsource] = 'TRSTRCPT' THEN 'RECEIPT'
					 WHEN tb.[postsource] = 'TRSTADJ' THEN 'ADJUSTMENT'
					 WHEN tb.[postsource] = 'TRSTTRSF' THEN 'TRANSFER'
				 END transaction_type_group
				,bank.BankAcctIndex
                ,bank.Name [bank_account_name]
                ,bank.[Description] [bank_description]
				,bank.AcctNum [bank_account_number]
				,tb.amount [amount]
			   	,COALESCE(disb.conversionrefnum,receipt.conversionrefnum,adjustment.conversionrefnum,transfers.authorizedby) [legacy_sequence_number]
                ,COALESCE(tc.PayeeName,receipt.drawnby,'') [payee_name]
				,REPLACE(REPLACE(REPLACE(COALESCE(disb.comment,receipt.narrative,adjustment.comment,transfers.narrative),CHAR(9),' '),CHAR(10),' '),CHAR(13),' ') [narrative]
				,REPLACE(REPLACE(REPLACE(COALESCE(disb.comment,receipt.Narrative_UnformattedText,adjustment.comment,transfers.Narrative_UnformattedText),CHAR(9),' '),CHAR(10),' '),CHAR(13),' ') [narrativeunformated]
                ,COALESCE(disb.trustdisbursementtype,receipt.trustreceipttype,adjustment.trustadjtype,transfers.trusttransfertype) [trust_transaction_type]
                ,COALESCE(tdt.[description],receipttype.[description],adjustmenttype.[description],transfertype.[description]) [transaction_type_description]
                ,COALESCE(disb.postdate,receipt.postdate,adjustment.postdate,transfers.postdate) [post_date]
                ,COALESCE(tc.GLDate,adjustment.gldate,transfers.gldate,receipt.gldate,disb.gldate,tb.GLDate) [gl_date]
				,COALESCE(disb.trandate,receipt.trandate,adjustment.trandate,transfers.trandate) [tran_date]
                ,COALESCE(tc.ReconStatusList,receipt.reconstatuslist,adjustment.reconstatuslist,transfers.reconstatuslist,disb.ReconStatusList) [recon_status]
				,COALESCE(tc.CkNum,receipt.documentnumber,adjustment.documentnumber,transfers.documentnumber) [reference_number]
				,tb.[postsource]
				,tc.GLDate AS TrustCheck_GLDate
				,tc.amount AS TrustCheckAmount
				,adjustment.GLDate AS TrustAdjustment_GLDate
				,adjustment.Amount AS AdjustmentAmount
				,transfers.GLDate AS TrustTransfers_GLDate
				,transfers.amount AS TransfersAmount
				,Receipt.GLDate AS TrustReceipt_GLDate
				,receipt.Amount AS ReceiptAmount
				,disb.GLDate AS TrustDisb_GLDate
				,disb.Amount AS DisbAmount
				,tb.GLDate AS TrustBalance_GLDate /*1.1JL*/
				,IsDeposit -- used for filtering transfers ... I think 1.2LD
				,COALESCE(adjustment.IsReversed,transfers.IsReversed,receipt.IsReversed,disb.IsReversed) IsReversed 
				,transferdetail.CashJournal [transfer_detail_cash_journal]
				,tc.CkNum [payment_cheque_number]
				,receipt.DocumentNumber [receipt_document_number]
				,adjustment.DocumentNumber [adjustment_document_number]
				,adjustment.DepositNumber [adjustment_deposit_number]
				,transfers.DocumentNumber [transfers_document_number]
				,transferdetail.IsSource
				,disb.TrustCheck
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
	--WHERE tb.BankAcctTrust = 41



GO
