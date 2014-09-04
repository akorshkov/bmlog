" Vim syntax file
" Language: BmLogFiles

if exists("b:current_syntax")
  finish
endif

" highlight ID's. Of cource it does not work if the name of ID
" does not end with 'ID'. But it is still usefull.
syntax match bmlKeyWord /\w\+ID\>/

" ====> lines:
execute 'syntax match bmlRetVal /'.bmlog_lib#GetHdrMask("", "").' \+=\+>.*$/'

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
