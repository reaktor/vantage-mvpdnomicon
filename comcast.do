redo-always

MATCHER='.*(weekly_[0-9]+_capped|dailyimpressionreport(_capped| -)).*'
DEST='translated/mvpd/comcast/%f.csv'

find mvpd/comcast -regextype egrep -regex "$MATCHER" -printf "$DEST\0" | xargs -0 redo-ifchange
