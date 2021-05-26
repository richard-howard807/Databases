SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE view [dbo].[GLBankBalance_3ESQ-01]
as
select        sum(total_balance) as total_balance
from            (select        GLA.Description, GLN.GLNat, GTS.GLAcct, GTS.FiscalYear, sum(GTS.OpenTranDR) + sum(GTS.OpenTranCR) + sum(GTS.TranPer01DR) 
                                                    + sum(GTS.TranPer01CR) + sum(GTS.TranPer02DR) + sum(GTS.TranPer02CR) + sum(GTS.TranPer03DR) + sum(GTS.TranPer03CR) 
                                                    + sum(GTS.TranPer04DR) + sum(GTS.TranPer04CR) + sum(GTS.TranPer05DR) + sum(GTS.TranPer05CR) + sum(GTS.TranPer06DR) 
                                                    + sum(GTS.TranPer06CR) + sum(GTS.TranPer07DR) + sum(GTS.TranPer07CR) + sum(GTS.TranPer08DR) + sum(GTS.TranPer08CR) 
                                                    + sum(GTS.TranPer09DR) + sum(GTS.TranPer09CR) + sum(GTS.TranPer10DR) + sum(GTS.TranPer10CR) + sum(GTS.TranPer11DR) 
                                                    + sum(GTS.TranPer11CR) + sum(GTS.TranPer12DR) + sum(GTS.TranPer12CR) as total_balance
                          from            [SVR-LIV-3ESQ-01].TE_3E_PROD.dbo.GLTranSumm as GTS with (nolock) inner join
                                                    [SVR-LIV-3ESQ-01].TE_3E_PROD.dbo.GLAcct as GLA with (nolock) on GLA.AcctIndex = GTS.GLAcct inner join
                                                    [SVR-LIV-3ESQ-01].TE_3E_PROD.dbo.GLNatural as GLN with (nolock) on GLN.GLNaturalID = GLA.GLNatural inner join
                                                    [SVR-LIV-3ESQ-01].TE_3E_PROD.dbo.GLAcctClass as GLC with (nolock) on GLC.Code = GLN.GLAcctClass
                          where        (GLC.Code = 'OffBank') and (GTS.FiscalYear = '2022')
                          group by GLA.Description, GLN.GLNat, GTS.GLAcct, GTS.GLAcct, GTS.FiscalYear) as total
GO
EXEC sp_addextendedproperty N'MS_DiagramPane1', N'[0E232FF0-B466-11cf-A24F-00AA00A3EFFF, 1.00]
Begin DesignProperties = 
   Begin PaneConfigurations = 
      Begin PaneConfiguration = 0
         NumPanes = 4
         Configuration = "(H (1[40] 4[20] 2[20] 3) )"
      End
      Begin PaneConfiguration = 1
         NumPanes = 3
         Configuration = "(H (1 [50] 4 [25] 3))"
      End
      Begin PaneConfiguration = 2
         NumPanes = 3
         Configuration = "(H (1 [50] 2 [25] 3))"
      End
      Begin PaneConfiguration = 3
         NumPanes = 3
         Configuration = "(H (4 [30] 2 [40] 3))"
      End
      Begin PaneConfiguration = 4
         NumPanes = 2
         Configuration = "(H (1 [56] 3))"
      End
      Begin PaneConfiguration = 5
         NumPanes = 2
         Configuration = "(H (2 [66] 3))"
      End
      Begin PaneConfiguration = 6
         NumPanes = 2
         Configuration = "(H (4 [50] 3))"
      End
      Begin PaneConfiguration = 7
         NumPanes = 1
         Configuration = "(V (3))"
      End
      Begin PaneConfiguration = 8
         NumPanes = 3
         Configuration = "(H (1[56] 4[18] 2) )"
      End
      Begin PaneConfiguration = 9
         NumPanes = 2
         Configuration = "(H (1 [75] 4))"
      End
      Begin PaneConfiguration = 10
         NumPanes = 2
         Configuration = "(H (1[66] 2) )"
      End
      Begin PaneConfiguration = 11
         NumPanes = 2
         Configuration = "(H (4 [60] 2))"
      End
      Begin PaneConfiguration = 12
         NumPanes = 1
         Configuration = "(H (1) )"
      End
      Begin PaneConfiguration = 13
         NumPanes = 1
         Configuration = "(V (4))"
      End
      Begin PaneConfiguration = 14
         NumPanes = 1
         Configuration = "(V (2))"
      End
      ActivePaneConfig = 0
   End
   Begin DiagramPane = 
      Begin Origin = 
         Top = 0
         Left = 0
      End
      Begin Tables = 
         Begin Table = "total"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 224
            End
            DisplayFlags = 280
            TopColumn = 0
         End
      End
   End
   Begin SQLPane = 
   End
   Begin DataPane = 
      Begin ParameterDefaults = ""
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 12
         Column = 1440
         Alias = 900
         Table = 1170
         Output = 720
         Append = 1400
         NewValue = 1170
         SortType = 1350
         SortOrder = 1410
         GroupBy = 1350
         Filter = 1350
         Or = 1350
         Or = 1350
         Or = 1350
      End
   End
End
', 'SCHEMA', N'dbo', 'VIEW', N'GLBankBalance_3ESQ-01', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'GLBankBalance_3ESQ-01', NULL, NULL
GO
