SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2020-06-22
-- Description:	61937 New leavers report for Office Managers
-- =============================================

CREATE PROCEDURE [dbo].[Leavers]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

SELECT forename+' '+surname AS [Name]
	, leaverlastworkdate AS [Leaver Last Work Date]
	, DATEDIFF(DAY, GETDATE(), leaverlastworkdate) AS [Days until leaving]
	--, * 
FROM red_dw.dbo.dim_employee
WHERE leaverlastworkdate>GETDATE()
AND DATEDIFF(DAY, GETDATE(), leaverlastworkdate)<=14

ORDER BY leaverlastworkdate

END
GO
