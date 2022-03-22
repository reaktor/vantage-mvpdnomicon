redo-always

DEST='translated/mvpd/altice/%f.csv'

find mvpd/altice -iname '*_weekly_*.xlsx' -printf "$DEST\0" | xargs -0 redo-ifchange
