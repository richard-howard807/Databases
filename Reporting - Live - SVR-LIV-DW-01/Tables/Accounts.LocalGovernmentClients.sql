CREATE TABLE [Accounts].[LocalGovernmentClients]
(
[Client] [char] (8) COLLATE Latin1_General_BIN NULL,
[Matter] [char] (8) COLLATE Latin1_General_BIN NULL,
[SectorName] [varchar] (60) COLLATE Latin1_General_BIN NULL,
[Ranking] [bigint] NULL
) ON [PRIMARY]
GO
GRANT DELETE ON  [Accounts].[LocalGovernmentClients] TO [SBC\DWH_SSASAdmin]
GO
GRANT INSERT ON  [Accounts].[LocalGovernmentClients] TO [SBC\DWH_SSASAdmin]
GO
GRANT SELECT ON  [Accounts].[LocalGovernmentClients] TO [SBC\DWH_SSASAdmin]
GO
GRANT UPDATE ON  [Accounts].[LocalGovernmentClients] TO [SBC\DWH_SSASAdmin]
GO
