CREATE TABLE [dbo].[client_billing_addresses]
(
[client_number] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[client_name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NOT NULL,
[bill_contact_name] [nvarchar] (100) COLLATE Latin1_General_CI_AS NULL,
[net_bill_address_line_1] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[net_bill_address_line_2] [nvarchar] (50) COLLATE Latin1_General_CI_AS NOT NULL,
[net_bill_address_line_3] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[net_bill_address_line_4] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[net_bill_address_line_5] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[net_bill_address_post_code] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[contact_ids] [nvarchar] (400) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
