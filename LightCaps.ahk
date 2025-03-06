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

; 使用IMEID激活对应的输入法
switchIMEbyID(IMEID, WinTitle="A") {
    ;WinGetTitle, Title, %WinTitle%
    ControlGet, hwnd, HWND,,, %WinTitle%
    PostMessage, 0x50, 0, %IMEID%,, ahk_id %hwnd%
}
; 获取当前激活窗口所使用的IME的ID
getCurrentIMEID(WinTitle="A") {
    WinGet, hWnd, ID, %WinTitle%
    ThreadID:=DllCall("GetWindowThreadProcessId", "UInt", hWnd, "UInt", 0)
    InputLocaleID:=DllCall("GetKeyboardLayout", "UInt", ThreadID, "UInt")
    return InputLocaleID
}
; 判断是否处于英文模式，返回值是0表示是英文模式
getIMEMode(WinTitle="A") {
    ControlGet, hwnd, HWND,,, %WinTitle%
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI,  0, "UInt")  ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
                    ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }
    return DllCall("SendMessage"
            , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
            , UInt, 0x0283 ;Message : WM_IME_CONTROL
            ,  Int, 0x001  ;wParam  : IMC_GETCONVERSIONMODE
            ,  Int, 0)     ;lParam  : 0
}
; IME状态设置
IME_SET(SetSts, WinTitle="A")    {
    ControlGet, hwnd, HWND,,, %WinTitle%
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI,  0, "UInt")  ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
                 ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }

    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283 ;Message : WM_IME_CONTROL
          ,  Int, 0x006  ;wParam  : IMC_SETOPENSTATUS
          ,  Int, SetSts) ;lParam  : 0 or 1
}
; IME输入模式设置
IME_SetConvMode(ConvMode,WinTitle="A")   {
    ControlGet, hwnd, HWND,,, %WinTitle%
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI,  0, "UInt")  ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
                 ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }
    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283     ;Message : WM_IME_CONTROL
          ,  Int, 0x002      ;wParam  : IMC_SETCONVERSIONMODE
          ,  Int, ConvMode)  ;lParam  : CONVERSIONMODE
}
; IME转换模式设置
IME_SetSentenceMode(SentenceMode,WinTitle="A")  {
    ControlGet, hwnd, HWND,,, %WinTitle%
    if  (WinActive(WinTitle))   {
        ptrSize := !A_PtrSize ? 4 : A_PtrSize
        VarSetCapacity(stGTI, cbSize:=4+4+(PtrSize*6)+16, 0)
        NumPut(cbSize, stGTI,  0, "UInt")  ;   DWORD   cbSize;
        hwnd := DllCall("GetGUIThreadInfo", Uint,0, Uint,&stGTI)
                 ? NumGet(stGTI,8+PtrSize,"UInt") : hwnd
    }
    return DllCall("SendMessage"
          , UInt, DllCall("imm32\ImmGetDefaultIMEWnd", Uint,hwnd)
          , UInt, 0x0283         ;Message : WM_IME_CONTROL
          ,  Int, 0x004          ;wParam  : IMC_SETSENTENCEMODE
          ,  Int, SentenceMode)  ;lParam  : SentenceMode
}

CheckAudioRelay() {
    Process Exist, audiorelay-backend.exe
    ProcessId := ErrorLevel
    return ProcessId
}

GetDeviceName(device)
{
    VarSetCapacity(PKEY_Device_FriendlyName, 32)
    DllCall("ole32\CLSIDFromString", "wstr", "{A45C254E-DF1C-4EFD-8020-67D146A850E0}", "ptr", &PKEY_Device_FriendlyName)
    NumPut(14, PKEY_Device_FriendlyName, 16)
    VarSetCapacity(prop, 16)
    DllCall(NumGet(NumGet(device+0)+4*A_PtrSize), "ptr", device, "uint", 0, "ptr*", store)
    DllCall(NumGet(NumGet(store+0)+5*A_PtrSize), "ptr", store, "ptr", &PKEY_Device_FriendlyName, "ptr", &prop)
    ObjRelease(store)
    deviceName := NumGet(prop,8)
    deviceName := StrGet(ptr := deviceName, "UTF-16")
    DllCall("ole32\CoTaskMemFree", "ptr", ptr)
    return deviceName
}

