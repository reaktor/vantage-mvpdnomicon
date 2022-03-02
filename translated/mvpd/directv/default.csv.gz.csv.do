# .csv.gz.csv is ridiculous, but follows the pattern that the translated
# file has the same name as the source file but with .csv appended.
SOURCE="../../../mvpd/directv/$2.csv.gz"
redo-ifchange "$SOURCE"

zcat "$SOURCE"
