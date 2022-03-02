redo-always

DEST='translated/mvpd/directv/%f.csv'

find mvpd/directv -name 'VCBSDelivery_DTV_*.csv.gz' -printf "$DEST\0" | xargs -0 redo-ifchange
