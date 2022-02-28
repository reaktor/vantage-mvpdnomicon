SOURCE="../../../mvpd/comcast/$2.xlsx"
redo-ifchange "$SOURCE"

xlsx2csv "$SOURCE" --sheetname "Data" --dateformat "%Y-%m-%d" --timeformat "%H:%M:%S"
