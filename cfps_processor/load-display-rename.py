#!/usr/bin/env python
# encoding: utf-8


'''
	This file processes the emails sent by wordpress to papers@fhiso.org
	If/when wordpress changes, most of this file will also have to change.
'''
import getpass
uname = "papers@fhiso.org"
pword = getpass.getpass("Enter password for papers@fhiso.org: ")



from imaplib import *
from ftplib import FTP
from urllib import *
import re
import os.path, os, codecs, sys, copy

'''Most of this file is POSIX-based, but for .doc and .docx we need Windows'''
try: import pythoncom, win32com.client
except: pass

import json

'''Also depends on coverpage.py'''
from coverpage import cover
from glob import glob

from subprocess import call

############################################################################


'''
For updates, we also need a master list (in masterlist.json) formatted like the following:
{
	cfps: {
		"versions": [
			{ version:"1.0", subnum:"", first:"", ... },
			{ version:"1.1", subnum:"", first:"", ... },
			{ version:"2.0", subnum:"", first:"", ... },
		],
		"seealso": [],
		"tablerow": "<tr>...</tr>",
	},
	cfps: {
	},
	...
}
'''
try:
	with open("masterlist.json", "rb") as f:
		masterlist = json.load(f)
		for k in masterlist.keys():
			masterlist[int(k)] = masterlist[k]
			del masterlist[k]
except:
	for p in sys.exc_info():
		print p
	print 'WARNING: master list of submissions not found'
	masterlist = {}

############################################################################

