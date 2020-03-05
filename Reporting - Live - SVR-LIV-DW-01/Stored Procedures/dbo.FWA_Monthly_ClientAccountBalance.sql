SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		sgrego
-- Create date: 2018-12-13
-- Description:	[FWA_Monthly_ClientAccountBalance]
-- =============================================
CREATE PROCEDURE [dbo].[FWA_Monthly_ClientAccountBalance]
(
@date NVARCHAR(8)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT maclin 'Client No', mamatn 'Matter No', caname 'Client Name', madesc 'Matter Description', MAX(cldate) lastdate_update, isnull(sum(clclia), 0.00) 'Client Account'
FROM red_Dw.dbo.ds_sh_fwa_mafile
left JOIN  red_Dw.dbo.ds_sh_fwa_clfile ON  clclin =maclin  and clmatn=mamatn  
LEFT JOIN red_Dw.dbo.ds_sh_fwa_cafile ON caclin=maclin AND ds_sh_fwa_cafile.dss_current_flag = 'Y' 
WHERE
madtop < @date +'01' and cldate < @date +'01' AND ds_sh_fwa_mafile.dss_current_flag = 'Y'
GROUP BY caname, maclin, mamatn, madesc
HAVING sum(clclia) <> 0
ORDER BY 'Client Account'

end


GO
