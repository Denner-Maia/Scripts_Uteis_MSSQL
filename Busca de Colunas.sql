--ESTA QUERY EXIBI TODAS AS TABELAS ONDE UMA DETERMINADA COLUNA EXISTE:


SELECT
	O.NAME AS TABELA,
	C.NAME AS COLUNA,
	T.NAME AS 'TIPO DOS DADOS',
	C.MAX_LENGTH AS TAMANHO
FROM SYS.ALL_OBJECTS O
    INNER JOIN SYS.ALL_COLUMNS C ON O.OBJECT_ID=C.OBJECT_ID
    INNER JOIN SYS.TYPES T ON C.USER_TYPE_ID=T.USER_TYPE_ID
WHERE O.TYPE='U'
        AND C.NAME = 'NOME DA COLUNA'
ORDER BY 1,2
GO