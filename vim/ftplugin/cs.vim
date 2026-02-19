" C# uses 4-space indentation
setlocal shiftwidth=4
setlocal tabstop=4

" Run project
nmap <buffer> <Leader>r :!clear && dotnet run<CR>

" Run tests
nmap <buffer> <Leader>a :!clear && dotnet test<CR>
