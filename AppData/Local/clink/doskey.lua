os.setalias( "ls", [[dir $*]] )
os.setalias( "cp", [[copy $*]] )
os.setalias( "rm", [[del $*]] )
os.setalias( "clear", [[cls]] )
os.setalias( "cat", [[type $*]] )
os.setalias( "mv", [[move $*]] )
os.setalias( "z", [["%LOCALAPPDATA%\clink\plugins\z.lua\z.cmd" $*]])

