SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[udt_TallySplit_SQL2K8]
(	@Delim	CHAR(1) = ','
,	@String	VARCHAR(max)
)
RETURNS TABLE
AS
RETURN
	(	SELECT		Row_Number() over (partition by 1 order by N) as SubRowID
				,	ltrim(rtrim(SUBSTRING(@Delim + @String + @Delim,N+1,	CHARINDEX(@Delim,@Delim + @String + @Delim,N+1)-N-1))) as ListValue    
		FROM	dbo.Tally with (nolock)
		WHERE	N < LEN(@Delim + @String + @Delim)    
			AND	SUBSTRING(@Delim + @String + @Delim,N,1) = @Delim 
	)
	
GO
