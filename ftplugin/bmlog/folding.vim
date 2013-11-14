
" fold innermost loglevel
nnoremap <buffer> zl :set operatorfunc=<SID>FoldInnermost<cr>g@<cr>
vnoremap <buffer> zl :<c-u>call <SID>FoldInnermost(visualmode())<cr>

" fold one more loglevel
nnoremap <buffer> zL :set operatorfunc=<SID>Fold1<cr>g@<cr>
vnoremap <buffer> zL :<c-u>call <SID>Fold1(visualmode())<cr>

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


" TODO : remove this map (current debug purposes)
nnoremap <leader>x :echo <SID>GetCurDepth()<cr>

" common masks
let s:bmlog_msk = '\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d '
let s:bmlog_msk.= '.\{11} '
let s:bmlog_msk.= '.\{7} '
let s:bmlog_msk.= '.\{3}]'

let s:bmmtd_start = s:bmlog_msk.' \++++\[\d\+\]'
let s:bmmtd_end = s:bmlog_msk.  ' \+---\[\d\+\]'


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
		let depth = <SID>GetCurDepth()
		if depth >= 0
			let amended_depth = depth - a:log_delta
			let amended_depth = amended_depth >= 0 ? amended_depth : 0
			call <SID>FoldDepth(amended_depth)
			echo ""
		else
			echo "nothing to fold: not inside a method"
		endif
	endif
endfunction


function s:FoldDepth(depth)
	" fold log lines of a method of a specified depth (around cur position)
	let startline = <SID>SearchMtdOfLevel(a:depth, 0, 1, 1)
	let startline = startline ? startline + 1 : 1
	let endline = <SID>SearchMtdOfLevel(a:depth, 1, 0, 1)
	let endline = endline ? endline -1 : line('$')
	while endline && <SID>LineIsResult(endline)
		let endline -= 1
	endwhile
	if endline > startline + 1
		execute startline.','.endline."fold"
	endif
endfunction


function s:SearchMtdOfLevel(depth, ifFwd, ifStart, acceptCurPos)
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


function s:LineIsResult(lineid)
	" returns 1 if line is a 'result'. That is if line looks like
	" [..usual stamp...] ==> ....
	let l = getline(a:lineid)
	let m = s:bmlog_msk.' =\+>'
	return l =~# m
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


function s:SearchNextMtd(ifFwd)
	" searches for method start/end
	" returns:
	"   method depth
	"   if it is method start or method end (1 or 0)
	"   line id in log file
	" if nothing found returns [-1, -1, 0]
	let [lNextStart, nextStartDepth] = <SID>SearchMtd(a:ifFwd, 1)
	let [lNextEnd, nextEndDepth] = <SID>SearchMtd(a:ifFwd, 0)
	let lineNext = <SID>GetMinLine(lNextStart, lNextEnd)
	if !lineNext
		return [-1, -1, 0]
	endif
	let useStart = lineNext == lNextStart ? 1 : 0
	let depth = useStart ? nextStartDepth : nextEndDepth
	return [depth, useStart, lineNext]
endfunction


function s:GetCurDepth()
	" returns depth of the current line
	let curLine = getpos('.')[1]
	let [depth, ifStart, lineid] = <SID>SearchNextMtd(1)
	if ifStart && curLine != lineid
		let depth -= 1
	endif
	return depth >= 0 ? depth : -1
endfunction


function s:MoveNextMethod()
	let ifFwd = 1
	let depth = <SID>GetCurDepth()
	let next_opening = <SID>SearchMtdOfLevel(depth, ifFwd, 1, 0)
	let next_closing = depth > 0 ? <SID>SearchMtdOfLevel(depth - 1, ifFwd, 0, 0) : 0
	let nextLine = <SID>GetMinLine(next_opening, next_closing)
	if nextLine
		" goto line:
		execute nextLine
	endif
endfunction


" ====================================
" Very auxiliary methods

function s:GetMinLine(line1, line2)
	" return min of 2 lines
	" The trick is that linex == 0 means 'undefined'
	return <SID>GetCmpLine(a:line1, a:line2, 1)
endfunction


function s:GetMaxLine(line1, line2)
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
