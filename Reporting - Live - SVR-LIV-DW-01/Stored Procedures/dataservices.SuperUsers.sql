SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dataservices].[SuperUsers] --EXEC [dataservices].[SuperUsers] 'All','All','All'
	@Division NVARCHAR(500)
    ,@Department NVARCHAR (500)
	,@Team		NVARCHAR(500)

AS
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	IF @Division = 'All'  SET @Division = NULL
	IF @Department = 'All'  SET @Department = NULL
	IF @Team = 'All' SET @Team = NULL

SELECT   ISNULL(fed_code,displayemployeeid) AS fed_code,ISNULL(name,dim_employee.knownas + ' ' + surname) AS name
,hierarchylevel2hist AS Division
,hierarchylevel3hist AS [Department]
,hierarchylevel4hist AS [Team]
,worksforname AS [Works For]
FROM  red_dw.dbo.dim_employee
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history ON dim_employee.dim_employee_key=dim_fed_hierarchy_history.dim_employee_key AND dss_current_flag='Y' AND (latest_hierarchy_flag='Y'  OR displayemployeeid IN ('3826','1756','1788'))
WHERE (ISNULL(role_responsibility_1,'')='Super User' OR ISNULL(role_responsibility_2,'')='Super User')
AND hierarchylevel2hist=ISNULL(@Division,hierarchylevel2hist)
AND hierarchylevel3hist=ISNULL(@Department,hierarchylevel3hist)
AND hierarchylevel4hist=ISNULL(@Team,hierarchylevel4hist)
ORDER BY hierarchylevel4hist




GO
