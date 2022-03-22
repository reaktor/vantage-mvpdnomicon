SOURCE="../../../mvpd/altice/$2.xlsx"
redo-ifchange "$SOURCE"

# Sheet 2 should be "Spot Level Detail", but sometimes it's "spot level detail".
xlsx2csv --sheet 2 --dateformat "%Y-%m-%d" --timeformat "%H:%M:%S" "$SOURCE"
