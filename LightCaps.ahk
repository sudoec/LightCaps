#UseHook
#SingleInstance force
#MaxHotkeysPerInterval 500
#NoEnv
ListLines Off
Process Priority,,High


if not A_IsAdmin ;running by administrator
{
   Run *RunAs "%A_ScriptFullPath%" 
   ExitApp
}


IfExist, icon.ico
{
    ;freezing icon
    menu, TRAY, Icon, icon.ico, , 1
}
Menu, Tray, Icon,,, 1


start:
;-----------------START-----------------
global ColeMak:=1
SetTimer, mouseWatch, 40

mouseWatch:
if !WinActive("ahk_class VMUIFrame")
    return
MouseGetPos, xpos, ypos
if(xpos!=xposLast || ypos!=yposLast){
    xposLast:=xpos
    yposLast:=ypos
    status:=1
}
else{
    status:=0
}
if(statusLast==1 && status==0){
    suspend on
    suspend off
}
statusLast:=status
return


;---------------CAPSLOCK--------------
global CapsLock2, CapsLock, CapsLockD, HalfSleep

$*Capslock::
;Capslock:  Capslock 键状态标记，按下是1，松开是0
;Capslock2: 是否使用过 Capslock+ 功能标记，使用过会清除这个变量
CapsLock2:=CapsLock:=1

SetTimer, setCapsLock2, -180 ; 180ms 犹豫操作时间

KeyWait, Capslock
CapsLock:="" ;Capslock最优先置空，来关闭 Capslock+ 功能的触发
if CapsLock2
{
    Send, {BackSpace}
}
CapsLock2:=""
Return

setCapsLock2:
CapsLock2:=""
return

setCapsLockD:
CapsLockD:=""
return

setHalfSleep:
HalfSleep:=""
return

delayedBackSpace()
{
    CapsLockD:=1
    SetTimer, setCapsLockD, -50
    while(CapsLockD)
    {
        counts:=0
        while(GetKeyState("CapsLock","P"))
        {
            ;CapsLockD:=""
            if(counts==0)
            {
                Send, {BackSpace}
            }
            if(counts>2)
            {
                CapsLockD:=""
            }
            if(counts>15)
            {
                Send, {BackSpace}
                sleep 10
            }
            counts++
            sleep 10
        }
    }
    return
}


;---------------------------colemak-keys-set----------------------------
#If ColeMak
;^!p::suspend
e::f
r::p
t::g
y::j
u::l
i::u
o::y
p::;
s::r
d::s
f::t
g::d
j::n
k::e
l::i
`;::o
n::k
#If
;#IfWinActive ahk_class Qt5QWindowIcon
#IfWinActive ahk_exe VirtualBoxVM.exe
LWin::
ControlSend, , {LWin Down}, A
while(GetKeyState("LWin","P"))
{}
ControlSend, , {LWin Up}, A
return
#IfWinActive

;----------------------------keys-set-start-----------------------------
;  KEY_TO_NAME := {"a":"a","b":"b","c":"c","d":"d","e":"e","f":"f","g":"g","h":"h","i":"i"
;    ,"j":"j","k":"k","l":"l","m":"m","n":"n","o":"o","p":"p","q":"q","r":"r"
;    ,"s":"s","t":"t","u":"u","v":"v","w":"w","x":"x","y":"y","z":"z"
;    ,"1":"1","2":"2","3":"3","4":"4","5":"5","6":"6","7":"7","8":"8","9":"9","0":"0"
;    ,"f1":"f1","f2":"f2","f3":"f3","f4":"f4","f5":"f5","f6":"f6"
;    ,"f7":"f7","f8":"f8","f9":"f9","f10":"f10","f11":"f11","f12":"f12"
;    ,"f13":"f13","f14":"f14","f15":"f15","f16":"f16","f17":"f17","f18":"f18","f19":"f19"
;    ,"space":"space","tab":"tab","enter":"enter","esc":"esc","backspace":"backspace"
;    ,"`":"backQuote","-":"minus","=":"equal","[":"leftSquareBracket","]":"rightSquareBracket"
;    ,"\":"backSlash",";":"semicolon","'":"quote",",":"comma",".":"dot","/":"slash","ralt":"ralt"
;    ,"wheelUp":"wheelUp","wheelDown":"wheelDown"}

;  for k,v in KEY_TO_NAME{
;      msgbox, % v
;  }

#If CapsLock ;when capslock key press and hold
;--------------------------Universal shortcut-------------------------
<!WheelUp::
try
    ;
Capslock2:=""
return

<!WheelDown::
try
    ;
Capslock2:=""
return

e::
try
    SendInput,{up}
Capslock2:=""
Return

d::
try
    SendInput,{down}
Capslock2:=""
Return

s::
try
    SendInput,{left}
Capslock2:=""
Return

f::
try
    SendInput,{right}
Capslock2:=""
Return

