

" common masks
let s:hdr_dt = '\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d '
let s:hdr_obj = '.\{11} '
let s:hdr_req = '.\{7} '
let s:hdr_th = '.\{7} '
let s:hdr_lvl = '.\{3}]'

let s:hdr_mask_5 = s:hdr_dt.s:hdr_obj.s:hdr_req.s:hdr_lvl
let s:hdr_mask_6 = s:hdr_dt.s:hdr_obj.s:hdr_req.s:hdr_th.s:hdr_lvl

" \%(+++\|---\) - either '+++' or '---' and it is not
" a subexpression! (note '%'):
let s:f_starts_ends = { 1: '+++', 0: '\%(---\|\.\.\.\)', -1: '\%(+++\|---\|\.\.\.\)' }

" ====================================
" Helper methods for moving around bmlog files

function! bmlog_lib#GetHdrMask(reqID, bm_ver)
	" returns mask for the header of the bmlog line.
	" (Header looks like '[date time object request loglevel]')
	"
	" Arguments:
	"   - reqID - if empty, returns mask to match header with any reqID
	"   - bm_ver - version of pba. '5' or '6'.
	"              If empty - take previously detected values saved in buffer
	"              variable
	let bm_ver = len(a:bm_ver) ? a:bm_ver : (exists('b:bm_ver') ? b:bm_ver : "6")
	if bm_ver == "6"
		return len(a:reqID) ? s:hdr_dt.s:hdr_obj.a:reqID.' \+'.s:hdr_th.s:hdr_lvl : s:hdr_mask_6
	else
		return len(a:reqID) ? s:hdr_dt.s:hdr_obj.a:reqID.' \+'.s:hdr_lvl : s:hdr_mask_5
	endif
endfunction


function! bmlog_lib#GetMtdMask(reqID, depth, ifStart)
	" returns mask for log line with method boundary
	" Arguments:
	"   - reqID : request id (or empty string to match any request)
	"   - depth : depth (or -1 to match any depth)
	"   - ifStart : 1 - match method start
	"               0 - match method end
	"               -1 - match either
	let hdr_m = bmlog_lib#GetHdrMask(a:reqID, "")
	let plus_minus = s:f_starts_ends[a:ifStart] " '+++' or '---' or '+++\|---' (or even '...')
	let dpth_m = a:depth == -1 ? '\[\d\+\]' : '\['.a:depth.'\]'
	return hdr_m .' \+' . plus_minus . dpth_m
endfunction


function! bmlog_lib#GetCurReqID(...)
	" returns the request id corresponding to the specified (or current)
	" line of log
	let curLineId = a:0 ? a:1 : getpos('.')[1]
	while curLineId
		let l = getline(curLineId)
		if l =~ bmlog_lib#GetHdrMask("", "")
			let reqid = l[35:41]
			" echom reqid
			return reqid
		endif
		let curLineId -= 1
	endwhile
	return ''
endfunction


function! bmlog_lib#GetCurDepth(reqID)
	" returns depth of the current log line
	" (-1 if current line is outside of a method of depth 0)
	return bmlog_lib#GetCurDepthAndPos(a:reqID)[0]
endfunction


function! bmlog_lib#GetCurDepthAndPos(reqID)
	" returns:
	"   - depth of the current log line
	"   - curLineId
	"   - posType of the current line:
	"      's' - curline is the start line of the method
	"      'b' - curline is in the body of the method
	"      'e' - curline is the last line of the method
	" If current line is outside of zero-level function
	" returns [-1, curLineId, 'o']

	let curLineId = getpos('.')[1]
	" usually it's enough just to look backward:
	let [depth, ifStart, lineId] = <SID>SearchNextMtd(a:reqID, 0)
	if lineId
		if ifStart
			let posType = lineId == curLineId ? 's' : 'b'
			return [depth, curLineId, posType]
		elseif lineId == curLineId
			return [depth, curLineId, 'e']
		elseif depth > 0
			return [depth - 1, curLineId, 'b']
		endif
	else
		return [-1, curLineId, 'o']
	endif
	" The only case not processed yet is: looking backwards we
	" found closing of method of depth 0.
	" This either means that we are outside of 0-depth method,
	" or that there was a nested call to other container.
	" Need to look forward to find out what happened.
	let [depth, ifStart, lineid] = <SID>SearchNextMtd(a:reqID, 1)
	if lineid
		if ifStart
			if depth > 0
				return [depth -1, curLineId, 'b']
			else
				" somehow we are between closing and opening of depth 0
				" strange, but possible
				return [-1, curLineId, 'o']
			endif
		else
			return [depth, curLineId, 'b']
		endif
	endif

	return [-1, curLineId, 'o']
endfunction


