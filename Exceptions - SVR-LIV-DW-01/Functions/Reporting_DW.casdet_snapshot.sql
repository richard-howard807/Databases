SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Reporting_DW].[casdet_snapshot](
	@SnapshotDate datetime
)
RETURNS TABLE
AS
RETURN (
	SELECT case_id
		 , seq_no
		 , cd_parent
		 , case_detail_code
		 , case_date
		 , case_mkr
		 , case_text
		 , case_value
	FROM [Reporting_DW].[casdet_historic]
	WHERE CAST(InsertedDate AS date) <= @SnapshotDate AND CAST(ReplacedDate AS date) > @SnapshotDate
	AND (case_date IS NOT NULL OR case_value IS NOT NULL OR case_mkr IS NOT NULL OR case_text IS NOT NULL)
)
GO
