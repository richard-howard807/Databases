SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[RM100PlusBreakDates]
AS
SELECT MainDetails.case_id,
       CAST(MainDetails.TitleNumber AS VARCHAR(10)) AS TitleNumber,
       CASE
           WHEN PRO1033.case_text = 'Fixed date' THEN
               PRO1036.case_date
           WHEN PRO1033.case_text = 'Rolling'
                AND GETDATE() < PRO1034.case_date THEN
               PRO1034.case_date
           WHEN PRO1033.case_text = 'Rolling'
                AND GETDATE() > PRO1034.case_date THEN
       (CASE
            WHEN PRO1037.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
        END
       )
           WHEN PRO1033.case_text = 'Both' THEN
               CASE
                   WHEN PRO1036.case_date < (CASE
                                                 WHEN PRO1033.case_text = 'Fixed date' THEN
                                                     PRO1036.case_date
                                                 WHEN PRO1033.case_text = 'Rolling'
                                                      AND GETDATE() < PRO1034.case_date THEN
                                                     PRO1034.case_date
                                                 WHEN PRO1033.case_text = 'Rolling'
                                                      AND GETDATE() > PRO1034.case_date THEN
       (CASE
            WHEN PRO1037.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
        END
       )
                                             END
                                            ) THEN
                       PRO1036.case_date
                   ELSE
       (CASE
            WHEN PRO1037.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
            WHEN PRO1037.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1037.case_value, PRO1034.case_date)
        END
       )
               END
       END AS LandlordBreak,
       CASE
           WHEN PRO1042.case_text = 'Fixed date' THEN
               PRO1045.case_date
           WHEN PRO1042.case_text = 'Rolling'
                AND GETDATE() < PRO1043.case_date THEN
               PRO1043.case_date
           WHEN PRO1042.case_text = 'Rolling'
                AND GETDATE() > PRO1043.case_date THEN
       (CASE
            WHEN PRO1046.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
        END
       )
           WHEN PRO1042.case_text = 'Both' THEN
               CASE
                   WHEN PRO1045.case_date < (CASE
                                                 WHEN PRO1042.case_text = 'Fixed date' THEN
                                                     PRO1045.case_date
                                                 WHEN PRO1042.case_text = 'Rolling'
                                                      AND GETDATE() < PRO1043.case_date THEN
                                                     PRO1043.case_date
                                                 WHEN PRO1042.case_text = 'Rolling'
                                                      AND GETDATE() > PRO1043.case_date THEN
       (CASE
            WHEN PRO1046.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
        END
       )
                                             END
                                            ) THEN
                       PRO1045.case_date
                   ELSE
       (CASE
            WHEN PRO1046.case_text = 'Month(s)' THEN
                DATEADD(MONTH, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Year(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Week(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Day(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
            WHEN PRO1046.case_text = 'Quarter(s)' THEN
                DATEADD(YEAR, PRO1046.case_value, PRO1043.case_date)
        END
       )
               END
       END AS TenantBreak
FROM
(
    SELECT casdet.case_id,
           casdet.case_text AS TitleNumber,
           casdet.seq_no
    FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet
        INNER JOIN red_dw.dbo.ds_sh_axxia_cashdr AS cashdr
            ON casdet.case_id = cashdr.case_id
               AND cashdr.current_flag = 'Y'
    WHERE (casdet.case_detail_code = 'PRO839')
          AND (cashdr.client = 'P00016')
          AND (casdet.case_text IS NOT NULL)
          AND casdet.current_flag = 'Y'
) AS MainDetails
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_8
        WHERE (case_detail_code = 'PRO1033') AND casdet_8.current_flag = 'Y'
    ) AS PRO1033
        ON MainDetails.case_id = PRO1033.case_id
           AND MainDetails.seq_no = PRO1033.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_7
        WHERE (case_detail_code = 'PRO1036') AND casdet_7.current_flag = 'Y'
    ) AS PRO1036
        ON MainDetails.case_id = PRO1036.case_id
           AND MainDetails.seq_no = PRO1036.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_6
        WHERE (case_detail_code = 'PRO1037') AND casdet_6.current_flag = 'Y'
    ) AS PRO1037
        ON MainDetails.case_id = PRO1037.case_id
           AND MainDetails.seq_no = PRO1037.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_5
        WHERE (case_detail_code = 'PRO1034') AND casdet_5.current_flag = 'Y'
    ) AS PRO1034
        ON MainDetails.case_id = PRO1034.case_id
           AND MainDetails.seq_no = PRO1034.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_4
        WHERE (case_detail_code = 'PRO1042') AND casdet_4.current_flag = 'Y'
    ) AS PRO1042
        ON MainDetails.case_id = PRO1042.case_id
           AND MainDetails.seq_no = PRO1042.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_3
        WHERE (case_detail_code = 'PRO1045') AND casdet_3.current_flag = 'Y'
    ) AS PRO1045
        ON MainDetails.case_id = PRO1045.case_id
           AND MainDetails.seq_no = PRO1045.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_2
        WHERE (case_detail_code = 'PRO1046') AND casdet_2.current_flag = 'Y'
    ) AS PRO1046
        ON MainDetails.case_id = PRO1046.case_id
           AND MainDetails.seq_no = PRO1046.cd_parent
    LEFT OUTER JOIN
    (
        SELECT case_id,
               seq_no,
               case_detail_code,
               case_detail_rectyp,
               case_date,
               case_mkr,
               case_text,
               case_value,
               must_enter,
               cd_proflg,
               cd_capact,
               cd_capidx,
               cd_calctd,
               cd_clcode,
               cd_webrpt,
               cd_address,
               cd_dettyp,
               cd_parent
        FROM red_dw.dbo.ds_sh_axxia_casdet AS casdet_1
        WHERE (case_detail_code = 'PRO1043') AND casdet_1.current_flag = 'Y'
    ) AS PRO1043
        ON MainDetails.case_id = PRO1043.case_id
           AND MainDetails.seq_no = PRO1043.cd_parent;
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
         Begin Table = "MainDetails"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 99
               Right = 189
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1033"
            Begin Extent = 
               Top = 6
               Left = 227
               Bottom = 114
               Right = 398
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1036"
            Begin Extent = 
               Top = 6
               Left = 436
               Bottom = 114
               Right = 607
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1037"
            Begin Extent = 
               Top = 6
               Left = 645
               Bottom = 114
               Right = 816
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1034"
            Begin Extent = 
               Top = 102
               Left = 38
               Bottom = 210
               Right = 209
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1042"
            Begin Extent = 
               Top = 114
               Left = 247
               Bottom = 222
               Right = 418
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1045"
            Begin Extent = 
               Top = 114
               Left = 456
               Bottom = 222
               Right = 627
            End
            DisplayFlags = 280
', 'SCHEMA', N'dbo', 'VIEW', N'RM100PlusBreakDates', NULL, NULL
GO
EXEC sp_addextendedproperty N'MS_DiagramPane2', N'
            TopColumn = 0
         End
         Begin Table = "PRO1046"
            Begin Extent = 
               Top = 114
               Left = 665
               Bottom = 222
               Right = 836
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "PRO1043"
            Begin Extent = 
               Top = 210
               Left = 38
               Bottom = 318
               Right = 209
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
', 'SCHEMA', N'dbo', 'VIEW', N'RM100PlusBreakDates', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=2
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'RM100PlusBreakDates', NULL, NULL
GO
