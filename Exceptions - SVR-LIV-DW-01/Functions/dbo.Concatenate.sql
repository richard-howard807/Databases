SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE AGGREGATE [dbo].[Concatenate] (@Value [nvarchar] (max), @Delimiter [nvarchar] (4000))
RETURNS [nvarchar] (max)
EXTERNAL NAME [CustomAggregates].[concat]
GO
