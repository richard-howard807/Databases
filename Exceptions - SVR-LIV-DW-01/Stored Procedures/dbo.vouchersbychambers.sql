SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<orlagh >
-- Create date: <10-13-2020>
-- Description:	<Description,,>
-- =============================================
-- ES 2022-05-18, #147678, added department
-- =============================================
CREATE PROCEDURE [dbo].[vouchersbychambers]
	-- Add the parameters for the stored procedure here


(
@StartDate AS DATE
,@EndDate AS DATE
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
 
SELECT
V.VchrIndex,
V.TranDate,
InvNum,
V.Amount,
V.VchrStatus,
A.FormattedString,
A.Street,
C.CostType,
hierarchylevel3hist AS [Department]


FROM [TE_3E_PROD].[dbo].[VOUCHER] V
JOIN [TE_3E_PROD].[dbo].[SITE] S ON S.SiteIndex = V.PayeeSite
JOIN [TE_3E_PROD].[dbo].[ADDRESS] A ON S.Address = A.AddrIndex
INNER JOIN [TE_3E_PROD].[dbo].[COSTCARD] C ON C.VOUCHER = V.VCHRINDEX
----- Extra code---------------------
INNER JOIN TE_3E_Prod.dbo.VchrDetail WITH(NOLOCK)
ON V.VchrIndex=VchrDetail.Voucher
INNER JOIN TE_3E_Prod.dbo.Matter WITH(NOLOCK)
ON VchrDetail.Matter=MattIndex
INNER JOIN MS_PROD.config.dbFile WITH(NOLOCK) ON VchrDetail.Matter=dbFile.fileExtLinkID
INNER JOIN MS_PROD.config.dbClient WITH(NOLOCK) ON dbFile.clID=dbClient.clID
INNER JOIN MS_PROD.dbo.udExtFile WITH(NOLOCK) ON dbFile.fileID=udExtFile.fileID
INNER JOIN MS_PROD.dbo.dbUser WITH(NOLOCK) ON dbFile.filePrincipleID=dbUser.usrID
LEFT OUTER JOIN [red_dw].[dbo].[dim_fed_hierarchy_history] WITH(NOLOCK) ON usrAlias=fed_code collate database_default AND dss_current_flag='Y'

WHERE C.CostType ='122' AND V.TranDate BETWEEN @StartDate AND @EndDate

ORDER BY Street

END
GO
