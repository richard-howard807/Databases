SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  FUNCTION [dbo].[get_ms_client_matter_code]
(
@number AS nvarchar(8)
) RETURNS nvarchar(8)
AS
BEGIN

 declare @number_return AS nvarchar(8)

 SET @number_return = ''
  BEGIN

  SELECT @number_return = CASE WHEN ISNUMERIC(@number) = 1 THEN RIGHT('00000000' + @number,8) ELSE @number   END

  End

RETURN  @number_return
End
GO
