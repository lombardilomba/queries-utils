SELECT
       S.OSUSER,
       S.USERNAME,
       S.STATUS,
       A.SQL_ID,
       A.SQL_TEXT
FROM
       V$SESSION S
       JOIN V$SQLAREA A ON S.SQL_ID = A.SQL_ID
WHERE
       A.FIRST_LOAD_TIME >= '2019-06-04/19:10:00'
       AND UPPER(SQL_TEXT) LIKE UPPER('%proposta_debito_automatico%')
;