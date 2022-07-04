SELECT NULL AS "ALBUNS OUVIDOS POR USUARIO MAIS VELHO QUE A DATA DE NASCIMENTO";
SELECT U.TAG, U.NOME, COALESCE(ALBUNS_OUVIDOS.QNT, 0) FROM USUARIO U LEFT JOIN 
(SELECT U.TAG, COUNT(U.NOME) AS QNT FROM
    (SELECT * FROM LISTA_PADRAO O 
        WHERE O.OUVIDOS = TRUE) O
    JOIN USUARIO U ON
        U.TAG = O.TAG_USUARIO
    JOIN ALBUM_LISTA AL ON
        AL.TAG_USUARIO = O.TAG_USUARIO AND AL.N_LISTA = O.N_LISTA
    JOIN ALBUM ALBUM_OUVIDO ON
        EXTRACT(YEAR FROM ALBUM_OUVIDO.ANO) < EXTRACT(YEAR FROM U.DATA_NASC) AND AL.ID_ALBUM = ALBUM_OUVIDO.ID_SPOTIFY 
    GROUP BY U.TAG, U.NOME
    ORDER BY U.TAG) ALBUNS_OUVIDOS ON
    U.TAG = ALBUNS_OUVIDOS.TAG;

SELECT NULL AS "Álbuns ouvidos e avaliados por artista de `ocramoi`";
SELECT ART.NOME, COUNT(ALBUM_OUVIDO.ID_SPOTIFY) AS QNT_ALBUNS_OUVIDOS, COUNT(ALBUM_AVALIADO.ID_ALBUM) AS QNT_ALBUNS_AVALIADOS FROM
    (SELECT * FROM LISTA_PADRAO O WHERE 
        O.TAG_USUARIO = 'ocramoi' AND O.OUVIDOS = TRUE) O
    JOIN ALBUM_LISTA AL ON
        AL.TAG_USUARIO = O.TAG_USUARIO AND AL.N_LISTA = O.N_LISTA
    JOIN ALBUM ALBUM_OUVIDO ON 
        AL.ID_ALBUM = ALBUM_OUVIDO.ID_SPOTIFY
    JOIN ALBUM_ARTISTA AA ON
        AA.ID_ALBUM = ALBUM_OUVIDO.ID_SPOTIFY
    JOIN ARTISTA ART ON
        ART.ID_SPOTIFY = AA.ID_ARTISTA
    LEFT JOIN AVALIACAO ALBUM_AVALIADO ON
        O.TAG_USUARIO = ALBUM_AVALIADO.TAG_USUARIO AND ALBUM_OUVIDO.ID_SPOTIFY = ALBUM_AVALIADO.ID_ALBUM
    GROUP BY (ART.NOME)
    ORDER BY (ART.NOME);

-- Quantidade de álbuns de um artista que um usuário já ouviu
SELECT U.TAG, A.NOME, COUNT(*) FROM 
	USUARIO U JOIN LISTA_PADRAO L
	    ON U.TAG = L.TAG_USUARIO AND L.OUVIDOS = TRUE
	JOIN ALBUM_LISTA AL ON 
	    AL.TAG_USUARIO = L.TAG_USUARIO AND L.N_LISTA = AL.N_LISTA
	JOIN ALBUM_ARTISTA AA
	    ON AL.ID_ALBUM = AA.ID_ALBUM
	JOIN ARTISTA A
	    ON AA.ID_ARTISTA = A.ID_SPOTIFY
	GROUP BY U.TAG, A.ID_SPOTIFY 
	ORDER BY U.TAG;

-- Quantidade de álbuns de um gênero que um usuário já ouviu
SELECT U.TAG, G.NOME, COUNT(*) FROM
    USUARIO U JOIN LISTA_PADRAO L ON
        U.TAG = L.TAG_USUARIO AND L.OUVIDOS = TRUE
    JOIN ALBUM_LISTA AL ON
	AL.TAG_USUARIO = L.TAG_USUARIO AND L.N_LISTA = AL.N_LISTA
    JOIN ALBUM_GENERO AG ON
        AG.ID_ALBUM = AL.ID_ALBUM
    JOIN GENERO G ON
        AG.ID_GENERO = G.ID_SPOTIFY
    GROUP BY U.TAG, G.NOME;

-- Consulta de quais álbuns de um achievement falta um usuário ouvir
SELECT A.NOME, A.ID_SPOTIFY FROM 
	(SELECT A.NOME, A.ID_SPOTIFY FROM 
		ALBUM A JOIN ACHIEVEMENT_POR_ALBUM AA ON 
		AA.ID_ALBUM = A.ID_SPOTIFY AND AA.NOME = 'Achieving Nirvana!') A
	EXCEPT
	(SELECT ALBUM_OUVIDO.NOME, ALBUM_OUVIDO.ID_SPOTIFY FROM 
		(SELECT * FROM LISTA_PADRAO O WHERE 
			O.TAG_USUARIO = 'ocramoi' AND O.OUVIDOS = TRUE) O
		    JOIN ALBUM_LISTA AL ON
			AL.TAG_USUARIO = O.TAG_USUARIO AND AL.N_LISTA = O.N_LISTA
		    JOIN ALBUM ALBUM_OUVIDO ON 
			AL.ID_ALBUM = ALBUM_OUVIDO.ID_SPOTIFY
		    JOIN ALBUM_ARTISTA AA ON
			AA.ID_ALBUM = ALBUM_OUVIDO.ID_SPOTIFY);

--- achievements por album que um usuario ainda n tem
SELECT Q.* FROM 
    (SELECT DISTINCT APA.NOME FROM ACHIEVEMENT_POR_ALBUM APA
        WHERE NOT EXISTS (
        (SELECT A.ID_ALBUM FROM ACHIEVEMENT_POR_ALBUM A WHERE A.NOME = APA.NOME)
        EXCEPT
        (SELECT AL.ID_ALBUM FROM ALBUM_LISTA AL WHERE AL.TAG_USUARIO = 'ocramoi' AND AL.N_LISTA = 1)
    )) Q
    EXCEPT
    (SELECT A.NOME FROM ACHIEVEMENT_USUARIO A
    JOIN ACHIEVEMENT_POR_ALBUM APA
        ON APA.NOME = A.NOME AND A.TAG_USUARIO = 'ocramoi');

--- Achievements por gênero que um usuario ainda n tem
SELECT Q.* FROM 
    (SELECT APG.NOME FROM ACHIEVEMENT_POR_GENERO APG
        JOIN (SELECT AG.ID_GENERO AS GENERO, COUNT(AG.ID_GENERO) AS QTD FROM ALBUM_LISTA AL
                JOIN ALBUM_GENERO AG 
                    ON AG.ID_ALBUM = AL.ID_ALBUM
                WHERE AL.N_LISTA=1 AND AL.TAG_USUARIO = 'ocramoi'
                GROUP BY AG.ID_GENERO) QPG
        ON QPG.GENERO = APG.ID_GENERO
        WHERE QPG.QTD >= APG.QUANTIDADE) AS Q
    EXCEPT
    (SELECT A.NOME FROM ACHIEVEMENT_USUARIO A
        JOIN ACHIEVEMENT_POR_GENERO APG
            ON APG.NOME = A.NOME AND A.TAG_USUARIO = 'ocramoi');
