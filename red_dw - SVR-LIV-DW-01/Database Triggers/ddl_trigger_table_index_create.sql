SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO








CREATE TRIGGER [ddl_trigger_table_index_create]
ON DATABASE
FOR CREATE_INDEX, CREATE_FULLTEXT_INDEX, CREATE_SPATIAL_INDEX, CREATE_XML_INDEX, CREATE_TABLE
AS
SET NOCOUNT ON;

DECLARE @ddltriggerxml XML,
        @body NVARCHAR(2000),
        @subject NVARCHAR(1000);
SELECT @ddltriggerxml = EVENTDATA();

SELECT SYSUTCDATETIME() AS [Time],
       ORIGINAL_LOGIN() AS [Login],
       @ddltriggerxml.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(128)') AS [SchemaName],
       @ddltriggerxml.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'nvarchar(128)') AS [TableName],
       @ddltriggerxml.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(128)') AS [IndexName]
INTO #temp;

SET @subject = 'Alert: New index has been created on ' + DB_NAME() + ' on ' + @@SERVERNAME;

SELECT @body
    = N'A new index has been created on ' + @@SERVERNAME + ' database ' + DB_NAME() + CHAR(13) + CHAR(13) + CHAR(13)
        + 'Index name: ' + IndexName + CHAR(13) + CHAR(13) + 'Table name: ' + TableName + CHAR(13) + CHAR(13)
        + 'Schema name: ' + SchemaName + CHAR(13) + CHAR(13) + 'Created on: ' + CAST([Time] AS NVARCHAR(255))
        + CHAR(13) + CHAR(13) + 'Created by: ' + [Login] + CHAR(13)
FROM #temp;

IF @body NOT LIKE '%SBC\dwh01redservice%'
BEGIN
	IF @body NOT LIKE '%SBC\6237%'
	BEGIN
		IF @body NOT LIKE '%SBC\5752%'
		BEGIN
			EXEC [msdb].[dbo].[sp_send_dbmail] 
				@profile_name = 'DBMail',
				@recipients = 'Kevin.Hansen@weightmans.com;Richard.Howard@weightmans.com;Emily.Smith@weightmans.com;DBAAlerts@weightmans.com',
				@body = @body,
				@subject = @subject;
		END;
	END;
END;
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
