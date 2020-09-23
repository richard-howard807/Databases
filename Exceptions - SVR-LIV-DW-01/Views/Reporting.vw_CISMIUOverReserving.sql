SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [Reporting].[vw_CISMIUOverReserving]
AS
SELECT     LeadMatter.case_id, LeadMatter.GuidNumber, CISMIUOverReserving.TotalDamagesPaid, CISMIUOverReserving.TotalClaimsCostPaid, 
                      CISMIUOverReserving.TotalReserve, CASE WHEN ISNULL(TotalDamagesPaid, 0) + ISNULL(TotalClaimsCostPaid, 0) > ISNULL(TotalReserve, 0) 
                      THEN 'Over Reserve' END AS OverReserve
FROM         (SELECT     cashdr.case_id, TRA123.case_text AS GuidNumber
                       FROM          axxia01.dbo.cashdr AS cashdr INNER JOIN
                                                  (SELECT     case_id, case_text
                                                    FROM          axxia01.dbo.casdet
                                                    WHERE      (case_detail_code = 'TRA123')) AS TRA123 ON cashdr.case_id = TRA123.case_id INNER JOIN
                                                  (SELECT     case_id, case_text
                                                    FROM          axxia01.dbo.casdet AS casdet_5
                                                    WHERE      (case_detail_code = 'NMI617')) AS NMI617 ON cashdr.case_id = NMI617.case_id
                       WHERE      (NMI617.case_text = 'Yes')) AS LeadMatter LEFT OUTER JOIN
                          (SELECT     GuidNumber, TotalDamagesPaid, TotalClaimsCostPaid, TotalReserve, CASE WHEN ISNULL(TotalDamagesPaid, 0) + ISNULL(TotalClaimsCostPaid, 0) 
                                                   > ISNULL(TotalReserve, 0) THEN 'Over Reserve' END AS OverReserve
                            FROM          (SELECT     GuidNumber.GuidNumber, SUM(TRA070.TotalDamagesPaid) AS TotalDamagesPaid, SUM(TRA072.TotalClaimsCostPaid) 
                                                                           AS TotalClaimsCostPaid, SUM(NMI672.TotalReserve) AS TotalReserve
                                                    FROM          (SELECT     case_id, case_text AS GuidNumber
                                                                            FROM          axxia01.dbo.casdet AS casdet_4
                                                                            WHERE      (case_detail_code = 'TRA123') AND (case_text IS NOT NULL) AND (case_text <> '')) AS GuidNumber LEFT OUTER JOIN
                                                                               (SELECT     case_id, case_value AS TotalDamagesPaid
                                                                                 FROM          axxia01.dbo.casdet AS casdet_3
                                                                                 WHERE      (case_detail_code = 'TRA070')) AS TRA070 ON GuidNumber.case_id = TRA070.case_id LEFT OUTER JOIN
                                                                               (SELECT     case_id, case_value AS TotalClaimsCostPaid
                                                                                 FROM          axxia01.dbo.casdet AS casdet_2
                                                                                 WHERE      (case_detail_code = 'TRA072')) AS TRA072 ON GuidNumber.case_id = TRA072.case_id LEFT OUTER JOIN
                                                                               (SELECT     case_id, case_value AS TotalReserve
                                                                                 FROM          axxia01.dbo.casdet AS casdet_1
                                                                                 WHERE      (case_detail_code = 'NMI672')) AS NMI672 ON GuidNumber.case_id = NMI672.case_id
                                                    GROUP BY GuidNumber.GuidNumber) AS DamagesCostGreater) AS CISMIUOverReserving ON 
                      LeadMatter.GuidNumber = CISMIUOverReserving.GuidNumber

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
         Begin Table = "LeadMatter"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 95
               Right = 198
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "CISMIUOverReserving"
            Begin Extent = 
               Top = 6
               Left = 236
               Bottom = 125
               Right = 421
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
      Begin ColumnWidths = 9
         Width = 284
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
         Width = 1500
      End
   End
   Begin CriteriaPane = 
      Begin ColumnWidths = 11
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
', 'SCHEMA', N'Reporting', 'VIEW', N'vw_CISMIUOverReserving', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'Reporting', 'VIEW', N'vw_CISMIUOverReserving', NULL, NULL
GO
