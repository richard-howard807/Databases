SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





--===============================================================================================
-- Author:	Lucy Dickinson
-- Date:	20160812
--			Amended the old procedure to look at 3E, we used to be able to run one procedure and
--			pass in a bank code but we have had to make tweaks to deal with conversion issues and 
--			now have multiple store procedures.  These are called from [converge].[account_reconciliation]  
--================================================================================================



CREATE PROCEDURE [converge].[account_reconciliation_next] 
(
	@EndDate DATETIME
) 
AS
		-- For testing purposes
	--DECLARE @EndDate datetime = '20160813'
  	
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#NextRec')) 
				DROP TABLE #NextRec

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
			
	INTO #NextRec			
	FROM reporting.[converge].[vw_replicated_trust_balance] tb
    
	
	WHERE	tb.recon_status <> 'R'
	AND  tb.bank_account_name = '0222'
	AND tb.postsource IN ( 'TRSTDISB', 'TRSTADJ')
	AND tb.post_date BETWEEN '20090501' AND  @EndDate 
	--WHERE tb.recon_status = 'O'
	--AND   tb.bank_account_name = '0222'
	--AND trust_transaction_type <> 'Gen'
	--AND post_date BETWEEN '20090501' AND  @EndDate
	

	ORDER BY tb.post_date

	
	
	BEGIN
	SELECT cashdr.client+ '-' + cashdr.matter  AS EngageRef
		 , finrec.post_date AS DateIssued
		 , ISNULL(RTRIM(paytypes.sd_listxt), sequence_number) AS PaymentType
		 , finrec.reference_number AS Details
		 , VE00158.case_value AS Net 
		 , VE00159.case_value AS VAT 
		 , ISNULL(VE00160.case_value,(amount*-1)) AS TotalPayment 

		
	FROM axxia01.dbo.cashdr
	INNER JOIN #NextRec  finrec ON cashdr.client = finrec.client COLLATE DATABASE_DEFAULT AND cashdr.matter = finrec.matter COLLATE DATABASE_DEFAULT
	
	LEFT JOIN axxia01.dbo.casdet VE00327 ON cashdr.case_id = VE00327.case_id AND finrec.sequence_number COLLATE DATABASE_DEFAULT = VE00327.case_text AND VE00327.case_detail_code = 'VE00327'
	LEFT JOIN axxia01.dbo.casdet VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.seq_no = VE00327.cd_parent AND VE00156.case_detail_code = 'VE00156'
	LEFT JOIN axxia01.dbo.casdet VE00158 ON cashdr.case_id = VE00158.case_id AND VE00158.cd_parent = VE00156.seq_no AND VE00158.case_detail_code = 'VE00158'
	LEFT JOIN axxia01.dbo.casdet VE00159 ON cashdr.case_id = VE00159.case_id AND VE00159.cd_parent = VE00156.seq_no AND VE00159.case_detail_code = 'VE00159'
	LEFT JOIN axxia01.dbo.casdet VE00160 ON cashdr.case_id = VE00160.case_id AND VE00160.cd_parent = VE00156.seq_no AND VE00160.case_detail_code = 'VE00160'
	LEFT JOIN axxia01.dbo.stdetlst paytypes ON VE00156.case_text = paytypes.sd_liscod AND paytypes.sd_detcod = 'VE00156'

		
	ORDER BY finrec.reference_number
END















GO
