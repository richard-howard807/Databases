SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 24/11/2017
-- Description:	Transaction Details for the Client Balance Report (Webby 273458)
-- =============================================
CREATE PROCEDURE [dbo].[ClientBalanceAlertDetails] 
(
	@Client VARCHAR(8)
	,@Matter VARCHAR(8)
)
AS
BEGIN
	
	DECLARE @nRef VARCHAR(17) = @Client+'-'+@Matter

	SELECT	fin.client_code
			,fin.matter_number
			,tb.client_matter_number [mattersphere_reference]
			,mh.matter_owner_full_name
			,fed.hierarchylevel3 [department]
			,fed.hierarchylevel4 [team]
			,fin.client_account_balance_of_matter
			,tb.transaction_type_group,
			 tb.bank_account_name,
			 tb.bank_description,
			 tb.bank_account_number,
			 tb.amount,
			 tb.payee_name,
			 tb.reference_number,
			 tb.narrative,
			 tb.trust_transaction_type,
			 tb.transaction_type_description,
			 tb.post_date,
			 tb.gl_date,
			 tb.tran_date,
			 tb.recon_status,
			 tb.client
			 ,tb.matter
       
        
	FROM red_dw.dbo.dim_matter_header_current mh
	INNER JOIN red_dw.dbo.fact_finance_summary fin ON fin.client_code = mh.client_code AND fin.matter_number = mh.matter_number
	INNER JOIN red_dw.dbo.dim_fed_hierarchy_current fed ON mh.fee_earner_code = fed.fed_code 
	LEFT JOIN Reporting.[converge].[vw_replicated_trust_balance] tb  ON RTRIM(mh.client_code) +'-'+ mh.matter_number = tb.legacy_client_matter_number COLLATE DATABASE_DEFAULT
	WHERE tb.legacy_client_matter_number = @nRef
	--AND tb.transaction_type_group IN ('RECEIPT')
	ORDER BY tb.tran_date DESC 






END
GO
