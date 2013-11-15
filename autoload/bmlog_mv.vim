

" common masks
let s:bmlog_msk = '\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d '
let s:bmlog_msk.= '.\{11} '
let s:bmlog_msk.= '.\{7} '
let s:bmlog_msk.= '.\{3}]'

let s:bmmtd_start = s:bmlog_msk.' \++++\[\d\+\]'
let s:bmmtd_end = s:bmlog_msk.  ' \+---\[\d\+\]'

" ====================================
" Helper methods for moving around bmlog files

function bmlog_mv#GetLogMask()
	" returns mask for the first portion of the bmlog line:
	" [date time object request loglevel]
	return s:bmlog_msk
endfunction

function bmlog_mv#GetCurDepth()
	" returns depth of the current log line
	" (-1 if current line is outside of a method of depth 0)
	let curLine = getpos('.')[1]
	let [depth, ifStart, lineid] = <SID>SearchNextMtd(1)
	if ifStart && curLine != lineid
		let depth -= 1
	endif
	return depth >= 0 ? depth : -1
endfunction


function bmlog_mv#SearchMtdOfLevel(depth, ifFwd, ifStart, acceptCurPos)
	" search forward/backward a start/end of the method of a level depth
	" returns lineid of a found line or 0
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let plus_minus = a:ifStart ? ' \++++\[' : ' \+---\['
	let mask = s:bmlog_msk.plus_minus.a:depth.'\]'
	let searchflags = a:ifFwd ? 'nW' : 'nbW'
	if a:acceptCurPos
		let searchflags.='c'
	endif
	let lineid = search(mask, searchflags)
	call setpos('.', savec)
	return lineid
endfunction




" ====================================
" Internal auxiliary methods

function s:SearchNextMtd(ifFwd)
	" searches for method start/end
	" returns:
	"   method depth
	"   if it is method start or method end (1 or 0)
	"   line id in log file
	" if nothing found returns [-1, -1, 0]
	let [lNextStart, nextStartDepth] = <SID>SearchMtd(a:ifFwd, 1)
	let [lNextEnd, nextEndDepth] = <SID>SearchMtd(a:ifFwd, 0)
	let lineNext = bmlog_mv#GetMinLine(lNextStart, lNextEnd)
	if !lineNext
		return [-1, -1, 0]
	endif
	let useStart = lineNext == lNextStart ? 1 : 0
	let depth = useStart ? nextStartDepth : nextEndDepth
	return [depth, useStart, lineNext]
endfunction


function s:SearchMtd(ifFwd, ifStart)
	" searches for start/end of pba method
	" returns lineid and depth
	" if not found returns line = 0, depth = -1
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let m = a:ifStart ? s:bmmtd_start : s:bmmtd_end
	let flags = a:ifFwd ? 'cW' : 'bcW'
	let lineid = 0
	let depth = -1
	if search(m, flags)
		let foundpos = getpos('.') " [buf, line, col, offset]
		let lineid = foundpos[1]
		let l = getline(lineid)
		let md = matchlist(l, '\[\(\d\+\)\]')
		let depth = md[1]
	endif
	call setpos('.', savec)
	return [lineid, depth]
endfunction


" ====================================
" Very auxiliary methods

function bmlog_mv#GetMinLine(line1, line2)
	" return min of 2 lines
	" The trick is that linex == 0 means 'undefined'
	return <SID>GetCmpLine(a:line1, a:line2, 1)
endfunction


function bmlog_mv#GetMaxLine(line1, line2)
	" return min of 2 lines
	" The trick is that linex == 0 means 'undefined'
	return <SID>GetCmpLine(a:line1, a:line2, 0)
endfunction


function s:GetCmpLine(line1, line2, ifMin)
	if !a:line1
		return a:line2
	elseif !a:line2
		return a:line1
	else
		return a:ifMin ? min([a:line1, a:line2]) : max([a:line1, a:line2])
	endif
endfunction
