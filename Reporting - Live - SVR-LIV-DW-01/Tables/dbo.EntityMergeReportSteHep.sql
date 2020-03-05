CREATE TABLE [dbo].[EntityMergeReportSteHep]
(
[MS Entity Number] [bigint] NOT NULL,
[MS Entity Name] [nvarchar] (80) COLLATE Latin1_General_CI_AS NOT NULL,
[MS ContType] [nvarchar] (15) COLLATE Latin1_General_CI_AS NOT NULL,
[MS Client Number] [nvarchar] (12) COLLATE Latin1_General_CI_AS NULL,
[MS Client Name] [nvarchar] (80) COLLATE Latin1_General_CI_AS NULL,
[MS Default Site Address] [nvarchar] (4000) COLLATE Latin1_General_CI_AS NULL,
[MSaddLine1] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSaddLine2] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSaddLine3] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSaddLine4] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSaddLine5] [nvarchar] (50) COLLATE Latin1_General_CI_AS NULL,
[MSPostcode] [nvarchar] (15) COLLATE Latin1_General_CI_AS NULL,
[MS Entity Create Date] [datetime] NULL,
[MS Entity Last Modified Date] [datetime] NULL,
[MS Number of Matters (Open & Closed Matters)] [int] NOT NULL,
[MS Number of Site Links] [int] NOT NULL,
[MS Number of Contact Links] [int] NOT NULL,
[MS Number of Associate Links] [int] NOT NULL,
[MS Number of FED Entities] [int] NOT NULL,
[MS IS EMPR Link] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL,
[MS/3E Join Number] [int] NULL,
[3E Entity Number] [int] NULL,
[3E Entity Name] [nvarchar] (512) COLLATE Latin1_General_CI_AI NULL,
[3E ArchetypeCode] [nvarchar] (50) COLLATE Latin1_General_CI_AI NULL,
[3E Address formattedstring] [nvarchar] (1000) COLLATE Latin1_General_CI_AI NULL,
[3E Default Site Address] [nvarchar] (4000) COLLATE Latin1_General_CI_AI NULL,
[3EOrgName] [nvarchar] (255) COLLATE Latin1_General_CI_AI NULL,
[3EStreet] [nvarchar] (255) COLLATE Latin1_General_CI_AI NULL,
[3ECity] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[3EState] [nvarchar] (16) COLLATE Latin1_General_CI_AI NULL,
[3ECountry] [nvarchar] (8) COLLATE Latin1_General_CI_AI NULL,
[3EZipCode] [nvarchar] (20) COLLATE Latin1_General_CI_AI NULL,
[3ECounty] [nvarchar] (20) COLLATE Latin1_General_CI_AI NULL,
[3EAdditional1] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[3EAdditional2] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[3EAdditional3] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[3EAdditional4] [nvarchar] (64) COLLATE Latin1_General_CI_AI NULL,
[3E Country(ies)] [int] NOT NULL,
[3E Entity Created Date] [int] NULL,
[3E Entity Last Modified Date] [datetime] NULL,
[3E Number of Matters (Open & Closed Matters)] [int] NOT NULL,
[3E Number of Site Links] [int] NOT NULL,
[3E Number of Clients Links] [int] NOT NULL,
[3E Number of Payer Links] [int] NOT NULL,
[3E Number of Payee Links] [int] NOT NULL,
[3E Number of Vendor Links] [int] NOT NULL,
[3E Number of User Links] [int] NOT NULL,
[3E Number of Bank Links] [int] NOT NULL,
[Billings for clients in the last 3 yrs (Profit Costs)] [int] NULL,
[Interaction UCI] [int] NULL,
[existinInteraction] [varchar] (3) COLLATE Latin1_General_CI_AS NOT NULL
) ON [PRIMARY]
GO
