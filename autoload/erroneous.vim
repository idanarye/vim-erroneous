
"execute a command and return the list of errors
function! erroneous#execGetErrors(command)
	let l:errFile=tempname()
	exe "!".a:command." 2>".errFile
	let l:errFileContents=readfile(errFile)
	call delete(errFile)
	return l:errFileContents
endfunction

"set the specified error list(1=quickfix,2=locations) to the specified expression
function! s:setErrorList(targetList,jump,expression)
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
function! erroneous#run(command,clearIfNoError,echoErrors,targetList,jump)
	"Run the command
	let l:errors=erroneous#execGetErrors(a:command)

	"Check if there were errors
	if len(l:errors)==0 
		if a:clearIfNoError
			call s:setErrorList(a:targetList,a:jump,"")
		endif
		return 0
	endif

	"Set the error format
	let l:oldErrorFormat=&errorformat
	let &errorformat=erroneous#getErrorFormat(a:command)
	let l:errorFormatOK=&errorformat!=""
	if l:errorFormatOK
		call s:setErrorList(a:targetList,a:jump,l:errors)
	endif
	if (!l:errorFormatOK)||a:echoErrors
		echo join(l:errors,"\n")
	endif
	let &errorformat=l:oldErrorFormat
	return 1
endfunction

"find the error format for the program
function! erroneous#getErrorFormat(program)
	let l:wordsInProgram=split(a:program)
	if type(g:erroneous#errorFormatChooser)==4 "if it's a dictionary
		for l:word in l:wordsInProgram
			if has_key(g:erroneous#errorFormatChooser,l:word)
				if(g:erroneous#errorFormatChooser[l:word] isnot 0)
					return g:erroneous#errorFormatChooser[l:word]
				endif
			endif
		endfor
	endif
	return &errorformat
endfunction

"initialize the error format chooser to be an empty dictionary
if(has("g:erroneous#errorFormatChooser"))
	let g:erroneous#errorFormatChooser={}
endif
