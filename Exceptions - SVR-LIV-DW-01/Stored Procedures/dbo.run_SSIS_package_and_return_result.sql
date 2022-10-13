SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


CREATE PROC [dbo].[run_SSIS_package_and_return_result] @package_name VARCHAR(60)

as

SET NOCOUNT ON

-- Proc calles a SSIS package and returns execution results
-- Used to allow Finanace to upload Excel files for Budgets/Cost Rates etc.
-- RH - 20/04/2020 

	DECLARE -- @package_name VARCHAR(60) = 'Upload Budget.dtsx',
			@folder VARCHAR(60)='',
			@project VARCHAR(60) ='',
			@execution_id BIGINT,
			@output_execution_id BIGINT
	
-- Set Package Variable 



	SELECT @folder = folders.name, 
		   @project = projects.NAME
	FROM SSISDB.CATALOG.packages
	INNER JOIN SSISDB.CATALOG.projects ON projects.project_id = packages.project_id
	INNER JOIN SSISDB.CATALOG.folders ON folders.folder_id = projects.folder_id
	WHERE packages.name = @package_name
	
	--	PRINT @package_name
	--	PRINT @project
	--	PRINT @folder

	
-- Run SSIS Package

    EXEC SSISDB.catalog.create_execution @folder_name = @folder,
                                         @project_name = @project,
                                         @package_name = @package_name,
										 @use32bitruntime = 1,
                                         @execution_id = @execution_id OUTPUT;
										 
    EXEC SSISDB.catalog.start_execution @execution_id;
    SET @output_execution_id = @execution_id;
	
--	PRINT @output_execution_id


-- Wait for it to finish
--	(SELECT status FROM SSISDB.CATALOG.executions WHERE execution_id = @output_execution_id)

WHILE 	(SELECT status FROM SSISDB.CATALOG.executions WHERE execution_id = @output_execution_id) IN (2,5)
	
	BEGIN
	  
	  WAITFOR DELAY '00:00:01';
	--  PRINT 'WAITING'

	END


-- Get results of execution

 SELECT EX.package_name,
	O.operation_id EXECUTION_ID
    ,CASE EX.STATUS
        WHEN 4 THEN 'Package Failed'
        WHEN 7 THEN CASE EM.message_type 
            WHEN 120 THEN 'Package Failed' 
            WHEN 130 THEN 'Package Failed' ELSE 'Package Succeeded' END
        END AS STATUS
		    , STRING_AGG(OM.message, ' <br> ') ERROR_MESSAGE,
			MAX(OM.message_time) run_time
	-- select *
FROM SSISDB.CATALOG.operation_messages AS OM
INNER JOIN SSISDB.CATALOG.operations AS O ON O.operation_id = OM.operation_id
INNER JOIN SSISDB.CATALOG.executions AS EX ON O.operation_id = EX.execution_id
LEFT OUTER JOIN (VALUES (- 1,'Unknown'),(120,'Error'),(110,'Warning'),(130,'TaskFailed')) EM (message_type, message_desc) ON EM.message_type = OM.message_type
WHERE O.operation_id = @output_execution_id
GROUP BY  EX.package_name,
	O.operation_id 
    ,CASE EX.STATUS
        WHEN 4 THEN 'Package Failed'
        WHEN 7 THEN CASE EM.message_type 
            WHEN 120 THEN 'Package Failed' 
            WHEN 130 THEN 'Package Failed' ELSE 'Package Succeeded'END
        END 





GO
