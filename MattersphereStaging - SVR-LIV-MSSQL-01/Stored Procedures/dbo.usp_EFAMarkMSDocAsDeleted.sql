SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[usp_EFAMarkMSDocAsDeleted]
(
	@DocID INT
	)
AS
BEGIN
	BEGIN TRY
	
		DECLARE	@TransactionCheck INT = @@TRANCOUNT
		,	@ErrorMessage VARCHAR(4000);
	
		IF @TransactionCheck = 0
			BEGIN TRAN [docdel];

		UPDATE [MS_PROD].[config].[dbDocument]
		SET [docDesc] = [docDesc] + ' - Deleted due to EFA error'
		,[docDeleted] = 1
		WHERE [docID] = @DocID
	  
		IF @TransactionCheck = 0
			AND @@TRANCOUNT > 0
			COMMIT TRAN [docdel];
	
	END TRY
	BEGIN CATCH
	
		IF @TransactionCheck = 0
			AND @@TRANCOUNT > 0
			ROLLBACK TRAN [docdel];
		
		THROW;
	
	END CATCH;
END
GO
GRANT EXECUTE ON  [dbo].[usp_EFAMarkMSDocAsDeleted] TO [SBC\SQL - XpertRule access SVR-LIV-MSSQ-01]
GO
