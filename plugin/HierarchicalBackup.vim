" HierarchicalBackup - Provides backup keeping the original path
" Version: 0.0.1
" Copyright 2010, ISHIHARA Masaki <http://m4i.jp/>
" License: MIT license  {{{
"     Permission is hereby granted, free of charge, to any person obtaining
"     a copy of this software and associated documentation files (the
"     "Software"), to deal in the Software without restriction, including
"     without limitation the rights to use, copy, modify, merge, publish,
"     distribute, sublicense, and/or sell copies of the Software, and to
"     permit persons to whom the Software is furnished to do so, subject to
"     the following conditions:
"
"     The above copyright notice and this permission notice shall be
"     included in all copies or substantial portions of the Software.
"
"     THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
"     EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
"     MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
"     NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
"     LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
"     OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
"     WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
" }}}
"
" Usage:
"   1. Drop this file in your plugin directory.
"
"   2. Make your backup directory.
"     $ mkdir -m 0700 ~/.vim-backup
"
"   3. Put the following commands in your vimrc.
"     set backup
"     set backupdir^=~/.vim-backup
"     autocmd BufWritePre * let &backupext = strftime('~%Y%m%dT%H%M%S~')

if exists('g:loaded_HierarchicalBackup')
  finish
endif




function! s:onBufWritePre()
  if !&backup | return | endif

  let s:backupdir = &backupdir
  let path = s:AbsolutePath(bufname('%'))

  if has('win32')
    if s:IsUNCPath(path)
      let path = strpart(path, 1)
    else
      let path = s:PathSeparator() . s:DriveName(path) . strpart(path, 2)
    endif
  endif

  for backupdir in split(&backupdir, ',')
    if isdirectory(backupdir)
      for directory in split(s:ParentDirectoryName(path), '[/\\]')
        let backupdir .= s:PathSeparator() . directory
        if !isdirectory(backupdir)
          call s:MakePrivateDir(backupdir)
        endif
      endfor
      let &backupdir = backupdir
      break
    endif
  endfor
endfunction


function! s:onBufWritePost()
  if !&backup | return | endif

  let &backupdir = s:backupdir
endfunction


function! s:PathSeparator()
  return has('win32') && !&shellslash ? '\' : '/'
endfunction


function! s:IsAbsolutePath(path)
  if has('win32')
    return a:path =~ '^[A-Za-z]:' || s:IsUNCPath(a:path)
  else
    return a:path =~ '^/'
  endif
endfunction


function! s:IsUNCPath(path)
  return a:path =~ '^[/\\][/\\]'
endfunction


function! s:AbsolutePath(path)
  if s:IsAbsolutePath(a:path)
    return a:path
  else
    if has('win32') && a:path =~ '^[/\\]'
      let drive_name = s:DriveName(getcwd())
      return (len(drive_name) ? drive_name : 'c') . ':' . a:path
    else
      return getcwd() . s:PathSeparator() . a:path
    endif
  endif
endfunction


function! s:ParentDirectoryName(path)
  return substitute(a:path, '[/\\][^/\\]\+$', '', '')
endfunction


function! s:DriveName(path)
  if has('win32') && a:path =~ '^[A-Za-z]:'
    return tolower(strpart(a:path, 0, 1))
  else
    return ''
  endif
endfunction


function! s:MakePrivateDir(path)
  call mkdir(a:path, '', 0700)

  if exists('$SUDO_UID') && executable('chown')
    let owner = $SUDO_UID
    if exists('$SUDO_GID')
      let owner .= ':' . $SUDO_GID
    endif
    call system('chown ' . owner . ' ' . shellescape(a:path))
  endif
endfunction


augroup HierarchicalBackup
  autocmd!
  autocmd BufWritePre  * call s:onBufWritePre()
  autocmd BufWritePost * call s:onBufWritePost()
augroup END




let g:loaded_HierarchicalBackup = 1

" __END__
" vim: foldmethod=marker
