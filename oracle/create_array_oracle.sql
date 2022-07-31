declare
  TYPE meu_tipo_array IS TABLE OF VARCHAR2(500);
  meu_array meu_tipo_array;

begin  
    SELECT REGEXP_SUBSTR('A#;B#;C#;D', '[^#;]+', 1, LEVEL) AS data
           BULK COLLECT into meu_array
      FROM dual 
    CONNECT BY REGEXP_SUBSTR('A#;B#;C#;D', '[^#;]+', 1, LEVEL) IS NOT NULL;
    DBMS_OUTPUT.PUT_LINE(meu_array(4));
end;