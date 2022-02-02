SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[CampaignView]
AS
SELECT AllData.dim_matter_header_curr_key,
      COALESCE(AllData.NewCampaign, AllData.Campaign) AS Campaign
	  FROM (
SELECT        red_dw.dbo.dim_matter_header_current.dim_matter_header_curr_key, CASE WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN 'Stalking Protection Order' WHEN LOWER(work_type_name) 
                         LIKE '%cyber%' OR
                         LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data' WHEN LOWER(work_type_name) LIKE '%gdpr%' OR
                         LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR' WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN 'Building Safer Future' WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) 
                         = 'coronavirus' OR
                         (CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01' AND (LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%')) THEN 'Coronavirus' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'energy get ready' THEN 'Get ready!  Energy in transition' WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN 'Industrial and Logistics development' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'investment and asset management' THEN 'Investors, Property investment and Asset management' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'private rent schemes (prs)' THEN 'PRS Private Rented Sector' WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN 'Future of supply chain' WHEN LOWER(dim_matter_worktype.work_type_name) 
                         = 'healthcare - remedy' THEN 'Healthcare - Remedy' ELSE is_this_part_of_a_campaign END AS Campaign
,CASE WHEN CONVERT(DATE,date_opened_case_management,103) <CONVERT(DATE,marketing.concludedcampaigns.[Closed Date],103) THEN 'Concluded' END AS NewCampaign
FROM            red_dw.dbo.dim_matter_header_current INNER JOIN
                         red_dw.dbo.dim_matter_worktype ON red_dw.dbo.dim_matter_worktype.dim_matter_worktype_key = red_dw.dbo.dim_matter_header_current.dim_matter_worktype_key LEFT OUTER JOIN
                         red_dw.dbo.dim_detail_core_details ON red_dw.dbo.dim_detail_core_details.dim_matter_header_curr_key = red_dw.dbo.dim_matter_header_current.dim_matter_header_curr_key

LEFT OUTER JOIN marketing.concludedcampaigns
 ON concludedcampaigns.Campaign = CASE WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN 'Stalking Protection Order' WHEN LOWER(work_type_name) 
                         LIKE '%cyber%' OR
                         LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data' WHEN LOWER(work_type_name) LIKE '%gdpr%' OR
                         LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR' WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN 'Building Safer Future' WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) 
                         = 'coronavirus' OR
                         (CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01' AND (LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%')) THEN 'Coronavirus' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'energy get ready' THEN 'Get ready!  Energy in transition' WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN 'Industrial and Logistics development' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'investment and asset management' THEN 'Investors, Property investment and Asset management' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'private rent schemes (prs)' THEN 'PRS Private Rented Sector' WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN 'Future of supply chain' WHEN LOWER(dim_matter_worktype.work_type_name) 
                         = 'healthcare - remedy' THEN 'Healthcare - Remedy' ELSE is_this_part_of_a_campaign END COLLATE database_default

WHERE        (CASE WHEN LOWER(work_type_name) LIKE '%stalking protection order%' THEN 'Stalking Protection Order' WHEN LOWER(work_type_name) LIKE '%cyber%' OR
                         LOWER(matter_description) LIKE '%cyber%' THEN 'Cyber, Privacy & Data' WHEN LOWER(work_type_name) LIKE '%gdpr%' OR
                         LOWER(matter_description) LIKE '%gdpr%' THEN 'GDPR' WHEN LOWER(is_this_part_of_a_campaign) LIKE 'bsf%' THEN 'Building Safer Future' WHEN LOWER(dim_detail_core_details.is_this_part_of_a_campaign) 
                         = 'coronavirus' OR
                         (CAST(dim_matter_header_current.date_opened_practice_management AS DATE) >= '2020-01-01' AND (LOWER(dim_matter_header_current.matter_description) LIKE '%coronavirus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%corona virus%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%covid%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%cov-2%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%sars%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%pandemic%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%lock down%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%self-isolation%' OR
                         LOWER(dim_matter_header_current.matter_description) LIKE '%quarantine%')) THEN 'Coronavirus' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'energy get ready' THEN 'Get ready!  Energy in transition' WHEN LOWER(is_this_part_of_a_campaign) = 'industrial and logistics' THEN 'Industrial and Logistics development' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'investment and asset management' THEN 'Investors, Property investment and Asset management' WHEN LOWER(is_this_part_of_a_campaign) 
                         = 'private rent schemes (prs)' THEN 'PRS Private Rented Sector' WHEN LOWER(is_this_part_of_a_campaign) = 'supply chain' THEN 'Future of supply chain' WHEN LOWER(dim_matter_worktype.work_type_name) 
                         = 'healthcare - remedy' THEN 'Healthcare - Remedy' ELSE is_this_part_of_a_campaign END IS NOT NULL)


) AS AllData
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
         Begin Table = "dim_matter_header_current (red_dw.dbo)"
            Begin Extent = 
               Top = 6
               Left = 38
               Bottom = 136
               Right = 318
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dim_matter_worktype (red_dw.dbo)"
            Begin Extent = 
               Top = 6
               Left = 356
               Bottom = 136
               Right = 583
            End
            DisplayFlags = 280
            TopColumn = 0
         End
         Begin Table = "dim_detail_core_details (red_dw.dbo)"
            Begin Extent = 
               Top = 6
               Left = 621
               Bottom = 136
               Right = 1065
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
', 'SCHEMA', N'dbo', 'VIEW', N'CampaignView', NULL, NULL
GO
DECLARE @xp int
SELECT @xp=1
EXEC sp_addextendedproperty N'MS_DiagramPaneCount', @xp, 'SCHEMA', N'dbo', 'VIEW', N'CampaignView', NULL, NULL
GO
