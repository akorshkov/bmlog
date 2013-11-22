

" move forward to:
" n - next method (like 'next' in debugger)
" s - next method (like 'step' in debugger)
" f - end of current method
nnoremap <buffer> <leader>n :call bmlog_movements#MoveNextMethod()<cr>
nnoremap <buffer> <leader>s :call bmlog_movements#MoveNextMethod()<cr>
nnoremap <buffer> <leader>f :call bmlog_movements#MoveNextMethod()<cr>


nnoremap <buffer> <leader>N :call bmlog_movements#MoveNextMethod()<cr>
nnoremap <buffer> <leader>S :call bmlog_movements#MoveNextMethod()<cr>
nnoremap <buffer> <leader>F :call bmlog_movements#MoveNextMethod()<cr>

nnoremap <buffer> zx :call bmlog_mv#GetCurReqID()<cr>
