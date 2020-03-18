SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [CommercialRecoveries].[UnbilledDisbursements]
(
@Client AS NVARCHAR(50)
)
AS
BEGIN
--DECLARE @Client AS NVARCHAR(50);
--SET @Client = N'M1001';

SELECT AllData.clNo,
       AllData.fileNo,
       AllData.fileDesc,
       AllData.Matter,
       AllData.WorkDate,
       AllData.PostDate,
       AllData.WorkAmt,
       AllData.StdAmt,
       AllData.Narrative,
       AllData.IsHardCost FROM 
(SELECT clNo,
       fileNo,
       fileDesc,
       Matter.Number AS Matter,
       WorkDate,
       CostCard.PostDate,
       CostCard.WorkAmt,
       CostCard.StdAmt,
       CostCard.Narrative,
       CostCard.IsHardCost
FROM TE_3E_Prod.dbo.CostCard
    INNER JOIN TE_3E_Prod.dbo.Matter
        ON CostCard.Matter = matter.MattIndex
    INNER JOIN MS_Prod.config.dbFile
        ON MattIndex = fileExtLinkID
    LEFT OUTER JOIN MS_Prod.config.dbClient
        ON dbClient.clID = dbFile.clID
    LEFT OUTER JOIN TE_3E_Prod.dbo.InvMaster
        ON CostCard.InvMaster = InvMaster.InvIndex
    LEFT OUTER JOIN TE_3E_Prod.dbo.Client
        ON matter.Client = Client.ClientIndex
    LEFT OUTER JOIN TE_3E_Prod.dbo.CostBill
        ON CostCard.CostIndex = CostBill.CostCard
           AND CostBill.IsReversed = 0
    LEFT OUTER JOIN TE_3E_Prod.dbo.ChrgBillTax
        ON CostBill.CostBillIndex = ChrgBillTax.CostBill
    LEFT OUTER JOIN TE_3E_Prod.dbo.CostType
        ON CostCard.CostType = CostType.Code
    LEFT OUTER JOIN TE_3E_Prod.dbo.Timekeeper
        ON CostCard.Timekeeper = Timekeeper.TkprIndex
WHERE TE_3E_Prod.dbo.CostCard.IsActive = 1
      AND fileType = '2038'
) AS AllData
WHERE AllData.clNo=@Client
END
GO
