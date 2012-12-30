"Version: 0.2.0

"Parse errors for Rake. To be placed inside the erroneous dictionaries.
" * command: The command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous_rake#parseErrorOutput(command,output,errors,targetList,jump)
	let l:rakeAbortedLine=match(a:errors,"^rake aborted!$")
	let l:errorCommandLine=match(a:errors,'^Command failed with status (\d\+): \[.*\]$',l:rakeAbortedLine)
	if l:errorCommandLine<0
		call erroneous#setErrorList(a:targetList,a:jump,a:errors,0)
		return 1
	endif

	"Get the command
	let l:errorCommand=matchstr(a:errors[l:errorCommandLine],'\[.*\]$')[1:-2]
	if '...'==l:errorCommand[-3:]
		let l:errorCommand=l:errorCommand[:-4]
	endif
	let l:lineBefore=match(a:errors,'\V\^'.substitute(l:errorCommand,'\\','\\\\',"g"))
	"Get the errors taken from the command
	let l:actualErrors=a:errors[(l:lineBefore+1):(l:rakeAbortedLine-1)]

	return erroneous#handleCommandResults(l:errorCommand,a:output,l:actualErrors,a:targetList,a:jump)
endfunction
