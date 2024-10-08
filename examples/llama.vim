" sample config:
"
"   - Ctrl+F - trigger FIM completion
"
" copy paste this in your .vimrc:
"
"augroup llama_cpp
"    autocmd!
"    autocmd InsertEnter * inoremap <buffer> <silent> <C-F> <Esc>:call llama#fim()<CR>
"augroup END
"

let s:default_config = {
    \ 'endpoint':     'http://127.0.0.1:8012/infill',
    \ 'prefix_lines': 32,
    \ 'suffix_lines': 32,
    \ 'n_predict':    64,
    \ 'n_probs':      3,
    \ 'temperature':  0.1,
    \ 'stop':         ["\n"]
    \ }

let g:llama_config = get(g:, 'llama_config', s:default_config)

function! llama#fim() abort
    let l:lines_prefix = getline(max([1, line('.') - g:llama_config.suffix_lines]), line('.') - 1)
    let l:lines_suffix = getline(line('.') + 1, min([line('$'), line('.') + g:llama_config.prefix_lines]))

    let l:cursor_col = col('.')

    let l:line_cur        = getline('.')
    let l:line_cur_prefix = strpart(l:line_cur, 0, l:cursor_col)
    let l:line_cur_suffix = strpart(l:line_cur, l:cursor_col)

    let l:prefix = ""
        \ . join(l:lines_prefix, "\n")
        \ . "\n"
        \ . l:line_cur_prefix

    let l:suffix = ""
        \ . l:line_cur_suffix
        \ . join(l:lines_suffix, "\n")

    let l:request = json_encode({
        \ 'prompt':         "",
        \ 'input_prefix':   l:prefix,
        \ 'input_suffix':   l:suffix,
       "\ 'stop':           g:llama_config.stop,
        \ 'n_predict':      g:llama_config.n_predict,
       "\ 'n_probs':        g:llama_config.n_probs,
        \ 'penalty_last_n': 0,
        \ 'temperature':    g:llama_config.temperature,
        \ 'top_k':          5,
        \ 'infill_p':       0.20,
        \ 'infill_p_eog':   0.001,
        \ 'stream':         v:false,
        \ 'samplers':       ["top_k", "infill"]
        \ })

    " request completion from the server
    let l:curl_command = printf(
        \ "curl --silent --no-buffer --request POST --url %s --header \"Content-Type: application/json\" --data %s",
        \ g:llama_config.endpoint, shellescape(l:request)
        \ )

    let l:response = json_decode(system(l:curl_command))

    echom l:response

    let l:content = []
    for l:part in split(get(l:response, 'content', ''), "\n", 1)
        call add(l:content, l:part)
    endfor

    echom l:content

    " insert the 'content' at the current cursor location
    let l:content[0]   = l:line_cur_prefix . l:content[0]
    let l:content[-1] .= l:line_cur_suffix

    call setline('.',       l:content[0])
    call append (line('.'), l:content[1:-1])
endfunction
