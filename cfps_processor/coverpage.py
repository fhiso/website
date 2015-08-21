'''
Uses reportlab, pdfrw, and pyPdf, as well as a lualatex executable,
to create a cover page and change log and attach them to a document

See https://pypi.python.org/pypi/pdfrw/0.1
See https://pypi.python.org/pypi/pyPdf
See https://bitbucket.org/rptlab/reportlab
'''


from reportlab.pdfgen import canvas
from reportlab.lib.pagesizes import letter, A4
from reportlab.platypus import Paragraph
from reportlab.lib.styles import ParagraphStyle
from reportlab.lib.enums import *
import re
import datetime
import codecs
try:
	from subprocess import check_output as call
except:
	from commands import getoutput as call

from pdfrw import PdfReader, PdfWriter
from pyPdf import PdfFileReader, PdfFileWriter

h12 = ParagraphStyle(fontName="Helvetica", fontSize=12, name="normal", leading=15)
h24 = ParagraphStyle(fontName="Helvetica", fontSize=24, name="title", alignment=TA_CENTER, leading=28)

latex_equivalents = {
    0x0009: ' ',
    0x000a: '\n',
    0x0023: '{\#}',
    0x0026: '{\&}',
    0x00a0: '{~}',
    0x00a1: '{!`}',
    0x00a2: '{\\not{c}}',
    0x00a3: '{\\pounds}',
    0x00a7: '{\\S}',
    0x00a8: '{\\"{}}',
    0x00a9: '{\\copyright}',
    0x00af: '{\\={}}',
    0x00ac: '{\\neg}',
    0x00ad: '{\\-}',
    0x00b0: '{\\mbox{$^\\circ$}}',
    0x00b1: '{\\mbox{$\\pm$}}',
    0x00b2: '{\\mbox{$^2$}}',
    0x00b3: '{\\mbox{$^3$}}',
    0x00b4: "{\\'{}}",
    0x00b5: '{\\mbox{$\\mu$}}',
    0x00b6: '{\\P}',
    0x00b7: '{\\mbox{$\\cdot$}}',
    0x00b8: '{\\c{}}',
    0x00b9: '{\\mbox{$^1$}}',
    0x00bf: '{?`}',
    0x00c0: '{\\`A}',
    0x00c1: "{\\'A}",
    0x00c2: '{\\^A}',
    0x00c3: '{\\~A}',
    0x00c4: '{\\"A}',
    0x00c5: '{\\AA}',
    0x00c6: '{\\AE}',
    0x00c7: '{\\c{C}}',
    0x00c8: '{\\`E}',
    0x00c9: "{\\'E}",
    0x00ca: '{\\^E}',
    0x00cb: '{\\"E}',
    0x00cc: '{\\`I}',
    0x00cd: "{\\'I}",
    0x00ce: '{\\^I}',
    0x00cf: '{\\"I}',
    0x00d1: '{\\~N}',
    0x00d2: '{\\`O}',
    0x00d3: "{\\'O}",
    0x00d4: '{\\^O}',
    0x00d5: '{\\~O}',
    0x00d6: '{\\"O}',
    0x00d7: '{\\mbox{$\\times$}}',
    0x00d8: '{\\O}',
    0x00d9: '{\\`U}',
    0x00da: "{\\'U}",
    0x00db: '{\\^U}',
    0x00dc: '{\\"U}',
    0x00dd: "{\\'Y}",
    0x00df: '{\\ss}',
    0x00e0: '{\\`a}',
    0x00e1: "{\\'a}",
    0x00e2: '{\\^a}',
    0x00e3: '{\\~a}',
    0x00e4: '{\\"a}',
    0x00e5: '{\\aa}',
    0x00e6: '{\\ae}',
    0x00e7: '{\\c{c}}',
    0x00e8: '{\\`e}',
    0x00e9: "{\\'e}",
    0x00ea: '{\\^e}',
    0x00eb: '{\\"e}',
    0x00ec: '{\\`\\i}',
    0x00ed: "{\\'\\i}",
    0x00ee: '{\\^\\i}',
    0x00ef: '{\\"\\i}',
    0x00f1: '{\\~n}',
    0x00f2: '{\\`o}',
    0x00f3: "{\\'o}",
    0x00f4: '{\\^o}',
    0x00f5: '{\\~o}',
    0x00f6: '{\\"o}',
    0x00f7: '{\\mbox{$\\div$}}',
    0x00f8: '{\\o}',
    0x00f9: '{\\`u}',
    0x00fa: "{\\'u}",
    0x00fb: '{\\^u}',
    0x00fc: '{\\"u}',
    0x00fd: "{\\'y}",
    0x00ff: '{\\"y}',
    
    0x0100: '{\\=A}',
    0x0101: '{\\=a}',
    0x0102: '{\\u{A}}',
    0x0103: '{\\u{a}}',
    0x0104: '{\\c{A}}',
    0x0105: '{\\c{a}}',
    0x0106: "{\\'C}",
    0x0107: "{\\'c}",
    0x0108: "{\\^C}",
    0x0109: "{\\^c}",
    0x010a: "{\\.C}",
    0x010b: "{\\.c}",
    0x010c: "{\\v{C}}",
    0x010d: "{\\v{c}}",
    0x010e: "{\\v{D}}",
    0x010f: "{\\v{d}}",
    0x0112: '{\\=E}',
    0x0113: '{\\=e}',
    0x0114: '{\\u{E}}',
    0x0115: '{\\u{e}}',
    0x0116: '{\\.E}',
    0x0117: '{\\.e}',
    0x0118: '{\\c{E}}',
    0x0119: '{\\c{e}}',
    0x011a: "{\\v{E}}",
    0x011b: "{\\v{e}}",
    0x011c: '{\\^G}',
    0x011d: '{\\^g}',
    0x011e: '{\\u{G}}',
    0x011f: '{\\u{g}}',
    0x0120: '{\\.G}',
    0x0121: '{\\.g}',
    0x0122: '{\\c{G}}',
    0x0123: '{\\c{g}}',
    0x0124: '{\\^H}',
    0x0125: '{\\^h}',
    0x0128: '{\\~I}',
    0x0129: '{\\~\\i}',
    0x012a: '{\\=I}',
    0x012b: '{\\=\\i}',
    0x012c: '{\\u{I}}',
    0x012d: '{\\u\\i}',
    0x012e: '{\\c{I}}',
    0x012f: '{\\c{i}}',
    0x0130: '{\\.I}',
    0x0131: '{\\i}',
    0x0132: '{IJ}',
    0x0133: '{ij}',
    0x0134: '{\\^J}',
    0x0135: '{\\^\\j}',
    0x0136: '{\\c{K}}',
    0x0137: '{\\c{k}}',
    0x0139: "{\\'L}",
    0x013a: "{\\'l}",
    0x013b: "{\\c{L}}",
    0x013c: "{\\c{l}}",
    0x013d: "{\\v{L}}",
    0x013e: "{\\v{l}}",
    0x0141: '{\\L}',
    0x0142: '{\\l}',
    0x0143: "{\\'N}",
    0x0144: "{\\'n}",
    0x0145: "{\\c{N}}",
    0x0146: "{\\c{n}}",
    0x0147: "{\\v{N}}",
    0x0148: "{\\v{n}}",
    0x014c: '{\\=O}',
    0x014d: '{\\=o}',
    0x014e: '{\\u{O}}',
    0x014f: '{\\u{o}}',
    0x0150: '{\\H{O}}',
    0x0151: '{\\H{o}}',
    0x0152: '{\\OE}',
    0x0153: '{\\oe}',
    0x0154: "{\\'R}",
    0x0155: "{\\'r}",
    0x0156: "{\\c{R}}",
    0x0157: "{\\c{r}}",
    0x0158: "{\\v{R}}",
    0x0159: "{\\v{r}}",
    0x015a: "{\\'S}",
    0x015b: "{\\'s}",
    0x015c: "{\\^S}",
    0x015d: "{\\^s}",
    0x015e: "{\\c{S}}",
    0x015f: "{\\c{s}}",
    0x0160: "{\\v{S}}",
    0x0161: "{\\v{s}}",
    0x0162: "{\\c{T}}",
    0x0163: "{\\c{t}}",
    0x0164: "{\\v{T}}",
    0x0165: "{\\v{t}}",
    0x0168: "{\\~U}",
    0x0169: "{\\~u}",
    0x016a: "{\\=U}",
    0x016b: "{\\=u}",
    0x016c: "{\\u{U}}",
    0x016d: "{\\u{u}}",
    0x016e: "{\\r{U}}",
    0x016f: "{\\r{u}}",
    0x0170: "{\\H{U}}",
    0x0171: "{\\H{u}}",
    0x0172: "{\\c{U}}",
    0x0173: "{\\c{u}}",
    0x0174: "{\\^W}",
    0x0175: "{\\^w}",
    0x0176: "{\\^Y}",
    0x0177: "{\\^y}",
    0x0178: '{\\"Y}',
    0x0179: "{\\'Z}",
    0x017a: "{\\'Z}",
    0x017b: "{\\.Z}",
    0x017c: "{\\.Z}",
    0x017d: "{\\v{Z}}",
    0x017e: "{\\v{z}}",

    0x01c4: "{D\\v{Z}}",
    0x01c5: "{D\\v{z}}",
    0x01c6: "{d\\v{z}}",
    0x01c7: "{LJ}",
    0x01c8: "{Lj}",
    0x01c9: "{lj}",
    0x01ca: "{NJ}",
    0x01cb: "{Nj}",
    0x01cc: "{nj}",
    0x01cd: "{\\v{A}}",
    0x01ce: "{\\v{a}}",
    0x01cf: "{\\v{I}}",
    0x01d0: "{\\v\\i}",
    0x01d1: "{\\v{O}}",
    0x01d2: "{\\v{o}}",
    0x01d3: "{\\v{U}}",
    0x01d4: "{\\v{u}}",
    0x01e6: "{\\v{G}}",
    0x01e7: "{\\v{g}}",
    0x01e8: "{\\v{K}}",
    0x01e9: "{\\v{k}}",
    0x01ea: "{\\c{O}}",
    0x01eb: "{\\c{o}}",
    0x01f0: "{\\v\\j}",
    0x01f1: "{DZ}",
    0x01f2: "{Dz}",
    0x01f3: "{dz}",
    0x01f4: "{\\'G}",
    0x01f5: "{\\'g}",
    0x01fc: "{\\'\\AE}",
    0x01fd: "{\\'\\ae}",
    0x01fe: "{\\'\\O}",
    0x01ff: "{\\'\\o}",

    0x02c6: '{\\^{}}',
    0x02dc: '{\\~{}}',
    0x02d8: '{\\u{}}',
    0x02d9: '{\\.{}}',
    0x02da: "{\\r{}}",
    0x02dd: '{\\H{}}',
    0x02db: '{\\c{}}',
    0x02c7: '{\\v{}}',
    
    0x03c0: '{\\mbox{$\\pi$}}',
    # consider adding more Greek here
    
    0xfb00: "{ff}",
    0xfb01: "{fi}",
    0xfb02: "{fl}",
    0xfb03: "{ffi}",
    0xfb04: "{ffl}",
    0xfb05: "{ff}",
    0xfb06: "{st}",
    
    0x2013: '{--}',
    0x2014: '{---}',
    0x2018: "{`}",
    0x2019: "{'}",
    0x201c: "{``}",
    0x201d: "{''}",
    0x2020: "{\\dag}",
    0x2021: "{\\ddag}",
    0x2122: "{\\mbox{$^\\mbox{TM}$}}",
    0x2022: "{\\mbox{$\\bullet$}}",
    0x2026: "{\\ldots}",
    0x2202: "{\\mbox{$\\partial$}}",
    0x220f: "{\\mbox{$\\prod$}}",
    0x2211: "{\\mbox{$\\sum$}}",
    0x221a: "{\\mbox{$\\surd$}}",
    0x221e: "{\\mbox{$\\infty$}}",
    0x222b: "{\\mbox{$\\int$}}",
    0x2248: "{\\mbox{$\\approx$}}",
    0x2260: "{\\mbox{$\\neq$}}",
    0x2264: "{\\mbox{$\\leq$}}",
    0x2265: "{\\mbox{$\\geq$}}",
    
}

