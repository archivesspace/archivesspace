---
title: Reports
layout: en
permalink: /user/reports/
---
Adding a report is intended to be a fairly simple process. The requirements for creating a report are outlined below.

## Adding a Report
### Required
- Create a class for your report that is a subclass of AbstractReport.
- Call register report. If your report has any params, specify them here.
- Implement query_string
	- This should be a raw SQL string
	- To prevent SQL injection, use db.literal for any user input i.e. use ```"select * from table where column = #{db.literal(value)}" ``` instead of ```"select * from table where column = '#{value}'"```
- Provide translations for column headers and the title of your report
	- They should be in yml files under *language*.reports.*report name*
	- The translation for title should be whatever you want the name of the report to be.
	- If the translation you want is already in *language*.reports.translation_defalts (found in the static folder) you do not need to specify it.
	- Translations specific to the individual report are given priority over translation defaults.

### Optional
- Implement your own initializer if your report has any params.
- Implement fix_row in order to clean up data and add subreports.
	- Each result will be passed to fix_row as a hash
	- ReportUtils offers various class methods to simplify cleaning up data.
	- You can also add subreports here with something like ```row[:subreport_name] = SubreportClassName.new(self, row[:id]).get_content``` where row is the result as a hash which was a parameter to fix_row. See [Adding a Subreport](#adding-a-subreport) for more information on adding subreports.
	- Sometimes you will want to delete something from the result that you needed in order to generate a subreport but do not want to show up in the final report (such as id). To do this use ```row.delete[:id]```.
- Special implementation of query - The default implementation is simply ```db.fetch(query_string)``` but implementing it yourself may give you more flexibility. In the end, it needs to return a result set.
- There is a hash called info that controlls what show up in the header at the top of the report. Examples may include total record count, total extent, or any parameters that are provide by the user for your report. Add anything you want to show up in the report header to info. Repository name will be included automatically. Be sure to provide translations for the keys you add to info.
- after_tasks is run after fix_row executes on all the results. Implement this if you have anything that needs to get done here before the report is rendered
- Specify identifier_field if you want to add a heading to each individual record. For instance, identifier_field might be ```:accession_number``` for a report on accessions.
- Implement page_break to be false if you do not want a page break after each record in the PDF of the report.
- Implement special_translation if there is anything you want translate in a special way (i.e. it can't be accomplished by the yml file).

## Adding A Subreport

### Required
- Create a class for your subreport that subclasses AbstractSubreport.
- Create an initializer that takes in the parent report/subreport as well as any parameters you need to run the subreport (usually this is just an id from the result in the parent report/subreport). Your initializer should call ```super(parent_report)```.
- Implement query_string. This works the same way as it does for reports.
- Provide neccesary translations.

### Optional
- Special implementation of query
- fix_row works just like in reports
	- note that you can add nested subreports
