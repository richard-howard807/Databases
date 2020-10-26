SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-10-08
-- Description:	#74760, created sproc for query connor kenny sent over to create a report
-- =============================================
CREATE PROCEDURE [te_3e_prod].[top_30_suppliers_by_amounted_owed]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Top 30 Suppliers by amount owed --
SELECT TOP 30
		pe.PayeeNum
	,	pe.Name as 'Payee Name'
	,	ve.VendorNum
	,	ve.Name as 'Vendor Name'
	,	format(sum(v.OpenAmt),'c','en-gb') as 'Amount Owed'
	,	gl.GLNat
	
	FROM [TE_3E_PROD]..Voucher V
	INNER JOIN [TE_3E_PROD]..Payee pe 
		ON v.Payee = pe.PayeeIndex
	INNER JOIN [TE_3E_PROD]..vendor ve 
		ON ve.VendorIndex = pe.Vendor
	INNER JOIN [SVR-LIV-3ESQ-01].[TE_3E_PROD].[DBO].[GLNatural] GL with (NOLOCK)
		ON gl.GLNaturalID = pe.APGLNat
	
	WHERE gl.GLNat in ('420002','420003')
	
	GROUP BY pe.Name, ve.Name, pe.PayeeNum, ve.VendorNum, gl.GLNat
		HAVING SUM(v.OpenAmt) > 0
		ORDER BY SUM(v.openamt) DESC
END
GO
