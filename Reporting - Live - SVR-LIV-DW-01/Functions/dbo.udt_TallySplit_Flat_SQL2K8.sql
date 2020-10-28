SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE FUNCTION [dbo].[udt_TallySplit_Flat_SQL2K8]
(
	@delim	CHAR(1)
,	@string	VARCHAR(500)
)
RETURNS @return TABLE 
(
	col1 VARCHAR(100)
,	col2 VARCHAR(100)
,	col3 VARCHAR(100)
,	col4 VARCHAR(100)
,	col5 VARCHAR(100)
,	col6 VARCHAR(100)
)
AS
BEGIN
	INSERT INTO @return
	SELECT	[1],[2],[3],[4],[5],[6]
	FROM	(
				SELECT	SubRowID, LEFT(ListValue,100) AS ListValue FROM dbo.udt_TallySplit_SQL2K8 (@delim, @string)
			) p
	PIVOT
	(	MAX(ListValue)
		FOR	SubRowID IN ([1],[2],[3],[4],[5],[6])
	) pvt;
	
	RETURN 
END
GO
