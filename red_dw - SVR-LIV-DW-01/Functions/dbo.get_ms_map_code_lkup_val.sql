SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE  FUNCTION [dbo].[get_ms_map_code_lkup_val]
(
@cdType AS NVARCHAR(15)
,@cdCode AS NVARCHAR(15)
) RETURNS NVARCHAR(255)
AS
BEGIN

  DECLARE
  @lkuptxt    NVARCHAR(255) 

  SET @lkuptxt = NULL

  BEGIN

  SELECT @lkuptxt= LEFT(txtLookupDesc,255)  FROM MS_Prod.dbo.udMapCodeLookup
  WHERE txtMSLookupType=@cdType AND txtMSLookupCode=@cdCode


   END

RETURN  @lkuptxt

END









GO