SetDeviceMute(Mute, Desc="capture")
{
    static CLSID_MMDeviceEnumerator := "{BCDE0395-E52F-467C-8E3D-C4579291692E}",
                  IID_IMMDeviceEnumerator := "{A95664D2-9614-4F35-A746-DE8DB63617E6}"
    deviceEnumerator := ComObjCreate(CLSID_MMDeviceEnumerator, IID_IMMDeviceEnumerator)
    
    device := 0
    DllCall(NumGet(NumGet(deviceEnumerator+0)+5*A_PtrSize), "ptr", deviceEnumerator, "wstr", Desc, "ptr*", device)
    
    if(Desc="capture") {
        DllCall(NumGet(NumGet(deviceEnumerator+0)+4*A_PtrSize), "ptr", deviceEnumerator, "int", 1, "int", 0, "ptr*", device)
    }
    else {
        DllCall(NumGet(NumGet(deviceEnumerator+0)+3*A_PtrSize), "ptr", deviceEnumerator, "int", 2, "uint", 1, "ptr*", devices)
        DllCall(NumGet(NumGet(devices+0)+3*A_PtrSize), "ptr", devices, "uint*", count)
        Loop % count
            if DllCall(NumGet(NumGet(devices+0)+4*A_PtrSize), "ptr", devices, "uint", A_Index-1, "ptr*", device) = 0 {
                if InStr(GetDeviceName(device), Desc)
                    break
            }
        ObjRelease(devices)
    }

    ObjRelease(deviceEnumerator)
    VarSetCapacity(IID, 16, 0)
    DllCall("ole32\CLSIDFromString", "wstr", "{5CDF2C82-841E-4546-9722-0CF74078229A}", "ptr", &IID)
    DllCall(NumGet(NumGet(device+0)+3*A_PtrSize), "ptr", device, "ptr", &IID, "uint", 7, "uint", 0, "ptr*", endpointVolume)
    DllCall(NumGet(NumGet(endpointVolume+0)+14*A_PtrSize), "ptr", endpointVolume, "int", Mute, "ptr", 0)
    ObjRelease(endpointVolume)
    ObjRelease(device)
}

GetAppVolumeObj(ProcessId) {
    ISimpleAudioVolume := ""
    IMMDeviceEnumerator := ComObjCreate("{BCDE0395-E52F-467C-8E3D-C4579291692E}", "{A95664D2-9614-4F35-A746-DE8DB63617E6}")
    DllCall(NumGet(NumGet(IMMDeviceEnumerator+0)+4*A_PtrSize), "UPtr", IMMDeviceEnumerator, "UInt", 0, "UInt", 1, "UPtrP", IMMDevice, "UInt")
    ObjRelease(IMMDeviceEnumerator)

    VarSetCapacity(GUID, 16)
    DllCall("Ole32.dll\CLSIDFromString", "Str", "{77AA99A0-1BD6-484F-8BC7-2C654C9A9B6F}", "UPtr", &GUID)
    DllCall(NumGet(NumGet(IMMDevice+0)+3*A_PtrSize), "UPtr", IMMDevice, "UPtr", &GUID, "UInt", 23, "UPtr", 0, "UPtrP", IAudioSessionManager2, "UInt")
    ObjRelease(IMMDevice)

    DllCall(NumGet(NumGet(IAudioSessionManager2+0)+5*A_PtrSize), "UPtr", IAudioSessionManager2, "UPtrP", IAudioSessionEnumerator, "UInt")
    ObjRelease(IAudioSessionManager2)

    DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+3*A_PtrSize), "UPtr", IAudioSessionEnumerator, "UIntP", SessionCount, "UInt")
    Loop % SessionCount
    {
        DllCall(NumGet(NumGet(IAudioSessionEnumerator+0)+4*A_PtrSize), "UPtr", IAudioSessionEnumerator, "Int", A_Index-1, "UPtrP", IAudioSessionControl, "UInt")
        IAudioSessionControl2 := ComObjQuery(IAudioSessionControl, "{BFB7FF88-7239-4FC9-8FA2-07C950BE9C6D}")
        ObjRelease(IAudioSessionControl)

        DllCall(NumGet(NumGet(IAudioSessionControl2+0)+14*A_PtrSize), "UPtr", IAudioSessionControl2, "UIntP", PID, "UInt")
        If (PID == ProcessId)
        {
            ISimpleAudioVolume := ComObjQuery(IAudioSessionControl2, "{87CE5498-68D6-44E5-9215-6DA47EF883D8}")
        }
        ObjRelease(IAudioSessionControl2)
    }
    ObjRelease(IAudioSessionEnumerator)
    return ISimpleAudioVolume
}

