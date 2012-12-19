command! -nargs=1 -complete=shellcmd -bang Emake call erroneous#run(<q-args>,1,1,1,<bang>0)
command! -nargs=1 -complete=shellcmd -bang Elmake call erroneous#run(<q-args>,1,1,2,<bang>0)
