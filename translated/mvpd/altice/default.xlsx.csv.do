SOURCE="../../../mvpd/altice/$2.xlsx"
redo-ifchange "$SOURCE"

xlsx2csv --sheetname "Spot Level Detail" --dateformat "%Y-%m-%d" --timeformat "%H:%M:%S" "$SOURCE"
