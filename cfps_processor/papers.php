<script type="text/javascript" src="/columnsort.js"></script>
<style type="text/css"> .hide, .keywords { display:none; } </style>

<h1>Call for Papers Submissions</h1>

<p>The CFPS (Call For Paper Submission) number is a unique identifier for each
submitted document. Posted submissions may be referred to by title and author
or by CFPS number as, e.g., CFPS 12.</p>

<p>The table may be sorted by clicking on column headers.</p>

<p>You may filter the rows by search string (keywords and visible text are 
searched as you type): <input type="text" id="cfpsfilter" 
onkeyup="filterrows('tablerows',document.getElementById('cfpsfilter').value)"/>
</p>

<table class="widetable">
<tbody id="tablerows">
<tr>
	<th onclick="sortcolumn('tablerows',0,1)" class="cfps">CFPS</th>
	<th onclick="sortcolumn('tablerows',1,1)" class="author">Submitter</th>
	<th onclick="sortcolumn('tablerows',2,1)" class="title">Title</th>
	<th onclick="sortcolumn('tablerows',3,1)" class="type">Type</th>
	<th onclick="sortcolumn('tablerows',4,1)" class="date">Created</th>
	<th onclick="sortcolumn('tablerows',5,1)" class="date">Updated</th>
	<th onclick="sortcolumn('tablerows',6,1)" class="keywords">Keywords</th>
	<th onclick="sortcolumn('tablerows',7,1)" class="description">Description</th>
	<th onclick="sortcolumn('tablerows',8,1)" class="references">See Also</th>
</tr>
<?php
# The file is installed as /cfps/papers.php, so ../include is the right path
set_include_path('../include');
include_once('database.php');

$sql = <<<EOF
    SELECT cfps.*, papers.*, cfps_types.name AS type, 
    GROUP_CONCAT(cfps_see_also.references_id 
                 ORDER BY cfps_see_also.references_id) AS refs,
    cfps_references.references_id AS comment_on
    FROM cfps JOIN papers ON latest_version=papers.id 
    JOIN cfps_types ON submission_type=cfps_types.id 
    LEFT JOIN cfps_see_also ON cfps.id=cfps_see_also.cfps_id 
    LEFT JOIN cfps_references ON cfps.id=cfps_references.cfps_id
      AND (cfps_references.is_primary_subject 
           OR cfps_references.is_primary_subject IS NULL)
    GROUP BY cfps.id
    ORDER BY cfps.id DESC
EOF;

foreach ( fetch_objs_with_sql($sql) as $c ) { ?>
  <tr>
    <td class="cfps"><?php esc($c->cfps_id) ?></td> 
    <td class="author"><?php esc($c->surname.', '.$c->given_name) ?></td>
    <td class="title"><a href="files/cfps<?php esc($c->cfps_id) ?>.pdf"><?php
      esc($c->title) ?></a></td>
    <td class="type"><?php esc($c->type);
      if ($c->comment_on) { ?> on CFPS <a href="files/cfps<?php 
        esc($c->comment_on) ?>.pdf"><?php esc($c->comment_on) ?></a><?php } 
      ?></td> 
    <td class="date"><?php esc($c->date_created) ?></td>
    <td class="date"><?php esc($c->version_created) ?></td> 
    <td class="keywords"><?php esc($c->keywords) ?></td> 
    <td class="description"><?php esc($c->description) ?></td>
    <td class="references"><?php 
      $first = 1;
      foreach (preg_split('/,/', $c->refs) as $a) {
        if (!$first) echo ', '; ?>
        <a href="files/cfps<?php esc($a) ?>.pdf"><?php esc($a) ?></a><?php
      }
    ?></td> 
  </tr>
<?php } ?>
</tbody>
</table>

<p>To view a paper in your browser (if your browser supports viewing PDF
files), simply click on any of the titles above. If you would like to save a
copy locally, right click on the title and choose the "Save Link As..." option
(or your browser's equivalent).</p>

