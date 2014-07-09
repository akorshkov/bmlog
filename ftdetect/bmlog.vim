autocmd BufNewFile,BufRead *.log call Detect_bmlog_filetype()
" autocmd BufNewFile,BufRead summary setfiletype ssm

let s:bmlog_msk = '\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d '
let s:bmlog_msk.= '.\{11} '
let s:bmlog_msk.= '.\{7} '
let s:bmlog_msk.= '.\{7} '
let s:bmlog_msk.= '.\{3}\]'

function! Detect_bmlog_filetype()
	" detect filetype as bmlog if one o the first
	" lines matches looks like standard pba log record:
	" [date time worker request loglevel]
	let savec = getpos('.')
	call cursor(1, 1)
	if search(s:bmlog_msk, 'cn', 200)
		setfiletype bmlog
	end
	call setpos('.', savec)
endfunction
