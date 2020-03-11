SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<orlagh >
-- Create date: <10-13-2020>
-- Description:	<Description,,>
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
C.CostType
FROM [TE_3E_PROD].[dbo].[VOUCHER] V
 
JOIN [TE_3E_PROD].[dbo].[SITE] S ON S.SiteIndex = V.PayeeSite
 
JOIN [TE_3E_PROD].[dbo].[ADDRESS] A ON S.Address = A.AddrIndex
 
INNER JOIN [TE_3E_PROD].[dbo].[COSTCARD] C ON C.VOUCHER = V.VCHRINDEX
 
WHERE C.CostType ='122' AND V.TranDate BETWEEN @StartDate AND @EndDate
 
ORDER BY Street
END
GO
