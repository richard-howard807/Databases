CREATE TABLE [dbo].[client_billing_addresses]
(
[Client_Number] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Client_Name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Bill_Contact_Name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Line_1] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Line_2] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Line_3] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Line_4] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Line_5] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Net_Bill_Address_Post_Code] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[Contact_IDs] [nvarchar] (400) COLLATE Latin1_General_CI_AS NULL
) ON [PRIMARY]
GO
