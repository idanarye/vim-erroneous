"Version: 0.2.0

"Parse errors for Ant. To be placed inside the erroneous dictionaries.
" * command: The command
" * output: The standard output
" * errors: The error output
" * targetList: The target list
" * jump: The 'jump' choice
function! erroneous_ant#parseErrorOutput(command,output,errors,targetList,jump)
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
	return 1
endfunction
