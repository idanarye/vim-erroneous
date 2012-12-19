
"execute a command and return the list of errors
function! erroneous#execGetErrors(command,useTee)
	let l:errFile=tempname()
	if a:useTee
		if has('unix')
			exe "!".a:command." 2> >(tee ".l:errFile.")"
		elseif has('win32')
		endif
	else
		exe "!".a:command." 2>".l:errFile
	end
	let l:errFileContents=readfile(errFile)
	call delete(errFile)
	return l:errFileContents
endfunction

"set the specified error list(1=quickfix,2=locations) to the specified expression
function! erroneous#setErrorList(targetList,jump,expression)
	if a:targetList==1
		if(a:jump)
			cexpr a:expression
		else
			cgetexpr a:expression
		endif
	elseif a:targetList==2
		if(a:jump)
			lexpr a:expression
		else
			lgetexpr a:expression
		endif
	endif
endfunction

"runs the command
" * clearIfNoError: determines if the list will be clear in case there were no errors.
" * errorPrintingMode: 0 for not printing them, 1 for printing the file after
"   the process finished, and 2 for using 'tee' to print while the process is running.
" * targetList: 1 for the quickfix list, 2 for the locations list.
" * jump: determines if vim will jump to the first error.
function! erroneous#run(command,clearIfNoError,errorPrintingMode,targetList,jump)
	"Run the command
	let l:errors=erroneous#execGetErrors(a:command,2==a:errorPrintingMode)

	"Check if there were errors
	if len(l:errors)==0
		if a:clearIfNoError
			call erroneous#setErrorList(a:targetList,a:jump,"")
		endif
		return 0
	endif

	"Set the error format
	let l:oldErrorFormat=&errorformat
	let l:tmpErrorFormat=erroneous#getErrorFormat(a:command)
	if type("")==type(l:tmpErrorFormat) && ""!=l:tmpErrorFormat
		let &errorformat=l:tmpErrorFormat
	end
	call erroneous#setErrorList(a:targetList,a:jump,l:errors)
	if 1==a:errorPrintingMode
		echo join(l:errors,"\n")
	endif
	let &errorformat=l:oldErrorFormat
	return 1
endfunction

"find the error format for the program
function! erroneous#getErrorFormat(program)
	let l:wordsInProgram=split(a:program)
	if(exists("g:erroneous_errorFormatChooser"))
		if type(g:erroneous_errorFormatChooser)==type({}) "if it's a dictionary
			for l:word in l:wordsInProgram
				let l:word=split(l:word,'/')[-1]
				if has_key(g:erroneous_errorFormatChooser,l:word)
					if(g:erroneous_errorFormatChooser[l:word] isnot 0)
						return g:erroneous_errorFormatChooser[l:word]
					endif
				endif
			endfor
		endif
	endif
	return &errorformat
endfunction


