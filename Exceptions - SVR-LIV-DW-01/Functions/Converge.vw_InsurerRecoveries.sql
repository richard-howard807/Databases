SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Converge].[vw_InsurerRecoveries] (
	  @CaseID int
	, @SnapshotDate datetime
)
RETURNS TABLE
AS
RETURN (
	SELECT cashdr.case_id
		 , ISNULL(SUM(CASE WHEN snap.Insurer = 'Insurer' THEN snap.Amount ELSE 0 END), 0) * -1 AS TotalInsurerRecovered
	FROM axxia01.dbo.cashdr
	LEFT JOIN Converge.vw_Payment_Reserve_Summary_Snapshot(@SnapshotDate) snap ON cashdr.case_id = snap.case_id AND snap.Financial_Category_Code = 'RC'
	WHERE cashdr.case_id = @CaseID
	GROUP BY cashdr.case_id
)
GO
