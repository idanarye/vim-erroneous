#Version: 1.0.0

module Erroneous
	require 'open3'
	require 'rbconfig'

	NO_POPEN_FOR_OS=['mingw32']

	#Breaks the buffer into a list of lines that ends with "\n" and the
	#remaining buffer.
	def self.breakBuffer(buffer)
		buffer=buffer.gsub("\r",'') #Get rid of stupid carrige returns
		lastNewLine=buffer.rindex("\n")
		if lastNewLine
			return buffer[0...lastNewLine].split("\n"),buffer[1+lastNewLine..-1]
		else
			return [],buffer
		end
	end

	def self.to_vim(source)
		if source.is_a? String or source.is_a? Symbol
			return "'#{source.to_s.gsub("'","''")}'"
		elsif source.is_a? Numeric
			return source.to_s
		elsif source.is_a? Array
			return "[#{source.map{|e|to_vim(e)}.join(',')}]"
		end
	end

	#Echoes a string, allowing you to choose highlight group for it.
	def self.vimEcho(msgs,highlight=nil)
		msgs=[msgs] unless msgs.is_a? Array
		restoreMoreOption=0!=VIM::evaluate('&more')
		VIM::command 'set nomore'
		msgs.flat_map{|e|e.split("\n")}.each do|line|
			VIM::command "echohl #{highlight}" if highlight
			VIM::command "echo #{to_vim line}"
			VIM::command 'echohl None' if highlight
		end
		VIM::command 'set more' if restoreMoreOption
	end

	#Runs a shell command while echoing it's stdout and stderr, and returns
	#exitCode, stdout and stderr.
	def self.runShellCommand(command)
		if NO_POPEN_FOR_OS.include? RbConfig::CONFIG['target_os']
			outFile=VIM::evaluate('tempname()')
			errFile=VIM::evaluate('tempname()')
			result=system("(#{command}) 2>#{errFile} 1>#{outFile}")
			outFileContent=File.readlines(outFile).map{|e|e.strip} rescue []
			errFileContent=File.readlines(errFile).map{|e|e.strip} rescue []
			File.delete outFile,errFile
			vimEcho outFileContent
			vimEcho errFileContent,:ErrorMsg
			return [result ? 0 : 1,outFileContent,errFileContent]
		end
		Open3.popen3(command) do|stdin,stdout,stderr,wait_thd|
			stdin.close_write
			outBuffer=""
			outLines=[]
			errBuffer=""
			errLines=[]
			finishedReading=false
			while wait_thd.status or not(finishedReading)
				processCanceled=0!=VIM::evaluate("s:sleepCheckIfInterrupted()")
				finishedReading=true
				begin
					outBuffer+=stdout.read_nonblock(1024)
					finishedReading=false
				rescue
				end
				begin
					errBuffer+=stderr.read_nonblock(1024)
					finishedReading=false
				rescue
				end
				newOutLines,outBuffer=breakBuffer(outBuffer)
				vimEcho newOutLines,:None
				outLines+=newOutLines
				newErrLines,errBuffer=breakBuffer(errBuffer)
				vimEcho newErrLines,:ErrorMsg
				errLines+=newErrLines
				if(processCanceled)
					wait_thd.kill
					return [wait_thd.value.exitstatus,outLines,errLines]
				end
			end
			newOutLines,outBuffer=breakBuffer(outBuffer+"\n")
			puts newOutLines
			vimEcho newOutLines,:None
			outLines+=newOutLines
			newErrLines,errBuffer=breakBuffer(errBuffer+"\n")
			vimEcho newErrLines,:ErrorMsg
			errLines+=newErrLines
			return [wait_thd.value.exitstatus,outLines,errLines]
		end rescue [127,[],["${command}: command not found"]]
	end
end
