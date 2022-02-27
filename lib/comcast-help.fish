set comcast_translations translated/mvpd/comcast

function comcast-spot-files
  ls $comcast_translations/*dailyimpressionreport_capped*.csv
  ls $comcast_translations/*dailyimpressionreport_-_*.csv
end

function comcast-daily-files
  ls $comcast_translations/*weekly_*_capped.xlsx.csv
end

# @todo make this work, probably need to make a new ruby script to handle
# basic csv mapping from mvpd/comcast -> translated/mvpd/comcast 
#function sorted-comcast-spot-files
#  comcast-spot-files | bin/sort-translations-by-upload-time
#end

function sorted-comcast-daily-files
  comcast-daily-files | bin/sort-translations-by-upload-time
end

function comcast-daily-megasheet
  sorted-comcast-daily-files | xargs xsv cat rows
end

function limit-dates-comcast-daily
  xsv search -s 'Report Period Start','Report Period End' (bin/date-range-regex $argv)
end
