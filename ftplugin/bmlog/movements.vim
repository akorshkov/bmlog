

" move forward to:
" n - next method (like 'next' in debugger)
" s - next method (like 'step' in debugger)
" f - end of current method
nnoremap <silent> <buffer> <leader>n :call bmlog_movements#MoveNext()<cr>
nnoremap <silent> <buffer> <leader>s :call bmlog_movements#MoveNext()<cr>
nnoremap <silent> <buffer> <leader>f :call bmlog_movements#MoveFinish()<cr>


nnoremap <silent> <buffer> <leader>N :call bmlog_movements#MovePrev()<cr>
nnoremap <silent> <buffer> <leader>S :call bmlog_movements#MoveNext()<cr>
nnoremap <silent> <buffer> <leader>F :call bmlog_movements#MoveStart()<cr>

nnoremap <silent> <buffer> zX :echo bmlog_lib#GetCurReqID()<cr>
nnoremap <silent> <buffer> zx :echo bmlog_lib#GetCurDepth( bmlog_lib#GetCurReqID() )<cr>
