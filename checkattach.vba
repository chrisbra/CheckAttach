" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
doc/CheckAttach.txt	[[[1
72
*CheckAttach.txt*  Check for attachments when using mutt - Vers 0.2   Sep 29, 2009

Author:  Christian Brabandt <cb@256bit.org>
Copyright: (c) 2009 by Christian Brabandt 		    *CheckAttach-copyright*
           The VIM LICENSE applies to SudoEdit.vim and SudoEdit.txt
           (see |copyright|) except use SudoEdit instead of "Vim".
	   NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.


==============================================================================
                                                                  *CheckAttach*
1. Functionality

When using mutt as your mail user agent, you can specify which files to attach
using the pseudo header :Attach. This only works when edit_headers is set in
your .muttrc configuration file. See the mutt manual for further information
about that topic.

A simple version of this plugin has been posted to the mutt-users list (see
http://marc.info/?i=20090116091203.GB3197%20()%20256bit%20!%20org) and
after using it for some time, I decided to make a plugin out of it.

This plugin checks, whether certain keywords exist in your mail, and if found,
you'll be asked to attach the files. This is done to prevent that you sent
mails in which you announce to attach some files but actually forget to attach
the files so that your have to write a second mail which often is quite
embarassing.

Therefore this plugin checks for the presence of keywords which indicate that
an attachment should be attached. If if finds these keywords, the plugin will
ask you for the files to attach, whenever you save your mail.

This looks like this:
Attach file: (leave empty to abbort):

At that prompt you can specify any file you'd like to attach. It allows
filename completion, so you can use <Tab> to let vim complete file paths.
Additionally you can specify glob patterns and let vim attach all files, that
match the pattern. So if you enter ~/.vim/plugin/*.vim vim would add for each
plugin it finds an Attach-header.  If you enter an empty value or "n" (without
the quotes), no file will be attached.

The plugin will by default escape blank space in your filename by using '\'.
mutt before version 1.5.20 had a bug, that would not allow you to add files
whose filename contain spaces. If you are using mutt version smaller 1.5.20
this means you would have to rename those files first before attaching them.
(See mutt bug 3179: http://dev.mutt.org/trac/ticket/3179)

You can specify which keywords will be searched by setting the
g:attach_check_keywords variable. By default this variable is specified as:
let g:attach_check_keywords = 'attach,attachment,angehängt,Anhang'
so that it can handle German and English. If you would like to add the keyword
foobar, use this command:
let g:attach_check_keywords .=',foobar'

                                         *EnableCheckAttach* *DisableCheckAttach*
You can disable the plugin by issuing the command 
:DisableCheckAttach
Enabling the attachment check is then again enabled by issuing
:EnableCheckAttach
You can also use the ! attribute when saving your buffer to temporarily skip
the check. So if you use :w! the buffer will not be checked for attachments,
only if you use :w it will.


==============================================================================
2. CheckAttach History					    *CheckAttach-history*
    0.2: Sept 29, 2009     Added Documentation
    0.1: Sept 29, 2009	   First working version, using simple commands

==============================================================================
vim:tw=78:ts=8:ft=help
plugin/CheckAttach.vim	[[[1
81
" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: 2009 Sep 29
" Version:     0.2

" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
" - the autocmd event is not availble.
if exists("g:loaded_checkattach") || &cp || !exists("##BufWriteCmd") || !exists("##FileWriteCmd")
  finish
endif
let g:loaded_checkattach = 1

" enable Autocommand for attachment checking
let s:load_autocmd=1

" On which keywords to trigger, comma separated list of keywords
let g:attach_check_keywords = 'attach,attachment,angehängt,Anhang'

fu! <SID>AutoCmd()
    if !empty("s:load_autocmd") && s:load_autocmd && &ft == 'mail'
	augroup CheckAttach  
	    au! BufWriteCmd mutt* :call <SID>CheckAttach() 
	augroup END
    else
	silent! au! CheckAttach BufWriteCmd mutt*
	silent! augroup! CheckAttach
    endif
endfu

" Write the Buffer contents
fu! <SID>WriteBuf(bang)
    :exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    :setl nomod
endfu

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
    if search('\%('.val.'\)','W')
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
endfu

" Define commands that will disable and enable the plugin.
command! DisableCheckAttach let s:load_autocmd=0 | :call <SID>AutoCmd()
command! EnableCheckAttach let s:load_autocmd=1 | :call <SID>AutoCmd() 

" Enable autocommand when loading file
:call <SID>AutoCmd()

augroup CheckAttach
    au!
    au FileType * if expand("<amatch>") =~ 'mail' | :call <SID>AutoCmd() | endif
augroup END

