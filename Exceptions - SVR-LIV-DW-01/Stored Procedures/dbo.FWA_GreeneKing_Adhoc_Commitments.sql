SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-12-13
-- Description:	[FWA_GreeneKing_Adhoc_Commitments]
-- =============================================
CREATE PROCEDURE [dbo].[FWA_GreeneKing_Adhoc_Commitments]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select clclin 'Client No', clmatn 'Matter No', madesc 'Matter Desc', cldate 'Date', clrefn 'RFF No',
cloffa 'Amount', cldes1 'Description 1', cldes2 'Description 2',
CASE
WHEN costat=0 THEN 'Open'
WHEN costat=1 THEN 'Funds Requested'
WHEN costat=2 THEN 'Billed'
WHEN costat=3 THEN 'Client Paying Direct'
ELSE '-'
END AS 'Status'
from red_Dw.dbo.ds_sh_fwa_cofile 
INNER JOIN red_Dw.dbo.ds_sh_fwa_clfile ON clsern = cosern  --AND ds_sh_fwa_clfile.dss_current_flag = 'Y'
INNER JOIN red_Dw.dbo.ds_sh_fwa_mafile ON clclin = maclin AND mamatn = clmatn and ds_sh_fwa_mafile.dss_current_flag = 'Y'
INNER JOIN red_Dw.dbo.ds_sh_fwa_fefile ON maeact = feidnm   AND ds_sh_fwa_fefile.dss_current_flag = 'Y'
WHERE
costat IN (0,1,2,3) and
cloffa <> 0 and
clclin IN (22350,31900,31067)
order by clclin, clmatn, coidno

end


GO
