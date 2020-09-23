SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO




CREATE procedure [Config].[uspAuditError]
(
@AuditID int,
@ErrorCode varchar(100),
@ErrorDescription varchar(1000)
)
AS
UPDATE [Config].Audit SET AuditError=1 WHERE AuditID=@AuditID
INSERT INTO Config.AuditDetail(AuditID,AuditDetailDate,AuditErrorCode,AuditErrorDescription)
VALUES (@AuditID, GETDATE(), @ErrorCode, @ErrorDescription)




GO
