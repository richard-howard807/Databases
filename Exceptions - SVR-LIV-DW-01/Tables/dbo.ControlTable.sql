CREATE TABLE [dbo].[ControlTable]
(
[id] [int] NOT NULL IDENTITY(1, 1),
[ControlItem] [char] (25) COLLATE Latin1_General_BIN NULL,
[Value] [int] NULL
) ON [PRIMARY]
GO
