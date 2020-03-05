SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE FUNCTION [dbo].[fnc_RiskYear](
	@AsOf			DATETIME
)
RETURNS INT
AS
BEGIN

	DECLARE @Answer		INT

	-- You define what you want here (September being your changeover month)
	IF ( MONTH(@AsOf) < 10 )
		SET @Answer = YEAR(@AsOf) - 1
	ELSE
		SET @Answer = YEAR(@AsOf)


	RETURN @Answer

END
GO
