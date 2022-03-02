SOURCE="../../../mvpd/dish/$2.xlsx"
redo-ifchange "$SOURCE"

xlsx2csv --dateformat "%Y-%m-%d" --timeformat "%H:%M:%S" "$SOURCE"
