"Version: 0.2.1

if has('unix')
	command! -nargs=? -complete=shellcmd -bang Emake call erroneous#run(&makeprg." ".<q-args>,1,2,1,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Elmake call erroneous#run(&makeprg." ".<q-args>,1,2,2,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Ebuild call erroneous#run(<q-args>,1,2,1,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Elbuild call erroneous#run(<q-args>,1,2,2,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Erun call erroneous#run(<q-args>,0,2,1,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,0,2,2,<bang>1)
elseif has('win32')
	command! -nargs=? -complete=shellcmd -bang Emake call erroneous#run(&makeprg." ".<q-args>,1,3,1,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Elmake call erroneous#run(&makeprg." ".<q-args>,1,3,2,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Ebuild call erroneous#run(<q-args>,1,3,1,<bang>1)
	command! -nargs=? -complete=shellcmd -bang Elbuild call erroneous#run(<q-args>,1,3,2,<bang>1)
	if executable('tee')
		command! -nargs=? -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,2,1,<bang>1)
		command! -nargs=? -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,2,2,<bang>1)
	else
		command! -nargs=? -complete=shellcmd -bang Erun call erroneous#run(<q-args>,1,1,1,<bang>1)
		command! -nargs=? -complete=shellcmd -bang Elrun call erroneous#run(<q-args>,1,1,2,<bang>1)
	endif
endif
