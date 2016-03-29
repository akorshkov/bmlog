

" bmlog navigation:

" jump between start and end of method
nnoremap <silent> <buffer> [] :call bmlog_movements#StartEnd()<cr>

" move to the next method of the same depth
nnoremap <silent> <buffer> ]] :call bmlog_movements#MoveNext()<cr>
nnoremap <silent> <buffer> [[ :call bmlog_movements#MovePrev()<cr>

" move to the start/end of current method
nnoremap <silent> <buffer> }} :call bmlog_movements#MoveEnd()<cr>
nnoremap <silent> <buffer> {{ :call bmlog_movements#MoveStart()<cr>

" debug helpers
" nnoremap <silent> <buffer> zX :echo bmlog_lib#GetCurReqID()<cr>
" nnoremap <silent> <buffer> zx :echo bmlog_lib#GetCurDepth( bmlog_lib#GetCurReqID() )<cr>
