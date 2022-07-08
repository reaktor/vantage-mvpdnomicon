#!/bin/fish
source (dirname (status -f))/charter-help.fish

set -l file "$argv[1]"

function test-dupes \
  --argument data_file \
  --description "Checks for duplicate spots and prints results."

  set -l num_dupes (count-duplicate-spots $data_file)
  if test $num_dupes -gt 0
    echo "Contains $num_dupes duplicate spots."\n
    return 1
  end
end

function test-underscore-num-asd \
  --argument data_file \
  --description "Checks for _[num] in the Audience Segment Name column and prints results."

  set underscore_num_asd (count-underscore-num-asd $data_file)
  if test (count $underscore_num_asd) -gt 0
    echo "Contains the following Audience Segment Names ending in _[num]:"
    print-bulleted-list $underscore_num_asd
    echo \n
    return 1
  end
end

function test-default-asn \
  --argument data_file \
  --description "Checks for ASN set to Default and prints results"

  set num_default_asn (count-default-asn $data_file)
  if test $num_default_asn -gt 0
    echo "Contains $num_default_asn rows with Audience Segment Name set to \"Default\"."\n
    return 1
  end
end

function print-bulleted-list \
  --argument list \
  --description "Prints a bulleted list to console."

  for item in $list
    echo \t\U2022"  $item"
  end
end

function validate-file \
  --argument data_file \
  --description "Runs the given file through a few validation tests specific to spot-level Charter data."

  set -l tmp_file (mktemp -u).csv
  get-vantage-spots $data_file > $tmp_file # Store vantage-specific data in temp file
  
  set -l total_status 0

  # Check for duplicate spots
  test-dupes $tmp_file
  set -l total_status (math $total_status + $status)
  
  # Check for "_1", "_2" (etc.) appended to ASN
  test-underscore-num-asd $tmp_file
  set -l total_status (math $total_status + $status)
  
  # Check for Audience Segment Name set to "Default"
  test-default-asn $data_file # Use the full file instead of tmp_file because rows with "Default" as the ASN will be filtered out by the get-vantage-spots function
  set -l total_status (math $total_status + $status)

  if test $total_status = 0
    echo "No issues found in file."
  end
  
  rm $tmp_file  
end

if test ! -n "$file"
  echo "No file provided."
else
  validate-file $file
end