def latexEscape(s):
	s = s.replace('\\','\\textbackslash')
	for c in '$%_{}#&':
		s = s.replace(c,"\\"+c)
	def tr(c):
		if ord(c) > 127:
			if ord(c) in latex_equivalents: return latex_equivalents[ord(c)]
			else: return ''
		return c
	s = ''.join(tr(c) for c in s)
	s = s.replace('\\textbackslash','{\\textbackslash}')
	s = s.replace("<","{\\textless}")
	s = s.replace(">","{\\textgreater}")
	s = s.replace("-","{-}")
	s = re.sub('"(\\S)','``\\1',s)
	
	return s

	
def makeTempCover(mb, num, title, **kargs):
	# fill in a cover page
	pw = int(mb[0])

	c = canvas.Canvas("temporary-cover-part.pdf", pagesize=mb)
	c.setFont("Helvetica", 18)
	y = float(mb[1])-2.5*72
	c.drawString(90, y, "CFPS "+str(num))
	c.setFont("Helvetica", 12)
	c.drawString(90, y-15, "(Call for Papers Submission number "+str(num)+")")
	
	ptitle = Paragraph(title, h24)
	y -= 72
	w,h = ptitle.wrap(pw-90*2, y-72)
	ptitle.drawOn(c, 90, y-h)
	y -= h + 36+18
	for s in ['submitter', 'type', 'replyto', 'cdate', 'mdate', 'version', 'description', 'keywords']:
		if s not in kargs: continue
		c.drawString(90, y-12, {'submitter':"Submitted by", 'type':"Type", 'replyto':"Comment on", 'cdate':"Created", 'mdate':"Last updated", 'version':"URL", 'description':"Description", 'keywords':"Keywords"}[s]+":")
		if kargs[s] is None:
			print 'MISSING:',s
			continue
		if s != "version":
			p = Paragraph(kargs[s], h12)
			w,h = p.wrap(pw-90*2-84, y-72-12)
			p.drawOn(c, 90+84, y-h)
		else:
			c.drawString(90+84,y-12,"Most recent version:")
			c.drawString(90+195,y-12, "http://fhiso.org/files/cfp/cfps"+str(num)+".pdf")
			c.drawString(90+84,y-12-15,"This version:")
			c.drawString(90+195,y-12-15, "http://fhiso.org/files/cfp/cfps"+str(num)+"_v"+re.sub("[^0-9a-zA-Z]+","-",kargs[s])+".pdf")
			h = 30
		y -= h
		y -= 15
	
	c.showPage()
	c.save()
	
	cpdf = PdfFileReader(file("temporary-cover-part.pdf", "rb"))
	if mb == letter:
		lpdf = PdfFileReader(file("coverpage-letter.pdf", "rb"))
	else:
		lpdf = PdfFileReader(file("coverpage-a4.pdf", "rb"))
	opdf = PdfFileWriter()
	p0 = cpdf.getPage(0)
	p0.mergePage(lpdf.getPage(0))
	opdf.addPage(p0)
	with file("temporary-cover.pdf", "wb") as ostream:
		opdf.write(ostream)

