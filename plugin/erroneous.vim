"Version: 0.5.0

command! -nargs=? -complete=shellcmd -bang Emake call erroneous#run(&makeprg." ".<q-args>,1,1,<bang>1)
command! -nargs=? -complete=shellcmd -bang Elmake call erroneous#run(&makeprg." ".<q-args>,1,2,<bang>1)
command! -nargs=? -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,1,<bang>1)
command! -nargs=? -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,2,<bang>1)
