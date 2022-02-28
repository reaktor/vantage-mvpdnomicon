redo-always

DEST='translated/mvpd/altice/%f.csv'

find mvpd/altice -name 'Viacom_Altice_Daily_Report*.xlsx' -printf "$DEST\0" | xargs -0 redo-ifchange
