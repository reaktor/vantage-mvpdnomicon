#!/bin/fish
source (dirname (status -f))/charter-help.fish

set -l file "$argv[1]"

function validate-file \
  --argument data_file \
  --description "Runs the given file through a few validation tests specific to spot-level Charter data."

  set -l tmp_file (mktemp -u).csv
  get-vantage-spots $data_file > $tmp_file # Store vantage-specific data in temp file
  
  # Check for duplicate spots
  calc-duplicate-spots $tmp_file
  set -l dupes_status $status
  
  # Check for "_1", "_2" (etc.) appended to ASN
  contains-underscore-num-asd $tmp_file
  set -l underscore_num_status $status
  
  # Check for Audience Segment Name set to "Default"
  contains-default-asn $file # Use complete file instead of tmp_file because we can't tell if a row with "Default" ASN is vantage data
  set -l default_asn_status $status

  if test $dupes_status = 0; and test $underscore_num_status = 0; and test $default_asn_status = 0
    echo "No issues found in file."
  end
  
  rm $tmp_file  
end

if test ! -n "$file"
  echo "No file provided."
else
  validate-file $file
end
