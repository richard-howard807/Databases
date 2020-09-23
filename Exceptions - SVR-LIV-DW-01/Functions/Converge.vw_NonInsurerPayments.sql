SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Converge].[vw_NonInsurerPayments] (
	  @CaseID int
	, @SnapshotDate datetime
)
RETURNS TABLE
AS
RETURN (
	SELECT cashdr.case_id
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Non-Insurer' THEN snap.Amount ELSE 0 END), 0) AS TotalPaidIncFees
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Non-Insurer' AND snap.Level2 <> 'Loss Adjuster Fees' THEN snap.Amount ELSE 0 END), 0) AS TotalPaidExcFees
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Non-Insurer' AND Local = 'Local' THEN snap.Amount ELSE 0 END), 0) AS TotalLocallyPaid
	FROM axxia01.dbo.cashdr
	LEFT JOIN vw_Payment_Reserve_Summary_Snapshot(@SnapshotDate) snap ON cashdr.case_id = snap.case_id AND snap.Financial_Category_Code = 'PG'
	WHERE cashdr.case_id = @CaseID
	GROUP BY cashdr.case_id
)
GO
