" Vimball Archiver by Charles E. Campbell, Jr., Ph.D.
UseVimball
finish
ftplugin/mail/CheckAttach.vim	[[[1
265
" Vim plugin for checking attachments with mutt
" Maintainer:  Christian Brabandt <cb@256bit.org>
" Last Change: Wed, 14 Aug 2013 22:24:01 +0200
" Version:     0.15
" GetLatestVimScripts: 2796 15 :AutoInstall: CheckAttach.vim

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
    sleep 1
    echohl Normal
    let v:errmsg = msg
endfun

fu! <SID>Init() "{{{2
    " List of highlighted matches
    let s:matchid = []

    " On which keywords to trigger, comma separated list of keywords
    let s:attach_check = 'attach,attachment,angehängt,Anhang'
    let s:attach_check .= exists("g:attach_check_keywords") ? 
	\ g:attach_check_keywords : ''
    
    " Check for using an external file browser for selecting the files
    let s:external_file_browser = exists("g:checkattach_filebrowser") ? 
	\ g:checkattach_filebrowser : ''

    if !empty(s:external_file_browser)
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
	" Check that the part until the first space is executable
	let binary = matchstr(s:external_file_browser,
		    \ '^[^[:blank:]\\]\+\(\\\s\S\+\)\?')
	if !executable(binary)
	    call <sid>WarningMsg(binary . ' is not executable!')
	    let s:external_file_browser = ''
	endif
    endif

    " Enable Autocommand per default
    let s:load_autocmd = exists("g:checkattach_autocmd") ? 
	\ g:checkattach_autocmd : exists("s:load_autocmd") ? 
	\ s:load_autocmd : 1
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
	    au! BufWriteCmd <buffer> :call <SID>CheckAttach() 
	augroup END
    else
	silent! au! CheckAttach BufWriteCmd <buffer>
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

fu! <SID>CheckAlreadyAttached(line) "{{{2
    " argument line = subject line
    let cpos = getpos('.')
    exe a:line
    " Cursor should be at the subject line,
    " so Attach-header line should be below current position.
    if exists("g:checkattach_once") &&
    \ g:checkattach_once =~? 'y' &&
    \ search('^Attach: ', 'nW')
	return 1
    else
	return 0
    endif
    call setpos('.', cpos)
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
    let s:oldpos = winsaveview()
    1
    " Needed for function <sid>CheckNewLastLine()
    let s:header_end = search('^$', 'W')
    let s:lastline = line('$')
    1
    let val = join(split(escape(s:attach_check,' \.+*'), ','),'\|')
    " don't match in the quoted part of the message
    let pat = '\(^\s*>\+.*\)\@<!\c\%(' . val . '\)'
    let prompt = "Attach file: (leave empty to abort): "
    if !empty(s:external_file_browser)
	let prompt = substitute(prompt, ')', ', Space starts filebrowser)', '')
    endif
    let prompt2 = substitute(prompt, 'file', 'another &', '')

    " Search starting at the line, that contains the subject
    let subjline = search('^Subject:', 'W')
    let subj = getpos('.')
    " Move after the header line (so we don't match the Subject line
    noa norm! }
    let ans = 1
    if search(pat, 'nW') && !<sid>CheckAlreadyAttached(subjline)
	" Delete old highlighting, don't pollute buffer with matches
	if exists("s:matchid")
	    "for i in s:matchid | call matchdelete(i) | endfor
	    map(s:matchid, 'matchdelete(v:val)')
	    let s:matchid = []
	endif
	call add(s:matchid,matchadd('WildMenu', pat))
	redr!
	let ans = input(prompt, "", "file")
        while (ans != '') && (ans != 'n')
	    norm! }-
	    if empty(s:external_file_browser)
		let list = split(expand(ans), "\n")
		for attach in list
		    call append(line('.'), 'Attach: ' .
			\ escape(attach, " \t\\"))
		    redraw
		endfor
		if <sid>CheckAlreadyAttached(subjline)
		    let ans = 'n'
		else
		    let ans = input(prompt2, "", "file")
		endif
	    else
		call <sid>ExternalFileBrowser(isdirectory(ans) ? ans : 
			\ fnamemodify(ans, ':h'))
		let ans = 'n'
	    endif
	    call setpos('.', subj)
        endwhile
	call <SID>CheckNewLastLine()
    endif
    call <SID>WriteBuf(v:cmdbang)
    call winrestview(s:oldpos)
endfu

fu! <SID>ExternalFileBrowser(pat) "{{{2
    " Call external File Browser
    exe ':sil !' s:external_file_browser   a:pat
    " Force redrawing, so the screen doesn't get messed up
    redr!
    if filereadable(s:external_choosefile)
	call append('.', map(readfile(s:external_choosefile), '"Attach: ".
	    \ escape(v:val, " \t\\")'))
	call delete(s:external_choosefile)
    endif
endfu

fu! <SID>AttachFile(pattern) "{{{2
    call <sid>Init()
    if empty(a:pattern) && empty(s:external_file_browser)
	call <sid>WarningMsg("No pattern supplied, can't attach a file!")
	return
    endif

    let s:oldpos = winsaveview()
    1
    let s:header_end = search('^$', 'W')
    norm! -
    let s:lastline = line('$')

    if !empty(s:external_file_browser)
	call <sid>ExternalFileBrowser(isdirectory(a:pattern) ? a:pattern :
	    \ fnamemodify(a:pattern, ':h'))
    else "empty(a:pattern)
	" glob supports returning a list
	if v:version > 703 || v:version == 703 && has("patch465")
	    let list = "glob(a:pattern, 1, 1)"
	else
	    " glob returns new-line separated items
	    let list = 'split(glob(a:pattern, 1), "\n")'
	endif
	for item in eval(list)
	    call append('.', 'Attach: '. escape(item, " \t\\"))
	    redraw!
	endfor
    endif
    call <SID>CheckNewLastLine()
    call winrestview(s:oldpos)
endfun

fu! <SID>CheckNewLastLine() "{{{2
    let s:newlastline = line('$')
    " Adding text above, means, we need to adjust
    " the cursor position from the oldpos dictionary. 
    " Should oldpos.topline also be adjusted ?
    if s:oldpos.lnum >= s:header_end
	let s:oldpos.lnum += s:newlastline - s:lastline
	if s:oldpos.topline > s:header_end
	    let s:oldpos.topline += s:newlastline - s:lastline
	endif
    endif
endfu

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
doc/CheckAttach.txt	[[[1
237
*CheckAttach.txt*  Check attachments when using mutt

Author:  Christian Brabandt <cb@256bit.org>
Version: 0.15 Wed, 14 Aug 2013 22:24:01 +0200
Copyright: (c) 2009-2013 by Christian Brabandt            *CheckAttach-copyright*
           The VIM LICENSE applies to CheckAttach.vim and CheckAttach.txt
           (see |copyright|) except use CheckAttach instead of "Vim".
           NO WARRANTY, EXPRESS OR IMPLIED.  USE AT-YOUR-OWN-RISK.

=============================================================================
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
embarrassing.

Therefore this plugin checks for the presence of keywords (but does not
consider the quoted part of the message, that is, any line that does not start
with '>') which indicate that an attachment should be attached. If if finds
these keywords, the plugin will highlight the keywords and ask you for the
files to attach, whenever you save your mail.

This looks like this:
Attach file: (leave empty to abort):

At that prompt you can specify any file you'd like to attach. It allows
filename completion, so you can use <Tab> to let vim complete file paths.
Additionally you can specify glob patterns and let vim attach all files, that
match the pattern. So if you enter ~/.vim/plugin/*.vim vim would add for each
plugin it finds an Attach-header. If you enter an empty value or "n" (without
the quotes), no file will be attached. If you have the plugin configured to
use an external filebrowser (see point 2 below |CheckAttach-Config|), you need
to enter at least a space, otherwise the plugin won't attach any file to your
mail. If you enter a directory, your filebrowser will be called with that
directory as argument.

The plugin will by default escape blank space in your filename by using '\'.
mutt before version 1.5.20 had a bug, that would not allow you to add files
whose filename contain spaces. If you are using mutt version smaller 1.5.20
this means you would have to rename those files first before attaching them.
(See mutt bug 3179: http://dev.mutt.org/trac/ticket/3179)

Configuration                                        *CheckAttach-Config*
=============

1. Specify different keywords
-----------------------------

You can specify which keywords will be searched by setting the
g:attach_check_keywords variable. By default this variable is specified as:
let g:attach_check_keywords = 'attached,attachment,angehängt,Anhang'
so that it can handle German and English. If you would like to add the keyword
foobar, use this command:

let g:attach_check_keywords =',foobar'

NOTE: The comma is important. It is used to separate the different keywords
and needs to be included.

2. Use an external filemanager
------------------------------

Instead of using Vim to select the files, you can also specify to use an
external filemanager. It must be configured to write all selected files into a
temporary file, which in turn will be read in by Vim and put as Attach: header
into your mail. To use an external filebrowser, use the
g:checkattach_filebrowser variable.

Let's assume you want to use ranger (http://ranger.nongnu.org/) as external
file manager. So in your |.vimrc| you put: >

    :let g:checkattach_filebrowser = 'ranger'
<
For ranger, Vim will try to determine, whether it supports the --choosefiles
paramter. This is only supported with Version 1.5.1 of ranger, otherwise, it
will only support the --choosefile parameter. The difference is when using the
--chosefile parameter you can only select 1 file to be attached, while
starting from version 1.5.1 you can attach a list of files. In this case, Vim
will execute the command 'ranger --choosefile/choosefiles=<tempname>' where
<tempname> will be substituted by a temporary file that will be created when
running the command.

You can also force vim to execute a different command, in this case, specify
the command to be run like this: >

    :let g:checkattach_filebrowser = 'ranger --choosefiles=%s'
<
The special parameter '%s' will be replaced by Vim by a temporary filename.
Again, your filebrowser will be expected to write the selected filenames into
that file.

3. Check only once
------------------

You can CheckAttach configure, so that it will only check once until an
:Attach header is present and on further writes, it will assume that nothing
needs to be done since you already attached a file. To enable this, simply set
this variable: >

    :let g:checkattach_once = 'y'

<

                                                        *CheckAttach_Problems*
Problems with CheckAttach
=========================

If you try to attach a file, whose name contains 8bit letters, it could be,
that mutt can't attach that file and instead displays an error message similar
to this one:

    "<filename>: unable to attach file"

where <filename> is mangled, this is a problem with the way mutt works in
conjunction with the assumed_charset patch. In this case, you should either
not use filenames containing 8bit letters or only 8bit letters in the same
encoding as given to the assumed_charset option.

                                      *EnableCheckAttach* *DisableCheckAttach*
You can disable the plugin by issuing the command >
    :DisableCheckAttach
Enabling the attachment check is then again enabled by issuing >
    :EnableCheckAttach

If you'd like to suggest adding additional keywords (for your language),
please contact the author (see first line of this help page).

You can also use the ! attribute when saving your buffer to temporarily skip
the check. So if you use :w! the buffer will not be checked for attachments,
only if you use :w it will.

                                                            *:AttachFile*
The plugin also defines the command :AttachFile. This allows you to simply
attach any number of files, using a glob pattern. So, if you like to attach
all your pictures from ~/pictures/ you can simply enter: >

     :AttachFile ~/pictures/*.jpg

and all jpg files will be attached automatically. You can use <Tab> to
complete the directory.

==============================================================================
2. CheckAttach History                                   *CheckAttach-history*
   0.15: Aug 13, 2013 "{{{1

   - don't match Attach: header when trying to look for matching attachment
     keywords

   0.14: Jun 16, 2012 "{{{1

   - Fix issue 2 from github: https://github.com/chrisbra/CheckAttach/issues/2
     (:AttachFile, does not correctly attach filenames with spaces, reported by
     daaugusto, thanks!)

   0.13: Nov 08, 2011 "{{{1

    - allow plugin to use an external file manager for selecting the files
      (suggested by mutt-users mailinglist)
    - Command definition will be buffer local
    - Don't check for matches of the keywords in the quoted of the message
      (suggested by Sebastian Tramp, thanks!)
    - Don't check for matches inside the header (start at subject line,
      suggested by Sebastian Tramp, thanks!)
    - Only check as long, as no :Attach header is available when the
      g:checkattach_once variable is set (suggested by Sebastian Tramp,
      thanks!)
    - Documentation update

   0.12: Oct  25, 2011 "{{{1

    - Update the plugin (include some changes, that got lost with 0.11)

   0.11: Sep  30, 2011 "{{{1

    - Make a filetype plugin out of it, it does not make sense to have it as
      plugin, since its only use is with mutt (aka ft: mail)
    - Documentation update

   0.10: Jan  17, 2011 "{{{1

    - Spelling fixes by Scott Stevenson (Thanks!)

    0.9: Dec  17, 2010 "{{{1

    -  new command |:AttachFile|

    0.8: Nov  29, 2010 "{{{1

    - Make ftplugin instead of plugin, don't trigger check of filetypes clear
      matchlist on next run code cleanup

    0.7: May  05, 2010 "{{{1

    - Force checking the filetype

    0.6: May  05, 2010 "{{{1

    - Force filetype detection, which did prevent of the plugin to be working
      correctly
    - Created a public github repository at http://github.com/chrisbra/CheckAttach
    - Small changes to the documentation

    0.5: Mar  02, 2010 "{{{1
    
    - Search without matching case

    0.4: Jan  26, 2010 "{{{1

    - Highlight matching keywords, use g:attach_check_ft to specify for which
      filetypes to enable the plugin

    0.3: Oct   1, 2009 "{{{1

    - Fixed Copyright statement, enabled GetLatestScripts

    0.2: Sept 29, 2009 "{{{1
    
    - Added Documentation

    0.1: Sept 29, 2009 "{{{1
    
    - First working version, using simple commands

==============================================================================
vim:tw=78:ts=8:ft=help:et