SetAppVolume(ProcessId, MasterVolume) {
    MasterVolume := MasterVolume > 100 ? 100 : MasterVolume < 0 ? 0 : MasterVolume

    ISimpleAudioVolume := GetAppVolumeObj(ProcessId)
    DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+3*A_PtrSize), "UPtr", ISimpleAudioVolume, "Float", MasterVolume/100.0, "UPtr", 0, "UInt")
    ObjRelease(ISimpleAudioVolume)
}

GetAppVolume(ProcessId) {
    local MasterVolume := ""

    ISimpleAudioVolume := GetAppVolumeObj(ProcessId)
    DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+4*A_PtrSize), "UPtr", ISimpleAudioVolume, "Float*", MasterVolume, "UInt")
    ObjRelease(ISimpleAudioVolume)

    return Round(MasterVolume * 100)
}

SetAppMute(ProcessId, Muted) {
    ISimpleAudioVolume := GetAppVolumeObj(ProcessId)
    DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+5*A_PtrSize), "UPtr", ISimpleAudioVolume, "UInt", Muted, "UPtr", 0, "UInt")
    ObjRelease(ISimpleAudioVolume)
}

GetAppMute(ProcessId) {
    local Muted := 2
    ISimpleAudioVolume := GetAppVolumeObj(ProcessId)
    DllCall(NumGet(NumGet(ISimpleAudioVolume+0)+6*A_PtrSize), "UPtr", ISimpleAudioVolume, "UInt*", Muted)
    ObjRelease(ISimpleAudioVolume)
    return Muted
}

