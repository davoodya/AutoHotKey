#NoTrayIcon
*MButton::

GetKeyState, CapsState, CapsLock, T
If CapsState = D
SetCapsLockState, Off

Send, {AltDown}{Tab}
Sleep, 200
Loop
{
GetKeyState, WheelState, MButton, P
If WheelState = D
Sleep, 400
GetKeyState, WheelState, MButton, P
If WheelState = D
Send, {Tab}
Else
{
Send, {AltUp}
Break
}
}

Send, {AltUp}

If CapsState = D
SetCapsLockState, On