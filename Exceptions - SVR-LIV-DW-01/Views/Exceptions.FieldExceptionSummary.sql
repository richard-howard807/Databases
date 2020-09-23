SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [Exceptions].[FieldExceptionSummary]
AS
SELECT        df.DatasetID, df.FieldID, df.SequenceNumber, df.Alias, df.Filter, COUNT(f_ex.FieldID) AS ExceptionCount, COUNT(df_ex.FieldID) AS SelectedCount
FROM            Exceptions.DatasetFields AS df INNER JOIN
                         Exceptions.Fields AS f ON df.FieldID = f.FieldID LEFT OUTER JOIN
                         Exceptions.Fields AS f_ex ON f.FieldID = f_ex.LinkedFieldID AND f_ex.ExceptionField = 1 LEFT OUTER JOIN
                         Exceptions.DatasetFields AS df_ex ON f_ex.FieldID = df_ex.FieldID AND df.DatasetID = df_ex.DatasetID
WHERE        (f.ExceptionField = 0)
GROUP BY df.DatasetID, df.FieldID, df.SequenceNumber, df.Alias, df.Filter
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
         Begin Table = "df"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 135
               Right = 238
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f"
            Begin Extent = 
               Top = 6
               Left = 276
               Bottom = 135
               Right = 462
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "f_ex"
            Begin Extent = 
               Top = 6
               Left = 500
               Bottom = 135
               Right = 686
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "df_ex"
            Begin Extent = 
               Top = 6
               Left = 724
               Bottom = 135
               Right = 924
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
', 'SCHEMA', N'Exceptions', 'VIEW', N'FieldExceptionSummary', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'Exceptions', 'VIEW', N'FieldExceptionSummary', NULL, NULL
GO
