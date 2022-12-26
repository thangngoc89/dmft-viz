# Dental caries data visualization project

Data from [Oral Health Country/Area Profile Project](https://capp.mau.se/download)

## Process

1. Download raw data (in `csv` format) from [download page](https://capp.mau.se/download).
  Unfortunately, this step is manual at the moment and the data wasn't being updated that
  often.
2. Turn CSV into SQLite3 format using `sqlite-utils`
3. Query into ready to be used JSON format
4. Visualize
