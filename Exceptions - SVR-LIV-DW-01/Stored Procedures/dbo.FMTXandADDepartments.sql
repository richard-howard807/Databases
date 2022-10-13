SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith/Richard Howard
-- Create date: 2021-02-05
-- Description:	#84694 FMTX Department/Active Directory Report Request, checks the departments in flow matrix against the valid departments in cascade and flags any that are no longer active 
-- and checks the users are also in the correct team in flow matrix and flags any that aren't
-- =============================================
CREATE PROCEDURE [dbo].[FMTXandADDepartments]

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

  
WITH FlowMatrix_Groups AS (
		SELECT Groups.GroupName, Users.username, Users.fullname
		FROM [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].Users
		INNER JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].GroupMembership ON GroupMembership.user_id = Users.user_id
		INNER JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].Groups ON GroupMembership.group_id = Groups.GroupId
		INNER JOIN [SVR-LIV-3PTY-01].[FlowMatrix].[dbo].GroupParents ON GroupParents.child_group_id = GroupMembership.group_id 
		WHERE [enabled] = 1 -- Active User
		AND GroupParents.parent_group_id = 33 -- Department Group
		--and GroupMembership.user_id = 4848
		)


	,Cascade_Avtive_Teams AS (	
		SELECT ds_sh_valid_hierarchy_x.hierarchylevel4
		FROM red_dw.dbo.ds_sh_valid_hierarchy_x
		WHERE ds_sh_valid_hierarchy_x.disabled = 0
		AND ds_sh_valid_hierarchy_x.dss_current_flag= 'Y'
		AND ds_sh_valid_hierarchy_x.hierarchylevel4 IS NOT null
		)

	,Cascade_Team_Membership AS (
	SELECT dim_fed_hierarchy_history.hierarchylevel4hist, dim_fed_hierarchy_history.fed_code, dim_fed_hierarchy_history.windowsusername
	FROM red_dw.dbo.dim_fed_hierarchy_history
	WHERE dim_fed_hierarchy_history.dss_current_flag = 'Y'
	AND dim_fed_hierarchy_history.activeud = 1
	)


	
SELECT FlowMatrix_Groups.GroupName AS [Group Name], FlowMatrix_Groups.username AS [Username], FlowMatrix_Groups.fullname AS [Name],
	IIF(Cascade_Avtive_Teams.hierarchylevel4 IS NOT NULL, 'True', 'False')  [Active Team],
	IIF(Cascade_Team_Membership.hierarchylevel4hist IS NOT NULL, 'True', 'False')  [Active Team Membership]
FROM FlowMatrix_Groups
LEFT OUTER JOIN Cascade_Avtive_Teams ON Cascade_Avtive_Teams.hierarchylevel4 = FlowMatrix_Groups.GroupName COLLATE Latin1_General_CI_AS 
LEFT OUTER JOIN Cascade_Team_Membership ON FlowMatrix_Groups.username = Cascade_Team_Membership.windowsusername  COLLATE Latin1_General_CI_AS 
										AND FlowMatrix_Groups.GroupName = Cascade_Team_Membership.hierarchylevel4hist  COLLATE Latin1_General_CI_AS

WHERE IIF(Cascade_Avtive_Teams.hierarchylevel4 IS NOT NULL, 'True', 'False') = 'False'
   OR IIF(Cascade_Team_Membership.hierarchylevel4hist IS NOT NULL, 'True', 'False') = 'False'
 
 ORDER BY [Group Name]

END
GO
