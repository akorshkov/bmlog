
" fold innermost loglevel
if !mapcheck('zl', 'nvo')
	nnoremap <silent> <buffer> zl :set operatorfunc=<SID>FoldInnermost<cr>g@<cr>
	vnoremap <silent> <buffer> zl :<c-u>call <SID>FoldInnermost(visualmode())<cr>
endif

" fold one more loglevel
if !mapcheck('zL', 'nvo')
	nnoremap <unique> <silent> <buffer> zL :set operatorfunc=<SID>Fold1<cr>g@<cr>
	vnoremap <unique> <silent> <buffer> zL :<c-u>call <SID>Fold1(visualmode())<cr>
endif


function s:FoldInnermost(selection_type)
	" fold innermost level of log (around cur position)
	call <SID>DoFold(a:selection_type, 0)
endfunction


function s:Fold1(selection_type)
	" fold second innermost level of log (around cur position)
	call <SID>DoFold(a:selection_type, 1)
endfunction


function s:DoFold(selection_type, log_delta)
	" fold innermost level of log (around cur position)
	if a:selection_type ==# 'V'
		" TODO need to find out how to determine boundaries of selection
		execute "`[v`]fold"
	elseif a:selection_type ==# 'line'
		let depth = bmlog_mv#GetCurDepth()
		if depth >= 0
			let amended_depth = depth - a:log_delta
			let amended_depth = amended_depth >= 0 ? amended_depth : 0
			call <SID>FoldDepth(amended_depth)
			" echo ""
		else
			echo "nothing to fold: not inside a method"
		endif
	endif
endfunction


function s:FoldDepth(depth)
	" fold log lines of a method of a specified depth (around cur position)
	let startline = bmlog_mv#SearchMtdOfLevel(a:depth, 0, 1, 1)
	let startline = startline ? startline + 1 : 1
	let endline = bmlog_mv#SearchMtdOfLevel(a:depth, 1, 0, 1)
	let endline = endline ? endline -1 : line('$')
	while endline && <SID>LineIsResult(endline)
		let endline -= 1
	endwhile
	if endline > startline + 1
		execute startline.','.endline."fold"
	endif
endfunction


function s:LineIsResult(lineid)
	" returns 1 if line is a 'result'. That is if line looks like
	" [..usual stamp...] ==> ....
	let l = getline(a:lineid)
	let m = bmlog_mv#GetLogMask().' =\+>'
	return l =~# m
endfunction
