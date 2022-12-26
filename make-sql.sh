#!/usr/bin/env bash 
set -eu -o pipefail

db_name=capp.sqlite

rm -f $db_name
rm -rf tmp

mkdir -p tmp

filename="./data/caries-22-12-26.csv"
countries_data="./data/countries.json"

# Column names are case-insensitive
sed "1s/,dt,/,primary_dt,/;\
  1s/,mt,/,primary_mt,/;\
  1s/,ft,/,primary_ft,/;\
  1s/,dmft,/,primary_dmft,/" $filename >> tmp/caries.csv

#########################
# Download countries_data
if ! [ -f $countries_data ]; then
  curl "https://raw.githubusercontent.com/lukes/ISO-3166-Countries-with-Regional-Codes/master/all/all.json?raw=true"\
    -o $countries_data
fi

# Generate "countries" table
sqlite-utils insert $db_name countries $countries_data --pk alpha-2

# Promote 2 letters country name to primary key
sqlite-utils $db_name 'ALTER TABLE countries RENAME COLUMN "alpha-2" to id;'

# Insert caries data
sqlite-utils insert $db_name caries \
    tmp/caries.csv --csv\
     --detect-types
# Match and extract the country using `alpha-2`
sqlite-utils extract $db_name caries "Country Code" \
    --table countries \
    --fk-column country_code \
    --rename "Country Code" id
sqlite-utils $db_name 'ALTER TABLE caries DROP "Country";'

# Empty value from CSV got injected as empty string 
# We fix this by replacing empty string with NULL on each unknown columns
columns=$(sqlite-utils tables capp.sqlite --columns | jq -c '.[] | select( .table | contains("caries")) | .columns[]')
echo "$columns" | while read -r col; do 
  if [[ $col != "\"country_code\"" ]]; 
  then
    sql="UPDATE \"caries\" SET $col = NULL WHERE $col = \"\"";
    eval "sqlite-utils $db_name '$sql'"
  fi
done

sqlite-utils $db_name "CREATE INDEX dmft_age_from_to_idx ON caries ([DMFT From], [Age from], [Age to])";
sqlite-utils $db_name "CREATE INDEX year_from_idx ON caries ([Year from])";

sqlite-utils optimize $db_name
