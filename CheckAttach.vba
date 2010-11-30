" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
ftplugin/mail_CheckAttach.vim	[[[1
103
" Vim filetype plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Mon, 29 Nov 2010 09:16:04 +0100
" Version:     0.8
" GetLatestVimScripts: 2796 7 :AutoInstall: CheckAttach.vim

" Initialization "{{{1
" Exit quickly when:
" - this plugin was already loaded (or disabled)
" - when 'compatible' is set
" - the autocmd event is not availble.
if exists("g:loaded_checkattach") || &cp ||
	\ !exists("##BufWriteCmd") || !exists("##FileWriteCmd")
  finish
endif
let g:loaded_checkattach = 1
"}}}1

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
    :exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    :setl nomod
endfu 

" This function checks your mail for the words specified in "{{{1
" check, and if it find them, you'll be asked to attach
" a file. 
fu! <SID>CheckAttach()"{{{2
    call <SID>Init()
    if empty("s:attach_check") || v:cmdbang
	call <SID>WriteBuf(v:cmdbang)
	return
    endif
    let oldPos=winsaveview()
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
        let ans=input("Attach file: (leave empty to abbort): ", "", "file")
        while (ans != '') && (ans != 'n')
                let list = split(expand(glob(ans)), "\n")
                for attach in list
                    norm! magg}-
                    call append(line('.'), 'Attach: ' . escape(attach, ' '))
                    redraw
                endfor
            let ans=input("Attach another file?: (leave empty to abbort): ", "", "file")
        endwhile
    endif
    call <SID>WriteBuf(v:cmdbang)
    call winrestview(oldPos)
endfu "}}}2

" Define commands that will disable and enable the plugin. "{{{1
command! EnableCheckAttach  :call <SID>TriggerAuCmd(1)
command! DisableCheckAttach :call <SID>TriggerAuCmd(0)

" call Autocommand when loading mail
call <SID>TriggerAuCmd(s:load_autocmd)
doc/CheckAttach.txt	[[[1
96
*CheckAttach.txt*  Check attachments when using mutt - Vers 0.8  Mar 02, 2010

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.8 Mon, 29 Nov 2010 09:16:04 +0100
Copyright: (c) 2009 by Christian Brabandt               *CheckAttach-copyright*
           The VIM LICENSE applies to CheckAttach.vim and CheckAttach.txt
           (see |copyright|) except use CheckAttach instead of "Vim".
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
highlight the keywords and ask you for the files to attach, whenever you save
your mail.

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
let g:attach_check_keywords = 'attached,attachment,angehängt,Anhang'
so that it can handle German and English. If you would like to add the keyword
foobar, use this command:

let g:attach_check_keywords =',foobar'

NOTE: The comma is important. It is used to seperate the different keywords
and needs to be included.

If you'd like to suggest adding additional keywords (for your language),
please contact the author (see first line of this help page).

                                      *EnableCheckAttach* *DisableCheckAttach*
You can disable the plugin by issuing the command 
:DisableCheckAttach
Enabling the attachment check is then again enabled by issuing
:EnableCheckAttach
You can also use the ! attribute when saving your buffer to temporarily skip
the check. So if you use :w! the buffer will not be checked for attachments,
only if you use :w it will.

==============================================================================
2. CheckAttach History                                   *CheckAttach-history*
    0.8: Nov  29, 2010     Make ftplugin instead of plugin,
                           don't trigger check of filetypes
                           clear matchlist on next run
                           code cleanup
    0.7: May  05, 2010     Force checking the filetype
    0.6: May  05, 2010     Force filetype detection, which did prevent
                             of the plugin to be working correctly
                           Created a public github repository at
                             http://github.com/chrisbra/CheckAttach
                           Small changes to the documentation
    0.5: Mar  02, 2010     Search without matching case
    0.4: Jan  26, 2010     Highlight matching keywords,
                           use g:attach_check_ft to specify for which filetypes
                           to enable the plugin
    0.3: Oct   1, 2009     Fixed Copyright statement, 
                           enabled GetLatestScripts
    0.2: Sept 29, 2009     Added Documentation
    0.1: Sept 29, 2009     First working version, using simple commands

==============================================================================
vim:tw=78:ts=8:ft=help:et
