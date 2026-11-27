" ~/.vim/ide.vim
"
" Plugin-dependent "IDE" layer. bootstrap.sh links this file to ~/.vim/ide.vim
" and ~/.vimrc sources it last. Every block is guarded on its plugin being
" installed, so a machine with only part of the plugins (or none) still loads
" cleanly. Plugins come from config/vim/plugins.txt.
"
" Leader is <Space>. Muscle memory that exists only on this layer:
"
"   <leader>e   explorer sidebar
"   <leader>f   files            <leader>b   buffers        -    parent directory
"   <leader>a   files, ignored too (vendor/)
"   <leader>/   live ripgrep     <leader>?   same, ignoring .gitignore (vendor/)
"   <leader>*   grep word        <leader>H   recent files   <leader>o   outline (tags)
"   <leader>gs  git status       <leader>gb  git blame      <leader>gd  git diff
"   <leader>gl  git log          ]c / [c     next/prev hunk
"   <leader>hs / hp / hu   stage / preview / undo hunk (gitgutter)
"
"   <leader>m   preview Markdown (glow; in a tmux popup when inside tmux)
"
"   LSP / ALE (macOS only):
"   gd          definition       gr          references     K           hover
"   <leader>s   symbol search (class / function by name, then <CR>)
"   <leader>rn  rename (Intelephense needs a licence for PHP: use :Rg + :cdo)
"   <leader>ca  code action      <leader>d   error detail
"   ]d / [d     next/prev diagnostic                        <leader>F   fix (prettier)
"   <Tab>       pick next completion item, <CR> accepts it
"
" Everything else is stock Vim, which is what you will find on a server.

if v:version < 801
    finish
endif

let s:pack = $HOME . '/.vim/pack/plugins/start'

function! s:has(name) abort
    return isdirectory(s:pack . '/' . a:name)
endfunction

" ---------------------------------------------------------------------------
" Colors
" ---------------------------------------------------------------------------

" Transparent background: gruvbox paints an opaque #282828 on every cell, which
" hides Ghostty's background-opacity and blur. Clearing the background of the
" text area and the gutter lets the terminal's own background show through.
" Must be defined before `colorscheme`, and re-runs when the scheme reloads.
function! s:TransparentBackground() abort
    for l:group in ['Normal', 'NonText', 'EndOfBuffer', 'SignColumn', 'FoldColumn',
    \               'LineNr', 'CursorLineNr',
    \               'GruvboxRedSign', 'GruvboxGreenSign', 'GruvboxYellowSign',
    \               'GruvboxBlueSign', 'GruvboxPurpleSign', 'GruvboxAquaSign',
    \               'GruvboxOrangeSign']
        execute 'highlight ' . l:group . ' guibg=NONE ctermbg=NONE'
    endfor
endfunction

if s:has('gruvbox')
    augroup transparent_background
        autocmd!
        autocmd ColorScheme gruvbox call s:TransparentBackground()
    augroup END

    silent! colorscheme gruvbox
endif

" ---------------------------------------------------------------------------
" Files and search (fzf)
" ---------------------------------------------------------------------------

