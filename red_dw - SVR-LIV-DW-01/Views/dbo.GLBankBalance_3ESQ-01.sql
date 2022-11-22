SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO





CREATE VIEW [dbo].[GLBankBalance_3ESQ-01]
AS
SELECT        SUM(total_balance) AS total_balance
FROM            (SELECT        GLA.Description, GLN.GLNat, GTS.GLAcct, GTS.FiscalYear, SUM(GTS.OpenTranDR) + SUM(GTS.OpenTranCR) + SUM(GTS.TranPer01DR) 
                                                    + SUM(GTS.TranPer01CR) + SUM(GTS.TranPer02DR) + SUM(GTS.TranPer02CR) + SUM(GTS.TranPer03DR) + SUM(GTS.TranPer03CR) 
                                                    + SUM(GTS.TranPer04DR) + SUM(GTS.TranPer04CR) + SUM(GTS.TranPer05DR) + SUM(GTS.TranPer05CR) + SUM(GTS.TranPer06DR) 
                                                    + SUM(GTS.TranPer06CR) + SUM(GTS.TranPer07DR) + SUM(GTS.TranPer07CR) + SUM(GTS.TranPer08DR) + SUM(GTS.TranPer08CR) 
                                                    + SUM(GTS.TranPer09DR) + SUM(GTS.TranPer09CR) + SUM(GTS.TranPer10DR) + SUM(GTS.TranPer10CR) + SUM(GTS.TranPer11DR) 
                                                    + SUM(GTS.TranPer11CR) + SUM(GTS.TranPer12DR) + SUM(GTS.TranPer12CR) AS total_balance
                          FROM            TE_3E_PROD.[dbo].[GLTranSumm] AS GTS WITH (NOLOCK) INNER JOIN
                                          TE_3E_PROD.dbo.GLAcct AS GLA WITH (NOLOCK) ON GLA.AcctIndex = GTS.GLAcct INNER JOIN
                                          TE_3E_PROD.dbo.GLNatural AS GLN WITH (NOLOCK) ON GLN.GLNaturalID = GLA.GLNatural INNER JOIN
                                          TE_3E_PROD.dbo.GLAcctClass AS GLC WITH (NOLOCK) ON GLC.Code = GLN.GLAcctClass
                          WHERE        (GLC.Code = 'OffBank') 
						  AND (GTS.FiscalYear=(SELECT DISTINCT fin_year FROM red_dw.dbo.dim_date WHERE dim_date.current_fin_year='Current'))
						  --AND (GTS.FiscalYear = '2022')
                          GROUP BY GLA.Description, GLN.GLNat, GTS.GLAcct, GTS.GLAcct, GTS.FiscalYear) AS total
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
