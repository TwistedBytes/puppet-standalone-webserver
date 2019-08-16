#!/bin/bash

CHARSET=utf8mb4

mysql -s -r -N -e 'show databases;' | while read dbname; do
  echo $dbname | grep -q -e '_schema$' -e '^mysql$'

  if [ $? == 0 ]; then
    continue
  fi
  echo db: $dbname

  mysql -s -r -N -e 'show tables;' $dbname  | while read table; do
    echo table: $table
    mysql -s -r -N -e "ALTER TABLE ${table} CONVERT TO CHARACTER SET ${CHARSET} COLLATE ${CHARSET}_unicode_ci;" $dbname
  done
  # SELECT TABLE_SCHEMA, TABLE_NAME, COLUMN_NAME, COLUMN_TYPE,COLLATION_NAME,CHARACTER_SET_NAME FROM INFORMATION_SCHEMA.COLUMNS where COLLATION_NAME is not NULL and COLLATION_NAME like "%latin%";
  mysql -s -r -N -e "SELECT TABLE_NAME, COLUMN_NAME, COLUMN_TYPE,COLLATION_NAME,CHARACTER_SET_NAME FROM INFORMATION_SCHEMA.COLUMNS where TABLE_SCHEMA='${dbname}' and COLLATION_NAME is not NULL;" | while read TABLE_NAME COLUMN_NAME COLUMN_TYPE COLLATION_NAME CHARACTER_SET_NAME; do
    # echo $TABLE_NAME $COLUMN_NAME $COLUMN_TYPE $COLLATION_NAME $CHARACTER_SET_NAME
    mysql -s -r -N -e "ALTER TABLE ${TABLE_NAME} CHANGE ${COLUMN_NAME} ${COLUMN_NAME} ${COLUMN_TYPE} CHARACTER SET ${CHARSET} COLLATE ${CHARSET}_unicode_ci;" $dbname
  done


  mysql -s -r -N -e "ALTER DATABASE ${dbname} CHARACTER SET = ${CHARSET} COLLATE = ${CHARSET}_unicode_ci;"

done
mysqlcheck --auto-repair --optimize --all-databases
