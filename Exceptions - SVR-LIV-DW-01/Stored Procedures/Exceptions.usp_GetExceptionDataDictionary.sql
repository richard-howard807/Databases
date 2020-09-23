SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- EXEC BSC.usp_GetExceptionDataDictionary '42'

CREATE PROC [Exceptions].[usp_GetExceptionDataDictionary] (
	  @DatasetIDs varchar(255) = ''
)
AS
BEGIN
	SELECT d.DatasetID
		 , d.DatasetName
		 , d.MainFilter
		 , d.MainFilterNarrative
		 , f.FieldID
		 , ISNULL(df.Alias, f.FieldName) AS FieldName
		 , f.Narrative
		 , ISNULL(d.DescriptionSuffix, '') AS DescriptionSuffix
		 , d.Comments
		 , f.QueryString
		 , df.Severity
		 , df.Critical
		 , f.DetailsUsed
		 , Exceptions.dbo.Concatenate(RTRIM(caslup.case_detail_code) + ' - ' + RTRIM(caslup.case_detail_desc), '|') AS DetailsInvolved
	FROM Exceptions.Exceptions.Datasets d
	INNER JOIN Exceptions.Exceptions.DatasetFields df ON d.DatasetID = df.DatasetID
	INNER JOIN Exceptions.Exceptions.Fields f ON df.FieldID = f.FieldID
	OUTER APPLY Exceptions.dbo.udt_TallySplit(',', f.DetailsUsed) AS detailsplit
	LEFT JOIN axxia01.dbo.caslup ON detailsplit.ListValue = caslup.case_detail_code
	LEFT JOIN Exceptions.dbo.udt_TallySplit(',', @DatasetIDs) AS datasetsplit ON d.DatasetID = datasetsplit.ListValue
	WHERE f.ExceptionField = 1
		AND (datasetsplit.ListValue IS NOT NULL OR @DatasetIDs = '')
	GROUP BY d.DatasetID
		 , d.DatasetName
		 , d.MainFilter
		 , d.MainFilterNarrative
		 , f.FieldID
		 , ISNULL(df.Alias, f.FieldName)
		 , f.Narrative
		 , d.DescriptionSuffix
		 , d.Comments
		 , f.QueryString
		 , df.Severity
		 , df.Critical
		 , f.DetailsUsed
END
GO
