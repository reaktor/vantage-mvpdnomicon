redo-always

DEST='translated/mvpd/dish/%f.csv'

find mvpd/dish -name '*_daily_*.xlsx' -printf "$DEST\0" | xargs -0 redo-ifchange
