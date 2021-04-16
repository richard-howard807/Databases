CREATE TABLE [dbo].[CaptiaInsuredUpdate241120]
(
[assocID] [bigint] NOT NULL,
[fileID] [bigint] NOT NULL,
[assocType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[contName] [nvarchar] (80) COLLATE Latin1_General_CI_AS NOT NULL,
[addLine1] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[addPostcode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[contID] [bigint] NOT NULL
) ON [PRIMARY]
GO
