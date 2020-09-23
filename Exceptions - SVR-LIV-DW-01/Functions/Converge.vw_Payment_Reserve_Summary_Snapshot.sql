SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE FUNCTION [Converge].[vw_Payment_Reserve_Summary_Snapshot] (
	  @SnapshotDate datetime
	--, @CaseID int = NULL
)
RETURNS TABLE
AS
RETURN
(
	WITH casdet_snapshot AS (
		SELECT *
		FROM [Reporting_DW].[casdet_historic]
		WHERE CAST(InsertedDate AS date) <= @SnapshotDate AND CAST(ReplacedDate AS date) > @SnapshotDate
	), casdet_snapshot_RE AS (
		SELECT cs.*
		FROM casdet_snapshot AS cs
		INNER JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON cs.case_detail_code collate database_default = prs.Sub_Detail_Code AND prs.Financial_Category_Code = 'RE' collate database_default
	), casdet_snapshot_RR AS (
		SELECT cs.*
		FROM casdet_snapshot AS cs
		INNER JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON cs.case_detail_code collate database_default = prs.Sub_Detail_Code AND prs.Financial_Category_Code = 'RR' collate database_default
	)
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(VE00156.seq_no, VE00160.seq_no) AS seq_no
		 , 'PG' AS Financial_Category_Code
		 , 'Paid Gross' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve
		 , VE00156.case_date AS Transaction_Date
		 , RTRIM(VE00327.case_text) AS Sequence_Number
	 , ISNULL(VE00160.case_value , 0) AS Amount
	FROM axxia01.dbo.cashdr
	INNER JOIN casdet_snapshot AS VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.case_detail_code = 'VE00156'
	INNER JOIN casdet_snapshot AS VE00160 ON VE00156.case_id = VE00160.case_id AND VE00156.seq_no = VE00160.cd_parent AND VE00160.case_detail_code = 'VE00160'
	LEFT JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON VE00156.case_text = prs.sd_liscod AND prs.Financial_Category_Code = 'PG'
	LEFT JOIN casdet_snapshot AS VE00327 ON VE00156.case_id = VE00327.case_id AND VE00156.seq_no = VE00327.cd_parent AND VE00327.case_detail_code = 'VE00327'
	WHERE NOT (cashdr.client = '00513126' -- Exclude Severn Trent payments made on or after 08/10/11 which don't have sequence numbers.
			 AND VE00156.case_date >= '2011-10-08'
			 AND VE00327.case_text IS NULL
			 AND prs.Local = 'No' -- Local payments don't need a sequence number
		  )
	UNION ALL
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(VE00156.seq_no, VE00159.seq_no) AS seq_no
		 , 'PT' AS Financial_Category_Code
		 , 'Paid Tax' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve
		 , VE00156.case_date AS Transaction_Date
		 , RTRIM(VE00327.case_text) AS Sequence_Number
	 , ISNULL(VE00159.case_value , 0) AS Amount
	FROM axxia01.dbo.cashdr
	INNER JOIN casdet_snapshot AS VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.case_detail_code = 'VE00156'
	INNER JOIN casdet_snapshot AS VE00159 ON VE00156.case_id = VE00159.case_id AND VE00156.seq_no = VE00159.cd_parent AND VE00159.case_detail_code = 'VE00159'
	LEFT JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON VE00156.case_text = prs.sd_liscod AND prs.Financial_Category_Code = 'PT'
	LEFT JOIN casdet_snapshot AS VE00327 ON VE00156.case_id = VE00327.case_id AND VE00156.seq_no = VE00327.cd_parent AND VE00327.case_detail_code = 'VE00327'
	WHERE NOT (cashdr.client = '00513126' -- Exclude Severn Trent payments made on or after 08/10/11 which don't have sequence numbers.
			 AND VE00156.case_date >= '2011-10-08'
			 AND VE00327.case_text IS NULL
			 AND prs.Local = 'No' -- Local payments don't need a sequence number
		  )
	UNION ALL
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(VE00156.seq_no, VE00158.seq_no) AS seq_no
		 , 'PN' AS Financial_Category_Code
		 , 'Paid Net' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve
		 , VE00156.case_date AS Transaction_Date
		 , RTRIM(VE00327.case_text) AS Sequence_Number
	 , ISNULL(VE00158.case_value , 0) AS Amount
	FROM axxia01.dbo.cashdr
	INNER JOIN casdet_snapshot AS VE00156 ON cashdr.case_id = VE00156.case_id AND VE00156.case_detail_code = 'VE00156'
	INNER JOIN casdet_snapshot AS VE00158 ON VE00156.case_id = VE00158.case_id AND VE00156.seq_no = VE00158.cd_parent AND VE00158.case_detail_code = 'VE00158'
	LEFT JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON VE00156.case_text = prs.sd_liscod AND prs.Financial_Category_Code = 'PN'
	LEFT JOIN casdet_snapshot AS VE00327 ON VE00156.case_id = VE00327.case_id AND VE00156.seq_no = VE00327.cd_parent AND VE00327.case_detail_code = 'VE00327'
	WHERE NOT (cashdr.client = '00513126' -- Exclude Severn Trent payments made on or after 08/10/11 which don't have sequence numbers.
			 AND VE00156.case_date >= '2011-10-08'
			 AND VE00327.case_text IS NULL
			 AND prs.Local = 'No' -- Local payments don't need a sequence number
		  )
	UNION ALL
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(VE00167.seq_no, VE00130.seq_no) AS seq_no
		 , 'RC' AS Financial_Category_Code
		 , 'Recovery' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve
		 , VE00167.case_date AS Transaction_Date
		 , RTRIM(VE00328.case_text) AS Sequence_Number
	 , ISNULL(VE00130.case_value , 0) * -1 AS Amount
	FROM axxia01.dbo.cashdr
	INNER JOIN casdet_snapshot AS VE00167 ON cashdr.case_id = VE00167.case_id AND VE00167.case_detail_code = 'VE00167'
	INNER JOIN casdet_snapshot AS VE00130 ON VE00167.case_id = VE00130.case_id AND VE00167.seq_no = VE00130.cd_parent AND VE00130.case_detail_code = 'VE00130'
	LEFT JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON VE00167.case_text = prs.sd_liscod AND prs.Financial_Category_Code = 'RC'
	LEFT JOIN casdet_snapshot AS VE00328 ON VE00167.case_id = VE00328.case_id AND VE00167.seq_no = VE00328.cd_parent AND VE00328.case_detail_code = 'VE00328'
	WHERE NOT (cashdr.client = '00513126' -- Exclude Severn Trent payments made on or after 08/10/11 which don't have sequence numbers.
			 AND VE00167.case_date >= '2011-10-08'
			 AND VE00328.case_text IS NULL
			 AND prs.Local = 'No' -- Local payments don't need a sequence number
		  )
	UNION ALL
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(cd_child.cd_parent, cd_child.seq_no) AS seq_no
		 , 'RE' AS Financial_Category_Code
		 , 'Reserve' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve		 
		 , NULL AS Transaction_Date
		 , NULL AS Sequence_Number
	 , ISNULL(cd_child.case_value , 0) AS Amount
	FROM axxia01.dbo.cashdr
	LEFT JOIN casdet_snapshot_RE AS cd_child ON cashdr.case_id = cd_child.case_id
	INNER JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON cd_child.case_detail_code collate database_default = prs.Sub_Detail_Code AND prs.Financial_Category_Code = 'RE' collate database_default
	UNION ALL
	SELECT cashdr.case_id
		 , cashdr.client
		 , cashdr.matter
		 , ISNULL(cd_child.cd_parent, cd_child.seq_no) AS seq_no
		 , 'RR' AS Financial_Category_Code
		 , 'Recovery Reserve' AS Financial_Category
		 , (CASE WHEN prs.Insurer = 'Yes' THEN 'Insurer' ELSE 'Non-Insurer' END) AS Insurer
		 , (CASE WHEN prs.Local = 'Yes' THEN 'Local' ELSE 'Non-Local' END) AS [Local]
		 , prs.Level4 AS Level4
		 , prs.Level3 AS Level3
		 , prs.Level2 AS Level2
		 , prs.Level1 AS Level1
		 , prs.Codeve AS Codeve
		 , NULL AS Transaction_Date
		 , NULL AS Sequence_Number
	 , ISNULL(cd_child.case_value , 0) * -1 AS Amount
	FROM axxia01.dbo.cashdr
	LEFT JOIN casdet_snapshot_RR AS cd_child ON cashdr.case_id = cd_child.case_id
	INNER JOIN [Veolia_axxia01].[Payment_Reserve_Structure] AS prs ON cd_child.case_detail_code collate database_default = prs.Sub_Detail_Code AND prs.Financial_Category_Code = 'RR' collate database_default
)


GO
