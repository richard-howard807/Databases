CREATE TABLE [dbo].[MSStatus]
(
[StatusID] [int] NOT NULL,
[StatusDescription] [varchar] (50) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
ALTER TABLE [dbo].[MSStatus] ADD CONSTRAINT [PK_StatusID] PRIMARY KEY CLUSTERED  ([StatusID]) ON [PRIMARY]
GO
