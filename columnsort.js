/*
 * Custom column sorting application by Luther Tychonievich, 2013-04-15
 * Treats numbers a single entities; this a22b33c < a22b100c
 * 
 * USAGE: sortcolumn( "id-of-tbody-element", 3 ) to sort on the 4th column
 * Assumes the existence of a header row
 */

function compareColumn( column ) {
	return function(a,b) {
		a = a.cells[column].innerHTML.replace(/<[^>]*>/g, "");
		b = b.cells[column].innerHTML.replace(/<[^>]*>/g, "");
		var i=0;
		var j=0;
		while( i < a.length && j < b.length ) {
			var ac = a.charCodeAt(i);
			i += 1;
			var bc = b.charCodeAt(j);
			j += 1;
			if (ac >= 48 && ac <= 57 && bc >= 48 && bc <= 57) {
				ac -= 48;
				while (i < a.length && a.charCodeAt(i) >= 48 && a.charCodeAt(i) <= 57) {
					ac = ac*10 + a.charCodeAt(i) - 48;
					i += 1;
				}
				bc -= 48;
				while (j < b.length && b.charCodeAt(j) >= 48 && b.charCodeAt(j) <= 57) {
					bc = bc*10 + b.charCodeAt(j) - 48;
					j += 1;
				}
			} 
			if (ac != bc) return ac - bc;
		}
		return (a.length - i) - (b.length - j);
	}
}

function stableSort( array, func, si, ei ) {
	if ( si === undefined ) { si = 0; ei = array.length-1; }
	if ( si >= ei ) return;
	var mi = Math.floor((si+ei)/2);
	stableSort( array, func, si, mi );
	stableSort( array, func, mi+1, ei );
	var front = array.slice(si,mi+1);
	var back = array.slice(mi+1,ei+1);
	var fi = 0;
	var bi = 0;
	for (var ai = si; ai <= ei; ai += 1) {
		if ( bi >= back.length || (fi < front.length && (func(front[fi], back[bi]) <= 0)) ) {
			array[ai] = front[fi];
			fi += 1;
		} else {
			array[ai] = back[bi];
			bi += 1;
		}
	}
}


function sortcolumn( tbody, column, doalt ) {
	var tab = document.getElementById( tbody );
	var toSort = new Array();
	for (var i=1; i<tab.rows.length; i+=1) {
		toSort[i-1] = tab.rows[i];
	}
	var header = tab.rows[0];
//	toSort.sort( compareColumn(column) );
	stableSort( toSort, compareColumn(column) );
	
	var changed = false;
	for (var i=1; i<tab.rows.length; i+=1) {
		if (toSort[i-1] != tab.rows[i]) changed = true;
	}
	if (!changed) toSort.reverse();
	
	while (tab.hasChildNodes()) tab.removeChild( tab.lastChild );
	tab.appendChild(header);
	for (var i=0; i<toSort.length; i+=1) {
		tab.appendChild(toSort[i]);
		if (doalt) {
			if ((i % 2) == 0) {
				tab.lastChild.setAttribute("class","");
			} else {
				tab.lastChild.setAttribute("class","alt");
			}
		}
	}
}



var filterrows = function(tbody, searchstring) {
	var tab = document.getElementById( tbody );
	var visCount = 0;
	for (var i=1; i<tab.rows.length; i+=1) {
		var contents = tab.rows[i].innerHTML;
		var tag = /<[^><]*>/g;
		while (contents.search(tag) >= 0) contents = contents.replace(tag,"\t");
		contents = contents.replace(/\t\t+/,"\t");
		var where = contents.toLowerCase().search(searchstring);
		if ( where < 0 ) {
			tab.rows[i].setAttribute("class","hide");
		} else {
			visCount += 1;
			if ( (visCount%2) == 1 ) {
				tab.rows[i].setAttribute("class","alt");
			} else {
				tab.rows[i].setAttribute("class","");
			}
		}
	}
}
