if has('unix')
	command! -nargs=1 -complete=shellcmd -bang Emake call erroneous#run(<q-args>,1,2,1,<bang>0)
	command! -nargs=1 -complete=shellcmd -bang Elmake call erroneous#run(<q-args>,1,2,2,<bang>0)
	command! -nargs=1 -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,2,1,<bang>0)
	command! -nargs=1 -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,2,2,<bang>0)
elseif has('win32')
	command! -nargs=1 -complete=shellcmd -bang Emake call erroneous#run(<q-args>,1,3,1,<bang>0)
	command! -nargs=1 -complete=shellcmd -bang Elmake call erroneous#run(<q-args>,1,3,2,<bang>0)
	if executable('tee')
		command! -nargs=1 -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,2,1,<bang>0)
		command! -nargs=1 -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,2,2,<bang>0)
	else
		command! -nargs=1 -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,1,1,<bang>0)
		command! -nargs=1 -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,1,2,<bang>0)
	endif
endif