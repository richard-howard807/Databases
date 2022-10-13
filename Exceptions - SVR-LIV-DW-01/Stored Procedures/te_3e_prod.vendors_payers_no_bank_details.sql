SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-10-08
-- Description:	#74760, created sproc for query connor kenny sent over to create a report
-- =============================================
CREATE PROCEDURE [te_3e_prod].[vendors_payers_no_bank_details]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

-- Vendors / Payees with No Bank Details --

SELECT	PayeeNum
,		Vendor
,		Name
,		PayeeType
,		PayeeStatus
,		IsEFTOnly
,		BankNum
,		AcctNum
,	max(PostDate) as 'Last Transaction'

FROM [TE_3E_PROD]..payee pe
	FULL OUTER JOIN [TE_3E_PROD]..payeebank PB
		on pb.Payee = pe.PayeeIndex
	FULL OUTER JOIN [TE_3E_PROD]..Voucher V
		ON V.Payee = PE.PayeeIndex
	
	WHERE pe.IsEFTOnly = 0
		AND PayeeBankID is null
		AND PayeeType in ('EXPERT','COUN')
		AND PayeeStatus = 'ACTIVE'
		
		GROUP BY
		PayeeNum
,		Vendor
,		Name
,		PayeeType
,		PayeeStatus
,		IsEFTOnly
,		BankNum
,		AcctNum
	
	ORDER BY max(postdate) DESC
    
END
GO
