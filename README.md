# mvpdnomicon

I am so sorry.

This is a grab bag of utilities for interactive exploration of MVPD data.

The general idea is...

1. Get all the source data.
2. Turn all the source data from whatever nonsense it is into CSV.
3. Use "standard" Unix-y text processing tools on the CSV data to figure
   out that thing you're trying to figure out.

If you want to try the happier path and work with this data like
a normal, modern person, check out [the Vantage Data Livebook
Playground](https://github.com/vc-vantage/vantage-data-livebook).

## Requirements

Again, I am so sorry.

This uses some random stuff.

### Hard requirements

1. The `aws` command line tool: for getting the source files.
2. [`xlsx2csv`][xlsx2csv] (the Python one, not the Rust one. (Just
   because I found it first, not necessarily because it's better.)):
   does what it says on the tin.
3. [`redo`][redo]: a dependency-based build tool, used for effeciently
   translating files.
4. Ruby: for random small custom utilities. (Recommended: install
   through `asdf`.)

### Soft requirements

You can forge your own path without these things, if you like doing
things the extra-hard way.

1. [`xsv`][xsv]: really good for working with CSV data.
2. [`ripgrep`][ripgrep]: really good for finding stuff in text files.
3. [`asdf`][asdf]: for managing tool versions, mainly Ruby.
4. [`fish`][fish]: because I use fish, and I've written some helpful
   tiny functions for working with the data.

[asdf]: https://asdf-vm.com/
[fish]: https://fishshell.com/
[redo]: https://redo.readthedocs.io/en/latest/
[ripgrep]: https://github.com/BurntSushi/ripgrep
[xlsx2csv]: https://github.com/dilshod/xlsx2csv
[xsv]: https://lib.rs/crates/xsv

## Example usage

These examples assuming I'm running in a fish shell session.

Always start by getting the latest data from S3 and translating it to
CSV. This will be slow the first time:

```fish
# Get the latest data from S3:
$ redo sync

# Translate/extract/copy the data to CSV.
$ redo -j 9
```

This will take the source files from the `mvpd` directory, and create
CSV files in the `translated` directory. So for example,
`mvpd/charter/VIACOM_CHARTER_DAILY_20211101_details.txt` will be
available as a CSV in
`translated/mvpd/charter/VIACOM_CHARTER_DAILY_20211101_details.txt.csv`.

If you only care about a specific partner, you can build just the files
for that partner like so:

```
$ redo -j 9 altice
```

You can also adjust the `9` in `-j 9` to change the number of jobs that
will run in parallel. Maybe you have more cores and you want to run more
jobs, or maybe you want to remove the `-j 9` entirely because you want
to wait literally all day.

### The path to insanity: some easy tasks...

#### What files contain data for this order?

Let's say we want to see which files have data for order 79535.
Since we have all the data as CSV, which is just text, we can just use
a standard text search tool, like [`ripgrep`][ripgrep]:

```fish
$ rg -l O79535 translated
translated/mvpd/altice/Viacom_Altice_Daily_Report_20220115-20220116.xlsx.csv
translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220131_summary.txt.csv
translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220112_details.txt.csv
...
```

Key points:

- Prefix the order number with `O` (the letter, not the number).
  Otherwise, you'll also get results for unrelated fields that
  coincidentally _contain_ the order number, e.g. reach percentages.
- Remember that in rare cases, the order number doesn't start with the
  letter `O`, so that previous tip might not apply!
- This is just a full-text search. It doesn't respect the CSV
  structure, so it doesn't just search the segment name. If you're
  unlucky, you'll get some false positives here. In those cases, you
  can do a more sophisticated search using `xsv`, like in the next
  example!

#### Just give me one file's data for one order

We want to look at the data for order `79535` from one file:
`translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220112_details.txt.csv`

```fish
# It's usually handy to put these things in variables:
$ set order 79535
$ set file 'translated/mvpd/charter/VIACOM_CHARTER_DAILY_20220112_details.txt.csv'

# Now we'll use `xsv` to filter the data to this order, based on the
# fact that the order number is contained in the Audience Segment Name
# column.
$ xsv search -s 'Audience Segment Name' $order $file
Advertiser,Campaign Name,Campaign Start Date,Campaign End Date,Audience Segment Name,Segment Priority,Target Household Count,Event Date,Event Time,Hour,Daypart,ISCI/ADID,Network,Title,Impressions Delivered,Households Reached,Median Seconds Viewed,Mean Seconds Viewed,Completion Rate
VIACOM_CHARTER_DAILY,WALGREENS / WENDYS 1/10,2022-01-10,2022-01-23,O79535_CHARTER_VA_Walgreens_1PD_E1198117_A,1,832718,2022-01-10,01:19:25,01 AM - 02 AM,12 AM - 2 AM,WALG3151000VH,MTV,,174,173,27.030001,26.771034,99.1520%
VIACOM_CHARTER_DAILY,WALGREENS / WENDYS 1/10,2022-01-10,2022-01-23,O79535_CHARTER_VA_Walgreens_1PD_E1198117_A,1,832718,2022-01-10,02:19:04,02 AM - 03 AM,2 AM - 5 AM,WALG3151000VH,MTV,,123,122,27.030001,26.892195,99.6007%
...

# That's...not super easy to read.  We can skip some of this data.
$ xsv search -s 'Audience Segment Name' $order $file |
    xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered'
Audience Segment Name,Event Date,Event Time,Network,Impressions Delivered
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A,2022-01-10,01:19:25,MTV,174
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A,2022-01-10,02:19:04,MTV,123
...

# Still could be nicer to read:
$ xsv search -s 'Audience Segment Name' $order $file |
    xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered' |
    xsv table
Audience Segment Name                       Event Date  Event Time  Network  Impressions Delivered
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A  2022-01-10  01:19:25    MTV      174
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A  2022-01-10  02:19:04    MTV      123
...
```

### We have arrived at insanity: more complex tasks

#### Give me _all_ the data for one order

This is basically a combination of the previous two tactics:

```fish
$ set order 79535
$ rg -l O$order translated/mvpd/charter/ |
    grep -v '_summary.txt' |
    xargs xsv cat rows |
    xsv search -s 'Audience Segment Name' $order |
    xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered' |
    xsv table
Audience Segment Name                       Event Date  Event Time  Network  Impressions Delivered
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A  2022-01-10  01:19:25    MTV      174
O79535_CHARTER_VA_Walgreens_1PD_E1198117_A  2022-01-10  02:19:04    MTV      123
...
```

1. We find all the files that might contain data for this order.
2. We exclude Charter's `_summary.txt` files. Those are PCR data, and
   we just want spot-level data.
3. We jam all the data together into one megasheet using `xsv cat rows`.
4. We use `xsv search`, `xsv select`, and `xsv table` to filter the
   rows to our order, narrow down the columns, and make the result
   human-readable.

In some cases, this is what you want! For Charter, this isn't yet fully
helpful, because earlier rows should be replaced by later rows for the
same segment, date, time, and network. In that case, what you really
want is...

#### Give me the final-est data for one order

```diff
 $ set order 79535
 $ rg -l O$order translated/mvpd/charter/ |
     grep -v '_summary.txt' |
+    bin/sort-translations-by-upload-time |
     xargs xsv cat rows |
     xsv search -s 'Audience Segment Name' $order |
     xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered' |
+    bin/accumulate |
     xsv table
```

This is the same as before, except with a couple fun little utilities.

`bin/sort-translations-by-upload-time` takes a list of translated files
(i.e., our CSVs) and sorts them based on the original upload time of the
original files. (It figures this out using the modification time of the
source files, which `aws s3 sync` helpfully sets. But this means you
shouldn't touch the source files!)

This is important because the order of upload dictates the order that
data should be processed in.

`bin/accumulate` takes in CSV data of the exact format we're selecting
here (Audience Segment Name, Event Date, Event Time, Network,
Impressions Delivered) and spits out the same CSV data, but with only
the _latest_ row for each grouping of segment, date, time, and network.
This is specifically for working with Altice and Charter data, where
this rule applies.

In the end, the CSV data you get from `bin/accumulate` _should_ match
our Redshift data row-for-row.

#### Interlude: some helpful functions

We've just done all this the hard way. Lucky for you, someone has
already done it the hard way, and so you can do it the
slightly-less-hard way!

Use [fish][fish], and load these handy helper functions:

```fish
$ source lib/charter-help.fish
```

Now let's redo that previous monster pipeline:

```diff
 $ set order 79535
-$ rg -l O$order translated/mvpd/charter/ |
-    grep -v '_summary.txt' |
-    bin/sort-translations-by-upload-time |
+$ rg -l O$order (sorted-charter-spot-files) |
     xargs xsv cat rows |
-    xsv search -s 'Audience Segment Name' $order |
+    filter-segments $order |
-    xsv select 'Audience Segment Name','Event Date','Event Time','Network','Impressions Delivered' |
+    select-relevant-fields |
     bin/accumulate |
     xsv table
```

This does exactly what we did before.
In more copy-and-pastable form:

```fish
$ set order 79535
$ rg -l O$order (sorted-charter-spot-files) |
    xargs xsv cat rows |
    filter-segments $order |
    select-relevant-fields |
    bin/accumulate |
    xsv table
```

It's... "nicer"!

#### Sanity-check the total impressions

Anyway, now that we've produced all the rows that should be in Redshift, we can
just take the impressions and add them up!

Most of the time, you're probably not getting the _total_ total, but
you're looking at our verification bot, which gives totals by week.
We'll also filter to just a week's worth of events here.

```diff
 $ set order 79535
 $ rg -l O$order (sorted-charter-spot-files) |
     xargs xsv cat rows |
     filter-segments $order |
+    limit-dates 2022-01-17 2022-01-23 |
     select-relevant-fields |
     bin/accumulate |
-    xsv table
+    just-impressions |
+    sum-nums
```

Hopefully, this matches the number you get from Redshift!

##### Compare to the Redshift data

If you're still reading this, either you're just _really_ interesting in
sadistic data analysis (unlikely) or your number didn't match the number
you got from Redshift (more likely).

If you don't know where to go from here, you can compare your data to
the data in Redshift!

Put your rows into a file:

```fish
$ set order 79535
$ rg -l O$order (sorted-charter-spot-files) |
    xargs xsv cat rows |
    filter-segments $order |
    limit-dates 2022-01-17 2022-01-23 |
    select-relevant-fields |
    bin/accumulate > my-probably-correct-data.csv
```

Then write a query to get the same data from Redshift.

Put something like this into, say, `get-probably-incorrect-data.sql`:

```sql
SELECT
  audience_segment_name,
  event_date,
  event_time,
  network,
  impressions_delivered
FROM mvpd.charter_spot_level
WHERE
  audience_segment_name IN (
    'O79535_CHARTER_VA_Walgreens_1PD_E1198117_A',
    'O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2'
  )
  AND event_date >= '2022-01-17'
  AND event_date <= '2022-01-23'
ORDER BY audience_segment_name, event_date, event_time, network;
```

In this particular case, we're "lucky" because this one order number
contains multiple segment names. We need to account for them both in
our query.

Now, run that query and get the result as CSV:

```fish
$ psql -h $REDSHIFT_HOST -U $REDSHIFT_USER -p $REDSHIFT_PORT -d $REDSHIFT_DB \
    --csv -f get-probably-incorrect-data.sql -o probably-incorrect-data.csv
```

Now you have your "correct" data in `my-probably-correct-data.csv`
and Redshift's "incorrect" data in `probably-incorrect-data.csv`.

We can `diff` them!

```fish
$ diff probably-incorrect-data my-sorted-correct-data.csv
```

```diff
1c1
< audience_segment_name,event_date,event_time,network,impressions_delivered
---
> Audience Segment Name,Event Date,Event Time,Network,Impressions Delivered
1080c1080
< O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-17,19:21:06,MTV,1
---
> O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-17,19:21:06,MTV,2
1148c1148
< O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-17,23:18:38,TVL,1
---
> O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-17,23:18:38,TVL,4
1214c1214
< O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-18,08:11:06,MTV,1
---
> O79535_CHARTER_VA_Walgreens_1PD_E1198117_A_2,2022-01-18,08:11:06,MTV,2
```

Now we have something to go on! From here, maybe you could...

- Find the most recent file that these particular
  segment-date-time-network combinations occurred in, and make sure your
  data's right.
- Query the `file_name` for those rows in the Redshift table, and see if
  it's what you expect.
- Go on a long, fun _data adventure!_

## Teaching it new tricks

The basic rules here are...

1. The `mvpd` directory is kept in sync with the S3 source files.  (That
   is, updates to S3 are synced to `mvpd`, but changes in `mvpd` are
   _not_ synced back.)
2. When files in the `mvpd` directory are added or changed, CSV copies
   of them are created in the `translated` directory.
3. Sometimes the source files in `mvpd` are used for metadata (e.g., to
   sort them by upload time), so you should be able to figure out the
   source file for any translated file by removing the `translated/`
   prefix and the `.csv` suffix.

To manage the translation of files, we use [`redo`][redo].  Redo
serves the same purpose as Make.  We started out using Make, but the
problem with Make is that it can't comprehend filenames with spaces.

With redo, each target lives in its own file.  When you run just plain
`redo`, it runs the `all` target, and the code for that lives in
`all.do`.  `.do` files are basically just shell scripts.

`all` runs all the targets for the partners.  Each partner target has
a corresponding `.do` file in the root directory (e.g. `altice.do`).
The top-level partner targets will...

1. Find the source files we care about.
2. Figure out what the translated files should be named.
3. Run the targets for the translated files, if the sources have
   changed.

The rules for producing the translated files are in `.do` files in the
translated directories.  For instance, the rule to produce a `.csv` file
from an Altice `.xlsx` file is in
`translated/mvpd/altice/default.xlsx.csv.do`: this is the rule that redo
uses to build a `.xlsx.csv` file in the `translated/mvpd/altice/`
directory.  A partner might have multiple `default.*.csv.do` files,
since file formats have changed over time.

The important things to know about these `.do` files are...

- They're basically just shell scripts.
- Standard output will be used to create the target file.
- The variable `$2` contains the target name.  (So in the case of
  generating CSV data with a `default.something.csv.do` file, `$2` would
  be the name of the _translated_ file, without the directory, like
  `source-data-file-2022-04-01.something.csv`.)
- If you don't want to just write to stdout, the variable `$3` contains
  a file that you can write to to create the target.
