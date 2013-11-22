

" common masks
let s:hdr_dt = '\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d '
let s:hdr_obj = '.\{11} '
let s:hdr_req = '.\{7} '
let s:hdr_lvl = '.\{3}]'

let s:hdr_mask = s:hdr_dt.s:hdr_obj.s:hdr_req.s:hdr_lvl


" ====================================
" Helper methods for moving around bmlog files

function bmlog_mv#GetHdrMask(reqID)
	" returns mask for the header of the bmlog line.
	" (Header looks like '[date time object request loglevel]')
	"
	" if reqID is empty, returns mask to match header with any reqID
	return len(a:reqID) ? s:hdr_dt.s:hdr_obj.a:reqID.' \+'.s:hdr_lvl : s:hdr_mask
endfunction


function bmlog_mv#GetMtdMask(reqID, depth, ifStart)
	" returns mask for log line with method boundary
	let hdr_m = bmlog_mv#GetHdrMask(a:reqID)
	let plus_minus = a:ifStart ? ' \++++' : ' \+---'
	let dpth_m = a:depth == -1 ? '\[\d\+\]' : '\['.a:depth.'\]'
	return hdr_m . plus_minus . dpth_m
endfunction


function bmlog_mv#GetCurReqID(...)
	" returns the request id corresponding to the specified (or current)
	" line of log
	let curLineId = a:0 ? a:1 : getpos('.')[1]
	while curLineId
		let l = getline(curLineId)
		if l =~ s:hdr_mask
			let reqid = l[35:41]
			echom reqid
			return reqid
		endif
		let curLineId -= 1
	endwhile
	return ''
endfunction


function bmlog_mv#GetCurDepth(reqID)
	" returns depth of the current log line
	" (-1 if current line is outside of a method of depth 0)
	let curLine = getpos('.')[1]
	let [depth, ifStart, lineid] = <SID>SearchNextMtd(a:reqID, 1)
	if ifStart && curLine != lineid
		let depth -= 1
	endif
	if depth >= 0
		return depth
	endif
	" let's try to find out
	return depth >= 0 ? depth : -1
endfunction


function bmlog_mv#SearchMtdOfLevel(reqID, depth, ifFwd, ifStart, acceptCurPos)
	" search forward/backward a start/end of the method of a level depth
	" returns lineid of a found line or 0
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let m = bmlog_mv#GetMtdMask(a:reqID, a:depth, a:ifStart)
	let searchflags = a:ifFwd ? 'nW' : 'nbW'
	if a:acceptCurPos
		let searchflags.='c'
	endif
	let lineid = search(m, searchflags)
	call setpos('.', savec)
	return lineid
endfunction


" ====================================
" Internal auxiliary methods

function s:SearchNextMtd(reqID, ifFwd)
	" searches for method start/end
	" returns:
	"   method depth
	"   if it is method start or method end (1 or 0)
	"   line id in log file
	" if nothing found returns [-1, -1, 0]
	let [lNextStart, nextStartDepth] = <SID>SearchMtd(a:reqID, a:ifFwd, 1)
	let [lNextEnd, nextEndDepth] = <SID>SearchMtd(a:reqID, a:ifFwd, 0)
	let lineNext = bmlog_mv#GetMinLine(lNextStart, lNextEnd)
	if !lineNext
		return [-1, -1, 0]
	endif
	let useStart = lineNext == lNextStart ? 1 : 0
	let depth = useStart ? nextStartDepth : nextEndDepth
	return [depth, useStart, lineNext]
endfunction


function s:SearchMtd(reqID, ifFwd, ifStart)
	" searches for start/end of pba method
	" returns lineid and depth
	" if not found returns line = 0, depth = -1
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let m = bmlog_mv#GetMtdMask(a:reqID, -1, a:ifStart)
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
