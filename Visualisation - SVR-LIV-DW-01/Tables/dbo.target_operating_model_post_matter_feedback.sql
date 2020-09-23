CREATE TABLE [dbo].[target_operating_model_post_matter_feedback]
(
[Post Matter Sample Date] [datetime] NOT NULL,
[Financial Quarter] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Client] [nvarchar] (255) COLLATE Latin1_General_CI_AS NULL,
[Speed of response] [decimal] (5, 2) NULL,
[Value] [decimal] (5, 2) NULL,
[Business understanding] [decimal] (5, 2) NULL,
[Sector knowledge] [decimal] (5, 2) NULL,
[Legal advice] [decimal] (5, 2) NULL,
[Commerciality] [decimal] (5, 2) NULL,
[Meet expectations] [decimal] (5, 2) NULL,
[Efficient] [decimal] (5, 2) NULL,
[Overall satisfaction] [decimal] (5, 2) NULL,
[Department] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[Office] [nvarchar] (200) COLLATE Latin1_General_CI_AS NULL,
[Financial Year] [char] (4) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
