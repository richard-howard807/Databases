CREATE TABLE [dbo].[catalina_post_snapshot]
(
[ms_ref] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[zurich_claim_ref] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[docID] [bigint] NULL,
[doc_received_date] [date] NULL,
[doc_allocated_date] [date] NULL,
[doc_completion_date] [date] NULL,
[outstanding_count] [int] NULL,
[response_time] [int] NULL,
[prior_weeks_response_time] [int] NULL,
[days_post_outstanding] [int] NULL,
[tskActive] [bit] NULL,
[docDesc] [nvarchar] (150) COLLATE Latin1_General_CI_AS NULL,
[tskDesc] [nvarchar] (150) COLLATE Latin1_General_CI_AS NULL,
[report_week] [date] NULL,
[report_week_no] [int] NULL,
[report_tab] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[post_split_by_age] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[outstanding_post] [nvarchar] (10) COLLATE Latin1_General_CI_AS NULL,
[update_time] [datetime] NULL,
[new_document] [int] NULL,
[catalina_claim_ref] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
