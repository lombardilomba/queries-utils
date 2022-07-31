DECLARE
  SOURCE_CODE   CLOB;
  DB_OWNER      VARCHAR2(100) := 'SEU_USER';    -- USUARIO QUE RECEBERÁ O OBJETO
  OBJECT_NAME   VARCHAR2(100) := 'NOME_OBJETO'; -- OBJETO A SER COPIADO
  OBJECT_OWNER  VARCHAR2(100) := 'SUPERVISOR';  -- DONO DO OBJETO A SER COPIADO
  RECOMPILAR_OBJETOS BOOLEAN  := FALSE;
  
BEGIN
  
     SOURCE_CODE := '';
     
      -- COPIA OBJETO DE OUTRO OWNER
      FOR OBJ IN (
                   SELECT
                          NAME,
                          TYPE,
                          TEXT,
                          LINE,
                          COUNT(1) OVER (PARTITION BY NAME, TYPE) TOTAL_LINHAS
                          /*
                            *CASO ESTEJA COPIANDO DE OUTRO USUARIO
                             UTILIZAR: ALL_SOURCE
                            *CASO NAO QUEIRA COPIAR DE PRODUÇÃO, REMOVER O DB_LINK
                          */
                     FROM DBA_SOURCE@PROD_LOMBARDI P       
                    WHERE                                  
                          P.OWNER    = UPPER(OBJECT_OWNER)
                          AND P.NAME = UPPER(OBJECT_NAME)  -- CASO QUEIRA VARIOS OBJETOS USAR A LINHA ABAIXO
                          --AND P.NAME IN (
                 ORDER BY NAME, TYPE, LINE
               )
      LOOP
        BEGIN
          OBJECT_NAME := OBJ.NAME;

          IF( OBJ.LINE = 1) THEN
              SOURCE_CODE := '';
              OBJ.TEXT := REPLACE(REPLACE(UPPER('CREATE OR REPLACE ' || OBJ.TEXT), OBJ.NAME, DB_OWNER || '.' || OBJ.NAME),'"','');
          END IF;
        
          SOURCE_CODE := SOURCE_CODE || OBJ.TEXT;
        
          IF OBJ.LINE = OBJ.TOTAL_LINHAS  THEN
             EXECUTE IMMEDIATE SOURCE_CODE;
             SOURCE_CODE := '';
          END IF;
          
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERR: ' || OBJECT_NAME);
        END;
         
      END LOOP;
    
    -- RECOMPILA OBJETOS INVALIDOS DO SEU OWNER
    IF RECOMPILAR_OBJETOS = TRUE THEN  
      FOR INVLD_OBJ IN (
                   SELECT DISTINCT
                          CASE WHEN OBJECT_TYPE = 'PACKAGE' OR OBJECT_TYPE = 'PACKAGE BODY' THEN
                            'ALTER PACKAGE ' || OBJECT_NAME || ' COMPILE BODY'
                          ELSE
                            'ALTER ' || OBJECT_TYPE || ' ' || OBJECT_NAME || ' COMPILE'
                           END  INSTRUCTION,
                          OBJECT_NAME
                     FROM ALL_OBJECTS
                    WHERE OWNER = DB_OWNER
                      AND STATUS = 'INVALID'
                 )
      LOOP
        BEGIN
          EXECUTE IMMEDIATE INVLD_OBJ.INSTRUCTION;
        EXCEPTION WHEN OTHERS THEN
          DBMS_OUTPUT.PUT_LINE('ERR: ' || INVLD_OBJ.OBJECT_NAME);
        END;
      END LOOP;
    END IF;  
      
END;