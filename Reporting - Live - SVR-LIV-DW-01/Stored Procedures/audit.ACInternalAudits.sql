SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		Emily Smith
-- Create date: 2021-09-13
-- Description:	Data for Risk and Complaince to keep track of audits created on audit comply
-- =============================================
CREATE PROCEDURE [audit].[ACInternalAudits]

( @Template AS NVARCHAR(MAX)
, @AuditYear AS NVARCHAR(50)
)
AS
--DECLARE @Template AS NVARCHAR(MAX)
--, @AuditYear AS NVARCHAR(50)


DROP TABLE IF EXISTS #Template

SELECT ListValue  INTO #Template  FROM Reporting.dbo.[udt_TallySplit]('|', @Template)

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

--SET @Template='Claims Audit'
--SET @AuditYear='2021/2022'

SELECT auditee.hierarchylevel3hist AS [Department]
, auditee.hierarchylevel4hist AS [Team]
, data.*
 
FROM (
SELECT  name AS [Auditee Name]
	, auditeekey AS [Auditee key]
	, CASE WHEN position LIKE '%1%' THEN 1
	WHEN position LIKE '%2%' THEN 2
	WHEN position LIKE '%3%' THEN 3 END AS [Auditee Poistion]
	, [Client Code]
	, [Matter Number]
	, [Date]
	, [Status]
	, [Template]
	, [Auditor]
	, [Audit Year]
	, [Audit Quarter]
FROM (SELECT 
 dim_ac_audits.auditee_1_name AS [Auditee Name 1]
, dim_ac_audits.dim_auditee1_hierarchy_history_key AS [Auditee Key 1]
, dim_ac_audits.auditee_2_name AS [Auditee Name 2]
, dim_ac_audits.dim_auditee2_hierarchy_history_key AS [Auditee Key 2]
, dim_ac_audits.auditee_3_name AS [Auditee Name 3]
, dim_ac_audits.dim_auditee3_hierarchy_history_key AS [Auditee Key 3]
, dim_ac_audits.client_code AS [Client Code]
, dim_ac_audits.matter_number AS [Matter Number]
, dim_ac_audits.completed_at AS [Date]
, dim_ac_audits.status AS [Status]
, dim_ac_audit_type.name AS [Template]
, auditor.name AS [Auditor]
,CAST((SELECT dim_date.fin_year
  FROM red_dw..dim_date WITH(NOLOCK)
  WHERE dim_date.calendar_date = CAST(completed_at AS DATE)
  )-1 AS VARCHAR)+'/'+CAST((SELECT dim_date.fin_year
  FROM red_dw..dim_date WITH(NOLOCK)
  WHERE dim_date.calendar_date = CAST(completed_at AS DATE)
  ) AS VARCHAR) AS [Audit Year]
,'Q'+CAST((SELECT dim_date.fin_quarter_no
  FROM red_dw..dim_date WITH(NOLOCK)
  WHERE dim_date.calendar_date = CAST(completed_at AS DATE)
  ) AS VARCHAR) AS [Audit Quarter]

--SELECT *
from red_dw.dbo.dim_ac_audits
LEFT OUTER JOIN red_dw.dbo.dim_ac_audit_type
ON dim_ac_audit_type.dim_ac_audit_type_key = dim_ac_audits.dim_ac_audit_type_key
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS [auditor]
ON auditor.dim_fed_hierarchy_history_key=dim_ac_audits.dim_auditor_fed_hierarchy_history_key

INNER JOIN #Template AS Template ON Template.ListValue COLLATE DATABASE_DEFAULT = dim_ac_audit_type.name COLLATE DATABASE_DEFAULT

WHERE  dim_ac_audits.created_at >='2021-09-01'
) src

UNPIVOT (name FOR position IN ([Auditee Name 1], [Auditee Name 2], [Auditee Name 3]))pvt1
UNPIVOT (auditeekey FOR akey IN ([Auditee Key 1], [Auditee Key 2], [Auditee Key 3]))pvt2

WHERE  RIGHT(akey,1)=RIGHT(position,1)

) AS data
LEFT OUTER JOIN red_dw.dbo.dim_fed_hierarchy_history AS auditee
ON auditee.dim_fed_hierarchy_history_key=data.[Auditee key]
	



END
GO
