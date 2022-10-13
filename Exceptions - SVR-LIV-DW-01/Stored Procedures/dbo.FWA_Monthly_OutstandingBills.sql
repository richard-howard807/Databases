SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-12-13
-- Description:	[FWA_Monthly_OutstandingBills]
-- =============================================
CREATE PROCEDURE [dbo].[FWA_Monthly_OutstandingBills]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
select fename 'Matter Owner',maclin 'Client No',mamatn 'Matter No',caname 'Client Name',
madesc 'Matter Description',blnumb 'Bill No',bldate 'Bill Date',bltotb-bltotp 'Outstanding'
from red_Dw.dbo.ds_sh_fwa_blfile
INNER JOIN red_Dw.dbo.ds_sh_fwa_mafile ON blclin = 'FW'+CAST(maclin AS NVARCHAR(8)) AND blmatn = mamatn AND ds_sh_fwa_mafile.dss_current_flag = 'Y'
INNER JOIN red_Dw.dbo.ds_sh_fwa_cafile ON 'FW'+CAST(caclin AS NVARCHAR(8)) = blclin AND ds_sh_fwa_cafile.dss_current_flag = 'Y'
INNER JOIN red_Dw.dbo.ds_sh_fwa_fefile ON maeact = feidnm   AND ds_sh_fwa_fefile.dss_current_flag = 'Y'
WHERE 
bltotb - bltotp != 0 and
bldate > '07/31/1997' and
ds_sh_fwa_blfile.dss_current_flag = 'Y'
order by fename,maclin,mamatn,blnumb


end


GO
