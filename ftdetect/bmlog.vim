autocmd BufNewFile,BufRead *.log call Detect_bmlog_filetype()

function! Detect_bmlog_filetype()
	" Detect filetype as bmlog if one of the first
	" lines matches looks like standard pba log record:
	" [date time worker request loglevel]
	"
	" If file looks like bm log, saves bm version into
	" b:bm_ver.
	let savec = getpos('.')
	call cursor(1, 1)
	if search(bmlog_lib#GetHdrMask("", "6"), 'cn', 200)
		let b:bm_ver = "6"
		setfiletype bmlog
	elseif search(bmlog_lib#GetHdrMask("", "5"), 'cn', 200)
		let b:bm_ver = "5"
		setfiletype bmlog
	end
	call setpos('.', savec)
endfunction
