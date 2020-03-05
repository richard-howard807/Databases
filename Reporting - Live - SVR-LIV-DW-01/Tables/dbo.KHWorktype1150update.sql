CREATE TABLE [dbo].[KHWorktype1150update]
(
[source_system_id] [int] NOT NULL,
[fileid] [bigint] NULL,
[clid] [bigint] NULL,
[fileacccode] [nvarchar] (30) COLLATE Latin1_General_BIN NULL,
[fileno] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[fileguid] [char] (36) COLLATE Latin1_General_BIN NULL,
[filedesc] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[fileresponsibleid] [int] NULL,
[fileprincipleid] [int] NULL,
[filemanagerid] [int] NULL,
[dss_create_time] [datetime] NULL,
[dss_update_time] [datetime] NULL,
[filealertmessage] [nvarchar] (150) COLLATE Latin1_General_BIN NULL,
[fileclosed] [datetime] NULL,
[created] [datetime] NULL,
[brid] [int] NULL,
[filetype] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[fileextlinkid] [bigint] NULL,
[filedepartment] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filestatus] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[fileclosedby] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[filereviewdate] [datetime] NULL,
[fileneedexport] [bit] NULL,
[filenotes] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[fileallowexternal] [bit] NULL,
[fileexternalnotes] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[filesmsenabled] [bit] NULL,
[filepassword] [nvarchar] (25) COLLATE Latin1_General_BIN NULL,
[filepasswordhint] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[fileriskassesment] [bit] NULL,
[fileuicultureinfo] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[fileconflictnotes] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[fileconflictfound] [int] NULL,
[fileconflictcheck] [bit] NULL,
[fileteam] [int] NULL,
[fileoffline] [bit] NULL,
[filesource] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filesourcecontact] [bigint] NULL,
[filesourceuser] [int] NULL,
[filepreclibrary] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filefundcode] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filecurisocode] [char] (3) COLLATE Latin1_General_BIN NULL,
[filefundref] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[filewarningperc] [int] NULL,
[filecreditlimit] [money] NULL,
[fileoriginallimit] [money] NULL,
[filerateperunit] [money] NULL,
[filebanding] [int] NULL,
[fileagreementdate] [datetime] NULL,
[filequotesent] [bit] NULL,
[fileestimate] [money] NULL,
[filelastestimate] [money] NULL,
[filewip] [money] NULL,
[filebtd] [money] NULL,
[filecost] [money] NULL,
[filerestrictions] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[filescope] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[filecomplexity] [nvarchar] (1) COLLATE Latin1_General_BIN NULL,
[filelacategory] [tinyint] NULL,
[filefrancode] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filefundingextension] [bit] NULL,
[filefundingextreason] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[filearchivedate] [datetime] NULL,
[filearchiveref] [nvarchar] (50) COLLATE Latin1_General_BIN NULL,
[filedestroydate] [datetime] NULL,
[filestorageprovider] [smallint] NULL,
[filespssite] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[filespsdocws] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[createdby] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[updated] [datetime] NULL,
[updatedby] [varchar] (10) COLLATE Latin1_General_BIN NULL,
[fileextlinktxtid] [nvarchar] (20) COLLATE Latin1_General_BIN NULL,
[filesmsdocws] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[filenickname] [nvarchar] (100) COLLATE Latin1_General_BIN NULL,
[phid] [bigint] NULL,
[rowguid] [char] (36) COLLATE Latin1_General_BIN NULL,
[filealertlevel] [smallint] NULL,
[defaultassociateid] [bigint] NULL,
[filetimeactivitygroup] [varchar] (15) COLLATE Latin1_General_BIN NULL,
[filertf] [nvarchar] (255) COLLATE Latin1_General_BIN NULL,
[securityoptions] [bigint] NULL,
[filelastestimatedate] [datetime] NULL,
[filexml] [nvarchar] (max) COLLATE Latin1_General_BIN NULL,
[filee3eeffectivedatedneedupdate] [bit] NULL
) ON [PRIMARY]
GO
