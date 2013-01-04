"Version: 0.3.0

"execute a command and return a list of two items: stdout and stderr(both are
"lists).
" * command: the command to run.
function! erroneous#execGetErrors(command)
	let l:outFile=tempname()
	let l:errFile=tempname()
	silent exe "!(".a:command.") 2>".l:errFile." 1>".l:outFile
	let l:outFileContents=readfile(l:outFile)
	let l:errFileContents=readfile(l:errFile)
	call delete(l:outFile)
	call delete(l:errFile)
	return [l:outFileContents,l:errFileContents]
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
" * targetList: 1 for the quickfix list, 2 for the locations list.
" * jump: determines if vim will jump to the first error.
function! erroneous#run(command,clearIfNoError,targetList,jump)
	"Run the command
	let [l:output,l:errors]=erroneous#execGetErrors(a:command)
	if 0<len(l:output)
		echo join(l:output,"\n")
	endif
	"If there were no errors, we might want to clean the erro list(depends on argument)
	if 0==len(l:errors)
		if a:clearIfNoError
			call erroneous#setErrorList(a:targetList,a:jump,"",0)
		endif
		return 0
	endif

	"If there were errors, we need to print them
	echohl ErrorMsg
	echo join(l:errors,"\n")
	echohl None

	return erroneous#handleCommandResults(a:command,l:output,l:errors,a:targetList,a:jump)
endfunction

"Assumed the supplied command was ran and given the supplied errors, and
"parses them normally.
" * command: the command that was ran.
" * errors: the standard output that were returned.
" * errors: the errors that were returned.
" * targetList: 1 for the quickfix list, 2 for the locations list.
" * jump: determines if vim will jump to the first error.
function! erroneous#handleCommandResults(command,output,errors,targetList,jump)
	let l:recursionDepth=1
	if exists("g:erroneous_detectionDepth")
		if type(0)==type(g:erroneous_detectionDepth)
			let l:recursionDepth=g:erroneous_detectionDepth
		endif
	endif
	let l:FormatGetterResult=erroneous#getErrorFormat(a:command,l:recursionDepth)
	if type("")==type(l:FormatGetterResult) || type(0)==type(l:FormatGetterResult)
		call erroneous#setErrorList(a:targetList,a:jump,a:errors,l:FormatGetterResult)
		return 1
	elseif type(function('tr'))==type(l:FormatGetterResult)
		return l:FormatGetterResult(a:command,a:output,a:errors,a:targetList,a:jump)
	endif
endfunction

"find the error format for a shell command
" * command: the command to get the format to
" * depth: how deep to go into files to search for shebangs\associations
function! erroneous#getErrorFormat(command,depth)
	if(exists("g:erroneous_errorFormatChooserPatterns"))
		if type(g:erroneous_errorFormatChooserPatterns)==type({}) "if we have a dictionary of patterns
			for l:key in keys(g:erroneous_errorFormatChooserPatterns)
				if a:command =~ l:key
					return g:erroneous_errorFormatChooserPatterns[l:key]
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

"Adds the prefix to the format before the errorformat prefixes
" * prefix: the prefix to add
" * format: the source errorformat
function! erroneous#addPrefixToFormat(prefix,format)
	let l:source=a:format
	let l:result=''
	while 1
		let l:formatPrefixLength=len(matchstr(l:source,'^.\{-}\(%[-+]\?[ACEIWZ>]\)'))
		if 0==l:formatPrefixLength
			return l:result.l:source
		endif
		let l:result=l:result.l:source[:(l:formatPrefixLength-1)].a:prefix
		let l:source=l:source[(l:formatPrefixLength):]
	endwhile
endfunction
