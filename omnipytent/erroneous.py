from omnipytent import FN
from omnipytent.execution import ShellCommandExecuter


class TargetList:
    QUICKFIX = 1
    LOCATION = 2


class ERUN(ShellCommandExecuter):
    @property
    def loc(self):
        return self(target_list=TargetList.LOCATION)

    @property
    def bang(self):
        return self(jump=False)


@ERUN
def ERUN(command, target_list=TargetList.QUICKFIX, jump=True):
    return FN['erroneous#run'](command, True, target_list, jump)