function! bmlog_lib#SearchMtdOfLevel(reqID, depth, ifFwd, ifStart, acceptCurPos)
	" search forward/backward a start/end of the method of a level depth
	" returns lineid of a found line or 0
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let m = bmlog_lib#GetMtdMask(a:reqID, a:depth, a:ifStart)
	let searchflags = a:ifFwd ? 'nW' : 'nbW'
	if a:acceptCurPos
		let searchflags.='c'
	endif
	let lineid = search(m, searchflags)
	call setpos('.', savec)
	return lineid
endfunction


function! bmlog_lib#SearchMatchingMtdLine(reqID, depth, ifFwd)
	" Returns lineid of matching opening/closing method line.
	" If searching forward looks for closing line,
	" otherwise looks for opening line
	let ifStart = !a:ifFwd
	return bmlog_lib#SearchPairMtdLine(a:reqID, a:depth, a:ifFwd, ifStart ,0)
endfunction


function! bmlog_lib#SearchPairMtdLine(reqID, depth, ifFwd, ifStart, ifSkipCurPos)
	" Returns lineid of matching opening/closing method line.
	" (f.e. closing line for method depth [n] even if
	" there are several opening/closing lines for the method
	" of the same depth on the way)
	let savec = getpos('.')
	let curLineId = savec[1]

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let start_m = bmlog_lib#GetMtdMask(a:reqID, a:depth, 1)
	let end_m = bmlog_lib#GetMtdMask(a:reqID, a:depth, 0)

	let lineid = 0
	let linefound = 0
	if !a:ifSkipCurPos
		let m_m = a:ifStart ? start_m : end_m
		if getline(curLineId) =~ m_m
			let lineid = curLineId
			let linefound = 1
		endif
	endif
	if !linefound
		if a:ifFwd + a:ifStart != 1
			let [start_m, end_m] = [end_m, start_m]
		endif
		let searchflags = a:ifFwd ? 'nW' : 'nbW'
		" depending on direction returns either position of start_m or end_m:
		let lineid = searchpair(start_m, '', end_m, searchflags)
	endif
	let lineid = lineid == -1 ? 0 : lineid
	call setpos('.', savec)
	return lineid
endfunction


" ====================================
" Internal auxiliary methods

function! s:SearchNextMtd(reqID, ifFwd)
	" searches for method start/end
	" returns:
	"   method depth
	"   if it is method start or method end (1 or 0)
	"   line id in log file
	" if nothing found returns [-1, -1, 0]
	let [lineid, depth, ifStart] = <SID>SearchMtd(a:reqID, a:ifFwd, -1)
	return [depth, ifStart, lineid]
endfunction


function! s:SearchMtd(reqID, ifFwd, ifStart)
	" search log line for start/end of pba method
	" Arguments:
	"   reqID : request id (or empty string)
	"   ifFwd : search direction
	"   ifStart : if search for method start (1),
	"     method end (0) or either (-1)
	" returns [lineid, depth, ifFoundStart]
	" if not found returns [line = 0, depth = -1, ifFoundStart = -1]
	let savec = getpos('.')

	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let m = bmlog_lib#GetMtdMask(a:reqID, -1, a:ifStart)
	let flags = a:ifFwd ? 'cW' : 'bcW'

	let lineid = 0
	let depth = -1
	let ifFoundStart = -1
	if search(m, flags)
		let foundpos = getpos('.') " [buf, line, col, offset]
		let lineid = foundpos[1]
		let [depth, ifFoundStart] = bmlog_lib#GetLineProps(lineid)
	endif
	call setpos('.', savec)
	return [lineid, depth, ifFoundStart]
endfunction


function! bmlog_lib#GetLineProps(lineid)
	let l = getline(a:lineid)
	let tst_msk = bmlog_lib#GetHdrMask("", "") . ' \+\(+++\|---\|\.\.\.\)\[\(\d\+\)\]'
	let md = matchlist(l, tst_msk)
	let ifFoundStart = md[1] == '+++'
	let depth = md[2] + 0  " convert to number
	return [depth, ifFoundStart]
endfunction


" ====================================
" Very auxiliary methods

function! bmlog_lib#GetMinLine(line1, line2)
	" return min of 2 lines
	" The trick is that linex == 0 means 'undefined'
	return <SID>GetCmpLine(a:line1, a:line2, 1)
endfunction


function! bmlog_lib#GetMaxLine(line1, line2)
	" return min of 2 lines
	" The trick is that linex == 0 means 'undefined'
	return <SID>GetCmpLine(a:line1, a:line2, 0)
endfunction


function! s:GetCmpLine(line1, line2, ifMin)
	if !a:line1
		return a:line2
	elseif !a:line2
		return a:line1
	else
		return a:ifMin ? min([a:line1, a:line2]) : max([a:line1, a:line2])
	endif
endfunction
