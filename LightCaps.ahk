#NoEnv
;#UseHook
;#InstallKeybdHook
#SingleInstance force
#MaxHotkeysPerInterval 500
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
global LgMeeter:=-1
global GuiMeeter:=0
global MODULE_PTR:=0
global VMR_FUNCTIONS:={}
global OFF:=0
global ON:=1
OnExit("ExitScript")

try {  ;文件末尾追加字节FF, 默认以QWERTY布局启动
    File := FileOpen(A_ScriptFullPath, 256)
    File.Seek(-1)
    if(File.ReadUChar()==255)
        ColeMak:=0
    File.Close()
    InitMeeter()
}

InitMeeter() {
    VM_INSTALL_PATH := "C:\Program Files (x86)\VB\Voicemeeter"
    Dll_Name := "VoicemeeterRemote64.dll"
    if(!MODULE_PTR)
        MODULE_PTR := DllCall("LoadLibrary", "Str", VM_INSTALL_PATH . "\" . Dll_Name, "Ptr")
    VMR_FUNCTIONS := GetFunctionPointers(MODULE_PTR)
    if(VMR_FUNCTIONS.haskey("Login"))
        LgMeeter := DllCall(VMR_FUNCTIONS["Login"], "Int")
}

ExitScript(exit_reason, exit_code) {
    if(LgMeeter>=0) {
        DllCall(VMR_FUNCTIONS["Logout"], "Int")
        DllCall("FreeLibrary", "Ptr", MODULE_PTR)
    }
    return 0
}

CheckMeeter() {
    if(LgMeeter<0)
        InitMeeter()
}

GetFunctionPointers(Module_Ptr) {
    if(!Module_Ptr)
        return {}
    Function_Prefix := "VBVMR_"
    Function_Names := ["Login", "Logout", "RunVoicemeeter", "GetParameterFloat", "SetParameterFloat", "IsParametersDirty", "GetLevel", "GetMidiMessage", "Input_GetDeviceNumber", "Input_GetDeviceDescA", "Output_GetDeviceNumber", "Output_GetDeviceDescA"]

    function_pointers := {}
    functions := ""
    for index, function_name in Function_Names
    {
        full_function_name := Function_Prefix . function_name
        function_ptr := DllCall("GetProcAddress", "Ptr", Module_Ptr, "AStr", full_function_name, "Ptr")
        function_pointers[function_name] := function_ptr
        functions := functions . function_name . " : " . function_ptr . "`n"
    }
    return function_pointers
}

GetParameter(parameter_name) {
    Loop
    {
        pDirty := DLLCall(VMR_FUNCTIONS["IsParametersDirty"]) ;Check if parameters have changed. 
        if (pDirty==0) ;0 = no new paramters.
            break
        else if (pDirty<0) ;-1 = error, -2 = no server
            return ""
        else ;1 = New parameters -> update your display. (this only applies if YOU have a display, couldn't find any code to update VM display which can get off sometimes)
            if A_Index > 200
                return ""
            sleep, 20
    }
    tParamVal := 0.0
    statusLvl := DllCall(VMR_FUNCTIONS["GetParameterFloat"], "AStr", parameter_name, "Ptr", &tParamVal, "Int")
    tParamVal := NumGet(tParamVal, 0, "Float")
    if (statusLvl < 0)
        return ""
    else
        return tParamVal
}

SetParameter(parameter_name, parameter_value) {
    status := DllCall(VMR_FUNCTIONS["SetParameterFloat"], "AStr", parameter_name, "Float", parameter_value, "Int")
}

GetSessionId() {
    ProcessId := DllCall("GetCurrentProcessId", "UInt")
    if (ErrorLevel)
        return 0
    DllCall("ProcessIdToSessionId", "UInt", ProcessId, "UInt*", SessionId)
    if (ErrorLevel)
        return 0
    return SessionId
}

GetDesktop() {
    SessionId := GetSessionId()
    if (SessionId) {
        RegRead, curId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\SessionInfo\%SessionId%\VirtualDesktops, CurrentVirtualDesktop
        RegRead, listId, HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VirtualDesktops, VirtualDesktopIDs
        ix := floor(InStr(listId,curId) / strlen(curId))
        return ix
    }
    return 0
}
;---------------CAPSLOCK--------------
global CapsLock2, CapsLock, HalfSleep

$*Capslock::
;Capslock:  Capslock 键状态标记，按下是1，松开是0
;Capslock2:  是否使用过 Capslock+ 功能标记，使用过会清除这个变量
CapsLock2:=CapsLock:=1

SetTimer, setCapsLock2, -180 ; 180ms 犹豫操作时间

KeyWait, Capslock
;while(GetKeyState("CapsLock","P")) {
;    Sleep, 20
;}
CapsLock:=""  ;Capslock最优先置空，来关闭 Capslock+ 功能的触发
if CapsLock2
{
    Send, {BackSpace}
}
CapsLock2:=""
return

setCapsLock2:
CapsLock2:=""
return

setHalfSleep:
HalfSleep:=""
return

setHintOff:
SetScrollLockState, on
sleep 60
SetScrollLockState, off
sleep 40
SetScrollLockState, on
sleep 60
SetScrollLockState, off
return

setHintOn:
SetScrollLockState, on
sleep 200
SetScrollLockState, off
return
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
=::[
[::'
'::=
#If
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

#If CapsLock  ;when capslock key press and hold
;--------------------------Universal shortcut-------------------------
e::
try
    Send, {up}
Capslock2:=""
return

d::
try
    Send, {down}
Capslock2:=""
return

s::
try
    Send, {left}
Capslock2:=""
return

f::
try
    Send, {right}
Capslock2:=""
return

a::
try
    Send, ^{Left}
Capslock2:=""
return

g::
try
    Send, ^{right}
Capslock2:=""
return

t::
try
    Send, {PgUp}
Capslock2:=""
return

v::
try
    Send, {PgDn}
Capslock2:=""
return

w::
try
    Send, {home}
Capslock2:=""
return

r::
try
    Send, {end}
Capslock2:=""
return

7::
try
    Send, {7}
Capslock2:=""
return

8::
try
    Send, {8}
Capslock2:=""
return

9::
try
    Send, {9}
Capslock2:=""
return

u::
try
    Send, {4}
Capslock2:=""
return

i::
try
    Send, {5}
Capslock2:=""
return

o::
try
    Send, {6}
Capslock2:=""
return

j::
try
    Send, {1}
Capslock2:=""
return

k::
try
    Send, {2}
Capslock2:=""
return

l::
try
    Send, {3}
Capslock2:=""
return

m::
try
    Send, {0}
Capslock2:=""
return

.::
try
    Send, {.}
Capslock2:=""
return

,::
try
    Send, {*}
Capslock2:=""
return

/::
try
    Send, {/}
Capslock2:=""
return

`;::
try
    Send, {-}
Capslock2:=""
return

'::
try
    Send, {+}
Capslock2:=""
return

p::
try
    Send, {:}
Capslock2:=""
return

-::
try
    Send, {_}
Capslock2:=""
return

=::
try
    Send, {`{}
Capslock2:=""
return

[::
try
    Send, {`"}
Capslock2:=""
return

]::
try
    Send, {`}}
Capslock2:=""
return

\::
try
    Send, {|}
Capslock2:=""
return

`::
try {
    if(GetDesktop()) {
        WinActivate, ahk_class Shell_TrayWnd
        Send, #^{Left}
        Sleep 40
        WinMinimize, ahk_class Shell_TrayWnd
        Send {Blind}{Ctrl Up}
        Send {Blind}{LWin Up}
    } else {
        WinActivate, ahk_class Shell_TrayWnd
        Send, #^{Right}
        Sleep 40
        WinMinimize, ahk_class Shell_TrayWnd
        Send {Blind}{Ctrl Up}
        Send {Blind}{LWin Up}
    }
}
Capslock2:=""
return

LAlt::
try
    Send, {Delete}
Capslock2:=""
return

RAlt::
try
    SetCapsLockState, % GetKeyState("CapsLock","T") ? "Off" : "On"
Capslock2:=""
return

esc::
try {
    ColeMak:=!ColeMak
    if(ColeMak)
        settimer, setHintOn, -100
    else
        settimer, setHintOff, -100
}
Capslock2:=""
return

space::
try {
    Send, {BackSpace}
    CapsLock2:=1
    HalfSleep:=1
    settimer, setHalfSleep, 200
    while(GetKeyState("Space","P")) {
        if(!HalfSleep) {
            Send, {BackSpace}
        }
        Sleep, 20
    }
}
Capslock2:=""
return

LWin::
try {
    CheckMeeter()
    if(LgMeeter>=0) {
        if(!GuiMeeter) {
            SetParameter("Command.Show", ON)
            GuiMeeter:=1
        } else {
            SetParameter("Command.Show", OFF)
            GuiMeeter:=0
        }
    }
}
Capslock2:=""
return

1::
try {
    CheckMeeter()
    if(LgMeeter>=0) {
        SetParameter("Strip[0].Mute", OFF)
        while(GetKeyState("1","P"))
        {
            Sleep, 20
        }
        SetParameter("Strip[0].Mute", ON)
    }
}
Capslock2:=""
return

<+1::
try {
    CheckMeeter()
    if(LgMeeter>=0) {
        SetParameter("Strip[0].Mute", OFF)
    }
}
Capslock2:=""
return

2::
try {
    CheckMeeter()
    if(!MODULE_PTR) {
        Send, {Volume_Down}
    } else {
        if(LgMeeter>=0) {
            BusGain:=GetParameter("Bus[0].Gain")-3
            if(BusGain<-60)
                BusGain:=-60
            if(BusGain>0 && BusGain<3)
                BusGain:=0
            SetParameter("Bus[0].Gain", BusGain)
        }
    }
}
Capslock2:=""
return

3::
try {
    CheckMeeter()
    if(!MODULE_PTR) {
        Send, {Volume_Up}
    } else {
        if(LgMeeter>=0) {
            BusGain:=GetParameter("Bus[0].Gain")+3
            if(BusGain>12)
                BusGain:=12
            if(BusGain>0 && BusGain<3)
                BusGain:=0
            SetParameter("Bus[0].Gain", BusGain)
        }
    }
}
Capslock2:=""
return

4::
try {
    CheckMeeter()
    if(!MODULE_PTR) {
        Send, {Volume_Mute}
    } else {
        if(LgMeeter>=0) {
            state:=GetParameter("Bus[0].Mute")
            if(state)
                SetParameter("Bus[0].Mute", OFF)
            else
                SetParameter("Bus[0].Mute", ON)
        }
    }
}
Capslock2:=""
return

5::
try
    Send, {Media_Play_Pause}
Capslock2:=""
return


y::
h::
n::
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
tab::
;esc::
enter::
;space::
backspace::
try
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
return

<!c::
try
    ;runFunc(keyset.caps_lalt_c)
Capslock2:=""
return

<!d::
try
    ;runFunc(keyset.caps_lalt_d)
Capslock2:=""
return

<!e::
try
    ;runFunc(keyset.caps_lalt_e)
Capslock2:=""
return

<!f::
try
    ;runFunc(keyset.caps_lalt_f)
Capslock2:=""
return

<!g::
try
    ;runFunc(keyset.caps_lalt_g)
Capslock2:=""
return

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
return

<!o::
try
    ;runFunc(keyset.caps_lalt_o)
Capslock2:=""
return

<!p::
try
    ;runFunc(keyset.caps_lalt_p)
Capslock2:=""
return

<!q::
try
    ;runFunc(keyset.caps_lalt_q)
Capslock2:=""
return

<!r::
try
    ;runFunc(keyset.caps_lalt_r)
Capslock2:=""
return

<!s::
try
    ;runFunc(keyset.caps_lalt_s)
Capslock2:=""
return

<!t::
try
    ;runFunc(keyset.caps_lalt_t)
Capslock2:=""
return

<!u::
try
    ;runFunc(keyset.caps_lalt_u)
Capslock2:=""
return

<!v::
try
    ;runFunc(keyset.caps_lalt_v)
Capslock2:=""
return

<!w::
try
    ;runFunc(keyset.caps_lalt_w)
Capslock2:=""
return

<!x::
try
    ;runFunc(keyset.caps_lalt_x)
Capslock2:=""
return

<!y::
try
    ;runFunc(keyset.caps_lalt_y)
Capslock2:=""
return

<!z::
try
    ;runFunc(keyset.caps_lalt_z)
Capslock2:=""
return

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
return

<!0::
try
    ;runFunc(keyset.caps_lalt_0)
Capslock2:=""
return

<!-::
try
    ;runFunc(keyset.caps_lalt_minus)
Capslock2:=""
return

<!=::
try
    ;runFunc(keyset.caps_lalt_equal)
Capslock2:=""
return

<!BackSpace::
try
    ;runFunc(keyset.caps_lalt_backspace)
Capslock2:=""
return

<!Tab::
try
    ;runFunc(keyset.caps_lalt_tab)
Capslock2:=""
return

<![::
try
    ;runFunc(keyset.caps_lalt_leftSquareBracket)
Capslock2:=""
return

<!]::
try
    ;runFunc(keyset.caps_lalt_rightSquareBracket)
Capslock2:=""
return

<!\::
try
    ;runFunc(keyset.caps_lalt_Backslash)
Capslock2:=""
return

<!`;::
try
    ;runFunc(keyset.caps_lalt_semicolon)
Capslock2:=""
return

<!'::
try
    ;runFunc(keyset.caps_lalt_quote)
Capslock2:=""
return

<!Enter::
try
    ;runFunc(keyset.caps_lalt_enter)
Capslock2:=""
return

<!,::
try
    ;runFunc(keyset.caps_lalt_comma)
Capslock2:=""
return

<!.::
try
    ;runFunc(keyset.caps_lalt_dot)
Capslock2:=""
return

<!/::
try
    ;runFunc(keyset.caps_lalt_slash)
Capslock2:=""
return

<!Space::
try
    ;runFunc(keyset.caps_lalt_space)
Capslock2:=""
return

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

