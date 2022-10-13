SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO
CREATE AGGREGATE [dbo].[Concatenate] (@Value [nvarchar] (max), @Delimiter [nvarchar] (4000))
RETURNS [nvarchar] (max)
EXTERNAL NAME [CustomAggregates].[concat]
GO
GRANT EXECUTE ON  [dbo].[Concatenate] TO [SBC\SQL - DataReader on SVR-LIV-DWH-01]
GO
GRANT EXECUTE ON  [dbo].[Concatenate] TO [ssrs_dynamicsecurity]
GO
