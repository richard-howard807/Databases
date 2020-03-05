CREATE TABLE [dbo].[fact_exceptions_update]
(
[source_system_id] [int] NULL,
[dim_matter_header_curr_key] [int] NOT NULL,
[case_id] [int] NULL,
[exceptionruleid] [int] NULL,
[datasetid] [int] NULL,
[exceptions_count] [int] NULL,
[dss_update_time] [datetime] NULL,
[critical] [bit] NULL,
[severity] [tinyint] NULL,
[includeinfirmwide] [bit] NULL,
[test] [bit] NULL,
[client_code] [char] (8) COLLATE Latin1_General_BIN NULL,
[matter_number] [char] (8) COLLATE Latin1_General_BIN NULL,
[dim_fed_hierarchy_history_key] [int] NULL,
[fed_code] [nvarchar] (50) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
