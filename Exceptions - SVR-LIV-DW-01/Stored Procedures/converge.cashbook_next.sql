SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO










--SELECT * FROM axxia01.dbo.casdet (NOLOCK) WHERE case_text = '517.23'
--EXEC [veolia].[MasterCashbook-SDVERSION4] 'Veolia ES', '2013-10-31'
--  EXEC veolia.CashbookReport_DV '2009-01-01', '2013-12-01', 'Veolia ES'
-- ===========================================
-- LD 20150211 Added Codeve as a client option
-- LD 20150319 LD Added Payment Notes1 and Payment Type (specific request for Codeve) as per Sam Ellertons Request
-- LD 20150729 LD Moved all the bankcode bits into a table Converge.CashbookBankCodes ... primarily to make modelling easier but also so that we can expose these in a report
-- LD 20150819 LD Added an additional Fees column so that payments can be separated into Fees or Indemnity
--					Thought about getting rid of the _DV extension but the CashbookReport stored procedure is used in the Veolia Account Reconcilliation Report

-- LD 20160519 Created new version using the DWH FactTrustBalance ... currently in testing
--============================================


CREATE PROCEDURE [converge].[cashbook_next]
(
    @EndDate AS DATETIME
  
)
AS 
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	---- For testing purposes
--	DECLARE @EndDate datetime = '20160927'
        
	 
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#NextCashbook')) 
				DROP TABLE #NextCashbook



	SELECT	
			client_matter_number
			,legacy_client_matter_number
			
			,client
			,matter
			,transaction_type_group
			,BankAcctIndex
			,bank_account_name
			,bank_description
			,bank_account_number
			,amount
			,ISNULL(legacy_sequence_number,cast (sequence_number AS VARCHAR(30))) sequence_number
			--,sequence_number
			,ISNULL(payee_name,narrative) narrative
			--,narrative
			,trust_transaction_type
			,transaction_type_description
			,post_date
			,gl_date
			,tran_date
			,recon_status
			,reference_number
			,postsource
			
	

  INTO #NextCashbook				
  FROM [Reporting].[converge].[vw_replicated_trust_balance] tb
     
  WHERE  tb.bank_account_name = '0222'
  --AND trust_transaction_type <> 'Gen'
  AND tb.post_date BETWEEN '20090501' AND @EndDate


 
  order by tb.post_date

  

    SELECT  DISTINCT
			cashdr.[client] AS Client,
            cashdr.[matter] AS Matter,
            ISNULL(cafintrn.reference_number,cafintrn.sequence_number) AS TransactionNumber,
            [narrative] AS TransactionDescription,
            [trust_transaction_type] AS TransactionType,
            [transaction_type_description] AS TransactionTypeDescription,
            [tran_date] AS TransactionDate,
            [post_date] AS PostingDate,
            [gl_date] AS SystemDate,
            cafintrn.bank_account_name AS [BankCode],
            payments.PaymentNumber,
            Recoveries.RecoveryNumber,
            cafintrn.sequence_number AS [ArtiionSequenceNumber],
            --ISNULL((CASE WHEN trust_transaction_type IN ( 'INT', 'CLCTR', 'CLCDC', 'CLRTC', 'CLTOC','Gen' )
            --     THEN amount
            --     ELSE amount * -1
            --END),0) AS ChequeAmount,
			 amount [ChequeAmount],
            ISNULL((CASE WHEN COALESCE(payments.PaymentNumber, Recoveries.RecoveryNumber, '0') <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL
						 WHEN PaymentGross IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC') THEN PaymentGross
				  WHEN RecoveryAmount IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLRTC','CHQ' ) THEN RecoveryAmount
				  WHEN cafintrn.trust_transaction_type IN ( 'INT', 'CLCTR', 'CLCDC', 'CLRTC' ) THEN cafintrn.amount 
				  ELSE cafintrn.amount * -1
			 END),0) AS PaymentGross,
            ISNULL((CASE WHEN COALESCE(payments.PaymentNumber , Recoveries.RecoveryNumber, '0') <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL
				  WHEN PaymentNet IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC') THEN PaymentNet
				  WHEN RecoveryAmount IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLRTC','CHQ'  ) THEN RecoveryAmount
				  ELSE NULL
			 END),0) AS PaymentNet,
            ISNULL((CASE WHEN ISNULL(payments.PaymentNumber, 0) <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL ELSE PaymentVAT END),0) AS PaymentVAT,
            ISNULL(RecoveryAmount,0) RecoveryAmount,
            payments.PaymentToWhom,
            payments.InvoiceNumber,
            Recoveries.RecoveryFromWhom,
            VE00038.case_date AS IncidentDate,
            stdetlst.sd_listxt AS PolicyType,
           

		   CASE 
				 WHEN trust_transaction_type IN ('CLCTR','GEN','EFT') THEN 'TRANSFER' -- client transfer
				 WHEN trust_transaction_type = 'INT' OR RTRIM(reference_number) IN ('INTEREST', 'INT') THEN 'INTEREST'
                 WHEN trust_transaction_type IN ('CLRTC','CHQ') THEN 'RECOVERY'  -- receipt to client
                 WHEN trust_transaction_type = 'CLCDC' AND cafintrn.[matter] NOT IN ('00000001','00009999')   THEN 'RECOVERY' -- DV 20130621 - fix for a recovery marked as a topup
                 WHEN trust_transaction_type IN ('CASH', 'CLCDC') THEN 'TOPUP' -- Direct credit client account
				 WHEN cafintrn.recon_status <> 'R' THEN 'UNPRESENTED'
				 WHEN trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC' ) THEN 'PAYMENT' --Client payment from client, returned cheque client account
                 

				
                 ELSE RTRIM(UPPER(transaction_type_description))
				END AS AmountType,

			CASE WHEN [transaction_type_group] = 'TRSTDISB' THEN 'DISBURSEMENT'
				 WHEN [transaction_type_group] = 'TRSTRCPT' THEN 'RECEIPT'
				 WHEN [transaction_type_group] = 'TRSTADJ' THEN 'ADJUSTMENT'
				 WHEN [transaction_type_group] = 'TRSTTRSF' THEN 'TRANSFER'
				 END transaction_type_group,

            cafintrn.reference_number,
			
			ISNULL(PaymentNotes1,RecoveryNote1) [PaymentNotes1],
			ISNULL(PaymentType,RecoveryType) [PaymentType],
			CASE WHEN PaymentType IS NULL THEN 3
				 WHEN PaymentType LIKE '%insurer paid%' AND PaymentType NOT LIKE '%TP%' THEN 1 
				 ELSE 0 END [Fees]
			
    FROM    #NextCashbook AS cafintrn WITH ( NOLOCK )
		    LEFT OUTER JOIN axxia01.dbo.cashdr AS cashdr WITH  ( NOLOCK ) ON cafintrn.client = cashdr.client  COLLATE DATABASE_DEFAULT AND cafintrn.matter = cashdr.matter  COLLATE DATABASE_DEFAULT 
            LEFT OUTER JOIN axxia01.dbo.casdet AS VE00038 WITH ( NOLOCK ) ON cashdr.case_id = VE00038.case_id AND VE00038.case_detail_code = 'VE00038'
            LEFT OUTER JOIN axxia01.dbo.casdet AS VE00002 WITH ( NOLOCK ) ON cashdr.case_id = VE00002.case_id AND VE00002.case_detail_code = 'VE00002'
            LEFT OUTER JOIN axxia01.dbo.stdetlst AS stdetlst WITH ( NOLOCK ) ON VE00002.case_text = stdetlst.sd_liscod AND sd_detcod = 'VE00002'
		    LEFT OUTER JOIN ( SELECT    VE00156.case_id,
                                        VE00156.seq_no AS SequenceNumber,
                                        VE00156.case_date AS paymentdate,
										VE00156_Desc.sd_listxt  AS PaymentType,
                                        VE00327.case_text AS PaymentNumber,
                                        VE00139.case_text AS PaymentToWhom,
                                        VE00144.case_text AS InvoiceNumber,
                                        --Added to ensure PFC are debits and RTC etc are credits
                                        VE00158.case_value * -1 AS PaymentNet,
                                        VE00159.case_value * -1 AS PaymentVAT,
                                        VE00160.case_value * -1 AS PaymentGross,
										VE00145.case_text AS PaymentNotes1
                              FROM      ( SELECT    case_id,
                                                    seq_no,
                                                    case_date,
                                                    case_text
                                          FROM      axxia01.dbo.casdet AS casdet
                                                    WITH ( NOLOCK )
                                          WHERE     case_detail_code = 'VE00156'
                                        ) AS VE00156 --Payment transaction Number
                                        INNER JOIN axxia01.dbo.casdet AS VE00327
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00327.case_id
                                                           AND VE00327.cd_parent = VE00156.seq_no
                                                           AND VE00327.case_detail_code = 'VE00327'
                                                           AND VE00327.case_text NOT LIKE '%.%'
                                                           --Payment Net
                                        INNER JOIN axxia01.dbo.casdet AS VE00158
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00158.case_id
                                                           AND VE00158.cd_parent = VE00156.seq_no
                                                           AND VE00158.case_detail_code = 'VE00158'
                                                           --Payment VAT
                                        INNER JOIN axxia01.dbo.casdet AS VE00159
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00159.case_id
                                                           AND VE00159.cd_parent = VE00156.seq_no
                                                           AND VE00159.case_detail_code = 'VE00159'
										--Payment Gross
                                        INNER JOIN axxia01.dbo.casdet AS VE00160
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00160.case_id
                                                           AND VE00160.cd_parent = VE00156.seq_no
                                                           AND VE00160.case_detail_code = 'VE00160'
										--Payment To Whom
                                        LEFT JOIN axxia01.dbo.casdet AS VE00139
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00139.case_id
                                                           AND VE00139.cd_parent = VE00156.seq_no
                                                           AND VE00139.case_detail_code = 'VE00139'
                                        --Invoice Payment Number 
                                        LEFT JOIN axxia01.dbo.casdet AS VE00144
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00144.case_id
                                                           AND VE00144.cd_parent = VE00156.seq_no
                                                           AND VE00144.case_detail_code = 'VE00144'
										--Payment: Notes (1)                                          
                                        LEFT JOIN axxia01.dbo.casdet AS VE00145
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00145.case_id
                                                           AND VE00145.cd_parent = VE00156.seq_no
                                                           AND VE00145.case_detail_code = 'VE00145'
										-- Payment:  Type description
										LEFT JOIN axxia01.dbo.stdetlst AS VE00156_Desc 
													ON VE00156.case_text = VE00156_Desc.sd_liscod 
													AND VE00156_Desc.sd_detcod = 'VE00156'

	
							--WHERE ISNUMERIC(VE00327.case_text) = 1
                            ) AS payments ON payments.case_id = cashdr.case_id
                                             AND cafintrn.sequence_number  = payments.PaymentNumber COLLATE DATABASE_DEFAULT 
											 --AND cafintrn.amount = (payments.PaymentGross * -1)
            LEFT OUTER JOIN ( SELECT    VE00167.case_id,
                                        VE00167.seq_no AS SequenceNumber,
                                        VE00167.case_date AS paymentdate,
                                        VE00328.case_text AS RecoveryNumber,
                                        VE00130.case_value AS RecoveryAmount,
                                        VE00134.case_text AS RecoveryFromWhom,
										VE00135.case_text AS RecoveryNote1,
										VE00167_Desc.sd_listxt  AS RecoveryType

                              FROM      ( SELECT    case_id,
                                                    seq_no,
                                                    case_date,
                                                    case_text
                                          FROM      axxia01.dbo.casdet AS casdet
                                                    WITH ( NOLOCK )
                                          WHERE     case_detail_code = 'VE00167'
                                        ) AS VE00167 --Recovery Transaction Number
                                        INNER JOIN axxia01.dbo.casdet AS VE00328
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00328.case_id
                                                           AND VE00328.cd_parent = VE00167.seq_no
                                                           AND VE00328.case_detail_code = 'VE00328'
                                                           AND VE00328.case_text NOT LIKE '%.%'
                                        --Recovery Amount
                                        INNER JOIN axxia01.dbo.casdet AS VE00130
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00130.case_id
                                                           AND VE00130.cd_parent = VE00167.seq_no
                                                           AND VE00130.case_detail_code = 'VE00130'
                                        --Recovery From Whom
                                        LEFT JOIN axxia01.dbo.casdet AS VE00134
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00134.case_id
                                                           AND VE00134.cd_parent = VE00167.seq_no
                                                           AND VE00134.case_detail_code = 'VE00134'
										--Recovery note 1
										LEFT JOIN axxia01.dbo.casdet AS VE00135
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00135.case_id
                                                           AND VE00135.cd_parent = VE00167.seq_no
                                                           AND VE00135.case_detail_code = 'VE00135'
											-- Payment:  Type description
										LEFT JOIN axxia01.dbo.stdetlst AS VE00167_Desc 
													ON VE00167.case_text = VE00167_Desc.sd_liscod 
													AND VE00167_Desc.sd_detcod = 'VE00167'


                              --WHERE ISNUMERIC(VE00328.case_text) = 1
                            ) AS Recoveries ON cashdr.case_id = Recoveries.case_id
                                               AND cafintrn.sequence_number   = Recoveries.RecoveryNumber COLLATE DATABASE_DEFAULT 
                                               AND cafintrn.amount = 
                                               -- added by SD as CRC have gone in as recovery reversals
                                               CASE WHEN trust_transaction_type ='CLCRC' COLLATE DATABASE_DEFAULT THEN Recoveries.RecoveryAmount * -1 
																			ELSE Recoveries.RecoveryAmount END
    	
	ORDER BY cafintrn.post_date

















GO
