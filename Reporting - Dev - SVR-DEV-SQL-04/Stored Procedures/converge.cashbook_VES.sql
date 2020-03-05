SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO












/*=================================
-- Author:			Lucy Dickinson
-- Date:			20160818
-- Description:		Cashbook for VES --this is all transactions up to the month reporting
-- Current Version: 1.2
--=================================
   Version History
****************************************
	Version	 By	    Date		Detail
	1.1		 JL		25-09-2016  added in tran type of AUTHE as was missing
	1.2		 JL		02-09-2016  added in new GL date logic and amended the join to remove blank spaces as was causing inconsistencies
	1.3		 LD     19/09/2016	added additional fields and a case statement to identify the eft transactions that should be payments 
								amended the unpresented item logic 
	1.4		LD 20161024 Hard coding some exclusions because of an anomaly
	1.5		LD 20161026 RTRIM'd the sequence number because someone is entering spaces.
	1.6		LD 20170209 Excluding disbursements that do not have a TrustCheck as these haven't been processed through the nominal yet
	
****************************************
Testing 
exec [converge].[cashbook_VES] '20160805'	  
*/


CREATE PROCEDURE [converge].[cashbook_VES] 
(
    @EndDate AS DATETIME
)

AS 

--	DECLARE @EndDate DATETIME = '20160919'
    
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#FTBVESCashbook')) 
				DROP TABLE #FTBVESCashbook

------get list from bank account VES from 3E tables view (41)

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
			,ISNULL(legacy_sequence_number,CAST (sequence_number AS VARCHAR(30))) sequence_number
			,CASE WHEN payee_name = '' OR payee_name IS NULL  THEN narrative ELSE payee_name END narrative
			,CASE WHEN transaction_type_group = 'PAYMENT' AND narrative LIKE '[[]%'  THEN   SUBSTRING(narrative,2,CHARINDEX('] - ',narrative)-2) END AS seq_no
			,narrative [narrative2]
			,payee_name
			,trust_transaction_type
			,transaction_type_description
			,post_date
			,gl_date
			,tran_date
			,recon_status
			,reference_number
			,postsource
			,IsReversed		-- LD 1.3
			,IsDeposit		-- LD 1.3	
			,[payment_cheque_number]
			,[receipt_document_number]
			,[adjustment_document_number]
			,[adjustment_deposit_number]
			,[transfers_document_number]
			,transfer_detail_cash_journal

  INTO		#FTBVESCashbook			
  FROM		[Reporting].[converge].[vw_replicated_trust_balance] tb
  
  WHERE   BankAcctIndex IN (41)   
  AND	   gl_date <= @EndDate

   AND NOT (tb.TrustDisbursement IS NOT NULL AND tb.TrustCheck IS NULL)  -- LD 1.6


    --LD below are the strange transactions that are not in the gl

