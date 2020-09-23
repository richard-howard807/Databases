SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Converge].[vw_NonInsurerReserve] (
	  @CaseID int
	, @HistoricDate datetime
)
RETURNS TABLE
AS
RETURN (
	SELECT cashdr.case_id
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Non-Insurer' THEN snap.Amount ELSE 0 END), 0) AS TotalReserveIncFees
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Non-Insurer' AND snap.Level2 <> 'Loss Adjuster Fees' THEN snap.Amount ELSE 0 END), 0) AS TotalReserveExcFees
	FROM axxia01.dbo.cashdr
	LEFT JOIN Converge.vw_Payment_Reserve_Summary_Snapshot(@HistoricDate) snap ON cashdr.case_id = snap.case_id AND snap.Financial_Category_Code = 'RE'
	WHERE cashdr.case_id = @CaseID
	GROUP BY cashdr.case_id
)
GO
