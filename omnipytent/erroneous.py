from omnipytent import CMD
from omnipytent.execution import ShellCommandExecuter


@ShellCommandExecuter
def ERUN(command):
    CMD.Erun.bang(command)


@ShellCommandExecuter
def ELRUN(command):
    CMD.Elrun.bang(command)
