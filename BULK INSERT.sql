

--BULK INSERT 


BULK INSERT TABELA						--NOME DA TABELA QUE IRÁ RECEBER OS DADOS 
FROM 'CAMINHO DO ARQUIVO .CSV'			--CAMINHO
WITH(
	FORMAT = 'CSV',						--FORMATO DO ARQUIVO
	FIRSTROW = 2,						--INICIAR APARTIR DA SEGUNDA LINHA CASO TENHA COLUNAS NO ARQUICO CSV
	CODEPAGE = 65001,					-- CODIGO UTF8 PADRÃO ALFABETO BRASILEIRO
	FIELDTERMINATOR = ',',				--DELINITADOR DA COLUNA
	--FIELDQUOTE = '"',					--EXPLICAÇÃO LINK -> https://www.youtube.com/watch?v=hGLitbTScnw&t=945s
	ROWTERMINATOR = '\n'				--SINALIZADOR PARA FIM DA LINHA 
	);
