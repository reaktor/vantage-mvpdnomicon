redo-always

DEST='translated/mvpd/charter/%f.csv\0'

find mvpd/charter -name '*.xlsx' -printf "$DEST" -o -name '*.txt' -printf "$DEST" | xargs -0 redo-ifchange
