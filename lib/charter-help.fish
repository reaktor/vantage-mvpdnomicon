set translations translated/mvpd/charter

function charter-spot-files
  ls $translations/*.xlsx.csv
  ls $translations/*_details.txt.csv
end

function sorted-charter-spot-files
  charter-spot-files | bin/sort-translations-by-upload-time
end

function charter-megasheet
  sorted-charter-spot-files | xargs xsv cat rows
end

function filter-segments
  set -l pattern $argv[1]

  xsv search -s 'Audience Segment Name' $pattern
end

function select-relevant-fields
  xsv select 'Audience Segment Name','Event Date','Event Time','Network','ISCI/ADID','Impressions Delivered'
end

function sum-nums
  ruby -e 'puts ARGF.each_line.map(&:to_i).reduce(&:+)'
end

function limit-dates
  xsv search -s 'Event Date' (bin/date-range-regex $argv)
end

function just-impressions
  xsv select 'Impressions Delivered' | tail -n +2
end
