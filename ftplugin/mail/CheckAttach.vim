" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 30 Sep 2011 21:40:15 +0200
" Version:     0.11
" GetLatestVimScripts: 2796 11 :AutoInstall: CheckAttach.vim

" Plugin folklore "{{{2
" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
" - the autocmd event is not available.
if exists("g:loaded_checkattach") || &cp ||
	\ !exists("##BufWriteCmd") ||
	\ !exists("##FileWriteCmd")
  finish
endif
let g:loaded_checkattach = 1
let s:cpo_save = &cpo
set cpo&vim

" default value, when plugin is loaded
let s:load_autocmd = 1

fu! <SID>Init() "{{{1
    " List of highlighted matches
    let s:matchid=[]

    " On which keywords to trigger, comma separated list of keywords
    let s:attach_check = 'attach,attachment,angehängt,Anhang'
    let s:attach_check .= exists("g:attach_check_keywords") ? 
	\ g:attach_check_keywords : ''

    " Enable Autocommand per default
    let s:load_autocmd = exists("g:checkattach_autocmd") ? 
	\ g:checkattach_autocmd : 1
endfun

fu! <SID>TriggerAuCmd(enable) "{{{1
    call <SID>Init()
    let s:load_autocmd = a:enable
    call <SID>AutoCmd()
endfun

" Enable Auto command "{{{1
fu! <SID>AutoCmd() "{{{2
    if !empty("s:load_autocmd") && s:load_autocmd 
	augroup CheckAttach  
	    au! BufWriteCmd * :call <SID>CheckAttach() 
	augroup END
    else
	silent! au! CheckAttach BufWriteCmd *
	silent! augroup! CheckAttach
        call map(s:matchid, 'matchdelete(v:val)')
	let s:matchid=[]
    endif
endfu

" Write the Buffer contents "{{{1
fu! <SID>WriteBuf(bang) "{{{2
    exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    setl nomod
endfu

" Function CheckAttach "{{{2
" This function checks your mail for the words specified in
" check, and if it find them, you'll be asked to attach
" a file.
fu! <SID>CheckAttach() "{{{2
    call <SID>Init()
    if empty("s:attach_check") || v:cmdbang
	call <SID>WriteBuf(v:cmdbang)
	return
    endif
    let oldPos=winsaveview()
    let ans=1
    let val = join(split(escape(s:attach_check,' \.+*'), ','),'\|')
    1
    if search('\c\%('.val.'\)','W')
	" Delete old highlighting, don't pollute buffer with matches
	if exists("s:matchid")
	    "for i in s:matchid | call matchdelete(i) | endfor
	    map(s:matchid, 'matchdelete(v:val)')
	    let s:matchid=[]
	endif
	call add(s:matchid,matchadd('WarningMsg', '\c\%('.val.'\)'))
	redr!
        let ans=input("Attach file: (leave empty to abort): ", "", "file")
        while (ans != '') && (ans != 'n')
	    let list = split(expand(ans), "\n")
	    for attach in list
		norm! magg}-
		call append(line('.'), 'Attach: ' . escape(attach, " \t\\"))
		redraw
	    endfor
            let ans=input("Attach another file?: (leave empty to abort): ", "", "file")
        endwhile
    endif
    call <SID>WriteBuf(v:cmdbang)
    call winrestview(oldPos)
endfu "}}}2

fu! <SID>AttachFile(pattern) "{{{2
    let oldpos=winsaveview()
    let lastline=line('$')
    " start at line 1, later we are searching the end
    " of the header of the mail, so that we can append the 
    " Attach-headers there.
    1
    let header_end=search('^$', 'nW')
    for item in split(a:pattern, ' ')
	let list=split(expand(item), "\n")
	for file in list
	    norm! gg}-
	    call append(line('.'), 'Attach: ' . escape(file, " \t\\"))
	    redraw
	endfor
    endfor
    let newlastline=line('$')
    " Adding text above, means, we need to adjust
    " the cursor position from the oldpos dictionary. 
    " Should oldpos.topline also be adjusted ?
    let oldpos.lnum+=newlastline-lastline
    if oldpos.topline > header_end
	let oldpos.topline+=newlastline-lastline
    endif
    call winrestview(oldpos)
endfun

" Define Commands: "{{{3
" Define commands that will disable and enable the plugin. "{{{1
command! EnableCheckAttach  :call <SID>TriggerAuCmd(1)
command! DisableCheckAttach :call <SID>TriggerAuCmd(0)
command! -nargs=+ -complete=file  AttachFile :call <SID>AttachFile(<q-args>)

" Call function to set everything up "{{{2
call <SID>TriggerAuCmd(s:load_autocmd)
" Restore setting "{{{2
let &cpo = s:cpo_save
unlet s:cpo_save

" Vim Modeline " {{{2
" vim: set foldmethod=marker: 
