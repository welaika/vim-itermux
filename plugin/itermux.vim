" itermux.vim - Turbo Ruby tests with iTerm
" Author:      Joshua Davey <http://joshuadavey.com/>
" Author:      Stefano Verna <http://stefanoverna.com/>
" Version:     1.0

" Install this file to plugin/itermux.vim.
" Relies on the following plugins:
" - rails.vim

if exists('g:loaded_itermux') || &cp || v:version < 700 || !has('mac')
  finish
endif
let g:loaded_itermux = 1

function! s:first_readable_file(files) abort
  let files = type(a:files) == type([]) ? copy(a:files) : split(a:files,"\n")
  for file in files
    if filereadable(rails#app().path(file))
      return file
    endif
  endfor
  return ''
endfunction

function! s:prefix_for_test(file)
  if a:file =~# '_spec.rb$'
    return "rspec "
  elseif a:file =~# '_test.rb$'
    return "ruby -Itest "
  elseif a:file =~# '.feature$'
    if a:file =~# '\<spec/'
      return "rspec -rturnip "
    else
      return "cucumber "
    endif
  endif
  return ''
endfunction

function! s:alternate_for_file(file)
  let related_file = ""
  if exists('g:autoloaded_rails')
    let alt = s:first_readable_file(rails#buffer().related())
    if alt =~# '.rb$'
      let related_file = alt
    endif
  endif
  return related_file
endfunction

function! s:command_for_file(file)
  let executable=""
  let alternate_file = s:alternate_for_file(a:file)
  if s:prefix_for_test(a:file) != ''
    let executable = s:prefix_for_test(a:file) . a:file
  elseif alternate_file != ''
    let executable = s:prefix_for_test(alternate_file) . alternate_file
  endif
  return executable
endfunction

function! Send_to_iTerm(command)
  let app = 'iTerm'
  if exists("g:itermux_app_name") && g:itermux_app_name != ''
    let app = g:itermux_app_name
  endif
  let session = 'iTermux'
  if exists("g:itermux_session_name") && g:itermux_session_name != ''
    let session = g:itermux_session_name
  endif

  let commands =  [ '-e "on run argv"',
                  \ '-e "tell application \"' . app . '\""',
                  \ '-e "tell the current terminal"',
                  \ '-e "tell (first session whose name contains \"' . session . '\")"',
                  \ '-e "set AppleScript''s text item delimiters to \" \""',
                  \ '-e "write text (argv as text)"',
                  \ '-e "set the name to \"' . session .  '\""',
                  \ '-e "end tell"',
                  \ '-e "end tell"',
                  \ '-e "end tell"',
                  \ '-e "end run"' ]

  let complete_command = "osascript " . join(commands, ' ') . " " . a:command
  return system(complete_command)
endfunction

function! s:send_test(executable)
  let executable = a:executable
  if executable == ''
    if exists("g:iTerm_last_command") && g:iTerm_last_command != ''
      let executable = g:iTerm_last_command
    else
      let executable = 'echo "Warning: No command has been run yet"'
    endif
  endif
  return Send_to_iTerm(executable)
endfunction

" Public functions
function! SendTestToiTerm(file) abort
  let executable = s:command_for_file(a:file)
  if executable != ''
    let g:iTerm_last_command = executable
  endif
  return s:send_test(executable)
endfunction

function! SendFocusedTestToiTerm(file, line) abort
  let focus = ":".a:line

  if s:prefix_for_test(a:file) != ''
    let executable = s:command_for_file(a:file).focus
    let g:iTerm_last_focused_command = executable
  elseif exists("g:iTerm_last_focused_command") && g:iTerm_last_focused_command != ''
    let executable = g:iTerm_last_focused_command
  else
    let executable = ''
  endif

  return s:send_test(executable)
endfunction

" Mappings
nnoremap <silent> <Plug>SendTestToiTerm :<C-U>w \| call SendTestToiTerm(expand('%'))<CR>
nnoremap <silent> <Plug>SendFocusedTestToiTerm :<C-U>w \| call SendFocusedTestToiTerm(expand('%'), line('.'))<CR>

if !exists("g:no_itermux_mappings")
  nmap <leader>t <Plug>SendTestToiTerm
  nmap <leader>T <Plug>SendFocusedTestToiTerm
endif

" vim:set ft=vim ff=unix ts=4 sw=2 sts=2:
