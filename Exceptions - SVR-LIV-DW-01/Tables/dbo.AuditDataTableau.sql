CREATE TABLE [dbo].[AuditDataTableau]
(
[employeeid] [char] (36) COLLATE Latin1_General_BIN NULL,
[Client Code] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[Matter Number] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[Client/Matter Number] [nvarchar] (121) COLLATE Latin1_General_BIN NULL,
[Date] [datetime] NULL,
[Status] [nvarchar] (60) COLLATE Latin1_General_BIN NULL,
[Template] [nvarchar] (200) COLLATE Latin1_General_BIN NULL,
[Auditor] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[fin_quarter] [varchar] (7) COLLATE Latin1_General_BIN NULL,
[fin_quarter_no] [int] NULL,
[fin_year] [int] NULL,
[question_id] [bigint] NULL,
[section_id] [int] NULL,
[subsection_id] [int] NULL,
[question_text] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL,
[observation] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[recommendation] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL,
[response] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL,
[audit_id] [int] NULL,
[Division] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Department] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[Team] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[display_name] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Auditee key] [int] NOT NULL,
[Auditee_Emp_key_1] [char] (36) COLLATE Latin1_General_BIN NOT NULL,
[audit_observations] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[audit_recommendations] [varchar] (max) COLLATE Latin1_General_BIN NULL,
[score] [int] NULL,
[Auditee Name 2] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Auditee Name 3] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[positive_feedback_details] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[complaint_details] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[matter_description] [nvarchar] (2000) COLLATE Latin1_General_BIN NULL,
[Fee Earner Job Title] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[Fee Earner] [nvarchar] (100) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
