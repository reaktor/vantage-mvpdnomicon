SOURCE="../../../mvpd/charter/$2.txt"
redo-ifchange "$SOURCE"

xsv fmt -d '|' "$SOURCE"
