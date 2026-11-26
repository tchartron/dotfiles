" ~/.vim/ide.vim
"
" Plugin-dependent "IDE" layer. bootstrap.sh links this file to ~/.vim/ide.vim
" and ~/.vimrc sources it last. Every block is guarded on its plugin being
" installed, so a machine with only part of the plugins (or none) still loads
" cleanly. Plugins come from config/vim/plugins.txt.
"
" Leader is <Space>. Muscle memory that exists only on this layer:
"
"   <leader>f   files            <leader>b   buffers        -    parent directory
"   <leader>/   ripgrep          <leader>h   recent files
"   <leader>gs  git status       <leader>gb  git blame      <leader>gd  git diff
"   <leader>gl  git log          ]c / [c     next/prev hunk
"
"   LSP / ALE (macOS only):
"   gd          definition       gr          references     K           hover
"   <leader>rn  rename           <leader>ca  code action    <leader>d   error detail
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

if s:has('gruvbox')
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

    nnoremap <leader>f :Files<CR>
    nnoremap <leader>b :Buffers<CR>
    nnoremap <leader>h :History<CR>
    nnoremap <leader>/ :Rg<CR>
    nnoremap <leader>* :Rg <C-r><C-w><CR>
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
    \}

    " On save: trim whitespace, and run `terraform fmt` on Terraform. Prettier
    " is available on demand (<leader>F) but never runs on save, so opening a
    " repo without a prettier config doesn't rewrite whole files.
    let g:ale_fix_on_save = 1
    let g:ale_fix_on_save_ignore = ['prettier']
    let g:ale_fixers = {
    \   '*': ['remove_trailing_lines', 'trim_whitespace'],
    \   'markdown': [],
    \   'terraform': ['terraform'],
    \   'javascript': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \   'typescript': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \   'vue': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \   'json': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \   'css': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \   'html': ['remove_trailing_lines', 'trim_whitespace', 'prettier'],
    \}

    nmap gd <Plug>(ale_go_to_definition)
    nmap gr <Plug>(ale_find_references)
    nmap K <Plug>(ale_hover)
    nmap <leader>rn <Plug>(ale_rename)
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
