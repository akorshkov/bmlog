
" ==========================================
" top-level functions to be used in mappings

function bmlog_movements#MoveNextMethod()
	let ifFwd = 1
	let reqID = bmlog_lib#GetCurReqID()
	let depth = bmlog_lib#GetCurDepth(reqID)
	let next_opening = bmlog_lib#SearchMtdOfLevel(reqID, depth, ifFwd, 1, 0)
	let next_closing = depth > 0 ? bmlog_lib#SearchMtdOfLevel(reqID, depth - 1, ifFwd, 0, 0) : 0
	let nextLine = bmlog_lib#GetMinLine(next_opening, next_closing)
	if nextLine
		" goto line:
		execute nextLine
	endif
endfunction

" ==========================================
" local helpers
