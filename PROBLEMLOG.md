# Problem Log

This is meant to be an _immutable_ log of all the awesome data adventures we've
gone on as a team! Any time you're tasked with investigating some MVPD
descrepencies please append to this file with a subtitle including the date,
partner, and some description of the issue. Here's an example:

```markdown
## 2022-02-23 Charter is missing impressions for the week of 202207 (Feb 7)
```

Also, be sure to ask for help from your teammates whenever necessary. Even if
it's just to scream, cry, or release emotion in some other way. You'll probably
need to.

Godspeed.

## 2022-02-23 Charter is missing impressions for the week of 202207 (Feb 7)

Ran the following and got the number in our Redshift:

```fish
$ rg -l O$order translated/mvpd/charter/ |
      grep -v '_summary' |
      bin/sort-translations-by-upload-time | xargs xsv cat rows |
          xsv search -s 'Audience Segment Name' 'O78670' | limit-dates '2022-02-07' '2022-02-13' |
          xsv select 'Audience Segment Name','Event Date','Event Time','Network','ISCI/ADID','Impressions Delivered' |
          bin/accumulate |
          just-impressions |
          sum-nums
```

We were unable to produce the numbers from the Big Query or what Toby had given
us. After throwing some darts like this:

```fish
$ rg -l 'O78553_Charter_VA_Carmax_Carmax_E1188991_A03' translated/mvpd/charter/ |
      grep -v '_summary' |
      bin/sort-translations-by-upload-time | xargs xsv cat rows |
          xsv search -s 'Audience Segment Name' 'O78553_Charter_VA_Carmax_Carmax_E1188991_A03' | limit-dates '2022-01-24' '2022-01-30' |
          xsv select 'Audience Segment Name','Event Date','Event Time','Network','ISCI/ADID','Impressions Delivered' |
          bin/accumulate |
          just-impressions |
          sum-nums

```

```diff
$ rg -l 'O78553_Charter_VA_Carmax_Carmax_E1188991_A03' translated/mvpd/charter/ |
      grep -v '_summary' |
      bin/sort-translations-by-upload-time | xargs xsv cat rows |
          xsv search -s 'Audience Segment Name' 'O78553_Charter_VA_Carmax_Carmax_E1188991_A03' | limit-dates '2022-01-24' '2022-01-30' |
          xsv select 'Audience Segment Name','Event Date','Event Time','Network','ISCI/ADID','Impressions Delivered' |
-         bin/accumulate |
          just-impressions |
          sum-nums
```

We got the number. This made us realize that the file had duplicated rows. We
loaded the most recent file into Excel, filtered by a single segment, then
sorted by event date and event time. We could see that each row was duplicated
5+ times.

The strange things about this:

- Why did their system spit this stuff out in a random way that wasn't obviously
  evident?
- Why is their system duplicating some more than others?

## 2022-03-24 Dish impressions for order 79220, which we don't have in our data

Had these 2 rows show up from the bot:

```
order_number,audience_segment_name,br_dt_key,earliest,latest,s3_imps,bq_imps,imps_diff,expected_imps_if_known
79220,Viacom Reach Booster_Wendy's_1Q22_79323_Enablement_E1195973_Unexposed_FEB,202207,2022-02-07,2022-02-13,0,10707,-10707,
79220,Viacom Reach Booster_Wendy's_1Q22_79323_Enablement_E1195973_Unexposed_FEB,202208,2022-02-17,2022-02-20,0,7413,-7413,
```

Funny thing is, we don't have an order 79220 in our Dish data...

After investigating, it turned out there was a mapping that didn't surface
itself in Big Query. The reason being only a subset of an element number needed
to be mapped, so there couldn't be a mapping for the whole set. We used our
older `dish_element_number_overrides` mechanism in the Python code by making a
few adustements. See commit `413279b` in the vantage-data-pipelines app.
