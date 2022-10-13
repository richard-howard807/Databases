SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO






/*=================================
   Version History
****************************************
	Version	 By	    Date		Detail
	1.1		 JL		09-09-2016  added in new logic for recon status and removed the start date pram as was not reconciling with this date in

			LD		2016-09-14 this version now caters for all including derwent with the new logic applied.			
****************************************
Testing 
exec [converge].[severn_trent_reconciliation] 'Severn Trent','20160831'
*/	



CREATE PROCEDURE [converge].[severn_trent_reconciliation] (
	  @ClientName VARCHAR(255)
	--, @StartDate DATETIME
	, @EndDate DATETIME
) AS
BEGIN

		
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
	--DECLARE @ClientName varchar(255) = 'Balance Sheet' 
	--DECLARE @StartDate datetime = '20111001'
	--DECLARE @EndDate datetime = '20161130'
	
	
	DECLARE @bank INT

	IF @ClientName = 'Severn Trent' SET @bank = 71
	IF @ClientName = 'Derwent' SET @bank = 96
	IF @ClientName = 'Balance Sheet' SET @bank = 101



	 
	IF EXISTS (SELECT * FROM tempdb..sysobjects WHERE id=OBJECT_ID('tempdb..#SevernTrentRec')) 
				DROP TABLE #SevernTrentRec


------------------Get 3E data-------------------
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
			,ISNULL(CAST(legacy_sequence_number AS VARCHAR),CAST(sequence_number AS NVARCHAR(50))) sequence_number
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
			
	

  INTO #SevernTrentRec			
  FROM [converge].[vw_replicated_trust_balance] tb

 WHERE	tb.recon_status <> 'R'
	AND  tb.BankAcctIndex = @bank
	AND tb.postsource IN ( 'TRSTDISB','TRSTADJ')
	AND tb.gl_date <= @EndDate
     
	 -- LD 20170302
	 AND ISNULL(tb.IsReversed,0) <> 1
     AND NOT (tb.TrustDisbursement IS NOT NULL AND tb.TrustCheck IS NULL)


  --WHERE  (  post_date <= @EndDate  /*1.1 JL*/
  --AND (BankAcctIndex  = @bank  )   
  --AND tb.recon_status = 'O' )
  --AND trust_transaction_type <> 'Gen'
  --  OR 
  --( recon_status = 'NA'
  --AND BankAcctIndex =  @bank  
  --AND trust_transaction_type  = 'EFT'
  --AND post_date = '20160804')

  --OR
  --  (recon_status = 'NA' /*1.1 JL*/
	 -- AND BankAcctIndex = @bank
	 -- AND trust_transaction_type  = 'AUTHC'
	 -- AND post_date  BETWEEN '20160420' AND @EndDate)

---Get FED Data---------------------------------------------

--SELECT * FROM #SevernTrentRec

	SELECT cashdr.client + '-' + cashdr.matter  AS EngageRef
		 , cafintrn.post_date AS DateIssued
		 , RTRIM(paytypes.sd_listxt) AS PaymentType
		 , cafintrn.reference_number AS Details
		 , ISNULL(VE00158.case_value,0) AS Net
		 , ISNULL(VE00159.case_value,0) AS VAT
		 , ISNULL(VE00160.case_value *-1,  amount) AS TotalPayment -- LD 20160818 Changed the signage of VE00160
		, amount 
		,  CAST([sequence_number] AS VARCHAR) [legacy_sequence_number]
		,VE00327.case_text


	FROM axxia01.dbo.cashdr
	INNER JOIN #SevernTrentRec cafintrn 
	 ON cafintrn.client = REPLACE(cashdr.client,' ','') COLLATE DATABASE_DEFAULT AND cafintrn.matter = REPLACE(cashdr.matter,' ','') COLLATE DATABASE_DEFAULT 
	LEFT JOIN axxia01.dbo.casdet VE00327 ON cashdr.case_id = VE00327.case_id AND sequence_number  = VE00327.case_text COLLATE DATABASE_DEFAULT AND VE00327.case_detail_code = 'VE00327'
	LEFT JOIN axxia01.dbo.casdet VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.seq_no = VE00327.cd_parent AND VE00156.case_detail_code = 'VE00156'
	LEFT JOIN axxia01.dbo.casdet VE00158 ON cashdr.case_id = VE00158.case_id AND VE00158.cd_parent = VE00156.seq_no AND VE00158.case_detail_code = 'VE00158'
	LEFT JOIN axxia01.dbo.casdet VE00159 ON cashdr.case_id = VE00159.case_id AND VE00159.cd_parent = VE00156.seq_no AND VE00159.case_detail_code = 'VE00159'
	LEFT JOIN axxia01.dbo.casdet VE00160 ON cashdr.case_id = VE00160.case_id AND VE00160.cd_parent = VE00156.seq_no AND VE00160.case_detail_code = 'VE00160'
	LEFT JOIN axxia01.dbo.stdetlst paytypes ON VE00156.case_text = paytypes.sd_liscod AND paytypes.sd_detcod = 'VE00156'
	--WHERE cafintrn.reference_number IS NOT NULL 
	ORDER BY cafintrn.reference_number
END



















GO
