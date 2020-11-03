SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Julie Loughlin
-- Create date: 02/11/2020
-- Description:	#70120 - New Report to to track new reports 
-- =============================================
CREATE PROCEDURE [dbo].[ReportTracker]
AS
BEGIN

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
--declare @startdate as date
--declare @enddate as date

SELECT

[Date Changed] as [Date Created]
,[Changed By] as [Developer]
,[Change Description]
,[Report Name]
FROM ReportInventory.dbo.TFSReportChangeTracking
where [Date Changed] >'20201001' --between  @startdate and @enddate
and [Change Description] like '%New%'
and [Change Description] like '%Report%'

ORDER BY [Date Created]
END
GO
