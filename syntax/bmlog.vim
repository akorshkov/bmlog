" Vim syntax file
" Language: BmLogFiles

if exists("b:current_syntax")
  finish
endif

" highlight ID's. Of cource it does not work if the name of ID
" does not end with 'ID'. But it is still usefull.
syntax match bmlKeyWord /\w\+ID\>/

let s:bmlm_time='\m^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d\d\d '
let s:bmlm_obj='.\{11} '
let s:bmlm_req='.\{7} '
let s:bmlm_lvl='.\{3}\]'

let s:bmlog_msk = s:bmlm_time.s:bmlm_obj.s:bmlm_req.s:bmlm_lvl

let s:ret_msk = s:bmlog_msk.' =\+>'

execute 'syntax match bmlRetVal /'.s:ret_msk.'.*$/'

syntax match bmlDbTransact /^.* application transaction =.*$/
syntax match bmlDbTransact /^.* ROLLBACK of transaction =.*$/
" syntax match bmlDbLocks /^.*Exclusively locking a row.*$/

syntax region bmlRDBMS start="^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d RDBMS " end="$" contains=bmlKeyWord

syntax region bmlIntercall start="^\[\d\d-\d\d-\d\d \d\d:\d\d:\d\d\.\d\d\d RO_" end="\]" contains=bmlKeyWord

syntax match bmlERRMsg /^.* ERR] .*$/

syntax region bmlMyMark start="^ \[" end="$"
syntax region bmlMyComment start="^c:" end="$"


highlight link bmlKeyWord SpecialKey

" highlight link bmlDbLocks Identifier
" highlight link bmlDbLocks SpecialComment
highlight link bmlRDBMS Statement

highlight link bmlDbTransact Special
" highlight link bmlDbTransact MoreMsg
highlight link bmlRetVal NonText

highlight link bmlERRMsg ErrorMsg
highlight link bmlIntercall WarningMsg

highlight link bmlMyMark Identifier

highlight link bmlMyComment MoreMsg
