SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [Config].[uspAuditEnd]
(
@AuditID int,
@CountInserted int,
@CountChanged int,
@CountNew int,
@CountExpired int
)
AS
--update package row count, run time, end time and total row count
UPDATE [Config].Audit
SET 
AuditRowInserted = @CountInserted, 
AuditRowChanged = @CountChanged,
AuditRowNew = @CountNew,
AuditRowExpired = @CountExpired,
AuditEndTime =GETDATE(), 
AuditRunTime=DATEDIFF(millisecond ,AuditStartTime, GETDATE()) / 1000.00,
AuditTotalRowcount = case when COALESCE(AuditTable,'N/A') like '%N/A%'--master packages, non table related objects being audited
THEN 0 ELSE (SELECT sysind.rows FROM sysobjects sysob INNER JOIN sysindexes sysind on sysob.id=sysind.id WHERE sysind.indid<2 AND sysob.name = AuditTable) END 
WHERE AuditID=@AuditID




GO
