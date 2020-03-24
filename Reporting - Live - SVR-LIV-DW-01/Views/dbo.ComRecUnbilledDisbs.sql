SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[ComRecUnbilledDisbs]
 AS
 (

SELECT fileID,SUM(CostCard.WorkAmt) AS UnbilledDisb
  FROM TE_3E_Prod.dbo.CostCard
  INNER JOIN  TE_3E_Prod.dbo.Matter
  ON CostCard.matter = matter.mattindex
  INNER JOIN MS_Prod.config.dbFile
   ON MattIndex=fileExtLinkID
LEFT OUTER JOIN MS_Prod.config.dbClient
 ON dbClient.clID = dbFile.clID
  LEFT OUTER JOIN TE_3E_Prod.dbo.InvMaster
  ON CostCard.invmaster = InvMaster.invindex
  
  LEFT OUTER JOIN TE_3E_Prod.dbo.Client
  ON matter.client = client.clientindex
  
  LEFT OUTER JOIN TE_3E_Prod.dbo.CostBill
  ON CostCard.costindex = CostBill.costcard
  AND CostBill.isreversed = 0 
  
  LEFT OUTER JOIN  TE_3E_Prod.dbo.ChrgBillTax
  ON CostBill.costbillindex = ChrgBillTax.costbill
  LEFT OUTER JOIN TE_3E_Prod.dbo.CostType
  ON CostCard.costtype = CostType.code
  LEFT OUTER JOIN TE_3E_Prod.dbo.Timekeeper
  ON CostCard.timekeeper = Timekeeper.tkprindex
 WHERE TE_3E_Prod.dbo.CostCard.isactive = 1  
 AND fileType='2038'
 AND  InvIndex is null
 GROUP BY fileID
)
GO