def makeChangeLog(mb, num, changes):
	psize = 'letter'
	if abs(float(mb[1]) - A4[1]) < 1: psize = 'a4'
	preamble=r'''\documentclass[onecolumn,12pt,%spaper]{article}
\usepackage[top=2in,bottom=1.25in,left=1.25in,right=1.25in]{geometry}
\usepackage{helvet,enumitem,fancyhdr,graphicx,eso-pic}
\newcommand\BackgroundPic{\put(0,0){\parbox[b][\paperheight]{\paperwidth}{\vfill\centering\includegraphics[width=\paperwidth,height=\paperheight]{coverpage-%s.pdf}\vfill}}}
\def\thepage{\roman{page}}
\headsep=0.75in\topmargin=0in
\pagestyle{fancy}
\fancyhf{}
\fancyhead[R]{\sf changelog \thepage\ of \pageref{lastpage}}
\def\headrule{}
\parindent=0pt
\parskip=\baselineskip
\begin{document}\sf
\AddToShipoutPicture{\BackgroundPic}
\thispagestyle{fancy}
{\Large Change Log for CFPS {%d}}
\begin{description}[leftmargin=1in,style=sameline]
''' % (psize, psize, num)
	postamble = '''\end{description}\label{lastpage}\end{document}'''
	
	body = ''
	for entry in reversed(changes):
		body += u"""\\item[\\sffamily {0}] {1}\\\\
{2}
""".format(entry[1], latexEscape(entry[0]), latexEscape(entry[2]))
	with open('changelog.tex','wb') as log:
		log.write(preamble)
		log.write(codecs.encode(body,'utf-8'))
		log.write(postamble)
	call('lualatex changelog'.split(' '))
	output = call('lualatex changelog'.split(' '))	
	ms = re.findall(r'Output written on changelog.pdf \(([0-9]*) page',output)
	if len(ms) == 0: pages = 1
	else: pages = int(ms[-1])
	return pages

