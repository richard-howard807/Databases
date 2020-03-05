SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








/*=======================================================
-- Author:		Lucy Dickinson
-- Date:		20160812
-- Description:	Listing of all transactions on the escrow, sproc runs this data into a table
--				so that the rec and funding request reports can render more quickly. 
--				taking hours before, this has improved the speed to minutes...
--========================================================
Version 
*/
-- exec [converge].[bsf_cashbook_build]  '20160831'

CREATE PROCEDURE [converge].[bsf_cashbook_build] 
(
  
      @EndDate AS DATETIME
)
AS 
   
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
	---- For testing purposes
		--DECLARE @EndDate AS DATETIME = '20160831'

	 
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#BSFCashbookBuild')) 
				DROP TABLE #BSFCashbookBuild
	
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
			,legacy_sequence_number
			,ISNULL(CAST(legacy_sequence_number AS VARCHAR),CAST(sequence_number AS VARCHAR(30)))  sequence_number 
			,CASE WHEN payee_name = '' OR payee_name IS NULL THEN narrative ELSE payee_name  END   narrative
			,CASE WHEN post_date <= '20160630' AND reference_number IN ('00757101','00792751','00798483','00832226',
								'00832221','33842001','00928967','77662001','35432001','00035711','00051782','00071949',
								'00071957','00084360','89100001','00094549','00113127','00113136','00113136','00051780')
						THEN 'CLCTR' 
						WHEN sequence_number in ('3e879394','3e879395') THEN 'CLPFC'
						ELSE trust_transaction_type 
			 END transaction_type_code
			,transaction_type_description
			,post_date
			,gl_date
			,tran_date
			,recon_status
			,reference_number document_number
			,postsource
			,IsReversed		-- LD 1.3
			,IsDeposit		-- LD 1.3	
			,CASE WHEN tb.postsource = 'TRSTTRSF'  AND transfer_detail_cash_journal IS NULL AND tb.gl_date > '20160831' THEN 1 ELSE 0 END [Exclude] 


	INTO #BSFCashbookBuild			
	FROM [converge].[vw_replicated_trust_balance] tb
	WHERE 
	
	  	 gl_date  <= @EndDate
	AND (BankAcctIndex  = 101)   

	TRUNCATE TABLE converge.cashbook_balancesheetfund

	INSERT INTO converge.cashbook_balancesheetfund
    
    SELECT 
				CASE 
				 WHEN IsReversed = 0 AND IsDeposit = 0 AND  transaction_type_code = 'EFT' THEN 'PAYMENT'
				 WHEN transaction_type_code IN ('CLCTR','GEN','EFT','INV') THEN 'TRANSFER' -- client transfer
				 WHEN transaction_type_code = 'INT' OR RTRIM(document_number) IN ('INTEREST', 'INT')  THEN 'INTEREST'
				 WHEN transaction_type_code = 'CASH' AND RTRIM(UPPER(cafintrn.narrative)) = 'INTEREST' THEN 'INTEREST'
                 WHEN transaction_type_code = 'CLRTC' THEN 'RECOVERY'  -- receipt to client
                 WHEN transaction_type_code IN ('CLCDC','CHQ') AND cafintrn.[matter] NOT IN ('00000001','00009999')   THEN 'RECOVERY' -- DV 20130621 - fix for a recovery marked as a topup
                 WHEN transaction_type_code IN ('CLCDC','CASH') THEN 'TOPUP' -- Direct credit client account
				 WHEN cafintrn.recon_status <> 'R' THEN 'UNPRESENTED'
				 WHEN transaction_type_code IN ( 'CLPFC', 'CLCRC','AUTHC','AUTHET','AUTHE' ) THEN 'PAYMENT' --Client payment from client, returned cheque client account /*1.2 JL*/
                   ELSE RTRIM(UPPER(transaction_type_description))
                     END AS Category,
			cashdr.case_id,
			[transaction_type_code],
            [document_number] AS ChequeNumber,
			cafintrn.[matter] AS InstructionID,
            RTRIM(VE00371.case_text) AS [Effect Description Additional],
            ISNULL(RTRIM(payments.InvoiceNumber), '') AS InvoiceNumber,
            ISNULL(VE00038.case_date,DOA.case_date) AS DateOfLoss,
            ISNULL(AccountPeriods.YearOfAccount,
				(CASE WHEN MONTH(VE00038.case_date) >= 4 THEN CAST(YEAR(VE00038.case_date) AS VARCHAR) + '/' + CAST(YEAR(VE00038.case_date) + 1 AS VARCHAR)
				 ELSE CAST(YEAR(VE00038.case_date) - 1 AS VARCHAR) + '/' + CAST(YEAR(VE00038.case_date) AS VARCHAR)
				 END))AS [Year OF Account] ,
            ISNULL(payments.PaymentToWhom, Recoveries.RecoveryFromWhom) AS PayableToName,
            payments.PaymentNet * -1 AS PaymentNet,
            (CASE WHEN payments.PaymentVAT IS NULL AND payments.PaymentNet IS NOT NULL THEN 0 ELSE payments.PaymentVAT * -1 END) AS PaymentVAT,
	         payments.PaymentGross * -1 AS PaymentGross,
			 CASE WHEN amount >= 0 THEN amount *-1 ELSE NULL END CreditAmount,
			 CASE WHEN amount <0 THEN amount *-1 ELSE NULL END DebitAmount,
			(CASE WHEN LEN(PaymentNotes) > 0 THEN PaymentNotes
				  WHEN LEN(RecoveryNotes) > 0 THEN RecoveryNotes
				  ELSE cafintrn.[narrative] COLLATE DATABASE_DEFAULT END) AS [Payment Notes],
			RTRIM(VE00002_lookup.sd_listxt) AS [Policy Type],
			
			 
			--------------------------------------------------------------------------------------------------------------------------------------------ori
			(CASE WHEN transaction_type_code = 'INT' OR RTRIM(document_number) IN ('INTEREST', 'INT') THEN 'B90' 
				  WHEN IsReversed = 0 AND IsDeposit = 0 AND  transaction_type_code = 'EFT' THEN RTRIM(VE00367.case_text)
				  WHEN transaction_type_code IN ('CLCTR','GEN','EFT') THEN ''
				ELSE ISNULL(RTRIM(VE00367.case_text),'') END) AS [Business Unit],
			--------------------------------------------------------------------------------------------------------------------------------------------ori
		
			RTRIM(VE00374.case_text) AS [Working Deductible],
			[post_date] AS PostingDate
		,   NewTotalPaid_Total
		,   NewTotalRecovered_Total
		,	ISNULL(RTRIM(VE00366.case_text),'-') AS [Peril Description] 
		,	ISNULL(VE00973.case_text,'-') [Wholesale OPS Burst Mains] 
		,   ISNULL(RTRIM(VE00365.case_text),'-') AS [District] 
		,   sequence_number
		,	legacy_sequence_number
		,	cafintrn.gl_date
		,	cafintrn.tran_date
		,	GETDATE() AS InsertDate

	
		  
	                      
    FROM    #BSFCashbookBuild AS cafintrn 
		    INNER JOIN axxia01.dbo.cashdr AS cashdr WITH ( NOLOCK ) ON cafintrn.client = RTRIM(cashdr.client) COLLATE DATABASE_DEFAULT
				AND cafintrn.matter = cashdr.matter COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN axxia01.dbo.casdet AS VE00038 WITH ( NOLOCK ) ON cashdr.case_id = VE00038.case_id AND VE00038.case_detail_code = 'VE00038'
            LEFT OUTER JOIN ( SELECT    VE00156.case_id,
                                        VE00156.seq_no AS SequenceNumber,
                                        VE00156.case_date AS paymentdate,
                                        VE00327.case_text AS PaymentNumber,
                                        VE00139.case_text AS PaymentToWhom,
                                        VE00144.case_text AS InvoiceNumber,
                                        --Added to ensure PFC are debits and RTC etc are credits
                                        VE00158.case_value *-1 AS PaymentNet,
                                        VE00159.case_value *-1 AS PaymentVAT,
                                        VE00160.case_value *-1 AS PaymentGross,
                                        RTRIM(ISNULL(RTRIM(VE00145.case_text), '') + ''
											+ ISNULL(RTRIM(VE00146.case_text), '') + ''
											+ ISNULL(RTRIM(VE00147.case_text), '') + ''
											+ ISNULL(RTRIM(VE00148.case_text), '') + ''
											+ ISNULL(RTRIM(VE00149.case_text), '') + '') PaymentNotes
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
                                        INNER JOIN axxia01.dbo.casdet AS VE00139
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00139.case_id
                                                           AND VE00139.cd_parent = VE00156.seq_no
                                                           AND VE00139.case_detail_code = 'VE00139'
                                        --Invoice Payment Number 
                                        INNER JOIN axxia01.dbo.casdet AS VE00144
                                        WITH ( NOLOCK ) ON VE00156.case_id = VE00144.case_id
                                                           AND VE00144.cd_parent = VE00156.seq_no
                                                           AND VE00144.case_detail_code = 'VE00144'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00145 ON VE00156.case_id = VE00145.case_id AND VE00145.cd_parent = VE00156.seq_no AND VE00145.case_detail_code = 'VE00145'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00146 ON VE00156.case_id = VE00146.case_id AND VE00146.cd_parent = VE00156.seq_no AND VE00146.case_detail_code = 'VE00146'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00147 ON VE00156.case_id = VE00147.case_id AND VE00147.cd_parent = VE00156.seq_no AND VE00147.case_detail_code = 'VE00147'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00148 ON VE00156.case_id = VE00148.case_id AND VE00148.cd_parent = VE00156.seq_no AND VE00148.case_detail_code = 'VE00148'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00149 ON VE00156.case_id = VE00149.case_id AND VE00149.cd_parent = VE00156.seq_no AND VE00149.case_detail_code = 'VE00149'
                            ) AS payments ON payments.case_id = cashdr.case_id
                                             AND cafintrn.[sequence_number] COLLATE DATABASE_DEFAULT = payments.PaymentNumber --AND cafintrn.amount = (payments.PaymentGross * -1)
            LEFT OUTER JOIN ( SELECT    VE00167.case_id,
                                        VE00167.seq_no AS SequenceNumber,
                                        VE00167.case_date AS paymentdate,
                                        VE00328.case_text AS RecoveryNumber,
                                        VE00130.case_value AS RecoveryAmount,
                                        VE00134.case_text AS RecoveryFromWhom,
                                        RTRIM(ISNULL(RTRIM(VE00135.case_text), '') + ''
											+ ISNULL(RTRIM(VE00136.case_text), '') + '') RecoveryNotes
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
                                        --Recovery Amount
                                        INNER JOIN axxia01.dbo.casdet AS VE00130
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00130.case_id
                                                           AND VE00130.cd_parent = VE00167.seq_no
                                                           AND VE00130.case_detail_code = 'VE00130'
                                        --Recovery From Whom
                                        INNER JOIN axxia01.dbo.casdet AS VE00134
                                        WITH ( NOLOCK ) ON VE00167.case_id = VE00134.case_id
                                                           AND VE00134.cd_parent = VE00167.seq_no
                                                           AND VE00134.case_detail_code = 'VE00134'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00135 ON VE00167.case_id = VE00135.case_id AND VE00135.cd_parent = VE00167.seq_no AND VE00135.case_detail_code = 'VE00135'
                                        LEFT JOIN axxia01.dbo.casdet AS VE00136 ON VE00167.case_id = VE00136.case_id AND VE00136.cd_parent = VE00167.seq_no AND VE00136.case_detail_code = 'VE00136'
                            ) AS Recoveries ON cashdr.case_id = Recoveries.case_id
                                               AND cafintrn.[sequence_number]  COLLATE DATABASE_DEFAULT = Recoveries.RecoveryNumber --AND cafintrn.amount = Recoveries.RecoveryAmount
    
					OUTER APPLY (	SELECT SUM(VE00160.case_value) NewTotalPaid_Total
									FROM axxia01.dbo.cashdr
									INNER JOIN axxia01.dbo.casdet AS VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.case_detail_code = 'VE00156'
									INNER JOIN axxia01.dbo.casdet AS VE00160 ON VE00156.case_id = VE00160.case_id AND VE00156.seq_no = VE00160.cd_parent AND VE00160.case_detail_code = 'VE00160'
									LEFT JOIN axxia01.dbo.casdet AS VE00327 ON cashdr.case_id = VE00327.case_id AND VE00327.case_detail_code = 'VE00327' AND VE00156.seq_no = VE00327.cd_parent
									LEFT JOIN #BSFCashbookBuild AS caftotal 
												ON	caftotal.client = cashdr.client COLLATE DATABASE_DEFAULT 
													AND caftotal.matter = cashdr.matter COLLATE DATABASE_DEFAULT
												AND VE00327.case_text = [sequence_number]  COLLATE DATABASE_DEFAULT
										WHERE cafintrn.client = cashdr.client  COLLATE DATABASE_DEFAULT 
											AND cafintrn.matter = cashdr.matter COLLATE DATABASE_DEFAULT 
							AND ((VE00327.case_text IS NOT NULL AND caftotal.post_date   <= cafintrn.post_date) OR VE00156.case_date < '2011-10-10')
						 GROUP BY cashdr.case_id) AS NewTotalToDate
      
				OUTER APPLY (		SELECT SUM(VE00130.case_value * -1)  AS NewTotalRecovered_Total
									FROM axxia01.dbo.cashdr
									INNER JOIN axxia01.dbo.casdet AS VE00167 ON cashdr.case_id = VE00167.case_id AND VE00167.case_detail_code = 'VE00167'
									INNER JOIN axxia01.dbo.casdet AS VE00130 ON VE00167.case_id = VE00130.case_id AND VE00167.seq_no = VE00130.cd_parent AND VE00130.case_detail_code = 'VE00130'
									LEFT JOIN axxia01.dbo.casdet AS VE00328 ON cashdr.case_id = VE00328.case_id AND VE00328.case_detail_code = 'VE00328' AND VE00167.seq_no = VE00328.cd_parent
									LEFT JOIN #BSFCashbookBuild AS caftotal 
											ON		caftotal.client = cashdr.client COLLATE DATABASE_DEFAULT 
													AND caftotal.matter = cashdr.matter COLLATE DATABASE_DEFAULT 
													AND VE00328.case_text = caftotal.[sequence_number]  COLLATE DATABASE_DEFAULT
									WHERE cafintrn.client = cashdr.client COLLATE DATABASE_DEFAULT 
										 AND cafintrn.matter = cashdr.matter COLLATE DATABASE_DEFAULT 
										AND ((VE00328.case_text IS NOT NULL AND caftotal.post_date   <= cafintrn.post_date) OR VE00167.case_date < '2011-10-10')
						 GROUP BY cashdr.case_id) AS NewRecoveredToDate
      		LEFT JOIN axxia01.dbo.casdet AS VE00002 ON cashdr.case_id = VE00002.case_id AND VE00002.case_detail_code = 'VE00002'
			LEFT JOIN axxia01.dbo.stdetlst AS VE00002_lookup ON VE00002.case_text = VE00002_lookup.sd_liscod AND VE00002_lookup.sd_detcod = 'VE00002' -- policy description
			LEFT JOIN axxia01.dbo.casdet AS VE00367 ON cashdr.case_id = VE00367.case_id AND VE00367.case_detail_code = 'VE00367' -- Business Unit
			LEFT JOIN axxia01.dbo.casdet AS VE00371 ON cashdr.case_id = VE00371.case_id AND VE00371.case_detail_code = 'VE00371' -- Effect description
			LEFT JOIN axxia01.dbo.casdet AS VE00374 ON cashdr.case_id = VE00374.case_id AND VE00374.case_detail_code = 'VE00374' -- Working deductible
			LEFT JOIN axxia01.dbo.casdet AS DOA ON cashdr.case_id = DOA.case_id AND DOA.case_detail_code = 'DOA' -- incident date
			LEFT JOIN axxia01.dbo.casdet AS VE00365 ON cashdr.case_id = VE00365.case_id AND VE00365.case_detail_code = 'VE00365'
			LEFT JOIN (SELECT YearOfAccount COLLATE DATABASE_DEFAULT YearOfAccount,DateFrom,DateTo  FROM converge.SevernTrentAccountPeriods ) AccountPeriods ON COALESCE(VE00038.case_date, DOA.case_date, cashdr.date_opened) >= AccountPeriods.DateFrom AND COALESCE(VE00038.case_date, DOA.case_date, cashdr.date_opened) <= AccountPeriods.DateTo	
			
			LEFT JOIN axxia01.dbo.casdet AS VE00366 ON cashdr.case_id = VE00366.case_id AND VE00366.case_detail_code = 'VE00366'
			LEFT JOIN axxia01.dbo.casdet AS VE00973 ON cashdr.case_id = VE00973.case_id AND VE00973.case_detail_code = 'VE00973'
		
   --   WHERE cafintrn.Exclude = 0	     
	
	ORDER BY post_date
	
	




























GO