--  AND tb.sequence_number NOT IN (
-- '3e1103878','3e1103879','3e1103880','3e1103881',
--'3e1103882','3e1103883','3e1103884','3e1103885',
--'3e1103886','3e1103887','3e1103889','3e1103890',
--'3e1103891','3e1103892','3e1103893','3e1103894',
--'3e1103895','3e1103896','3e1103897','3e1103898',
--'3e1105164','3e1105165','3e1105166','3e1105167',
--'3e1105168','3e1105169','3e1105170','3e1105171',
--'3e1105172','3e1105173','3e1105174','3e1105175',
--'3e1105176','3e1105177','3e1105178','3e1105179',
--'3e1105180','3e1105181','3e1105182','3e1105183' )

  
  

  ------Now join this to FED to get the detail------------------------------------------------------
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
			amount [ChequeAmount],
            ISNULL((CASE WHEN COALESCE(payments.PaymentNumber, Recoveries.RecoveryNumber, '0') <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL
						 WHEN PaymentGross IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC','CHQ','AUTHE','AUTHET' ) THEN PaymentGross /*1.1 JL*/
						 WHEN PaymentGross IS NOT NULL AND trust_transaction_type = 'EFT' AND IsReversed = 0 AND IsDeposit = 0 THEN PaymentGross
						 WHEN RecoveryAmount IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLRTC','CHQ' ) THEN RecoveryAmount
						 WHEN cafintrn.trust_transaction_type IN ( 'INT', 'CLCTR', 'CLCDC', 'CLRTC','GEN','Gen' ) THEN cafintrn.amount 
						 ELSE cafintrn.amount * -1
						 END),0) AS PaymentGross,
            ISNULL((CASE WHEN COALESCE(payments.PaymentNumber , Recoveries.RecoveryNumber, '0') <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL
				        WHEN PaymentNet IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC','CHQ','AUTHE','AUTHET' ) THEN PaymentNet /*1.1 JL*/
						WHEN PaymentNet IS NOT NULL AND cafintrn.trust_transaction_type = 'EFT' AND IsReversed = 0 AND IsDeposit = 0 THEN PaymentNet
						WHEN RecoveryAmount IS NOT NULL AND cafintrn.trust_transaction_type IN ( 'CLRTC','CHQ' ) THEN RecoveryAmount
						ELSE NULL
						END),0) AS PaymentNet,
            ISNULL((CASE WHEN ISNULL(payments.PaymentNumber, 0) <> cafintrn.sequence_number COLLATE DATABASE_DEFAULT THEN NULL 
						ELSE PaymentVAT 
						END),0) AS PaymentVAT,
            ISNULL(RecoveryAmount,0) RecoveryAmount,
            payments.PaymentToWhom,
            payments.InvoiceNumber,
            Recoveries.RecoveryFromWhom,
            VE00038.case_date AS IncidentDate,
            stdetlst.sd_listxt AS PolicyType,
			
        ------JL - Please not that the "unpresented" status below is not correct it is missing alot of transactions so on the cashbook report they are showing as Payments. 
		------This needs to be looked into to change the logic below    
			CASE 
				 
				 WHEN sequence_number IN (				 
				 '7645034','7652950','7654985',
				'3e1079665','3e1088022','3e1096190','3e1101526',
				'3e1101635','3e1102390','3e1102372','3e1108290',
				'3e1110727','3e1110731','3e1110733','3e1110735',
				'3e1110757','3e1110758','3e1111668','3e1111948',
				'3e1117994','3e1118150','3e1120909'	 ) THEN 'QUERY'
				 WHEN IsReversed = 0 AND IsDeposit = 0 AND trust_transaction_type = 'EFT' THEN 'PAYMENT' -- LD 1.3
				 WHEN trust_transaction_type IN ('CLCTR','GEN','EFT') THEN 'TRANSFER' -- client transfer
				 WHEN trust_transaction_type = 'INT' OR RTRIM(reference_number) IN ('INTEREST', 'INT') THEN 'INTEREST'
                 WHEN trust_transaction_type IN ('CLRTC','CHQ') THEN 'RECOVERY'  -- receipt to client
                 WHEN trust_transaction_type = 'CLCDC' AND cafintrn.[matter] NOT IN ('00000001','00009999')   THEN 'RECOVERY' -- DV 20130621 - fix for a recovery marked as a topup
                 WHEN trust_transaction_type IN ( 'CLCDC','CASH') THEN 'TOPUP' -- Direct credit client account
				 WHEN cafintrn.recon_status <> 'R' THEN 'UNPRESENTED' --needs looking into - JL 02-09-2016 -- LD 1.3
				 WHEN trust_transaction_type IN ( 'CLPFC', 'CLCRC','AUTHC','AUTHE','AUTHET' ) THEN 'PAYMENT' /*1.1 JL*/--Client payment from client, returned cheque client account --JL
					ELSE RTRIM(UPPER(transaction_type_description))
						END AS AmountType,

			CASE WHEN [transaction_type_group] = 'TRSTDISB' THEN 'DISBURSEMENT'
				 WHEN [transaction_type_group] = 'TRSTRCPT' THEN 'RECEIPT'
				 WHEN [transaction_type_group] = 'TRSTADJ' THEN 'ADJUSTMENT'
				 WHEN [transaction_type_group] = 'TRSTTRSF' THEN 'TRANSFER'
				 END AS transaction_type_group,

            cafintrn.reference_number,
			ISNULL(PaymentNotes1,RecoveryNote1) [PaymentNotes1],
			ISNULL(PaymentType,RecoveryType) [PaymentType],
			CASE WHEN PaymentType IS NULL THEN 3
				 WHEN PaymentType LIKE '%insurer paid%' AND PaymentType NOT LIKE '%TP%' THEN 1 
				 ELSE 0 END AS [Fees]
		--,trust_transaction_type 
		--,cafintrn.legacy_client_matter_number	
    FROM    #FTBVESCashbook			 AS cafintrn WITH ( NOLOCK )
		    LEFT OUTER JOIN axxia01.dbo.cashdr AS cashdr WITH  ( NOLOCK ) ON cafintrn.legacy_client_matter_number = RTRIM(cashdr.client) + '-' + cashdr.matter  COLLATE DATABASE_DEFAULT /*1.2 JL*/
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
                                             AND cafintrn.sequence_number  = RTRIM(payments.PaymentNumber) COLLATE DATABASE_DEFAULT 
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
                                               AND cafintrn.sequence_number   = RTRIM(Recoveries.RecoveryNumber) COLLATE DATABASE_DEFAULT 
                                               AND cafintrn.amount = 
                                               -- added by SD as CRC have gone in as recovery reversals
                                               CASE WHEN trust_transaction_type ='CLCRC' COLLATE DATABASE_DEFAULT THEN Recoveries.RecoveryAmount * -1 
																			ELSE Recoveries.RecoveryAmount END
    	
	
			ORDER BY cafintrn.post_date,cafintrn.reference_number

























GO