a::
try
    SendInput,^{Left}
Capslock2:=""
Return

g::
try
    SendInput,^{right}
Capslock2:=""
Return

t::
try
    SendInput, {PgUp}
Capslock2:=""
Return

v::
try
    SendInput, {PgDn}
Capslock2:=""
Return

w::
try
    SendInput,{home}
Capslock2:=""
Return

r::
try
    SendInput,{end}
Capslock2:=""
Return

m::
try
    SendInput,{0}
Capslock2:=""
Return

.::
try
    SendInput,{.}
Capslock2:=""
Return

j::
try
    SendInput,{1}
Capslock2:=""
Return

k::
try
    SendInput,{2}
Capslock2:=""
Return

l::
try
    SendInput,{3}
Capslock2:=""
Return

u::
try
    SendInput,{4}
Capslock2:=""
Return

i::
try
    SendInput,{5}
Capslock2:=""
Return

o::
try
    SendInput,{6}
Capslock2:=""
Return

7::
try
    SendInput,{7}
Capslock2:=""
Return

8::
try
    SendInput,{8}
Capslock2:=""
Return

9::
try
    SendInput,{9}
Capslock2:=""
Return

p::
try
    SendInput,{+}
Capslock2:=""
Return


,::
try
    SendInput,{-}
Capslock2:=""
Return

`;::
try
    SendInput,{*}
Capslock2:=""
Return

/::
try
    SendInput,{/}
Capslock2:=""
Return


1::
2::
3::
4::
5::
6::
0::
f1::
f2::
f3::
f4::
f5::
f6::
f7::
f8::
f9::
f10::
f11::
f12::
;space::
tab::
enter::
esc::
backspace::
;ralt::
try
    ;Send, {BackSpace}
    ;runFunc(keyset["caps_" . A_ThisHotkey])
Capslock2:=""
Return

`::
try
    ColeMak:=!ColeMak
Capslock2:=""
return

-::
try
    ;runFunc(keyset.caps_minus)
Capslock2:=""
return

=::
try
    ;runFunc(keyset.caps_equal)
Capslock2:=""
Return


[::
try
    ;runFunc(keyset.caps_leftSquareBracket)
Capslock2:=""
Return

]::
try
    ;runFunc(keyset.caps_rightSquareBracket)
Capslock2:=""
Return

\::
try
    ;runFunc(keyset.caps_backslash)
Capslock2:=""
return

'::
try
    ;runFunc(keyset.caps_quote)
Capslock2:=""
return

LAlt::
try
    Send, {Delete}
Capslock2:=""
return

space::
try
    Send, {BackSpace}
    CapsLock2:=1
    HalfSleep:=1
    settimer, setHalfSleep, 200
    while(GetKeyState("Space","P"))
    {
        if(HalfSleep)
        {
        }
        else
        {
            Send, {BackSpace}
            Sleep, 20
        }
    }
Capslock2:=""
return

RAlt::
try
    SetCapsLockState, % GetKeyState("CapsLock","T") ? "Off" : "On"
Capslock2:=""
return



;---------------------caps+lalt----------------

<!a::
try
    ;runFunc(keyset.caps_lalt_a)
Capslock2:=""
return

<!b::
try
    ;runFunc(keyset.caps_lalt_b)
Capslock2:=""
Return

<!c::
try
    ;runFunc(keyset.caps_lalt_c)
Capslock2:=""
return

<!d::
try
    ;runFunc(keyset.caps_lalt_d)
Capslock2:=""
Return

<!e::
try
    ;runFunc(keyset.caps_lalt_e)
Capslock2:=""
Return

<!f::
try
    ;runFunc(keyset.caps_lalt_f)
Capslock2:=""
Return

<!g::
try
    ;runFunc(keyset.caps_lalt_g)
Capslock2:=""
Return

<!h::
try
    ;runFunc(keyset.caps_lalt_h)
Capslock2:=""
return

<!i::
try
    ;runFunc(keyset.caps_lalt_i)
Capslock2:=""
return

<!j::
try
    ;runFunc(keyset.caps_lalt_j)
Capslock2:=""
return

<!k::
try
    ;runFunc(keyset.caps_lalt_k)
Capslock2:=""
return

<!l::
try
    ;runFunc(keyset.caps_lalt_l)
Capslock2:=""
return

<!m::
try
    ;runFunc(keyset.caps_lalt_m)
Capslock2:=""
return

<!n::
try
    ;runFunc(keyset.caps_lalt_n)
Capslock2:=""
Return

<!o::
try
    ;runFunc(keyset.caps_lalt_o)
Capslock2:=""
return

<!p::
try
    ;runFunc(keyset.caps_lalt_p)
Capslock2:=""
Return

<!q::
try
    ;runFunc(keyset.caps_lalt_q)
Capslock2:=""
return

<!r::
try
    ;runFunc(keyset.caps_lalt_r)
