
"execute a command and return the list of errors
" * command: the command to run.
" * printingMode: 0 to not print stderr, 1 to print it using 'tee',
"   2 to run the entire command silently and print stdout after it's done.
function! erroneous#execGetErrors(command,printingMode)
	let l:errFile=tempname()
	if 0==a:printingMode
		exe "!".a:command." 2>".l:errFile
	elseif 1==a:printingMode
		if has('unix')
			exe "!".a:command." 2> >(tee ".l:errFile.")"
		elseif has('win32')
		endif
	elseif 2==a:printingMode
		echo system(a:command." 2>".l:errFile)
	endif
	let l:errFileContents=readfile(l:errFile)
	call delete(l:errFile)
	return l:errFileContents
endfunction

"set the specified error list(1=quickfix,2=locations) to the specified errors
" * targetList: 1 for the quickfix list, 2 for locations list.
" * jump: determine if to jump to the first error.
" * errors: the errors to set the list to.
" * errorFormat: the errorformat to use when setting the list.
function! erroneous#setErrorList(targetList,jump,errors,errorFormat)
	if type('')==type(a:errorFormat)
		let l:oldErrorFormat=&errorformat
		let &errorformat=a:errorFormat
		call erroneous#setErrorList(a:targetList,a:jump,a:errors,0)
		let &errorformat=l:oldErrorFormat
	else
		if a:targetList==1
			if(a:jump)
				cexpr a:errors
			else
				cgetexpr a:errors
			endif
		elseif a:targetList==2
			if(a:jump)
				lexpr a:errors
			else
				lgetexpr a:errors
			endif
		endif
	endif
endfunction

"runs the command
" * command: the command to run.
" * clearIfNoError: determines if the list will be clear in case there were no errors.
" * errorPrintingMode: 0 for not printing them, 1 for printing the file after
"   the process finished, and 2 for using 'tee' to print while the process is running,
"   and 3 for running the command silently and printing the results afterward.
" * targetList: 1 for the quickfix list, 2 for the locations list.
" * jump: determines if vim will jump to the first error.
function! erroneous#run(command,clearIfNoError,errorPrintingMode,targetList,jump)
	"Run the command
	if 0==a:errorPrintingMode
		let l:errors=erroneous#execGetErrors(a:command,0)
	elseif 1==a:errorPrintingMode
		let l:errors=erroneous#execGetErrors(a:command,0)
		echo join(l:errors,"\n")
	elseif 2==a:errorPrintingMode
		let l:errors=erroneous#execGetErrors(a:command,1)
	elseif 3==a:errorPrintingMode
		let l:errors=erroneous#execGetErrors(a:command,1)
	endif

	"Check if there were errors
	if len(l:errors)==0
		if a:clearIfNoError
			call erroneous#setErrorList(a:targetList,a:jump,"",0)
		endif
		return 0
	endif

	let l:FormatGetterResult=erroneous#getErrorFormat(a:command,1)
	if type("")==type(l:FormatGetterResult)
		call erroneous#setErrorList(a:targetList,a:jump,l:errors,l:FormatGetterResult)
		return 1
	elseif type(function('tr'))==type(l:FormatGetterResult)
		return l:FormatGetterResult(a:command,l:errors,a:targetList,a:jump)
	endif
endfunction

"find the error format for a shell command
" * command: the command to get the format to
" * depth: how deep to go into files to search for shebangs\associations
function! erroneous#getErrorFormat(command,depth)
	if(exists("g:erroneous_errorFormatChooserPatterns"))
		if type(g:erroneous_errorFormatChooserPatterns)==type({}) "if we have a dictionary of patterns
			for [l:key,l:value] in items(g:erroneous_errorFormatChooserPatterns)
				if a:command =~ l:key
					return l:value
				endif
			endfor
		endif
	endif
	let l:wordsInCommand=split(a:command)
	if(exists("g:erroneous_errorFormatChooserWords"))
		if type(g:erroneous_errorFormatChooserWords)==type({}) "if it's a dictionary
			for l:fileWord in l:wordsInCommand
				let l:word=split(l:fileWord,'/')[-1]
				if has_key(g:erroneous_errorFormatChooserWords,l:word)
					if(g:erroneous_errorFormatChooserWords[l:word] isnot 0)
						return g:erroneous_errorFormatChooserWords[l:word]
					endif
				elseif 0<a:depth
					if executable(l:fileWord)
						let l:fileCommand=erroneous#getCommandForRunningFile(l:fileWord)
						if type('')==type(l:fileCommand)
							let l:FileResult=erroneous#getErrorFormat(l:fileCommand,a:depth-1)
							if type('')==type(l:FileResult) || type(function('tr'))==type(l:FileResult)
								return l:FileResult
							end
						endif
					endif
				endif
			endfor
		endif
	endif
	return 0
endfunction

"find the command used by the OS for running a file
function! erroneous#getCommandForRunningFile(file)
	if has('unix')
		let l:filePath=split(system('which '.a:file),'\n')[0]
		if filereadable(l:filePath)
			let l:firstLine=readfile(l:filePath,'',1)[0]
			if "#!"==l:firstLine[:1]
				return l:firstLine[2:]
			else
				return 0
			endif
		endif
	elseif has('win32')
	endif
endfunction

