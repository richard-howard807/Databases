SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE  FUNCTION [dbo].[get_ms_employee_name]
(
@cdCode AS nvarchar(15)
) RETURNS nvarchar(255)
AS
BEGIN

  DECLARE
  @lkuptxt    nvarchar(255) 

  SET @lkuptxt = NULL

  BEGIN

  select @lkuptxt= ds_sh_ms_dbuser.usrfullname
  from dbo.ds_sh_ms_dbuser
  where ds_sh_ms_dbuser.usrid = @cdCode

   END

RETURN  @lkuptxt

END
GO