Capslock2:=""
Return

<!s::
try
    ;runFunc(keyset.caps_lalt_s)
Capslock2:=""
Return

<!t::
try
    ;runFunc(keyset.caps_lalt_t)
Capslock2:=""
Return

<!u::
try
    ;runFunc(keyset.caps_lalt_u)
Capslock2:=""
return

<!v::
try
    ;runFunc(keyset.caps_lalt_v)
Capslock2:=""
Return

<!w::
try
    ;runFunc(keyset.caps_lalt_w)
Capslock2:=""
Return

<!x::
try
    ;runFunc(keyset.caps_lalt_x)
Capslock2:=""
Return

<!y::
try
    ;runFunc(keyset.caps_lalt_y)
Capslock2:=""
return

<!z::
try
    ;runFunc(keyset.caps_lalt_z)
Capslock2:=""
Return

<!`::
    ;runFunc(keyset.caps_lalt_backquote)
Capslock2:=""
return

<!1::
try
    ;runFunc(keyset.caps_lalt_1)
Capslock2:=""
return

<!2::
try
    ;runFunc(keyset.caps_lalt_2)
Capslock2:=""
return

<!3::
try
    ;runFunc(keyset.caps_lalt_3)
Capslock2:=""
return

<!4::
try
    ;runFunc(keyset.caps_lalt_4)
Capslock2:=""
return

<!5::
try
    ;runFunc(keyset.caps_lalt_5)
Capslock2:=""
return

<!6::
try
    ;runFunc(keyset.caps_lalt_6)
Capslock2:=""
return

<!7::
try
    ;runFunc(keyset.caps_lalt_7)
Capslock2:=""
return

<!8::
try
    ;runFunc(keyset.caps_lalt_8)
Capslock2:=""
return

<!9::
try
    ;runFunc(keyset.caps_lalt_9)
Capslock2:=""
Return

<!0::
try
    ;runFunc(keyset.caps_lalt_0)
Capslock2:=""
Return

<!-::
try
    ;runFunc(keyset.caps_lalt_minus)
Capslock2:=""
return

<!=::
try
    ;runFunc(keyset.caps_lalt_equal)
Capslock2:=""
Return

<!BackSpace::
try
    ;runFunc(keyset.caps_lalt_backspace)
Capslock2:=""
Return

<!Tab::
try
    ;runFunc(keyset.caps_lalt_tab)
Capslock2:=""
Return

<![::
try
    ;runFunc(keyset.caps_lalt_leftSquareBracket)
Capslock2:=""
Return

<!]::
try
    ;runFunc(keyset.caps_lalt_rightSquareBracket)
Capslock2:=""
Return

<!\::
try
    ;runFunc(keyset.caps_lalt_Backslash)
Capslock2:=""
return

<!`;::
try
    ;runFunc(keyset.caps_lalt_semicolon)
Capslock2:=""
Return

<!'::
try
    ;runFunc(keyset.caps_lalt_quote)
Capslock2:=""
return

<!Enter::
try
    ;runFunc(keyset.caps_lalt_enter)
Capslock2:=""
Return

<!,::
try
    ;runFunc(keyset.caps_lalt_comma)
Capslock2:=""
Return

<!.::
try
    ;runFunc(keyset.caps_lalt_dot)
Capslock2:=""
return

<!/::
try
    ;runFunc(keyset.caps_lalt_slash)
Capslock2:=""
Return

<!Space::
try
    ;runFunc(keyset.caps_lalt_space)
Capslock2:=""
Return

<!RAlt::
try
    ;runFunc(keyset.caps_lalt_ralt)
Capslock2:=""
return

<!F1::
try
    ;runFunc(keyset.caps_lalt_f1)
Capslock2:=""
return

<!F2::
try
    ;runFunc(keyset.caps_lalt_f2)
Capslock2:=""
return

<!F3::
try
    ;runFunc(keyset.caps_lalt_f3)
Capslock2:=""
return

<!F4::
try
    ;runFunc(keyset.caps_lalt_f4)
Capslock2:=""
return

<!F5::
try
    ;runFunc(keyset.caps_lalt_f5)
Capslock2:=""
return

<!F6::
try
    ;runFunc(keyset.caps_lalt_f6)
Capslock2:=""
return

<!F7::
try
    ;runFunc(keyset.caps_lalt_f7)
Capslock2:=""
return

<!F8::
try
    ;runFunc(keyset.caps_lalt_f8)
Capslock2:=""
return

<!F9::
try
    ;runFunc(keyset.caps_lalt_f9)
Capslock2:=""
return

<!F10::
try
    ;runFunc(keyset.caps_lalt_f10)
Capslock2:=""
return

<!F11::
try
    ;runFunc(keyset.caps_lalt_f11)
Capslock2:=""
return

<!F12::
try
    ;runFunc(keyset.caps_lalt_f12)
Capslock2:=""
return


