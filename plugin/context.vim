nnoremap <silent> <C-L> <C-L>:call Context(1)<CR>
nnoremap <silent> <C-E> <C-E>:call Context(0)<CR>
nnoremap <silent> <C-Y> <C-Y>:call Context(0)<CR>
nnoremap <silent> <C-D> <C-D>:call Context(0)<CR>
nnoremap <silent> <C-U> <C-U>:call Context(0)<CR>
nnoremap <silent> gg gg:call Context(0)<CR>
nnoremap <silent> G G:call Context(0)<CR>
" NOTE: this is pretty hacky, we call zz/zt/zb twice here
" if we only do it once it seems to break something
" to reproduce: search for something, then alternate: n zt n zt n zt ...
nnoremap <silent> zz zzzz:call Context(0)<CR>
nnoremap <silent> zt ztzt:call Context(0)<CR>
nnoremap <silent> zb zbzb:call Context(0)<CR>

let s:min_height=0
let s:top_line=-10
let s:buffer_name="<context.vim>"

function! Context(force_resize)
    if a:force_resize
        let s:top_line=-10
    endif

    call s:echof('----')
    call Context1(1)
endfunction

function! Context1(allow_resize)
    let current_line = line('w0')
    call s:echof("in", s:top_line, current_line)
    if s:top_line == current_line
        return
    endif

    if a:allow_resize
        " avoid resizing if we only moved a single line
        " (so scrolling is still somewhat smooth)
        if abs(s:top_line - current_line) > 1
            let s:min_height=0
        endif
    endif

    let s:top_line = current_line

    " find line which isn't empty
    while current_line > 0
        let line = getline(current_line)
        if !empty(matchstr(line, '[^\s]'))
            let current_indent = indent(current_line)
            break
        endif
        let current_line += 1
    endwhile

    let context = []
    let current_line = s:top_line
    while current_line > 1
        let allow_same = 0

        " if line starts with closing brace: jump to matching opening one and add it to context
        " also for other prefixes to show the if which belongs to an else etc.
        if line =~ '^\s*\([]})]\|end\|else\|case\>\|default\>\)'
            let allow_same = 1
        endif

        " search for line with same indent (or less)
        while current_line > 1
            let current_line -= 1
            let line = getline(current_line)
            if empty(matchstr(line, '[^\s]'))
                continue " ignore empty lines
            endif

            let indent = indent(current_line)
            if indent < current_indent || allow_same && indent == current_indent
                call insert(context, line, 0)
                let current_indent = indent
                break
            endif
        endwhile
    endwhile

    let oldpos = getpos('.')

    call ShowInPreview(context)
    " call again until it stabilizes
    " disallow resizing to make sure it will eventually
    call Context1(0)
endfunction

" https://vi.stackexchange.com/questions/19056/how-to-create-preview-window-to-display-a-string
function! ShowInPreview(lines)
    pclose
    if s:min_height < len(a:lines)
        let s:min_height = len(a:lines)
    endif

    if s:min_height == 0
        return
    endif

    let &previewheight=s:min_height

    while len(a:lines) < s:min_height
        call add(a:lines, "")
    endwhile

    execute 'silent! pedit +setlocal\ ' .
                  \ 'buftype=nofile\ nobuflisted\ ' .
                  \ 'noswapfile\ nonumber\ nowrap\ ' .
                  \ 'filetype=' . &filetype . " " . s:buffer_name

    call setbufline(s:buffer_name, 1, a:lines)
endfunction

" uncomment to activate
" let s:logfile = "~/temp/vimlog"

function! s:echof(...)
    if exists('s:logfile')
        silent execute "!echo '" . join(a:000) . "' >> " . s:logfile
    endif
endfunction
