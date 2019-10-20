filetype off
filetype plugin indent on

if &compatible    
  set nocompatible    
endif    

" Add the dein installation directory into runtimepath    
set runtimepath+=/home/sinai/.cache/dein/repos/github.com/Shougo/dein.vim    

if has('nvim')
	set undodir=$XDG_CONFIG_HOME/nvim/undo
	set viminfo+='1000,\"1000,s1000,:1000,n~/.config/nvim/viminfo
	source ~/.config/nvim/mycommands/MakeQuery.vim
	set termguicolors
	set pumblend=30
	
	if dein#load_state('/home/sinai/.cache/dein')
		call dein#begin('/home/sinai/.cache/dein')
		call dein#load_toml('/home/sinai/.config/nvim/tomls/dein.toml', {'lazy': 0})
		call dein#load_toml('/home/sinai/.config/nvim/tomls/dein_lazy.toml', {'lazy': 1})
		call dein#end()
		call dein#save_state()
	endif
else
	set undodir=~/.vim/undo
	set viminfo+='1000,\"1000,s1000,:1000,n~/.vim/viminfo
	set completeopt=menuone
	for k in split("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_",'\zs')
		  exec "imap " . k . " " . k . "<C-N><C-P>"
	endfor
	imap <expr> <TAB> pumvisible() ? "\<Down>" : "\<Tab>"

	if dein#load_state('/home/sinai/.cache/dein')
		call dein#begin('/home/sinai/.cache/dein')
		call dein#load_toml('/home/sinai/.vim/vim.toml')
		call dein#end()
		call dein#save_state()
		 
	"powerline
	set rtp+=/home/sinai/anaconda3/lib/python3.7/site-packages/powerline/bindings/vim
	let g:powerline_pycmd="py3"
	set laststatus=2

	endif
endif

"filetype and Templetes
augroup vimrc    
        au!    
        au BufNewFile,BufRead *.jl setfiletype julia    
        au BufNewFile,BufRead *.zen  setfiletype zen    
        au BufNewFile,BufNewFile *.csv setfiletype csv    
        au BufNewFile,BufNewFile *.lds setfiletype ld
		au BufNewfile *.c 0r ~/Templetes/c.c
		au BufNewfile *.jl 0r ~/Templetes/julia.jl
		au BufNewFile *.sh 0r ~/Templetes/shell.sh
		au BufNewFile *.vhd 0r ~/Templetes/vhdl.vhd
augroup END    

"install if not installed    
if dein#check_install()    
  call dein#install()    
endif    
    
syntax enable    
set background=dark    
colorscheme molokai
set nopaste    
set number    
set clipboard+=unnamed
set hidden
set nobackup
set tags=./tags;,tags;

set belloff=all
set fileencodings=utf-8,sjis,iso-2022-jp,euc-jp
nn <F4> a<C-R>=strftime("%Y-%m-%d %H:%M:%S")<CR><Esc>
imap <Nul> <Nop>
set viminfo=
set termguicolors
set mouse=n
set ts=4
nn tn :tabnew 
nn <C-S-r> :source ~/.vimrc<CR><Esc> 
nn <C-S-t> :e ~/.vimrc<CR><Esc> 

"see through
highlight Normal ctermbg=none
highlight NonText ctermbg=none
highlight LineNr ctermbg=none
highlight Folded ctermbg=none
highlight EndOfBuffer ctermbg=none 
"call map(dein#check_clean(), "delete(v:val, 'rf')")

filetype plugin indent on
