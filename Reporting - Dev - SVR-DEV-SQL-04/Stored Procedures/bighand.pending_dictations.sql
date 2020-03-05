SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Lucy Dickinson
-- Create date: 15/11/2017
-- Description:	A report for Chris Ball for pending dictations (Webby 272239)
--				Debated whether to open this up to all departments but decided against it
--				as there has been no other similar request.  May need to rethink in the future.
-- =============================================
CREATE PROCEDURE [bighand].[pending_dictations]
(
		@author_department VARCHAR(250)
)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		SELECT  AuthorDepartment Team
		, Author 
		, [LengthToSum] [Length] 
		, [Priority] 
		, [Title]
		, [State]
		,[LocaleCreated] [Created]

		FROM [SQL02SVR].[BigHand].[dbo].[BHV_REPORT_PENDING]

		WHERE AuthorDepartment = @author_department


END
GO
