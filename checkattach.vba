" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
doc/CheckAttach.txt	[[[1
93
*CheckAttach.txt*  Check attachments when using mutt - Vers 0.5  Mar 02, 2010

Author:  Christian Brabandt <cb@256bit.org>
Copyright: (c) 2009 by Christian Brabandt 		    *CheckAttach-copyright*
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

let g:attach_check_keywords .=',foobar'

NOTE: The comma is important. It is used to seperate the different keywords
and needs to be included.

By default this plugin only works with mail filetypes. So it shouldn't
interfere, when you are writing C-Code or wrinting a report. You can however
define for which filetypes this plugin will be enabled. This is done by
specifying attach_check_ft as comma separated list for all filetypes that
you'll want to be checked. If attach_check_ft is not defined, it is set to
the default filetype 'mail'. So to add a new filetype, do something like this
in your .vimrc:

let g:attach_check_ft='mail,foobar'

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
    0.5: Mar  02, 2010     Search without matching case
    0.4: Jan  26, 2010     Highlight matching keywords,
                           use g:attach_check_ft to specify for which filetypes
			   to enable the plugin
    0.3: Oct   1, 2009     Fixed Copyright statement, 
                           enabled GetLatestScripts
    0.2: Sept 29, 2009     Added Documentation
    0.1: Sept 29, 2009	   First working version, using simple commands

==============================================================================
vim:tw=78:ts=8:ft=help
plugin/CheckAttach.vim	[[[1
95
" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: 2010 Mar, 02
" Version:     0.5
" GetLatestVimScripts: 2796 4 :AutoInstall: CheckAttach.vim

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

" List of highlighted matches
let s:matchid=[]

" For which filetypes to check for attachments
" Define as comma separated list. If you want additional filetypes
" besides mail, use attach_check_ft to specify all filetypes
let s:filetype=(exists("attach_check_ft") ? attach_check_ft : 'mail')

" On which keywords to trigger, comma separated list of keywords
let g:attach_check_keywords = 'attach,attachment,angehängt,Anhang'

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

" Write the Buffer contents
fu! <SID>WriteBuf(bang)
    :exe ":write" . (a:bang ? '!' : '') . ' '  . expand("<amatch>")
    :setl nomod
endfu

" This function checks your mail for the words specified in
" check, and if it find them, you'll be asked to attach
" a file.
fu! <SID>CheckAttach()"{{{
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

" Define commands that will disable and enable the plugin.
command! DisableCheckAttach let s:load_autocmd=0 | :call <SID>CheckFT()
command! EnableCheckAttach let s:load_autocmd=1 | :call <SID>CheckFT()

" Enable autocommand when loading file
":call <SID>AutoCmd()

fu! <SID>CheckFT()
    let s:filetype=(exists("attach_check_ft") ? attach_check_ft : 'mail')
    let s:check_filetype=join(split(escape(s:filetype, '\\*?'),','),'\|')
    "au FileType * if expand("<amatch>") =~ 'mail' | :call <SID>AutoCmd() | endif
    if &ft =~ s:check_filetype | :call <SID>AutoCmd() | endif
endfun
