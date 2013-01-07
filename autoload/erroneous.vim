"Version: 0.4.0

if has('ruby')
	ruby load File.join(VIM::evaluate("expand('<sfile>:p:h')"),'erroneous.rb')
endif

"execute a command and return a list of three items: exit code, stdout and
"stderr(last two are lists).
" * command: the command to run.
function! erroneous#execGetErrors(command)
	if has('ruby') && !(exists("g:erroneous_dontUseRuby") && g:erroneous_dontUseRuby)
		ruby VIM::command("return #{Erroneous::to_vim(Erroneous::runShellCommand(VIM::evaluate('a:command')))}")
	endif
	let l:outFile=tempname()
	let l:errFile=tempname()
	silent exe "!(".a:command.") 2>".l:errFile." 1>".l:outFile
	let l:outFileContents=readfile(l:outFile)
	let l:errFileContents=readfile(l:errFile)
	call delete(l:outFile)
	call delete(l:errFile)

	"If there was output, we need to print it
	if 0<len(l:outFileContents)
		echo join(l:outFileContents,"\n")
	endif
	"If there were errors, we need to print them
	if 0<len(l:errFileContents)
		echohl ErrorMsg
		echo join(errFileContents,"\n")
		echohl None

		"We can't tell the exit status without ruby, so since there was error
		"output we just use 1.
		return [1,l:outFileContents,l:errFileContents]
	endif

	"We can't tell the exit status without ruby, so since there was no error
	"output we just use 0.
	return [0,l:outFileContents,l:errFileContents]
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
	let [l:exitCode,l:output,l:errors]=erroneous#execGetErrors(a:command)

	"If there were no errors, we might want to clean the error list(depends on argument)
	if !l:exitCode && 0==len(l:errors) "Check both exit code and error output
		if a:clearIfNoError
			call erroneous#setErrorList(a:targetList,a:jump,"",0)
		endif
		return 0
	endif

	return erroneous#handleCommandResults(a:command,l:exitCode,l:output,l:errors,a:targetList,a:jump)
endfunction

"Assumed the supplied command was ran and given the supplied errors, and
"parses them normally.
" * command: the command that was ran.
" * exitCode the exit code returned by the command(or guessed, if Ruby was not
"	used for running the command)
" * output the standard output that were returned.
" * errors: the errors that were returned.
" * targetList: 1 for the quickfix list, 2 for the locations list.
" * jump: determines if vim will jump to the first error.
function! erroneous#handleCommandResults(command,exitCode,output,errors,targetList,jump)
	let l:recursionDepth=1
	if exists("g:erroneous_detectionDepth")
		if type(0)==type(g:erroneous_detectionDepth)
			let l:recursionDepth=g:erroneous_detectionDepth
		endif
	endif
	let l:FormatGetterResult=erroneous#getErrorFormat(a:command,l:recursionDepth)
	if type("")==type(l:FormatGetterResult) || type(0)==type(l:FormatGetterResult)
		call erroneous#setErrorList(a:targetList,a:jump,a:errors,l:FormatGetterResult)
		return a:exitCode
	elseif type(function('tr'))==type(l:FormatGetterResult)
		return l:FormatGetterResult(a:command,a:exitCode,a:output,a:errors,a:targetList,a:jump)
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
		try
			let l:suffix=matchstr(a:file,'\.\w*$')
			let l:filetype=matchstr(system('assoc '.l:suffix),'=.*$')[1:]
			let l:command matchstr(system('ftype '.l:filetype),'=.*$')[1:]
			if 0<len(l:command)
				return l:command
			else
				return 0
			endif
		catch
			return 0
		endtry
	else
		return 0
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

"Parse errors for Make. To be placed inside the erroneous dictionaries.
" * command: The command
" * exitCode the exit code returned by the command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous#parseMakeErrorOutput(command,exitCode,output,errors,targetList,jump)
	return erroneous#handleCommandResults(a:output[-1],a:exitCode,a:output,a:errors,a:targetList,a:jump)
endfunction

"Parse errors for Rake. To be placed inside the erroneous dictionaries.
" * command: The command
" * exitCode the exit code returned by the command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous#parseRakeErrorOutput(command,exitCode,output,errors,targetList,jump)
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

	return erroneous#handleCommandResults(l:errorCommand,a:exitCode,a:output,l:actualErrors,a:targetList,a:jump)
endfunction

"Parse errors for Ant. To be placed inside the erroneous dictionaries.
" * command: The command
" * exitCode the exit code returned by the command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous#parseAntErrorOutput(command,exitCode,output,errors,targetList,jump)
	let l:subCommands={}
	for l:subCommand in map(filter(copy(a:output)+copy(a:errors),'v:val=~"\\s*\\[.*\\]"'),'matchstr(v:val,"\\[.*\\]")[1:-2]')
		if !has_key(l:subCommands,l:subCommand)
			let l:FormatGetterResult=erroneous#getErrorFormat(l:subCommand,0) "Using zero depth 'cause it's an ant task.
			if type('')==type(l:FormatGetterResult) "Make sure it's a string
				let l:subCommands[l:subCommand]=l:FormatGetterResult
			else "If it's not a string, don't check this command again.
				let l:subCommands[l:subCommand]=0
			endif
		endif
	endfor
	let l:errorformat=''
	for [l:key,l:value] in items(l:subCommands)
		let l:errorformat=l:errorformat.erroneous#addPrefixToFormat('%\s\*['.l:key.']',l:value).','
	endfor
	let l:errorformat=l:errorformat."%^%f:%l: %m" "add Ant's error format

	call erroneous#setErrorList(a:targetList,a:jump,a:output+a:errors,l:errorformat)
	return a:exitCode
endfunction

"Parse errors for Maven. To be placed inside the erroneous dictionaries.
" * command: The command
" * exitCode the exit code returned by the command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous#parseMavenErrorOutput(command,exitCode,output,errors,targetList,jump)
	"Check if Maven was ran in '-e' mode - if so, we want to catch the error
	"trace.
	if a:command=~'\(\s\|[|><]\)-e\(\s\|[|><]\|$\)'
		let l:errorformat='[ERROR] %f:[%l\,%v] %m'.",%Z[ERROR]\t%$,%-C\t%.%#"
	else
		let l:errorformat='[ERROR] %f:[%l\,%v] %m'
	endif
	call erroneous#setErrorList(a:targetList,a:jump,filter(a:output,'v:val=~''^\(\(\[ERROR\]\)\|\t\)'''),l:errorformat)
	return a:exitCode
endfunction
