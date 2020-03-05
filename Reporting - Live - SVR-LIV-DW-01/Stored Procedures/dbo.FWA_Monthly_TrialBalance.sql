SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-12-13
-- Description:	[FWA_Monthly_TrialBalance_section1]
-- =============================================
CREATE PROCEDURE [dbo].[FWA_Monthly_TrialBalance]
(
@date NVARCHAR(8)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select 
nlcode,
ncdesc,
SUM(nlamnt) ' ' 
FROM red_Dw.dbo.ds_sh_fwa_nlfile
INNER JOIN red_Dw.dbo.ds_sh_fwa_ncfile ON nlcode = nccnum
where  nlperd <= @date
group by nlcode,ncdesc
order by nlcode

end


GO
