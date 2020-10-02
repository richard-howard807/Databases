SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[get_ms_code_lkup_val_multiselect]
(
@cdType AS nvarchar(15)
,@cdCode AS nvarchar(15)
) RETURNS nvarchar(255)
AS
BEGIN

  
  DECLARE   @lkuptxt    nvarchar(255) 
 
  SET @lkuptxt = NULL

  begin

  SELECT @lkuptxt = LEFT(STRING_AGG(dbCodeLookup.cdDesc, ', '), 800) -- limited to 800 for now to prevent truncation errors
  FROM  -- [dbo].[SplitDelimitedToRows](@cdCode, ',')
		 Reporting.dbo.udt_TallySplit( ',', @cdCode)
  INNER join MS_Prod.dbo.dbCodeLookup on dbCodeLookup.cdType=@cdType  
										AND cdCode=LTRIM(RTRIM(udt_TallySplit.ListValue)) COLLATE Latin1_General_BIN





	END

RETURN  @lkuptxt

END









GO
