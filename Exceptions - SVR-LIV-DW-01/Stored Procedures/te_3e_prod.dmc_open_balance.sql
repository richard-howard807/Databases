SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-10-08
-- Description:	#74760, created sproc for query connor kenny sent over to create a report
-- =============================================
CREATE PROCEDURE [te_3e_prod].[dmc_open_balance]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Daily Matter Cheques where Balance open --
SELECT
	pe.PayeeNum,
	pe.Name as 'Payee Name',
	ve.VendorNum,
	ve.Name as 'Vendor Name',
	V.TranDate AS 'Voucher Date',
	format(sum(v.OpenAmt),'c','en-gb') as 'Balance',
	vs.description as 'Voucher Type'
	
	from [TE_3E_PROD]..Voucher V
	INNER JOIN [TE_3E_PROD]..Payee as pe 
		ON v.Payee = pe.PayeeIndex
	INNER JOIN [TE_3E_PROD]..vendor as ve 
		ON ve.VendorIndex = pe.Vendor
	INNER JOIN [TE_3E_PROD].[DBO].[VchrStatus] as vs WITH (NOLOCK) 
		ON vs.Code = v.VchrStatus
	
	where v.VchrStatus = 'GEN'
		AND OpenAmt > 0
	
	GROUP BY pe.Name, ve.Name, pe.PayeeNum, ve.VendorNum, V.TRANDATE, vs.description
		HAVING SUM(v.OpenAmt) > 0
		ORDER BY SUM(v.openamt) DESC
END
GO
