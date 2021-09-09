SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create PROCEDURE [dbo].[load_auditcomply_custom] 
(@FileName NVARCHAR(MAX)) AS 

DECLARE @sql NVARCHAR(MAX)

--DECLARE @FileName NVARCHAR(250)
--SET @FileName='C:\APIDataStaging\AuditComply\Files\Custom\Custom 1.json'
SET @sql =
'
DECLARE @JSON nvarchar(MAX)

SELECT @JSON = BulkColumn
FROM OPENROWSET 
(BULK '''+@FileName+''', SINGLE_NCLOB) 
AS j


INSERT INTO dbo.auditcomply_custom
SELECT data.id
     , data.created_at
     , data.name
     , data.status
     , data.schedule_id
     , data.updated_at
     , data.compliant
     , data.status_color
     , data.state
     , data.completed_at
     , data.closed_at
     , data.auditor auditor_email
     , data.closed_by closed_by_email
     , data.report
     , data.nc_breakdown
     , noncon.score
	--into dbo.auditcomply_custom
from OPENJSON (@JSON) 
WITH (	  id int
		, created_at nvarchar(30)
		, name nvarchar(max)
		, status nvarchar(250)
		, schedule_id int
		, updated_at nvarchar(30)
		, compliant bit
		, status_color varchar(30)
		, state varchar(250)
		, completed_at nvarchar(30)
		, closed_at nvarchar(30)
		, auditor nvarchar(250)
		, closed_by nvarchar(250)
		, report nvarchar(max)
		, nc_breakdown  nvarchar(max) as json
		) data

outer apply openjson( nc_breakdown, ''$'' ) 
	with ( 
			score int
			) noncon

--'
--SELECT @sql

EXECUTE sys.sp_executesql @sql
GO
