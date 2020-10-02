SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[get_ms_code_lkup_val]
(
@cdType AS nvarchar(15)
,@cdCode AS nvarchar(15)
) RETURNS nvarchar(255)
AS
BEGIN

  DECLARE
  @lkuptxt    nvarchar(255) 

  SET @lkuptxt = NULL

  BEGIN

  SELECT @lkuptxt= LEFT(cddesc,255)  FROM MS_Prod.dbo.dbCodeLookup
  WHERE cdType=@cdType AND cdCode=@cdCode


   END

RETURN  @lkuptxt

END









GO
GRANT EXECUTE ON  [dbo].[get_ms_code_lkup_val] TO [ssrs_dynamicsecurity]
GO
