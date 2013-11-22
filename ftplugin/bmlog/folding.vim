
" fold innermost loglevel
if mapcheck('zl', 'n') == ''
	nnoremap <silent> <buffer> zl :set operatorfunc=bmlog_folding#FoldInnermost<cr>g@<cr>
endif
if mapcheck('zl', 'v') == ''
	vnoremap <silent> <buffer> zl :<c-u>call bmlog_folding#FoldInnermost(visualmode())<cr>
endif

" fold one more loglevel
if mapcheck('zL', 'n') == ''
	nnoremap <unique> <silent> <buffer> zL :set operatorfunc=bmlog_folding#Fold1<cr>g@<cr>
endif
if mapcheck('zL', 'v') == ''
	vnoremap <unique> <silent> <buffer> zL :<c-u>call bmlog_folding#Fold1(visualmode())<cr>
endif
