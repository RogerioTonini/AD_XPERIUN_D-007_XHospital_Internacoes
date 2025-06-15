SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE TABLE [dbo].[T_Classe_Procedimento](
	[Cod_ClasseProc] [int] IDENTITY(1,1) NOT NULL,
	[Descr_ClasseProc] [nvarchar](15) NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Convenio](
	[Cod_Convenio] [int] IDENTITY(1,1) NOT NULL,
	[Descr_Convenio] [nvarchar](30) NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Faixa_Idade](
	[ID_Faixa] [int] IDENTITY(1,1) NOT NULL,
	[Descr_Faixa] [nvarchar](22) NOT NULL,
	[IdadeInicio] [int] NOT NULL,
	[IdadeFim] [int] NOT NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Internacao](
	[ID_Internacao] [int] IDENTITY(1,1) NOT NULL,
	[Num_Internacao] [int] NULL,
	[DataAdmissao] [date] NULL,
	[HoraAdmissao] [time](7) NULL,
	[DataAlta] [date] NULL,
	[HoraAlta] [time](7) NULL,
	[Cod_Paciente] [int] NULL,
	[Cod_Medico] [int] NULL,
	[Cod_Procedimento] [int] NULL,
	[Cod_TipoAcomodacao] [int] NULL,
	[Cod_TipoAlta] [int] NULL,
	[ValorDespesas] [money] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Medico](
	[Cod_Medico] [int] IDENTITY(1,1) NOT NULL,
	[Nome_Medico] [nvarchar](40) NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Paciente](
	[Cod_Paciente] [int] IDENTITY(1,1) NOT NULL,
	[Nome_Paciente] [nvarchar](40) NULL,
	[Sexo_Paciente] [varchar](1) NULL,
	[Cod_Convenio] [int] NULL,
	[Nome_Convenio] [nvarchar](30) NULL,
	[Data_Nascimento] [date] NULL,
	[ID_Faixa_Idade] [int] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Procedimento](
	[Cod_Procedimento] [int] IDENTITY(1,1) NOT NULL,
	[Descr_Procedimento] [nvarchar](50) NULL,
	[Cod_Classe] [int] NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Tipo_Acomodacao](
	[Cod_TipoAcomodacao] [int] IDENTITY(1,1) NOT NULL,
	[Descr_Acomodacao] [nvarchar](50) NOT NULL
) ON [PRIMARY]
GO
CREATE TABLE [dbo].[T_Tipo_Alta](
	[Cod_TipoAlta] [int] IDENTITY(1,1) NOT NULL,
	[Descr_Alta] [nvarchar](20) NOT NULL
) ON [PRIMARY]
GO