SOURCE="../../../mvpd/comcast/$2.csv"
redo-ifchange "$SOURCE"

cp "$SOURCE" "$3"
