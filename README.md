# 2022 Large IT projects – R analysis

This repository contains an R project to analyze sessional paper data for the [Large Government of Canada IT projects](https://large-government-of-canada-it-projects.github.io/) website.

The [primary repository for the website is located here](https://github.com/YOWCT/large-government-of-canada-it-projects).

This repository includes:

* Table extraction from [an MS Word adaptation](https://github.com/sboots/2022-large-it-projects/blob/main/data/source/8530-441-13-505-b-rotated.docx) of the [source PDF file](https://large-government-of-canada-it-projects.github.io/pdf/8530-441-13-505-b.pdf)
* Data cleanup and parsing (supporting several manual spreadsheet-editing steps)
* Data merging with 2016 and 2019 data [already in CSV format](https://github.com/sboots/2022-large-it-projects/tree/main/data/source)
* Combining the three years' datasets together and grouping related projects together for analysis

This repository also includes the logic [determining each “estimated status” value](https://github.com/sboots/2022-large-it-projects/blob/main/compare-part-2.R#L139-L156).

For more information, see each individual R file. See the [helpers.R file](https://github.com/sboots/2022-large-it-projects/blob/main/helpers.R#L3-L5) for the set of libraries used in this project.

## An [Ottawa Civic Tech](https://ottawacivictech.ca/) project

This is a volunteer project and is not affiliated with the Government of Canada.