if s:has('fzf') && s:has('fzf.vim') && executable('fzf')
    " List files with ripgrep so .gitignore is respected.
    if executable('rg')
        let $FZF_DEFAULT_COMMAND = 'rg --files --hidden --glob "!.git"'
    endif

    " Live ripgrep: the search is re-run on every keystroke. (:Rg with an
    " empty pattern would list every line of a big repository.) Select several
    " results with <Tab> and press <CR> to send them to the quickfix list,
    " then use :cdo / :cfdo for project-wide edits.
    function! s:RipgrepFzf(flags, query, fullscreen) abort
        let l:cmd = 'rg --column --line-number --no-heading --color=always --smart-case '
        \ . a:flags . ' -- %s || true'
        let l:initial = a:query ==# '' ? 'true' : printf(l:cmd, shellescape(a:query))
        let l:reload = printf(l:cmd, '{q}')
        let l:spec = {'options': ['--phony', '--query', a:query,
        \ '--bind', 'change:reload:' . l:reload]}

        call fzf#vim#grep(l:initial, 1, fzf#vim#with_preview(l:spec), a:fullscreen)
    endfunction

    command! -nargs=* -bang RG call s:RipgrepFzf('', <q-args>, <bang>0)
    command! -nargs=* -bang RGAll call s:RipgrepFzf('--no-ignore --hidden --glob "!.git"', <q-args>, <bang>0)

    " Same as :Files but also lists ignored files (vendor/, node_modules/).
    command! -bang -nargs=? -complete=dir FilesAll
    \ call fzf#vim#files(<q-args>, fzf#vim#with_preview({'source':
    \ 'rg --files --no-ignore --hidden --glob "!.git"'}), <bang>0)

    " In the explorer sidebar the finders run from the previous window, so
    " the chosen file opens next to the tree instead of replacing it.
    function! s:ExplorerFinders() abort
        for [l:key, l:cmd] in [['f', 'Files'], ['a', 'FilesAll'], ['b', 'Buffers'],
        \                      ['H', 'History'], ['/', 'RG'], ['?', 'RGAll']]
            execute 'nnoremap <buffer> <silent> <leader>' . l:key
            \ . ' :wincmd p<Bar>' . l:cmd . '<CR>'
        endfor
    endfunction

    augroup fzf_in_explorer
        autocmd!
        autocmd FileType netrw call s:ExplorerFinders()
    augroup END

    nnoremap <leader>f :Files<CR>
    nnoremap <leader>a :FilesAll<CR>
    nnoremap <leader>b :Buffers<CR>
    nnoremap <leader>H :History<CR>
    nnoremap <leader>o :BTags<CR>
    nnoremap <leader>/ :RG<CR>
    nnoremap <leader>? :RGAll<CR>
    nnoremap <leader>* :Rg <C-r><C-w><CR>
endif

" ---------------------------------------------------------------------------
" Markdown preview (glow)
" ---------------------------------------------------------------------------

" Renders the current file in the terminal: in a tmux popup when inside tmux
" (q closes it and you land back in Vim), full screen otherwise.
function! s:MarkdownPreview() abort
    if !executable('glow')
        echohl WarningMsg | echo 'glow is not installed' | echohl None
        return
    endif

    if expand('%') ==# ''
        echo 'No file to preview'
        return
    endif

    silent update

    let l:file = expand('%:p')

    " Gruvbox style without background colors (see config/glow/gruvbox.json).
    " Passed explicitly: a tmux popup may not inherit GLOW_STYLE.
    let l:style = expand('~/.config/glow/gruvbox.json')
    let l:glow = 'glow --pager '
    if filereadable(l:style)
        let l:glow = 'glow --style ' . shellescape(l:style) . ' --pager '
    endif

    if $TMUX !=# ''
        call system('tmux display-popup -E -w 90% -h 90% '
        \ . shellescape(l:glow . shellescape(l:file)))
    else
        execute 'silent !' . l:glow . shellescape(l:file, 1)
        redraw!
    endif
endfunction

if executable('glow')
    augroup markdown_preview
        autocmd!
        autocmd FileType markdown nnoremap <buffer> <silent> <leader>m :call <SID>MarkdownPreview()<CR>
    augroup END
endif

" ---------------------------------------------------------------------------
" Git (fugitive, gitgutter)
" ---------------------------------------------------------------------------

if s:has('vim-fugitive')
    nnoremap <leader>gs :Git<CR>
    nnoremap <leader>gb :Git blame<CR>
    nnoremap <leader>gd :Gdiffsplit<CR>
    nnoremap <leader>gl :Git log --oneline --decorate --graph<CR>
endif

" ---------------------------------------------------------------------------
" Statusline
" ---------------------------------------------------------------------------

function! StatusGit() abort
    if !exists('*FugitiveHead')
        return ''
    endif

    let l:head = FugitiveHead()

    return l:head ==# '' ? '' : ' [' . l:head . ']'
endfunction

