

" move forward to:
" n - next method (like 'next' in debugger)
" s - next method (like 'step' in debugger)
" f - end of current method
nnoremap <buffer> <leader>n :call <SID>MoveNextMethod()<cr>
nnoremap <buffer> <leader>s :call <SID>MoveNextMethod()<cr>
nnoremap <buffer> <leader>f :call <SID>MoveNextMethod()<cr>


nnoremap <buffer> <leader>N :call <SID>MoveNextMethod()<cr>
nnoremap <buffer> <leader>S :call <SID>MoveNextMethod()<cr>
nnoremap <buffer> <leader>F :call <SID>MoveNextMethod()<cr>


function s:MoveNextMethod()
	let ifFwd = 1
	let depth = bmlog_mv#GetCurDepth()
	let next_opening = bmlog_mv#SearchMtdOfLevel(depth, ifFwd, 1, 0)
	let next_closing = depth > 0 ? bmlog_mv#SearchMtdOfLevel(depth - 1, ifFwd, 0, 0) : 0
	let nextLine = bmlog_mv#GetMinLine(next_opening, next_closing)
	if nextLine
		" goto line:
		execute nextLine
	endif
endfunction
