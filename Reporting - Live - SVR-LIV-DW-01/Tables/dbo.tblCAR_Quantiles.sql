CREATE TABLE [dbo].[tblCAR_Quantiles]
(
[year] [int] NULL,
[work_type_group] [varchar] (255) COLLATE Latin1_General_CI_AS NULL,
[quant_25] [float] NULL,
[quant_50] [float] NULL,
[quant_75] [float] NULL,
[number_of_cases] [int] NULL
) ON [PRIMARY]
GO
