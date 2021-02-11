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
	, payrollid AS [Payroll ID]
	, hierarchylevel2hist AS [Division]
	, dim_fed_hierarchy_history.hierarchylevel3hist AS [Department]
	, dim_fed_hierarchy_history.hierarchylevel4hist AS [Team]
	, dim_employee.jobtitle AS [Job Title]
	, HSD.HSD AS [HSD]
	, worksforname AS [Team Manager]
	, leaverlastworkdate AS [Leaver Last Work Date]
	, DATEDIFF(DAY, GETDATE(), leaverlastworkdate) AS [Days until leaving]
	, Workstation AS [Asset]
	, AssetModel AS [Asset Model]
	,locationidud
	--, * 
FROM red_dw.dbo.dim_employee
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history
ON dim_fed_hierarchy_history.employeeid = dim_employee.employeeid
AND GETDATE() BETWEEN dss_start_date AND dss_end_date
AND dss_current_flag='Y'
AND activeud=1

LEFT OUTER JOIN (SELECT hierarchylevel3hist
						   , dim_fed_hierarchy_history.name AS [HSD]
					FROM red_dw.dbo.dim_fed_hierarchy_history
					WHERE dim_fed_hierarchy_history.windowsusername IS NOT NULL
						   AND dim_fed_hierarchy_history.dss_current_flag = 'Y'
						   AND dim_fed_hierarchy_history.activeud = 1
						   AND dim_fed_hierarchy_history.management_role_one = 'HoSD') AS [HSD] 
ON HSD.hierarchylevel3hist=dim_fed_hierarchy_history.hierarchylevel3hist

LEFT OUTER JOIN (
SELECT 
    SystemInfo.WORKSTATIONNAME AS Workstation,
    SystemInfo.MODEL AS AssetModel,
    SystemInfo.MANUFACTURER AS Manufacturer,
    SystemInfo.LOGGEDUSER AS LastLoggedInUser,
    OsInfo.OSNAME AS OS,
    DepartmentDefinition.DEPTNAME AS Department,
    AaaUser.USER_ID AS AllocatedTo,
    AaaUser.FIRST_NAME AS [User],
    ResourceState.DISPLAYSTATE AS AssetState,
    SDOrganization.NAME AS Site,
   SDUser.USERID
FROM [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.WorkstationCI WITH (NOLOCK)
    INNER JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.CI WITH (NOLOCK)
        ON (
               (WorkstationCI.CIID = CI.CIID)
               AND
               (
                   (
                       (WorkstationCI.CIID = CI.CIID)
                       AND (CI.HELPDESKID = 1)
                   )
                   AND (CI.HELPDESKID = 1)
               )
           )
    INNER JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.Resources WITH (NOLOCK)
        ON CI.CIID = Resources.CIID
    
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.BaseElement WITH (NOLOCK)
        ON CI.CIID = BaseElement.CIID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ImpactDefinition ImpactDefinition_IMPACTID WITH (NOLOCK)
        ON BaseElement.IMPACTID = ImpactDefinition_IMPACTID.IMPACTID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.SystemInfo WITH (NOLOCK)
        ON Resources.RESOURCEID = SystemInfo.WORKSTATIONID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.OsInfo WITH (NOLOCK)
        ON (
               (Resources.RESOURCEID = OsInfo.WORKSTATIONID)
               AND
               (
                   (
                       (Resources.RESOURCEID = OsInfo.WORKSTATIONID)
                       AND
                       (
                           (OsInfo.WORKSTATIONID >= 1)
                           AND (OsInfo.WORKSTATIONID <= 100000000)
                       )
                   )
                   AND
                   (
                       (OsInfo.WORKSTATIONID >= 1)
                       AND (OsInfo.WORKSTATIONID <= 100000000)
                   )
               )
           )
    
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ResourceOwner WITH (NOLOCK)
        ON Resources.RESOURCEID = ResourceOwner.RESOURCEID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ComponentDefinitionLaptop WITH (NOLOCK)
        ON (
               (Resources.COMPONENTID = ComponentDefinitionLaptop.COMPONENTID)
               AND
               (
                   (
                       (Resources.COMPONENTID = ComponentDefinitionLaptop.COMPONENTID)
                       AND
                       (
                           (ComponentDefinitionLaptop.COMPONENTID >= 1)
                           AND (ComponentDefinitionLaptop.COMPONENTID <= 100000000)
                       )
                   )
                   AND
                   (
                       (ComponentDefinitionLaptop.COMPONENTID >= 1)
                       AND (ComponentDefinitionLaptop.COMPONENTID <= 100000000)
                   )
               )
           )
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ResourceAssociation WITH (NOLOCK)
        ON ResourceOwner.RESOURCEOWNERID = ResourceAssociation.RESOURCEOWNERID

    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.AaaUser WITH (NOLOCK)
        ON ResourceOwner.USERID = AaaUser.USER_ID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.SDUser WITH (NOLOCK)
        ON (
               (AaaUser.USER_ID = SDUser.USERID)
               AND
               (
                   (
                       (AaaUser.USER_ID = SDUser.USERID)
                       AND
                       (
                           (
                               (SDUser.USERID IN (
                                                         SELECT PortalUsers.USERID
                                                         FROM [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.PortalUsers
                                                         WHERE (PortalUsers.HELPDESKID = 1)
                                                     )
                               )
                               OR (SDUser.USERID = 1)
                           )
                           OR (SDUser.USERID IS NULL)
                       )
                   )
                   AND
                   (
                       (
                           (SDUser.USERID IN (
                                                     SELECT PortalUsers.USERID
                                                     FROM [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.PortalUsers
                                                     WHERE (PortalUsers.HELPDESKID = 1)
                                                 )
                           )
                           OR (SDUser.USERID = 1)
                       )
                       OR (SDUser.USERID IS NULL)
                   )
               )
           )
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.DepartmentDefinition WITH (NOLOCK)
        ON ResourceOwner.DEPTID = DepartmentDefinition.DEPTID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ResourceLocation WITH (NOLOCK)
        ON Resources.RESOURCEID = ResourceLocation.RESOURCEID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.SiteDefinition WITH (NOLOCK)
        ON ResourceLocation.SITEID = SiteDefinition.SITEID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.SDOrganization WITH (NOLOCK)
        ON SiteDefinition.SITEID = SDOrganization.ORG_ID
    LEFT JOIN [SVR-LIV-3PTY-01].ServiceDeskPlus.dbo.ResourceState WITH (NOLOCK)
        ON Resources.RESOURCESTATEID = ResourceState.RESOURCESTATEID

WHERE (
          (
              (WorkstationCI.CIID >= 1)
              AND (WorkstationCI.CIID <= 100000000)
          )
          AND
          (
              (ComponentDefinitionLaptop.ISLAPTOP = 1)
              AND (SystemInfo.ISSERVER = 0)
          )
      )
	  --AND SystemInfo.WORKSTATIONNAME LIKE 'l08347%'
 )AS [Asset] ON [Asset].[User]=name COLLATE DATABASE_DEFAULT

WHERE leaverlastworkdate>GETDATE()
AND DATEDIFF(DAY, GETDATE(), leaverlastworkdate)<=14


ORDER BY leaverlastworkdate

END


GO
