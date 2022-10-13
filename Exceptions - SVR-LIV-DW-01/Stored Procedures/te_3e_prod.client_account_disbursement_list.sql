SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 25/10/2018
-- Description:	Subscription Report for Steve Scullion
-- =============================================
CREATE PROCEDURE [te_3e_prod].[client_account_disbursement_list]
	
AS

	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	SELECT TD.TranDate AS 'Date',
		   M.Number AS 'Matter Number',
		   M.DisplayName AS 'Matter Name',
		   TD.DocumentNumber AS 'Document Number',
		   TD.Amount,
		   TC.CkNum AS 'Cheque No',
		   TD.TrustIntendedUse,
		   TD.TrustDisbursementType,
		   TD.TrustDisbStatus,
		   TD.IsReversed,
		   TD.ReverseDate,
		   TD.Comment
	FROM TE_3E_Prod.dbo.TRUSTDISBURSEMENT TD WITH (NOLOCK)
		INNER JOIN TE_3E_Prod.dbo.MATTER M WITH (NOLOCK)
			ON M.MATTINDEX = TD.MATTER
		LEFT JOIN TE_3E_Prod.dbo.TRUSTCHECK TC WITH (NOLOCK)
			ON TC.TRUSTCHKINDEX = TD.TRUSTCHECK
	WHERE TC.CkNum IS NULL
		  AND ReverseDate IS NULL


GO
