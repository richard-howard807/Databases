SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO











CREATE trigger [ddl_trigger_table_index_create]
on database
for create_index, CREATE_FULLTEXT_INDEX, CREATE_SPATIAL_INDEX, CREATE_XML_INDEX, create_table
as
set nocount on;

declare @ddltriggerxml xml,
        @body NVARCHAR(2000),
        @subject NVARCHAR(1000);
select @ddltriggerxml = eventdata();

select sysutcdatetime() as [Time],
       original_login() as [Login],
       @ddltriggerxml.value('(/EVENT_INSTANCE/SchemaName)[1]', 'nvarchar(128)') as [SchemaName],
       @ddltriggerxml.value('(/EVENT_INSTANCE/TargetObjectName)[1]', 'nvarchar(128)') as [TableName],
       @ddltriggerxml.value('(/EVENT_INSTANCE/ObjectName)[1]', 'nvarchar(128)') as [IndexName]
into #temp;

set @subject = 'Alert: New index has been created on ' + db_name() + ' on ' + @@SERVERNAME;

select @body
    = N'A new index has been created on ' + @@SERVERNAME + ' database ' + db_name() + char(13) + char(13) + char(13)
        + 'Index name: ' + IndexName + char(13) + char(13) + 'Table name: ' + TableName + char(13) + char(13)
        + 'Schema name: ' + SchemaName + char(13) + char(13) + 'Created on: ' + cast([Time] as NVARCHAR(255))
        + char(13) + char(13) + 'Created by: ' + [Login] + char(13)
from #temp;

if @body not like '%SBC\dwh01redservice%'
begin
	if @body not like '%SBC\6237%'
	begin
		if @body not like '%SBC\esmith01%'
			begin
			
						exec [msdb].[dbo].[sp_send_dbmail] 
							@profile_name = 'DBMail',
							@recipients = 'Kevin.Hansen@weightmans.com;Richard.Howard@weightmans.com;Emily.Smith@weightmans.com;jamie.bonner@weightmans.com;DBAAlerts@weightmans.com',
							@body = @body,
							@subject = @subject;
			
			end;
	end;
end;
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
ENABLE TRIGGER ddl_trigger_table_index_create ON DATABASE
GO