'''
	We extract parts of HTML-formatted MIME message using the global dict refields and the function feilds
'''
refields = {
	"subnum": re.compile("New submission ([0-9]*) from Call for Papers Submission", re.DOTALL),
	"first": re.compile("Given Name</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"last": re.compile("Surname</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"email": re.compile("Email</strong></font>.*?>([^>]*)</a></font>", re.DOTALL),
	"kind": re.compile("Type of Submission</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"date": re.compile("Date Created</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"title": re.compile("Title</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"version": re.compile("Version</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"language": re.compile("Language</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"description": re.compile("Description</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"keywords": re.compile("Suggested Keywords</strong></font>.*?>([^>]*)</font>", re.DOTALL),
	"url": re.compile("(http://fhiso.org/wp-content/uploads/gravity_forms/[^\"']*)", re.DOTALL),
	"cfps": re.compile("CFPS ID Number</strong></font>.*?>[^1-9]*([1-9][0-9]*)</font>", re.DOTALL),
	"changes": re.compile("Summary of Changes</strong></font>.*?>([^>]*)</font>", re.DOTALL),
}
def fields(email):
	'''Returns a dict of the fields found in the given html text; all <br> are stripped.'''
	ans = {}
	email = re.sub("<br[^>]*>", "", email)
	for k in refields:
		m = refields[k].search(email)
		if m: m = m.group(1)
		ans[k] = m
	return ans

def latest(cfps, guess):
	'''Looks in the master list to find the most recent version'''
	v = masterlist[cfps]["versions"]
	for k in guess:
		if not guess[k] and k in v[0]:
			for i in xrange(1,len(v)+1):
				if v[-i][k]: 
					guess[k] = v[-i][k]
					break
	

def process(email):
	'''Processes an email
	- is it a submission or an inquiry? If inquiry, ignores the email
	- what type of submission is it?  We currently have 5 kinds
	- sanity-check updates (can't update a nonexistent CFPS)
	- refuse old version numbers; update version number if reusing most recent one
	- grab the attachment, convert to pdf, and display it for review
	- if review passes, give option of updating title and clipping pages'''
	global masterlist
	# first parse the email
	f = fields(email)
	if not f['subnum']:
		print 'NOTICE: email is not a submission'
		return
	f['extension'] = f['url'][f['url'].rfind('.'):]
	f['type'] = {
		"Technical proposal":"Proposal",
		"Functional requirements":"Requirement",
		"An area requiring standardisation":"Area to Standardise",
		"A comment on a submitted paper":"Comment",
		"An updated version of a previously submitted paper":"Update",
	}[f['kind']]
	f['submitter'] = f['last']+", "+f['first']

	
	# see if it makes sense
	if f['type'] == 'Update': 
		try:
			cfps = int(f['cfps'])
		except:
			cfps = -1
		if cfps not in masterlist:
			print 'ERROR: submission',f['subnum'],'is an update to cfps',cfps,'which has not yet been processed'
			return
	else: cfps = int(f['subnum'])
	f['sname'] = 'cfps'+str(cfps)+'.pdf'
	f['lname'] = 'cfps'+str(cfps)+"_v"+re.sub("[^0-9a-zA-Z]+","-",f['version'])+'.pdf'

	if cfps in masterlist:
		if masterlist[cfps]["versions"][-1]["version"] > f["version"]:
			print 'Already have',cfps,"with newer version",masterlist[cfps]["versions"][-1]["version"]
			return
		if masterlist[cfps]["versions"][-1]["version"] == f["version"]:
			print 'Already have',cfps,"version",f["version"]
			if masterlist[cfps]["versions"][-1]["subnum"] < f["subnum"]:
				f['version'] = f['version']+'.'+f['subnum']
				print 'Assuming this is an unlisted sub-version of ',cfps,", v"+f["version"]
				if masterlist[cfps]["versions"][-1]["version"] == f["version"]:
					print 'ERROR: anonymous version assumption failed'
					return
			else:
				return

	if f['type'] == 'Comment':
		refto = int(f['cfps'])
		if refto not in masterlist:
			print 'ERROR: comment on ',refto,'which has not yet been processed'
			return

	print 'Considering',cfps,'version',f['version']
	if cfps in masterlist:
		print '    Already have versions', ', '.join(_['version'] for _ in masterlist[cfps]['versions'])
	
	# retrieve and see if it is worth using
	urlretrieve(f['url'], 'raw'+f['extension'])
	if f['extension'] not in ['.pdf','.tex']:
		try:
			docToPdf('raw'+f['extension'])
		except:
			print 'Failed to convert',f['extension'],'to .pdf'
			return
	if f['extension'] not in ['.tex']:
		call("evince raw.pdf".split(" "))
	else:
		print 'tex file'
	answer = raw_input("Is file worth using? (y/n) ")
	if answer[0] not in 'yY': return
	f['title'] = f['title'].replace('_',' ')
	answer = raw_input("Insert custom title instead of \""+f['title']+"\"? (y/n) ")
	if answer[0] in 'yY': 
		s = raw_input("New title: ").strip()
		while True:
			t = raw_input("...> ").strip()
			if t and s[-1] != '-': s += " "+t
			elif t: s += t
			else: break
		f['title'] = s
	
	finalize(f, cfps, input("How many pages should be removed? "))

def finalize(entry, cfps, remove):
	'''(called automatically by process)
	updates masterlist and adds a cover page and version history
	puts the final file in ready/
	'''
	global masterlist
	# post in masterlist
	if cfps in masterlist:
		if entry not in masterlist[cfps]["versions"]:
			masterlist[cfps]["versions"].append(entry)
	else:
		masterlist[cfps] = {
			"versions": [entry],
			"seealso": [],
			"tablerow": "",
		}

	# create FHISO cover page
	custom = {
		'title':entry['title'],
		'submitter':entry['last']+", "+entry['first'],
		'delete':remove,
		'cdate':entry['date'],
		'version':entry['version'],
		'description':entry['description'],
		'keywords':entry['keywords']
	}
	if entry['type'] == 'Update': 
		custom['type'] = masterlist[cfps]['versions'][0]['kind']
		if masterlist[cfps]['versions'][0]['type'] == 'Comment':
			custom['replyto'] = masterlist[cfps]['versions'][0]['subnum']
	elif entry['type'] == 'Comment':
		custom['type'] = entry['kind']
		custom['replyto'] = entry['cfps']
	if cfps in masterlist and masterlist[cfps]['versions'][0]['date'] != entry['date']:
		custom['cdate'] = masterlist[cfps]['versions'][0]['date'] 
		custom['mdate'] = entry['date']
	latest(cfps, custom)
	edits = []
	for v in masterlist[cfps]['versions']:
		if 'changes' in v and v['changes'] is not None:
			edits.append((v['lname'],v['date'],v['changes']))
	if edits:
		edits.insert(0, (masterlist[cfps]['versions'][0]['lname'],masterlist[cfps]['versions'][0]['date'],'Initial version'))
	ifile = 'raw.pdf'
	if entry['extension'] == '.tex':
		ifile = 'raw.tex'
	cover(
		ifile,
		'ready/'+entry['lname'],
		cfps,
		edits,
		**custom
	)
	call(('cp ready/'+entry['lname']+' ready/'+entry['sname']).split(' '))


	# handle cross-referencing comments
	if entry['type'] == 'Comment':
		refto = int(entry['cfps'])
		if cfps not in masterlist[refto]['seealso']:
			masterlist[refto]['seealso'].append(cfps)
		if refto not in masterlist[cfps]['seealso']:
			masterlist[cfps]['seealso'].append(refto)
	for ref in masterlist[cfps]['seealso']:
		if cfps not in masterlist[ref]['seealso']:
			masterlist[ref]['seealso'].append(cfps)
			masterlist[ref]['seealso'].sort()
	masterlist[cfps]['seealso'].sort()
	
	
	
	

def webmail():
	'''Logs into webmail account and returns the connection'''
	global uname, pword
	con = IMAP4_SSL( "mail.fhiso.org", 993 )
	con.login( uname, pword )
	con.select()
	print con.list()
	return con

def docToPdf(doc):
	'''converts .doc or .docx to .pdf (only works on windows)'''
	wordapp = win32com.client.gencache.EnsureDispatch("Word.Application")
	print doc
	print os.path.abspath(doc)
	print os.getcwd()+"\\"+doc
	try:
		wordapp.Documents.Open(os.path.abspath(doc))
		docaspdf = doc[:doc.rfind(".")] + '.pdf'
		wordapp.ActiveDocument.ShowRevisions = False
		wordapp.ActiveDocument.SaveAs(os.path.abspath(docaspdf), FileFormat=win32com.client.constants.wdFormatPDF)
		wordapp.ActiveWindow.Close()
		return docaspdf
	finally:
		wordapp.Quit()
	


if __name__ == "__main__":
	import sys
	if 'redo' in sys.argv and len(sys.argv) > 2:
		for cfps in sys.argv[2:]:
			if int(cfps) not in masterlist:
				print 'Unknown CFPS',cfps
				continue
			entry = copy.deepcopy(masterlist[int(cfps)]['versions'][-1])
			print '\nredo', cfps
			for key in 'title description keywords changes version'.split():
				print key,'=', (entry[key] if key in entry else '')
				answer = raw_input("Change "+key+"? (y/n) ")
				if answer[0] not in 'yY': continue
				else:
					newvalue = raw_input("Entry new value for "+key+": ")
					entry[key] = newvalue
			call(('cp ready/'+entry['sname']+' raw.pdf').split(' '))
			crop = 1
			for v in masterlist[int(cfps)]['versions']:
				if 'changes' in v and v['changes'] is not None:
					crop += 1 # TODO: figure out abotu multi-page change logs
					break 
			finalize(entry, int(cfps), crop)
			print 'Changed CFPS'+cfps
		with open("masterlist.json","wb") as f:
			json.dump(masterlist, f, indent=2)
		sys.exit(0)
	else:
		print 'To change an existing paper, use arguments "redo [cfps]"'

	e = webmail()
	try:
		print e
		for entry in e.search(None, 'ALL')[1][0].split():
			k = e.fetch(entry,'(RFC822)')
			process(e.fetch(entry,'(RFC822)')[1][0][1])
	finally:
		e.logout()
		try:
			with open("masterlist.json","wb") as f:
				json.dump(masterlist, f, indent=2)
		except:
			print 'Failed to save modified masterlist'
