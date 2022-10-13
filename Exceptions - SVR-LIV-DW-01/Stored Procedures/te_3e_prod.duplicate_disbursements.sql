SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 06/12/2018
-- Description:	A report for Steven Scullion
-- =============================================
CREATE PROCEDURE [te_3e_prod].[duplicate_disbursements]
	
	@StartDate DATE
	,@EndDate DATE
	,@CostType VARCHAR(3000)

AS
BEGIN
	
	SET NOCOUNT ON;
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	-- FOR Testing Purposes
	--DECLARE @StartDate Date = '20180101'
	--DECLARE @EndDate Date = '20181206'
	--DECLARE @CostType varchar(3000) = 'COU,122,COUNSEL,CF'


	DECLARE @CostTypeTable TABLE(val varchar(30))
	INSERT INTO @CostTypeTable 
	select val from Reporting.[dbo].[split_delimited_to_rows] (@CostType,',')
	


	SELECT
	CL.DisplayName		[Client Name],
	MT.Number			[Matter Number],
	MT.DisplayName		[Matter Desc],
	CC.CostType			[Cost Type],
	CT.[Description]	[Cost Type Desc],
	cc.WorkAmt			[Work Amount],
	P.[Name]			[Payee Name], 
	CC.WorkDate			[Work Date],
	CC.Narrative_UnformattedText [Narrative],
	IM.InvNumber [		Invoice]
	,V.VchrIndex
	FROM TE_3E_Prod.dbo.CostCard AS CC WITH (NOLOCK)
	INNER JOIN TE_3E_Prod.dbo.CostType AS CT WITH (NOLOCK) ON CT.Code = CC.CostType
	INNER JOIN TE_3E_Prod.dbo.Voucher AS V WITH (NOLOCK) ON V.VchrIndex = CC.Voucher
	INNER JOIN TE_3E_Prod.dbo.Payee AS P WITH (NOLOCK) ON P.PayeeIndex = V.Payee
	INNER JOIN TE_3E_Prod.dbo.Matter AS MT WITH (NOLOCK) ON MT.MattIndex = CC.Matter
	INNER JOIN TE_3E_Prod.dbo.Client AS CL WITH (NOLOCK) ON CL.ClientIndex = MT.Client
	INNER JOIN TE_3E_Prod.dbo.MattDate AS MD WITH (NOLOCK) ON MD.MatterLkUp = MT.MattIndex AND MD.NxEndDate = '99991231'
	INNER JOIN TE_3E_Prod.dbo.Timekeeper AS TK WITH (NOLOCK) ON TK.TkprIndex = MD.RspTkpr
	INNER JOIN TE_3E_Prod.dbo.TkprDate AS TKD WITH (NOLOCK) ON TKD.TimekeeperLkUp = TK.TkprIndex AND TKD.NxEndDate = '99991231'
	INNER JOIN TE_3E_Prod.dbo.Section AS S WITH (NOLOCK) ON S.Code = TKD.Section
	INNER JOIN TE_3E_Prod.dbo.Timekeeper AS TKC WITH (NOLOCK) ON TKC.TkprIndex = CC.Timekeeper
	INNER JOIN TE_3E_Prod.dbo.TkprDate AS TKDC WITH (NOLOCK) ON TKDC.TimekeeperLkUp = TKC.TkprIndex AND TKDC.NxEndDate = '99991231'
	INNER JOIN TE_3E_Prod.dbo.Section AS SC WITH (NOLOCK) ON SC.Code = TKDC.Section
	INNER JOIN (
	SELECT
		MT.MattIndex 
		, CC.CostType 
		, cc.WorkAmt 
		, V.Payee 
		, COUNT(*) [cnt]

	FROM TE_3E_Prod.dbo.CostCard AS CC WITH (NOLOCK)
	INNER JOIN TE_3E_Prod.dbo.Matter AS MT WITH (NOLOCK) ON MT.MattIndex = CC.Matter
	INNER JOIN TE_3E_Prod.dbo.Voucher AS V WITH (NOLOCK) ON V.VchrIndex = CC.Voucher
	INNER JOIN TE_3E_Prod.dbo.Client AS CL WITH (NOLOCK) ON CL.ClientIndex = MT.Client
	INNER JOIN TE_3E_Prod.dbo.MattDate AS MD WITH (NOLOCK) ON MD.MatterLkUp = MT.MattIndex AND MD.NxEndDate = '99991231'

	WHERE CC.WorkDate BETWEEN @StartDate AND @EndDate
	AND CC.CostType COLLATE DATABASE_DEFAULT IN (SELECT val FROM @CostTypeTable)
	AND CC.IsActive = 1

	GROUP BY 
		MT.MattIndex 
		, CC.CostType 
		, cc.WorkAmt 
		, V.Payee 
	HAVING COUNT(*) >1

	) duplicates ON  duplicates.MattIndex = MT.MattIndex 
					AND duplicates.CostType = CC.CostType
					AND duplicates.WorkAmt = CC.WorkAmt
					AND duplicates.Payee = V.Payee  

	LEFT OUTER JOIN TE_3E_Prod.dbo.InvMaster AS IM WITH (NOLOCK) ON IM.InvIndex = CC.InvMaster

	ORDER BY MT.MattIndex,CC.CostType,CC.WorkAmt,V.Payee 




END
GO
