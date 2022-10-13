SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


-- =============================================
-- Author:		sgrego
-- Create date: 2018-12-13
-- Description:	[FWA_GreeneKing_Adhoc_Commitments]
-- =============================================
CREATE PROCEDURE [dbo].[FWA_Monthly_Nominal]
(
@date NVARCHAR(8)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT * FROM red_Dw.dbo.ds_sh_fwa_nlfile 
WHERE 
nlperd = @date
ORDER BY nlsern

END


GO
