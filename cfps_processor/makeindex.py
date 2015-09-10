#!/usr/bin/env python

'''
Reads masterlist.json and creates html table from it (to stdout)
No special libraries needed
'''

import json, sys, re


reload(sys)
sys.setdefaultencoding('utf-8')

live = set()

with open("masterlist.json", "rb") as f:
	masterlist = json.load(f)
	for k in masterlist.keys():
		masterlist[int(k)] = masterlist[k]
		masterlist[int(k)]['seealso'] = [int(x) for x in masterlist[int(k)]['seealso']]
		del masterlist[k]

for cfps in masterlist:
	if 'seealso' in masterlist[cfps]:
		for sa in masterlist[cfps]['seealso']:
			sa = int(sa)
			if 'seealso' not in masterlist[sa]:
				masterlist[sa]['seealso'] = [cfps]
			elif cfps not in masterlist[sa]['seealso']:
				masterlist[sa]['seealso'].append(cfps)
				masterlist[sa]['seealso'].sort()

live = masterlist.keys()

def makerow(cfps):
	global masterlist
	cdate = masterlist[cfps]["versions"][0]["date"]
	mdate = masterlist[cfps]["versions"][-1]["date"]
	if cdate != mdate:
		datestr = cdate+" (updated "+mdate+")"
	else:
		datestr = cdate
	
	kind = masterlist[cfps]["versions"][0]["type"]
	if kind == "Comment":
		targ = int(masterlist[cfps]['versions'][0]['cfps'])
		kind = 'Comment on <a href="files/'+masterlist[targ]['versions'][0]['sname']+'">CFPS '+str(targ)+'</a>'
		masterlist[cfps]["versions"][0]["keywords"] = masterlist[targ]['versions'][0]["keywords"]
	
	links = ", ".join(
		'<a href="files/'+masterlist[x]['versions'][0]['sname']+'">'+str(x)+'</a>'
		for x in sorted(masterlist[cfps]["seealso"])
		if x in live
	)
	
	return '''
<tr>
	<td class="cfps">{0}</td>
	<td class="author">{last}, {first}</td>
	<td class="title"><a href="files/{sname}">{title}</a></td>
	<td class="type">{1}</td>
	<td class="date">{2}</td>
	<td class="date">{4}</td>
	<td class="keywords">{keywords}</td>
	<td class="description">{description}</td>
	<td class="references">{3}</td>
</tr>
'''.format(
			cfps, 
			kind, 
			cdate, 
			links, 
			mdate,
			**masterlist[cfps]["versions"][0]
		)	



rows = []
live = list(sorted(live))
live.reverse()
for k in live:
	rows.append(re.sub("\s+"," ",makerow(k).strip()))

#rows.sort()
#rows.sort(lambda x,y: -cmp(x[x.find('"date"'):],y[y.find('"date"'):]))


print """<script type="text/javascript" src="http://fhiso.org/wp-includes/js/columnsort.js"></script>
<style type="text/css"> .hide, .keywords { display:none; } </style>

<h1>Call for Papers Submissions</h1>

<p>The CFPS (Call For Paper Submission) number is a unique identifier for each submitted document. Posted submissions may be referred to by title and author or by CFPS number as, e.g., CFPS 12.</p>

<p>The table may be sorted by clicking on column headers.</p>

<p>You may filter the rows by search string (keywords and visible text are searched as you type): <input type="text" id="cfpsfilter" onkeyup="filterrows('tablerows',document.getElementById('cfpsfilter').value)"/></p>

<table>
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
""" + "\n".join(s for s in rows) + """
</tbody>
</table>
<p>To view a paper in your browser (if your browser supports viewing PDF files), simply click on any of the titles above. If you would like to save a copy locally, right click on the title and choose the "Save Link As..." option (or your browser's equivalent).</p>
"""

import sys

unused = [k for k in masterlist if k not in live]
unused.sort(lambda x,y: cmp(masterlist[x]["versions"][0]["date"], masterlist[y]["versions"][0]["date"]))
#print >> sys.stderr, unused
usedplus = [k for k in masterlist]
usedplus.sort(lambda x,y: cmp(masterlist[x]["versions"][0]["date"], masterlist[y]["versions"][0]["date"]))
#print >> sys.stderr, usedplus
used = [k for k in masterlist if k in live]
used.sort(lambda x,y: cmp(masterlist[x]["versions"][0]["date"], masterlist[y]["versions"][0]["date"]))
#print >> sys.stderr, used