function! StatusALE() abort
    if !exists(':ALELint')
        return ''
    endif

    let l:counts = ale#statusline#Count(bufnr(''))

    if l:counts.total == 0
        return ''
    endif

    let l:errors = l:counts.error + l:counts.style_error

    return printf(' E:%d W:%d', l:errors, l:counts.total - l:errors)
endfunction

set statusline=%<%f%{StatusGit()}\ %h%m%r%=%{StatusALE()}\ %y\ %l:%c\ %P

" ---------------------------------------------------------------------------
" Lint, fix and LSP (ALE)
" ---------------------------------------------------------------------------

if s:has('ale')
    " Lint on save and when leaving insert mode, not on every keystroke.
    let g:ale_lint_on_text_changed = 'normal'
    let g:ale_lint_on_insert_leave = 1

    " Diagnostics, hover and details.
    let g:ale_sign_error = 'E'
    let g:ale_sign_warning = 'W'
    let g:ale_virtualtext_cursor = 'current'
    let g:ale_floating_preview = 1
    let g:ale_hover_to_floating_preview = 1
    let g:ale_detail_to_floating_preview = 1

    " Completion from the language server (must be set before ALE loads).
    let g:ale_completion_enabled = 1
    let g:ale_completion_autoimport = 1

    " Run only the linters listed here. A missing tool is skipped silently
    " (see :ALEInfo). Project-local tools in node_modules/.bin win over global
    " ones. Tools come from the Brewfile; intelephense from bootstrap.sh.
    let g:ale_linters_explicit = 1
    let g:ale_linters = {
    \   'php': ['intelephense'],
    \   'javascript': ['tsserver', 'eslint'],
    \   'typescript': ['tsserver', 'eslint'],
    \   'vue': ['volar', 'eslint'],
    \   'json': ['vscodejson'],
    \   'terraform': ['terraform_ls'],
    \   'yaml': ['yamllint'],
    \   'ansible': ['ansible_lint'],
    \   'dockerfile': ['hadolint'],
    \   'sh': ['language_server'],
    \   'go': ['gopls'],
    \}

    " On save: trim whitespace only on files we own (shell,
    " yaml, Dockerfile), `terraform fmt` on Terraform and gofmt on Go. PHP is
    " left alone so legacy code doesn't get noisy whitespace diffs. Prettier
    " is available on demand (<leader>F) but never runs on save, so opening a
    " repo without a prettier config doesn't rewrite whole files.
    let s:trim = ['remove_trailing_lines', 'trim_whitespace']

    let g:ale_fix_on_save = 1
    let g:ale_fix_on_save_ignore = ['prettier']
    let g:ale_fixers = {
    \   'sh': s:trim,
    \   'yaml': s:trim,
    \   'dockerfile': s:trim,
    \   'terraform': ['terraform'],
    \   'go': ['gofmt'],
    \   'javascript': s:trim + ['prettier'],
    \   'typescript': s:trim + ['prettier'],
    \   'vue': s:trim + ['prettier'],
    \   'json': s:trim + ['prettier'],
    \   'css': s:trim + ['prettier'],
    \   'html': s:trim + ['prettier'],
    \}

    nmap gd <Plug>(ale_go_to_definition)
    nmap gr <Plug>(ale_find_references)
    nmap K <Plug>(ale_hover)
    nmap <leader>rn <Plug>(ale_rename)
    " Workspace symbol search: type a class or function name, then <CR>.
    nnoremap <leader>s :ALESymbolSearch -relative<Space>
    nmap <leader>ca <Plug>(ale_code_action)
    nmap <leader>d <Plug>(ale_detail)
    nmap <leader>F <Plug>(ale_fix)
    nmap ]d <Plug>(ale_next_wrap)
    nmap [d <Plug>(ale_previous_wrap)

    " <Tab> / <S-Tab> walk the completion menu, <CR> accepts the selected item.
    inoremap <expr> <Tab>   pumvisible() ? "\<C-n>" : "\<Tab>"
    inoremap <expr> <S-Tab> pumvisible() ? "\<C-p>" : "\<S-Tab>"
    inoremap <expr> <CR>    pumvisible() && complete_info(['selected']).selected != -1 ? "\<C-y>" : "\<CR>"
endif
