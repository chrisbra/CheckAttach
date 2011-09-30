" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Fri, 30 Sep 2011 14:22:21 +0200
" Version:     0.8
" GetLatestVimScripts: 2796 8 :AutoInstall: CheckAttach.vim

" Plugin folklore "{{{2
" Exit quickly when: 
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
" - the autocmd event is not availble.
if exists("g:loaded_checkattach") || &cp ||
	\ !exists("##BufWriteCmd") ||
	\ !exists("##FileWriteCmd")
  finish
endif
let g:loaded_checkattach = 1
let s:cpo_save = &cpo
set cpo&vim

" enable Autocommand for attachment checking
let s:load_autocmd=1

" List of highlighted matches
let s:matchid=[]

" On which keywords to trigger, comma separated list of keywords
let g:attach_check_keywords = 'attach,attachment,angehängt,Anhang'

"Function AutoCmd "{{{2
fu! <SID>AutoCmd()
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

" Function WriteBuf "{{{2
fu! <SID>WriteBuf(bang)
    exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    setl nomod
endfu

" Function CheckAttach "{{{2
" This function checks your mail for the words specified in
" check, and if it find them, you'll be asked to attach
" a file.
fu! <SID>CheckAttach()
    if exists("g:attach_check_keywords")
       let s:attach_check = g:attach_check_keywords
    endif

    if empty("s:attach_check") || v:cmdbang
	:call <SID>WriteBuf(v:cmdbang)
	return
    endif
    let oldPos=getpos('.')
    let ans=1
    let val = join(split(escape(s:attach_check,' \.+*'), ','),'\|')
    1
    if search('\c\%('.val.'\)','W')
	call add(s:matchid,matchadd('WarningMsg', '\%('.val.'\)'))
        let ans=input("Attach file: (leave empty to abbort): ", "", "file")
        while (ans != '') && (ans != 'n')
	    let list = split(expand(glob(ans)), "\n")
	    for attach in list
		normal magg}-
		call append(line('.'), 'Attach: ' . escape(attach, ' '))
		redraw
	    endfor
            let ans=input("Attach another file?: (leave empty to abbort): ", "", "file")
        endwhile
    endif
    :call <SID>WriteBuf(v:cmdbang)
    call setpos('.', oldPos)
endfu"}}}
" Define Commands: "{{{3
" Define commands that will disable and enable the plugin.
command! DisableCheckAttach let s:load_autocmd=0 | :call <SID>AutoCmd()
command! EnableCheckAttach let s:load_autocmd=1 | :call <SID>AutoCmd()

" Call function to set everything up "{{{2
call <sid>AutoCmd()
" Restore setting "{{{2
let &cpo = s:cpo_save
unlet s:cpo_save

" Vim Modeline " {{{2
" vim: set foldmethod=marker: 
