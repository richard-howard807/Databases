CREATE TABLE [dbo].[legacy_bank_code_lookup]
(
[tr_bnkcod] [char] (4) COLLATE Latin1_General_BIN NOT NULL,
[tr_seqnum] [int] NOT NULL,
[tr_trrefn] [char] (8) COLLATE Latin1_General_BIN NOT NULL,
[tr_abbrv] [char] (3) COLLATE Latin1_General_BIN NULL
) ON [PRIMARY]
GO