VolumeMap(vol) {
    if(vol<=6 && vol>=-30) {
        return 80 + 2*vol
    } else if(vol>6) {
        return 92 + 4*(vol-6)/3
    } else if(vol<-30) {
        return 20 + 2*(vol+30)/3
    }
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
;----------------------------basic-keys-set----------------------------
;^!p::suspend
p::;
`;::p
=::[
[::=
^f::^t
^e::^f
^t::^e
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

n::
try
    Send, {)}
Capslock2:=""
return

h::
try
    Send, {(}
Capslock2:=""
return

.::
try
    Send, {.}
Capslock2:=""
return

,::
try
    Send, {,}
Capslock2:=""
return

/::
try
    Send, {/}
Capslock2:=""
return

`;::
try
    Send, {_}
Capslock2:=""
return

'::
try
    Send, {*}
Capslock2:=""
return

p::
try
    Send, {-}
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
    Send, {+}
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
try {
    if(getCurrentIMEID()=68224017) {
        if(getIMEMode()=11 || getIMEMode()=27)
            Send {F6}
        else
            Send {F7}
    }
    else {
        Send, {Delete}
    }
}
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
    ProcessId:=CheckAudioRelay()
    if(ProcessId) {
    }
    else {
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
}
Capslock2:=""
return

1::
try {
    switchIMEbyID(134481924)
    IME_SetConvMode(0)
    IME_SET(0)
    Sleep 50
    IME_SetConvMode(0)
    IME_SET(0)
    Sleep 150
    IME_SetConvMode(0)
    IME_SET(0)
}
Capslock2:=""
return

2::
try {
    switchIMEbyID(134481924)
    IME_SetConvMode(1025)
    IME_SET(1)
    Sleep 50
    IME_SetConvMode(1025)
    IME_SET(1)
    Sleep 150
    IME_SetConvMode(1025)
    IME_SET(1)
}
Capslock2:=""
return

3::
try {
    switchIMEbyID(68224017)
    IME_SetSentenceMode(8)
    IME_SetConvMode(25)
    IME_SET(1)
    Sleep 50
    IME_SetSentenceMode(8)
    IME_SetConvMode(25)
    IME_SET(1)
    Sleep 150
    IME_SetSentenceMode(8)
    IME_SetConvMode(25)
    IME_SET(1)
}
Capslock2:=""
return

4::
try {
    switchIMEbyID(68224017)
    IME_SetSentenceMode(8)
    IME_SetConvMode(27)
    IME_SET(1)
    Sleep 50
    IME_SetSentenceMode(8)
    IME_SetConvMode(27)
    IME_SET(1)
    Sleep 150
    IME_SetSentenceMode(8)
    IME_SetConvMode(27)
    IME_SET(1)
}
Capslock2:=""
return

5::
try
    Send, {Media_Play_Pause}
Capslock2:=""
return

f1::
try {
    ProcessId:=CheckAudioRelay()
    if(ProcessId) {
        SetDeviceMute(false, "Virtual Mic")
        while(GetKeyState("f1","P"))
        {
            Sleep, 20
        }
        if(GetKeyState("CapsLock","P"))
            SetDeviceMute(true, "Virtual Mic")
    }
    else {
        CheckMeeter()
        if(LgMeeter>=0) {
            SetParameter("Strip[0].Mute", OFF)
            while(GetKeyState("1","P"))
            {
                Sleep, 20
            }
            if(GetKeyState("CapsLock","P"))
                SetParameter("Strip[0].Mute", ON)
        }
    }
}
Capslock2:=""
return

f2::
try {
    ProcessId:=CheckAudioRelay()
    if(ProcessId) {
        SoundGet, Muted,, Mute
        Volume:=GetAppVolume(ProcessId)
        SetAppMute(ProcessId, False)
        SetAppVolume(ProcessId, Volume-5)
        if(Muted="On")
            Send, {Volume_Mute}
        Send {Volume_Down}
        SoundSet, Volume-5
    }
    else {
        CheckMeeter()
        if(!MODULE_PTR) {
            Send, {Volume_Down}
        } else {
            if(LgMeeter>=0) {
                BusGain:=GetParameter("Bus[0].Gain")
                if(BusGain<=6 && BusGain>-30) {
                    BusGain -= 2
                } else {
                    BusGain -= 3
                }
                if(BusGain<-60)
                    BusGain:=-60
                if(BusGain>0 && BusGain<2)
                    BusGain:=0
                SetParameter("Bus[0].Gain", BusGain)
                SoundSet, VolumeMap(BusGain)+2
                Send {Volume_Down}
            }
        }
    }
}
Capslock2:=""
return

f3::
try {
    ProcessId:=CheckAudioRelay()
    if(ProcessId) {
        SoundGet, Muted,, Mute
        Volume:=GetAppVolume(ProcessId)
        SetAppMute(ProcessId, False)
        SetAppVolume(ProcessId, Volume+5)
        if(Muted="On")
            Send, {Volume_Mute}
        Send, {Volume_Up}
        SoundSet, Volume+5
    }
    else {
        CheckMeeter()
        if(!MODULE_PTR) {
            Send, {Volume_Up}
        } else {
            if(LgMeeter>=0) {
                BusGain:=GetParameter("Bus[0].Gain")
                if(BusGain<6 && BusGain>=-30) {
                    BusGain += 2
                } else {
                    BusGain += 3
                }
                if(BusGain>12)
                    BusGain:=12
                if(BusGain>0 && BusGain<2)
                    BusGain:=0
                SetParameter("Bus[0].Gain", BusGain)
                SoundSet, VolumeMap(BusGain)-2
                Send {Volume_Up}
            }
        }
    }
}
Capslock2:=""
return

f4::
try {
    ProcessId:=CheckAudioRelay()
    if(ProcessId) {
        SoundGet, Muted,, Mute
        AppMuted:=GetAppMute(ProcessId)
        SetAppMute(ProcessId, !AppMuted)
        if((Muted="Off"&&AppMuted=0)||(Muted="On"&&AppMuted=1))
            Send, {Volume_Mute}
        Sleep 300
        if(GetKeyState("f4", "P")) {
            SetAppMute(ProcessId, False)
            SetAppVolume(ProcessId, 100)
            SoundSet, 100
            Send {Volume_Up}
            Sleep 600
        }
    }
    else {
        Send, {Volume_Mute}
    }
}
Capslock2:=""
return

b::
y::
q::
c::
x::
z::
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