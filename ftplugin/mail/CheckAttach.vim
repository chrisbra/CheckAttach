" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Tue, 25 Oct 2011 21:58:59 +0200
" Version:     0.12
" GetLatestVimScripts: 2796 12 :AutoInstall: CheckAttach.vim

" Plugin folklore "{{{1
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

" Functions: {{{1
fu! <SID>WarningMsg(msg) "{{{2
    " Output Warning Message
    let msg = "CheckAttach: " . a:msg
    echohl WarningMsg
    if exists(":unsilent") == 2
	    unsilent echomsg msg
    else
	    echomsg msg
    endif
    echohl Normal
    let v:errmsg = msg
endfun

fu! <SID>Init() "{{{2
    " List of highlighted matches
    let s:matchid=[]

    " On which keywords to trigger, comma separated list of keywords
    let s:attach_check = 'attach,attachment,angehängt,Anhang'
    let s:attach_check .= exists("g:attach_check_keywords") ? 
	\ g:attach_check_keywords : ''
    
    " Check for using an external file browser for selecting the files
    let s:external_file_browser = exists("g:checkattach_filebrowser") ? 
	\ g:checkattach_filebrowser : ''

    let s:external_choosefile = fnameescape(tempname())
    if s:external_file_browser == 'ranger'
	if system(s:external_file_browser . ' --choosefiles=' .
		\ s:external_choosefile . ' --version ') =~
		\ 'no such option: --choosefiles'
	    let s:external_file_browser = 'ranger --choosefile=' .
		\ s:external_choosefile
	else
	    let s:external_file_browser = 'ranger --choosefiles=' .
		\ s:external_choosefile
	endif
    endif
    if s:external_file_browser =~ '%s'
	let s:external_file_browser = substitute(s:external_file_browser,
	    \ '%s', s:external_choosefile, 'g')
    endif

    " Enable Autocommand per default
    let s:load_autocmd = exists("g:checkattach_autocmd") ? 
	\ g:checkattach_autocmd : 1
endfun

fu! <SID>TriggerAuCmd(enable) "{{{2
    " Install Autocmnd
    call <SID>Init()
    let s:load_autocmd = a:enable
    call <SID>AutoCmd()
endfun

fu! <SID>AutoCmd() "{{{2
    " Enable Auto command
    if !empty("s:load_autocmd") && s:load_autocmd 
	augroup CheckAttach  
	    au! BufWriteCmd * :call <SID>CheckAttach() 
	augroup END
    else
	silent! au! CheckAttach BufWriteCmd *
	silent! augroup! CheckAttach
        call map(s:matchid, 'matchdelete(v:val)')
	unlet! s:matchid
    endif
endfu

fu! <SID>WriteBuf(bang) "{{{2
    " Write the Buffer contents
    exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    setl nomod
endfu

fu! <SID>CheckAttach() "{{{2
    " This function checks your mail for the words specified in
    " check, and if it find them, you'll be asked to attach
    " a file.
    call <SID>Init()
    if empty("s:attach_check") || v:cmdbang
	call <SID>WriteBuf(v:cmdbang)
	return
    endif
    let oldPos=winsaveview()
    let ans=1
    let val = join(split(escape(s:attach_check,' \.+*'), ','),'\|')
    1
    let pat = '\(^\s*>\+.*\)\@<!\c\%(' . val . '\)'
    " don't match in the quoted part of the message
    if search(pat, 'W')
	" Delete old highlighting, don't pollute buffer with matches
	if exists("s:matchid")
	    "for i in s:matchid | call matchdelete(i) | endfor
	    map(s:matchid, 'matchdelete(v:val)')
	    let s:matchid=[]
	endif
	call add(s:matchid,matchadd('WildMenu', pat))
	redr!
        let ans=input("Attach file: (leave empty to abort): ", "", "file")
        while (ans != '') && (ans != 'n')
	    norm! gg}-
	    if empty(s:external_file_browser)
		let list = split(expand(ans), "\n")
		for attach in list
		    call append(line('.'), 'Attach: ' .
			\ escape(attach, " \t\\"))
		    redraw
		endfor
		let ans=input("Attach another file?: (leave empty to abort): "
		    \ , "", "file")
	    else
		call <sid>ExternalFileBrowser(isdirectory(ans) ? ans : 
			\ fnamemodify(ans, ':h'))
		let ans='n'
	    endif
        endwhile
    endif
    call <SID>WriteBuf(v:cmdbang)
    call winrestview(oldPos)
endfu

fu! <SID>ExternalFileBrowser(pat) "{{{2
    " Call external File Browser
    exe ':sil !' s:external_file_browser   a:pat
    " Force redrawing, so the screen doesn't get messed up
    redr!
    if filereadable(s:external_choosefile)
	call append('.', map(readfile(s:external_choosefile), '"Attach: ".
	    \escape(v:val, " \t\\")'))
	call delete(s:external_choosefile)
    endif
endfu

fu! <SID>AttachFile(pattern) "{{{2
    call <sid>Init()
    if empty(a:pattern) && empty(s:external_file_browser)
	call <sid>WarningMsg("No pattern supplied, can't attach a file!")
	return
    endif

    let oldpos=winsaveview()
    1
    let header_end=search('^$', 'W')
    norm! -
    let lastline=line('$')

    if !empty(s:external_file_browser)
	call <sid>ExternalFileBrowser(isdirectory(a:pattern) ? a:pattern :
	    \ fnamemodify(a:pattern, ':h'))
    else "empty(a:pattern)
	for item in split(a:pattern, ' ')
	    let list=split(expand(item), "\n")
	    for file in list
		call append('.', 'Attach: ' . escape(file, " \t\\"))
		redraw!
	    endfor
	endfor
    endif
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

" Define Commands: "{{{1
" Define commands that will disable and enable the plugin.
command! -buffer EnableCheckAttach  :call <SID>TriggerAuCmd(1)
command! -buffer DisableCheckAttach :call <SID>TriggerAuCmd(0)
command! -buffer -nargs=* -complete=file  AttachFile :call
	    \ <SID>AttachFile(<q-args>)

" Call function to set everything up "{{{2
call <SID>TriggerAuCmd(s:load_autocmd)

" Restore setting and modeline "{{{2
let &cpo = s:cpo_save
unlet s:cpo_save
" vim: set foldmethod=marker: 
