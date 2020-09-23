SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Converge].[vw_InsurerPayments] (
	  @CaseID int
	, @SnapshotDate datetime
)
RETURNS TABLE
AS
RETURN (
	SELECT cashdr.case_id
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Insurer' THEN snap.Amount ELSE 0 END), 0) AS TotalInsurerPaidIncFees
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Insurer' AND snap.Level2 <> 'Loss Adjuster Fees' THEN snap.Amount ELSE 0 END), 0) AS TotalInsurerPaidExcFees
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Insurer' AND Local = 'Local' THEN snap.Amount ELSE 0 END), 0) AS TotalInsurerLocallyPaid
	FROM axxia01.dbo.cashdr
	LEFT JOIN vw_Payment_Reserve_Summary_Snapshot(@SnapshotDate) snap ON cashdr.case_id = snap.case_id AND snap.Financial_Category_Code = 'PG'
	WHERE cashdr.case_id = @CaseID
	GROUP BY cashdr.case_id
)
GO