def cover(ifile, ofile, num, changes, title, **kargs):
	"""cover(ifilename, ofilename, cfps, title, **kargs)
	Adds a cover page to ifilename and saves it as ofilename
	mandatory kargs:
		submitter, type, date, version, description, keywords
	optional kargs:
		replyto (used for comment type proposals)
		delete=int (used to remove int pages from front before adding cover)"""
	
	# find page size (A4 or letter)
	if ifile[-4:] == '.tex':
		with open(ifile,"rb") as texin:
			tex = texin.read()
		if tex[0:14] == '\\documentclass':
			k = re.search(r'$\\documentclass\[[^\]]*(a4|letter)paper', tex)
		else:
			k = re.search(r'\n[^%]*\\documentclass\[[^\]]*(a4|letter)paper', tex)
		if k is None or k.group(1) == 'letter': mb = letter
		else: mb = A4
	else:
		ipdf = PdfFileReader(file(ifile, "rb"))
		mb = ipdf.getPage(0).mediaBox.getUpperRight_x(), ipdf.getPage(0).mediaBox.getUpperRight_y()
		if mb[0] is None: mb = letter
	
	# fill in a cover page
	makeTempCover(mb, num, title, **kargs)

	# make a change log page
	if changes:
		clpages = makeChangeLog(mb, num, changes)
	
	# apply the cover page and change log to the document
	if ifile[-4:] == '.tex':
		ipoint = re.search(r'\n[^%\n]*\\begin.document.',tex)
		if ipoint == None:
			raise Exception("No \\begin{document} in .tex file")
		
		pre = tex[:ipoint.start()]
		post = tex[ipoint.end():]
		lines = [ pre 
			, "\\usepackage{pdfpages,hyperref}" 
			, "\\hypersetup{pdfinfo={"
			, "Title={FHISO CFPS "+str(num)+": "+latexEscape(title)+"},"
			, "Author={"+latexEscape(kargs['submitter'])+"},"
			, "Subject={Family History Information Standards Organisation (FHISO) Call for Papers Submission},"
			, "Creator={FHISO CFPS Cover Page Script},"
			, "Producer={FHISO CFPS Cover Page Script},"
			, "Keywords={"+latexEscape(kargs['keywords'])+"},"
			, "CreationDate={D:"+datetime.datetime.strptime(kargs['cdate'],"%Y-%m-%d").strftime("%Y%m%d%H%M%S")+"},"
			, "ModDate={D:"+datetime.datetime.now().strftime("%Y%m%d%H%M%S")+"}"
			, "}}"
			, "\\begin{document}"
			, '\\thispagestyle{empty}\\includepdf[pages=1]{temporary-cover.pdf}\\newpage\\addtocounter{page}{-1}'
			]
		if changes:
			for i in range(1,clpages+1):
				lines.append(
				'\\thispagestyle{empty}\\includepdf[pages='+str(i)+']{changelog.pdf}\\newpage\\addtocounter{page}{-1}'
				)
		lines.append(post)
		with open('raw2.tex','wb') as texout:
			texout.write('\n'.join(lines))
		call('lualatex --halt-on-error --interaction=batchmode raw2'.split(' '))
		call('lualatex --halt-on-error --interaction=batchmode raw2'.split(' '))
		call('lualatex --halt-on-error --interaction=batchmode raw2'.split(' '))
		call(('mv raw2.pdf '+ofile).split(' '))
		
	else: # pdf not tex
		cpdf = PdfFileReader(file("temporary-cover.pdf", "rb"))
		opdf = PdfFileWriter()
		p0 = cpdf.getPage(0)
		opdf.addPage(p0)

		if changes:
			# add the changelog to the document
			cpdf = PdfFileReader(file("changelog.pdf", "rb"))
			for p in range(cpdf.getNumPages()):
				opdf.addPage(cpdf.getPage(p))
		
		# copy rest of pages
		if 'delete' in kargs:
			start = kargs['delete']
		else:
			start = 0
		for i in range(start, ipdf.numPages):
			opdf.addPage(ipdf.getPage(i))
	
		with file("temporary-output.pdf", "wb") as ostream:
			opdf.write(ostream)
		metadata = PdfReader("temporary-output.pdf")
		metadata.Info.Title = "FHISO CFPS "+str(num)+": "+title
		metadata.Info.Author = kargs['submitter']
		metadata.Info.Subject = "Family History Information Standards Organisation (FHISO) Call for Papers Submission"
		metadata.Info.Creator = "FHISO CFPS Cover Page Script"
		metadata.Info.Producer = "FHISO CFPS Cover Page Script"
		metadata.Info.Keywords = kargs['keywords']
		metadata.Info.CreationDate = "D:"+datetime.datetime.strptime(kargs['cdate'],"%Y-%m-%d").strftime("%Y%m%d%H%M%S")
		metadata.Info.ModDate = "D:"+datetime.datetime.now().strftime("%Y%m%d%H%M%S")
		writer = PdfWriter()
		writer.trailer = metadata
		writer.write(ofile)
	
	
	

__all__ = ["cover"]
