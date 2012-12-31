"Version: 0.2.1

"Parse errors for Make. To be placed inside the erroneous dictionaries.
" * command: The command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous_make#parseErrorOutput(command,output,errors,targetList,jump)
	return erroneous#handleCommandResults(a:output[-1],a:output,a:errors,a:targetList,a:jump)
endfunction
