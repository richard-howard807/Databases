SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO







-- LD 21050317 Converted Seq number to varchar as the isnumeric bit is not excluding decimals 343.24
-- LD 20160803 Amended to point to fact trust balance
-- LD 20161013 had to rtrim the client number ...

-- exec [converge].[cheque_postings_reconcilliation_report] NULL,NULL,'0141'

CREATE PROCEDURE [converge].[cheque_postings_reconcilliation_report_exclusions] 
(
      @StartDate AS DATETIME,
      @EndDate AS DATETIME,
      @Bankcode AS VARCHAR(4)
)
AS 
     --SET nocount ON
    -- For testing purposes


   -- DECLARE  @StartDate AS DATETIME = '20161213'
			--,@EndDate AS DATETIME = '20161213'
			--,@Bankcode AS VARCHAR(4) = '0141'
			
 



	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#ConvergePayments')) 
				DROP TABLE #ConvergePayments

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
			,ISNULL(payee_name,narrative) narrative
			,trust_transaction_type
			,transaction_type_description
			,post_date
			,gl_date
			,tran_date
			,recon_status
			,reference_number
			,postsource
			
	INTO #ConvergePayments
	FROM reporting.[converge].[vw_replicated_trust_balance] tb
   
    WHERE tb.bank_account_name = @Bankcode
	AND tb.postsource IN ( 'TRSTDISB', 'TRSTRCPT')
	AND tb.trust_transaction_type NOT IN ('CLCJN','CLTOC')
	AND tb.post_date BETWEEN ISNULL(@StartDate,'1900-01-01') AND  ISNULL(@EndDate,GETDATE())
	AND tb.client IN ('W15329',
 'W15412',
 '00538797',
 '00513126'
 )
	AND ISNULL(legacy_sequence_number,CAST (sequence_number AS VARCHAR(30)))  not in ('5934309','5934368','6432859','6434193','6439703','6439384','6916301','6917810'
	,'7638216','7637485','6432857','6434194')
	
		IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#FinalTransactions')) 
				DROP TABLE #FinalTransactions

	

    SELECT  cashdr.case_id,
			cashdr.[client] AS Client,
            cashdr.[matter] AS Matter,
            [mg_feearn] AS FeeEarner,
            [mg_datcls] AS DateClosed,
            [sequence_number] AS SequenceNumber,
            [reference_number] AS TransactionNumber,
            [bank_account_name] AS BankCode,
			[bank_account_number] AS BankAccount,
            '' AS BatchNumber,
            --Added to ensure PFC are debits and RTC etc are credits
            CASE WHEN cafintrn.postsource IN ( 'TRSTRCPT' )
                             THEN amount 
                             ELSE amount *-1
                        END AS ArtiiontransactionAmount,
            --[tr_amount] AS ArtiiontransactionAmount,
            [amount],
			[narrative] AS TransactionDescription,
            [trust_transaction_type] AS TransactionType,
            [post_date] AS PostingDate,
            '' AS SystemDate,
            '' AS UserID,
            PaymentNumber,
            RecoveryNumber,
            PaymentGross,
            RecoveryAmount,
            payments.paymenttype,
            ISNULL(dupesummary.ExceptionSum, 0) AS ExceptionSum,
            (CASE WHEN cafintrn.bank_account_name = '0215' AND UPPER(payments.paymenttype) LIKE '%INSURER%' THEN 1 
				  WHEN cafintrn.bank_account_name = '0240' AND UPPER(payments.paymenttype) LIKE '%INSURER%' THEN 1 
				  WHEN cafintrn.bank_account_name = '0216' AND NOT UPPER(payments.paymenttype) LIKE '%INSURER%' THEN 1 
             ELSE 0 END) AS PaymentTypeException,
			 CASE WHEN amount - COALESCE(PaymentGross,Recoveries.RecoveryAmount,0) <> 0 THEN 1 ELSE 0 END AS missingpayment,
			 postsource
			 INTO #FinalTransactions
    FROM    #ConvergePayments AS cafintrn WITH ( NOLOCK )
			INNER JOIN axxia01.dbo.cashdr cashdr ON RTRIM(cashdr.client) + '-' + cashdr.matter = cafintrn.legacy_client_matter_number COLLATE DATABASE_DEFAULT
			LEFT JOIN axxia01.dbo.camatgrp camatgrp (NOLOCK) ON RTRIM(camatgrp.mg_client) + '-' + camatgrp.mg_matter = cafintrn.legacy_client_matter_number COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN ( SELECT    cashdr.case_id,
                                        cashdr.client,
                                        cashdr.matter,
                                        VE00156.seq_no AS SequenceNumber,
                                        VE00156.case_date AS paymentdate,
                                        VE00156lookup.sd_listxt AS paymenttype,
                                        RTRIM(VE00327.case_text) AS PaymentNumber,
                                        VE00327.seq_no AS PaymentSeqNo,
                                        --Added to ensure PFC are debits and RTC etc are credits
                                        VE00160.case_value * -1 AS PaymentGross
                              FROM      ( SELECT    case_id,
                                                    seq_no,
                                                    case_date,
                                                    RTRIM(case_text) AS case_text
                                          FROM      axxia01.dbo.casdet AS casdet
                                          WHERE     case_detail_code = 'VE00156'
                                        ) AS VE00156
                                        LEFT JOIN axxia01.dbo.stdetlst VE00156lookup ON VE00156.case_text = VE00156lookup.sd_liscod AND VE00156lookup.sd_detcod = 'VE00156'
                                        INNER JOIN axxia01.dbo.cashdr AS cashdr ON VE00156.case_id = cashdr.case_id
                                        INNER JOIN ( SELECT case_id,
                                                            cd_parent,
                                                            seq_no,
                                                            RTRIM(case_text) AS case_text
                                                     FROM   axxia01.dbo.casdet
                                                     WHERE  case_detail_code = 'VE00327'
                                                            AND case_text IS NOT NULL
                                                         --   and case_text = 'AWE'
                                                         --   AND ISNUMERIC(case_text) = 1
                                                            
                                                   ) AS VE00327 ON VE00156.case_id = VE00327.case_id
                                                                   AND VE00327.cd_parent = VE00156.seq_no
                                        INNER JOIN ( SELECT case_id,
                                                            cd_parent,
                                                            case_value
                                                     FROM   axxia01.dbo.casdet
                                                     WHERE  case_detail_code = 'VE00160'
                                                   ) AS VE00160 ON VE00156.case_id = VE00160.case_id
                                                                   AND VE00160.cd_parent = VE00156.seq_no
                            ) AS payments ON  cashdr. case_id = payments.case_id
                                             AND cafintrn.sequence_number = RTRIM(payments.PaymentNumber) COLLATE DATABASE_DEFAULT -- LD amended
            LEFT OUTER JOIN ( SELECT    cashdr.case_id,
                                        cashdr.client,
                                        cashdr.matter,
                                        VE00167.seq_no AS SequenceNumber,
                                        VE00167.case_date AS paymentdate,
                                        RTRIM(VE00328.case_text) AS RecoveryNumber,
                                        VE00328.seq_no AS RecoverySeqNo,
                                        VE00130.case_value AS RecoveryAmount
                              FROM      ( SELECT    case_id,
                                                    seq_no,
                                                    case_date,
                                                    RTRIM(case_text) AS case_text
                                          FROM      axxia01.dbo.casdet AS casdet
                                          WHERE     case_detail_code = 'VE00167'
                                        ) AS VE00167
                                        INNER JOIN axxia01.dbo.cashdr AS cashdr ON VE00167.case_id = cashdr.case_id
                                        INNER JOIN ( SELECT case_id,
                                                            cd_parent,
                                                            seq_no,
                                                            RTRIM(case_text) AS case_text
                                                     FROM   axxia01.dbo.casdet
                                                     WHERE  case_detail_code = 'VE00328'
                                                            AND case_text IS NOT NULL
                                                         --   AND ISNUMERIC(case_text) = 1
                                                   ) AS VE00328 ON VE00167.case_id = VE00328.case_id
                                                                   AND VE00328.cd_parent = VE00167.seq_no
                                        INNER JOIN ( SELECT case_id,
                                                            cd_parent,
                                                            case_value
                                                     FROM   axxia01.dbo.casdet
                                                     WHERE  case_detail_code = 'VE00130'
                                                   ) AS VE00130 ON VE00167.case_id = VE00130.case_id
                                                                   AND VE00130.cd_parent = VE00167.seq_no
                            ) AS Recoveries ON Recoveries.case_id = cashdr.case_id
                                               AND cafintrn.sequence_number  = RTRIM(Recoveries.RecoveryNumber) COLLATE DATABASE_DEFAULT
            LEFT OUTER JOIN ( SELECT case_id
								   , SUM(ExceptionType) AS ExceptionSum
							  FROM ( SELECT c1.case_id
									      , c1.seq_no
										  , (CASE WHEN c1.case_detail_code = 'VE00327' THEN 1 ELSE 2 END) AS ExceptionType
									 FROM axxia01.dbo.casdet c1
									 INNER JOIN axxia01.dbo.casdet c2 ON c1.case_id = c2.case_id AND c1.seq_no <> c2.seq_no AND c1.case_detail_code IN ('VE00327', 'VE00328') AND c2.case_detail_code IN ('VE00327', 'VE00328')
									 INNER JOIN axxia01.dbo.casdet p1 ON c1.case_id = p1.case_id AND c1.cd_parent = p1.seq_no
									 INNER JOIN axxia01.dbo.casdet p2 ON c2.case_id = p2.case_id AND c2.cd_parent = p2.seq_no
									 WHERE RTRIM(c1.case_text) = RTRIM(c2.case_text)
									 AND ISNUMERIC(c1.case_text) =1
									 UNION
									 SELECT c1.case_id
									      , c1.seq_no
								 	      , 4
							 		 FROM axxia01.dbo.casdet c1
						 			 INNER JOIN axxia01.dbo.casdet p1 ON c1.case_id = p1.case_id AND c1.cd_parent = p1.seq_no
					 				 INNER JOIN #ConvergePayments cafintrn ON RTRIM(c1.case_text) = RTRIM(cafintrn.sequence_number) COLLATE DATABASE_DEFAULT --and isnumeric(c1.case_text) =1
									 WHERE c1.case_detail_code = 'VE00327' AND cafintrn.postsource = 'TRSTRCPT'
								   ) dupelist
							  GROUP BY case_id
							) dupesummary ON (payments.case_id = dupesummary.case_id)
											  OR (Recoveries.case_id = dupesummary.case_id)
  
 


					SELECT * FROM #FinalTransactions
					WHERE missingpayment = 1
					ORDER BY PostingDate


GO
