set translations translated/mvpd/altice

function altice-daily-files
  ls $translations/*.xlsx.csv
end

function sorted-altice-daily-files
  altice-daily-files | bin/sort-translations-by-upload-time
end

function altice-megasheet
  sorted-altice-daily-files | tr '\n' '\0' | xargs -0 xsv cat rows
end

function filter-segments
  set -l pattern $argv[1]

  xsv search -s 'Audience Segment Name' $pattern
end

function select-relevant-fields
  xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered'
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

function impressions-napkincalc \
  --argument order_number start_date end_date data_file \
  --description "Calculates the number of impressions for `order_number`\
  between `start_date` and `end_date` (inclusive), optionally using `data_file`\
  instead of generating the megasheet each time."

  if test -n "$data_file"
    cat "$data_file"
  else
    altice-megasheet
  end | filter-segments "$order_number" | limit-dates "$start_date" "$end_date" | select-relevant-fields | bin/accumulate | just-impressions | sum-nums
end

function check-altice-mismatch-file --argument file \
  --description "For each line of a mismatch CSV file, as generated by our bot,\
  attaches our napkin-math impressions number to compare to Redshift and BQ.\
  Outputs CSV."

  function check-line
    set -l raw_line (string trim "$argv[1]")
    set -l line (string split "," "$raw_line")
    set -l order "$line[1]"
    set -l earliest "$line[4]"
    set -l latest "$line[5]"

    set -l napkin_imps (impressions-napkincalc "$order" "$earliest" "$latest")
    if test -z "$napkin_imps"
      set napkin_imps 0
    end

    echo "$raw_line,$napkin_imps"
  end

  set -l awaiting_headers true

  for line in (cat $file)
    set -l trimmed_line (string trim "$line")

    if $awaiting_headers
      set awaiting_headers false
      echo "$trimmed_line,napkin_imps"
    else
      check-line "$trimmed_line"
    end
  end
end