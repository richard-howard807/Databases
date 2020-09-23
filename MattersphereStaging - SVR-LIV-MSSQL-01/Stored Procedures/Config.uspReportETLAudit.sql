SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE procedure [Config].[uspReportETLAudit]
(
@MASTER_PACKAGE varchar(100)
)

--EXEC [Config].[uspReportETLAudit] '_MasterExtranetETL'
AS



select
t1.AuditID as PARENT_AUDIT_ID,
t1.AuditDate as PARENT_AUDIT_DATE,
t1.AuditPackage as PARENT_PACKAGE,
t1.AuditRunTime as PARENT_RUN_TIME,
t1.AuditStartTime as PARENT_START_TIME,
case when t1.AuditError is null then 'N' else 'Y' end as PARENT_AUDIT_ERROR,
t2.AuditDate as AUDIT_DATE,
t2.AuditID as AUDIT_ID,
COALESCE(t2.AuditPackage,'None Run') as AUDIT_PACKAGE,
COALESCE(t2.AuditTask,'None Run') as AUDIT_TASK,
t2.AuditTable as AUDIT_TABLE,
t2.AuditRunTime as AUDIT_RUN_TIME,
t2.AuditStartTime as AUDIT_START_TIME,
case when t2.AuditError is null then 'N' else 'Y' end as AUDIT_ERROR,
t2.AuditSource as AUDIT_SOURCE
from Config.AUDIT t1
left outer join Config.AUDIT t2
on t1.AuditID = t2.ParentAuditID
where t1.AuditPackage = @MASTER_PACKAGE and t1.ParentAuditID = 0
and t1.AuditDate > DATEADD(MONTH,-1,GETDATE())
order by t1.AUDITID desc, t2.AuditDate DESC
 
GO
