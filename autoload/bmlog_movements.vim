

" ==========================================
" global constants

let s:F_START = 1
let s:F_END = 0

let s:MV_FWD = 1
let s:MV_BKWD = 0

" ==========================================
" top-level functions to be used in mappings


function! bmlog_movements#StartEnd()
	" jump between start and end of method
	let reqID = bmlog_lib#GetCurReqID()
	let [depth, curLineId, posType] = bmlog_lib#GetCurDepthAndPos(reqID)
	if posType == 'b' || posType == 's'
		:norm m'
		call <SID>MoveToFirstFoundLine(s:MV_FWD, reqID, [[depth, s:F_END], ])
	elseif posType == 'e'
		:norm m'
		call <SID>MoveToFirstFoundLine(s:MV_BKWD, reqID, [[depth, s:F_START], ])
	endif
endfunction


function! bmlog_movements#MoveNext()
	" move forward to the start of the next method of the same depth
	:norm m'
	let ifFwd = s:MV_FWD
	let reqID = bmlog_lib#GetCurReqID()
	let [depth, curLineId, posType] = bmlog_lib#GetCurDepthAndPos(reqID)
	if posType == 's' || posType == 'e'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth, s:F_START], [depth - 1, s:F_END]])
	elseif posType == 'b'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth + 1, s:F_START], [depth, s:F_END]])
	elseif posType == 'o'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[0, s:F_START]])
	else
		echo "bmlog_movements internal error"
	endif
endfunction


function! bmlog_movements#MovePrev()
	" move backwards to the start of the previous method of the same depth
	" usually opposite to MoveNext
	:norm m'
	let ifFwd = 0
	let reqID = bmlog_lib#GetCurReqID()
	let [depth, curLineId, posType] = bmlog_lib#GetCurDepthAndPos(reqID)
	if posType == 's' || posType == 'e'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth, s:F_START], [depth - 1, s:F_START]])
	elseif posType == 'b'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth + 1, s:F_START], [depth, s:F_START]])
	elseif posType == 'o'
		echo "outside method"
	else
		echo "bmlog_movements internal error"
	endif
endfunction


function! bmlog_movements#MoveStart()
	" move backwards to the start of the current method
	:norm m'
	let ifFwd = 0
	let reqID = bmlog_lib#GetCurReqID()
	let [depth, curLineId, posType] = bmlog_lib#GetCurDepthAndPos(reqID)
	if posType == 's'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth - 1, s:F_START]])
	elseif posType == 'b' || posType == 'e'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth, s:F_START]])
	elseif posType == 'o'
		echo "outside method"
	else
		echo "bmlog_movements internal error"
	endif
endfunction


function! bmlog_movements#MoveEnd()
	" move forward to the end of the current method
	:norm m'
	let ifFwd = 1
	let reqID = bmlog_lib#GetCurReqID()
	let [depth, curLineId, posType] = bmlog_lib#GetCurDepthAndPos(reqID)
	if posType == 's' || posType == 'e'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth - 1, s:F_END]])
	elseif posType == 'b'
		call <SID>MoveToFirstFoundLine(ifFwd, reqID,
			\ [[depth, s:F_END]])
	elseif posType == 'o'
		echo "outside method"
	else
		echo "bmlog_movements internal error"
	endif
endfunction


" ==========================================
" local helpers

function! s:MoveToClosingCurMethod(reqID, depth, ifFwd)
	let curpos = getpos('.')
	let lineid = bmlog_lib#SearchMatchingMtdLine(a:reqID, a:depth, a:ifFwd)
	if lineid
		let curpos[1] = lineid
		call setpos('.', curpos)
	endif
endfunction


function! s:MoveToFirstFoundLine(ifFwd, reqID, searchList)
	let tgtLineId = <SID>FindFirstSkipNested(a:ifFwd, a:reqID, a:searchList)
	if tgtLineId
		let curpos = getpos('.')
		let curpos[1] = tgtLineId
		call setpos('.', curpos)
	endif
endfunction


function! s:FindFirst(ifFwd, reqID, searchList)
	" Returns the id of the first string matching specified criteria.
	" F.e. finds closing line of depth 5 or opening line of depth 6.
	" Arguments:
	"  ifFwd    - if serach forward
	"  searchList - list of possible criteria sets. Each item of the list
	"             is also a list: [ifStart, depth].
	let masks = []
	for [depth, ifStart] in a:searchList
		if depth >= 0
			let m = bmlog_lib#GetMtdMask(a:reqID, depth, ifStart)
			call add(masks, m)
		endif
	endfor
	if len(masks) == 0
		return 0
	endif
	let the_mask = join(masks, '\|')

	let savec = getpos('.')
	let srch_start_pos = copy(savec)
	let srch_start_pos[2] = 1  " we will start search from the first column
	call setpos('.', srch_start_pos)

	let searchflags = a:ifFwd ? 'nW' : 'nbW'
	let lineid = search(the_mask, searchflags)

	call setpos('.', savec)

	return lineid
endfunction


function! s:FindFirstSkipNested(ifFwd, reqID, searchList)
	" Similar to FindFirst, but skip nested calls to other containers.
	let nestedCallSearchProps = [0, a:ifFwd]
	if count(a:searchList, nestedCallSearchProps) > 0
		" There is no need actually to skip nested calls. We are lookign for
		" it (that is for start of the call depth 0)
		return <SID>FindFirst(a:ifFwd, a:reqID, a:searchList)
	endif

	let extendedSearchList = add(a:searchList, nestedCallSearchProps)

	let lineid = <SID>FindFirst(a:ifFwd, a:reqID, extendedSearchList)
	if lineid <= 0
		return 0 " match not found
	endif

	if <SID>LineMatchesSearchProp(lineid, nestedCallSearchProps)
		" we found nested call
		let savec = getpos('.')
		let tmpPos = copy(savec)
		let tmpPos[1] = lineid
		call setpos('.', tmpPos)
		let lineid = <SID>SkipNestedCalls(a:ifFwd, a:reqID,
					\extendedSearchList, nestedCallSearchProps)
		call setpos('.', savec)
	endif

	return lineid
endfunction


function! s:SkipNestedCalls(ifFwd, reqID, extendedSearchList, nestedCallSearchProps)
	let curpos = getpos('.')
	let curlineId = curpos[1]
	while <SID>LineMatchesSearchProp(curlineId, a:nestedCallSearchProps)
		let curlineId = bmlog_lib#SearchMatchingMtdLine(a:reqID, 0, a:ifFwd)
		if curlineId <= 0
			return 0  " start of the nested call was found, but the end was not
		endif
		let curpos[1] = curlineId
		call setpos('.', curpos)
		let curlineId = <SID>FindFirst(a:ifFwd, a:reqID, a:extendedSearchList)
		let curpos[1] = curlineId
		call setpos('.', curpos)
	endwhile
	return curlineId
endfunction


function! s:LineMatchesSearchProp(lineid, searchProps)
	" checks if line matches searchProps [depth, ifStart]
	" (if line with lineid does not exists returns 0)
	if a:lineid <= 0
		return 0
	endif
	let tmpProps = bmlog_lib#GetLineProps(a:lineid)
	return a:searchProps == bmlog_lib#GetLineProps(a:lineid)
endfunction
