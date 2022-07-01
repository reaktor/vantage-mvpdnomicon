function has-duplicate-lines --argument filename
  set num_dupes (sort < $filename | uniq -d | wc -l)
  test $num_dupes -gt 0
end

function print-files-with-duplicate-lines
  while read file
    if has-duplicate-lines $file
      echo $file
    end
  end
end
