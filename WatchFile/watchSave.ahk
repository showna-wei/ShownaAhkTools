;WatchFolder  := D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI
;WatchFolders=C:\Temp*|%A_Temp%*|%A_Desktop%|%A_DesktopCommon%|%A_MyDocuments%*|%A_ScriptDir%|%A_WinDir%*
; varName:= vname,"string"
; StringName = str1str2%vname1%str3%vname4%
;MsgBox % Test3.id "," Test3.val

#Persistent
SetBatchLines,-1
SetWinDelay,-1
OnExit, GuiClose

GameExeFile= D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI\Evoland.exe
WatchFolders=D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI
; global DetectFileName:="D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI\atest.txt"
global DetectFileName:="D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI\slot0.sav"
global BackupFolderName="tempSave\"
global LastModifiedTimeTickCount:= 0
global CurrentModifiedTimeString:= ""
global ResultMessage:= ""
;backup time interval must more than
global timeItervalBackup:=6000
global timeIterval:=600

Hotkey, ^!Down, BackupFileByHand, On
Hotkey, ^!Up, BackupFileByHand, On
; Return
;1.shortcut to backup
;2.autorun when open

; Run, D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI\Evoland.exe,D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI
Gui,+Resize

Gui, Margin, 20, 20
Gui, Add, Text, , Add Game Execution File:
Gui, Add, Edit, xm y+3 w730 vGameExeFile cGray +ReadOnly, %GameExeFile%
Gui, Add, Button, x+m yp w50 hp +Default vSelectExe gSelectExeFile, ...
Gui, Add, Button, y+10 w50 hp +Default vRunExe gRunExe, Run

Gui, Add, Text, xm, Watch Save File:
Gui, Add, Edit, xm y+3 w730 vDetectFileName cGray +ReadOnly, %DetectFileName%
Gui, Add, Button, x+m yp w50 hp +Default vSelect gSelectFile, ...

; Gui,Add,ListView,xm r10 w800 vWatchingDirectoriesList HWNDhList1 gShow,WatchingDirectories|WatchingSubdirs
Gui,Add,ListView,xm r10 w800 vWatchingDirectoriesList HWNDhList1 gShow,WatchingFiles

;loop,parse is a way to split watchFolders into signle item indexed by A_LoopField with a splited sign('|')
Loop,Parse,WatchFolders,|
    ; Loop,Parse,DetectFileName,|
WatchDirectory(A_LoopField,"ReportChanges")

;A line that begins with a comma (or any other operator) is automatically appended to the line above it.
;SubStr: 0 extracts the last character and -1 extracts the two last characters
Loop,Parse,DetectFileName,|
    LV_Add("",SubStr(A_LoopField,0)="*" ? (SubStr(A_LoopField,1,StrLen(A_LoopField)-1)) : A_LoopField
,SubStr(A_LoopField,0)="*" ? 1 : 0)
LV_ModifyCol(1,"AutoHdr")
Gui,Add,ListView,xm r30 w800 vChangesList HWNDhList2 gShow,Time|FileChangedFrom - Double click to show in Explorer|FileChangedTo - Double click to show in Explorer| Backup
; Gui,Add,Button,gAdd Default,Watch new directory
Gui,Add,Button,gDelete Default,Stop watching all directories
Gui,Add,Button,gClear x+1,Clear List
Gui,Add,StatusBar,,Changes Registered
Gui, Show
Return

; ----------------------------------------------------------------------------------------------------------------------------------
RunExe:
    Run, %GameExeFile%, %WatchFolders%
return 

SelectExeFile: 
    FileSelectFile, GameExeFile
    If !(ErrorLevel) {
        GuiControl, +cDefault, GameExeFile
        GuiControl, , GameExeFile, %GameExeFile%
        GuiControl, Enable, Action
    }
Return

SelectFile: 
    FileSelectFile, DetectFileName
    If !(ErrorLevel) {
        GuiControl, +cDefault, DetectFileName
        GuiControl, , DetectFileName, %DetectFileName%
        GuiControl, Enable, Action
    }
    BackupInfo:=GetBackUpFilePath(DetectFileName,"")
    WatchFolders:=BackupInfo.OriginalPath
    ; MsgBox %WatchFolders%
    Gui,ListView, WatchingDirectoriesList
    LV_Delete()
    ; WatchDirectory(WatchFolders),LV_Add("",WatchFolders,0)
    WatchDirectory(WatchFolders),LV_Add("",BackupInfo.file,0)
    LV_ModifyCol(1,"AutoHdr")
    Gui,ListView, ChangesList
Return

Clear:
    Gui,ListView, ChangesList
    LV_Delete()
Return

Delete:
    WatchDirectory("")
    Gui,ListView, WatchingDirectoriesList
    LV_Delete()
    Gui,ListView, ChangesList
    TotalChanges:=0
    SB_SetText("Changes Registered")
Return

Show:
    If A_GuiEvent!=DoubleClick
        Return
    Gui,ListView,%A_GuiControl%
    LV_GetText(file,A_EventInfo,3)
    If file=
        LV_GetText(file,A_EventInfo,2)
    Run,% "explorer.exe /e`, /n`, /select`," . file
Return

Add:
    Gui,+OwnDialogs
    dir=
    FileSelectFolder,dir,,3,Select directory to watch for
        If !dir
        Return
    SetTimer,SetMsgBoxButtons,-10
    MsgBox, 262146,Add directory,Would you like to watch for changes in:`n%dir%

    Gui,ListView, WatchingDirectoriesList
    IfMsgBox Retry
    WatchDirectory(dir "*"),LV_Add("",dir,1)
    IfMsgBox Ignore
    WatchDirectory(dir),LV_Add("",dir,0)
    LV_ModifyCol(1,"AutoHdr")
    Gui,ListView, ChangesList
Return

SetMsgBoxButtons:
    WinWait, ahk_class #32770
    WinActivate
    WinWaitActive
    ControlSetText,Button2,&Incl. subdirs, ahk_class #32770
    ControlSetText,Button3,&Excl. subdirs, ahk_class #32770
Return

ReportChanges(times,from,to,message){
    global TotalChanges
    Gui,ListView, ChangesList
    LV_Insert(1,"",times,from,to,message)
    LV_ModifyCol()
    LV_ModifyCol(1,"AutoHdr"),LV_ModifyCol(2,"AutoHdr"),LV_ModifyCol(3,"AutoHdr")
    TotalChanges++
    SB_SetText("Changes Registered " . TotalChanges)
}

CopyFile(from,to,folderName){
    if (SubStr(folderName,0)="\")
        StringTrimRight,folderName,folderName,1
    ; MsgBox %folderName%
    if !FileExist(folderName){
        FileCreateDir, %folderName%
        ; MsgBox Create%folderName%
    }
    FileCopy, %from%, %to%
}

BackupFileByHand(){
    ; CopyTag:="BY"A_YYYY A_MM A_DD A_Hour A_Min A_Sec 
    ThisHotkey :=A_ThisHotkey
    ;MsgBox, %ThisHotkey%
    CopyTag:="ByHand" 
    BackupInfo:=GetBackUpFilePath(DetectFileName,CopyTag)
    BackupPath:=BackupInfo.path
    BackupFile:=BackupInfo.file
    ; MsgBox % " " . DetectFileName . " " . BackupFile . " " . BackupPath
    if( ThisHotkey="^!Down"){
        CopyFile(DetectFileName,BackupFile,BackupPath)
        message=Backup File By Hand
    }else if(ThisHotkey="^!Up") {
        CopyFile(BackupFile,DetectFileName,BackupPath)
        message=Restore Backup File By Hand
    }
    else{
        return
    }
    times:=A_Hour ":" A_Min ":" A_Sec ":" A_MSec
    ReportChanges(times,DetectFileName,BackupFile,message)
}

GetBackUpFilePath(DetectFileName,CopyTag){
    StringGetPos, pos1, DetectFileName, \, R
    length := StrLen(DetectFileName) - pos1 -1
    pos_prev1 := pos1+1 ;last / position
    pos1 += 2 ; Adjust for use with StringMid.
    StringGetPos, pos2, DetectFileName, ., R
    pos_prev2 := pos2+1 ; last . position
    namelength := pos_prev2- pos1
    StringMid, name_component1, DetectFileName, %pos1%, %namelength%
    StringMid, path_component, DetectFileName, 1, %pos_prev1%
    StringMid, name_component3, DetectFileName, %pos_prev2%, %length%
    OriginaName=%name_component1%%name_component3% 
    CopiedFileName=%name_component1%%CopyTag%%name_component3% 
    BackupPath=%path_component%%BackupFolderName%
    BackupFile=%path_component%%BackupFolderName%%CopiedFileName%
    BackupInfo:={path:BackupPath,file:BackupFile,OriginalPath:path_component,OriginalFName:OriginaName,NewFileNmae:CopiedFileName}
return BackupInfo
}

GuiClose:
    WatchDirectory("") ;Stop Watching Directory = delete all directories
ExitApp
END:
return

#include <_Struct>
WatchDirectory(p*){
    ;Structures
    static FILE_NOTIFY_INFORMATION:="DWORD NextEntryOffset,DWORD Action,DWORD FileNameLength,WCHAR FileName[1]"
    static OVERLAPPED:="ULONG_PTR Internal,ULONG_PTR InternalHigh,{struct{DWORD offset,DWORD offsetHigh},PVOID Pointer},HANDLE hEvent"
    ;Variables
    static running,sizeof_FNI=65536,temp1:=VarSetCapacity(nReadLen,8),WatchDirectory:=RegisterCallback("WatchDirectory","F",0,0)
    static timer,ReportToFunction,LP,temp2:=VarSetCapacity(LP,(260)*(A_PtrSize/2),0)
    static @:=Object(),reconnect:=Object(),#:=Object(),DirEvents,StringToRegEx="\\\|.\.|+\+|[\[|{\{|(\(|)\)|^\^|$\$|?\.?|*.*"
    ;ReadDirectoryChanges related
    static FILE_NOTIFY_CHANGE_FILE_NAME=0x1,FILE_NOTIFY_CHANGE_DIR_NAME=0x2,FILE_NOTIFY_CHANGE_ATTRIBUTES=0x4
    ,FILE_NOTIFY_CHANGE_SIZE=0x8,FILE_NOTIFY_CHANGE_LAST_WRITE=0x10,FILE_NOTIFY_CHANGE_CREATION=0x40
    ,FILE_NOTIFY_CHANGE_SECURITY=0x100
    static FILE_ACTION_ADDED=1,FILE_ACTION_REMOVED=2,FILE_ACTION_MODIFIED=3
    ,FILE_ACTION_RENAMED_OLD_NAME=4,FILE_ACTION_RENAMED_NEW_NAME=5
    static OPEN_EXISTING=3,FILE_FLAG_BACKUP_SEMANTICS=0x2000000,FILE_FLAG_OVERLAPPED=0x40000000
    ,FILE_SHARE_DELETE=4,FILE_SHARE_WRITE=2,FILE_SHARE_READ=1,FILE_LIST_DIRECTORY=1
    If p.MaxIndex(){
        If (p.MaxIndex()=1 && p.1=""){
            for i,folder in #
                DllCall("CloseHandle","Uint",@[folder].hD),DllCall("CloseHandle","Uint",@[folder].O.hEvent)
            ,@.Remove(folder)
            #:=Object()
            DirEvents:=new _Struct("HANDLE[1000]")
            DllCall("KillTimer","Uint",0,"Uint",timer)
            timer=
            Return 0
        } else {
            if p.2
                ReportToFunction:=p.2
            If !IsFunc(ReportToFunction)
                Return -1 ;DllCall("MessageBox","Uint",0,"Str","Function " ReportToFunction " does not exist","Str","Error Missing Function","UInt",0)
            RegExMatch(p.1,"^([^/\*\?<>\|""]+)(\*)?(\|.+)?$",dir)
            if (SubStr(dir1,0)="\")
                StringTrimRight,dir1,dir1,1
            StringTrimLeft,dir3,dir3,1
            If (p.MaxIndex()=2 && p.2=""){
                for i,folder in #
                    If (dir1=SubStr(folder,1,StrLen(folder)-1))
                    Return 0 ,DirEvents[i]:=DirEvents[#.MaxIndex()],DirEvents[#.MaxIndex()]:=0
                @.Remove(folder),#[i]:=#[#.MaxIndex()],#.Remove(i)
                Return 0
            }
        }
        if !InStr(FileExist(dir1),"D")
            Return -1 ;DllCall("MessageBox","Uint",0,"Str","Folder " dir1 " does not exist","Str","Error Missing File","UInt",0)
        for i,folder in #
        {
            If (dir1=SubStr(folder,1,StrLen(folder)-1) || (InStr(dir1,folder) && @[folder].sD))
                Return 0
            else if (InStr(SubStr(folder,1,StrLen(folder)-1),dir1 "\") && dir2){ ;replace watch
                DllCall("CloseHandle","Uint",@[folder].hD),DllCall("CloseHandle","Uint",@[folder].O.hEvent),reset:=i
            } 
        }
        LP:=SubStr(LP,1,DllCall("GetLongPathName","Str",dir1,"Uint",&LP,"Uint",VarSetCapacity(LP))) "\"
        If !(reset && @[reset]:=LP)
            #.Insert(LP)
        @[LP,"dir"]:=LP
        @[LP].hD:=DllCall("CreateFile","Str",StrLen(LP)=3?SubStr(LP,1,2):LP,"UInt",0x1,"UInt",0x1|0x2|0x4
        ,"UInt",0,"UInt",0x3,"UInt",0x2000000|0x40000000,"UInt",0)
        @[LP].sD:=(dir2=""?0:1)

        Loop,Parse,StringToRegEx,|
            StringReplace,dir3,dir3,% SubStr(A_LoopField,1,1),% SubStr(A_LoopField,2),A
        StringReplace,dir3,dir3,%A_Space%,\s,A
        Loop,Parse,dir3,|
        {
            If A_Index=1
                dir3=
            pre:=(SubStr(A_LoopField,1,2)="\\"?2:0)
            succ:=(SubStr(A_LoopField,-1)="\\"?2:0)
            dir3.=(dir3?"|":"") (pre?"\\\K":"")
            . SubStr(A_LoopField,1+pre,StrLen(A_LoopField)-pre-succ)
            . ((!succ && !InStr(SubStr(A_LoopField,1+pre,StrLen(A_LoopField)-pre-succ),"\"))?"[^\\]*$":"") (succ?"$":"")
        }
        @[LP].FLT:="i)" dir3
        @[LP].FUNC:=ReportToFunction
        @[LP].CNG:=(p.3?p.3:(0x1|0x2|0x4|0x8|0x10|0x40|0x100))
        If !reset {
            @[LP].SetCapacity("pFNI",sizeof_FNI)
            @[LP].FNI:=new _Struct(FILE_NOTIFY_INFORMATION,@[LP].GetAddress("pFNI"))
            @[LP].O:=new _Struct(OVERLAPPED)
        }
        @[LP].O.hEvent:=DllCall("CreateEvent","Uint",0,"Int",1,"Int",0,"UInt",0)
        If (!DirEvents)
            DirEvents:=new _Struct("HANDLE[1000]")
        DirEvents[reset?reset:#.MaxIndex()]:=@[LP].O.hEvent
        DllCall("ReadDirectoryChangesW","UInt",@[LP].hD,"UInt",@[LP].FNI[""],"UInt",sizeof_FNI
        ,"Int",@[LP].sD,"UInt",@[LP].CNG,"UInt",0,"UInt",@[LP].O[""],"UInt",0)
        Return timer:=DllCall("SetTimer","Uint",0,"UInt",timer,"UInt",timeIterval,"UInt",WatchDirectory)
    } else {
        Sleep, 0
        for LP in reconnect
        {
            If (FileExist(@[LP].dir) && reconnect.Remove(LP)){
                DllCall("CloseHandle","Uint",@[LP].hD)
                @[LP].hD:=DllCall("CreateFile","Str",StrLen(@[LP].dir)=3?SubStr(@[LP].dir,1,2):@[LP].dir,"UInt",0x1,"UInt",0x1|0x2|0x4
                ,"UInt",0,"UInt",0x3,"UInt",0x2000000|0x40000000,"UInt",0)
                DllCall("ResetEvent","UInt",@[LP].O.hEvent)
                DllCall("ReadDirectoryChangesW","UInt",@[LP].hD,"UInt",@[LP].FNI[""],"UInt",sizeof_FNI
                ,"Int",@[LP].sD,"UInt",@[LP].CNG,"UInt",0,"UInt",@[LP].O[""],"UInt",0)
            }
        }
        if !( (r:=DllCall("MsgWaitForMultipleObjectsEx","UInt",#.MaxIndex()
            ,"UInt",DirEvents[""],"UInt",0,"UInt",0x4FF,"UInt",6))>=0
        && r<#.MaxIndex() ){
            return
        }

        ;not update gui temperary
        DllCall("KillTimer", UInt,0, UInt,timer)
        LP:=#[r+1],DllCall("GetOverlappedResult","UInt",@[LP].hD,"UInt",@[LP].O[""],"UIntP",nReadLen,"Int",1)
        If (A_LastError=64){ ; ERROR_NETNAME_DELETED - The specified network name is no longer available.
            If !FileExist(@[LP].dir) ; If folder does not exist add to reconnect routine
                reconnect.Insert(LP,LP)
        } else

        EndLoop:=0
        Loop {
            ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;init time;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
            CurrentModifiedTimeString:=A_Hour ":" A_Min ":" A_Sec ":" A_MSec
            CurrentTimeTickCount:=A_TickCount
            CopyTag:=A_YYYY A_MM A_DD A_Hour A_Min
            ResultMessage=""

            FNI:=A_Index>1?(new _Struct(FILE_NOTIFY_INFORMATION,FNI[""]+FNI.NextEntryOffset)):(new _Struct(FILE_NOTIFY_INFORMATION,@[LP].FNI[""]))

            If (FNI.Action < 0x6){
                FileName:=@[LP].dir . StrGet(FNI.FileName[""],FNI.FileNameLength/2,"UTF-16")
                If (FNI.Action=FILE_ACTION_RENAMED_OLD_NAME)
                    FileFromOptional:=FileName
                If (@[LP].FLT="" || RegExMatch(FileName,@[LP].FLT) || FileFrom)
                If (FileName=DetectFileName){
                    If (FNI.Action=FILE_ACTION_ADDED){
                        FileTo:=FileName
                    } else If (FNI.Action=FILE_ACTION_REMOVED){
                        FileFrom:=FileName
                    } 
                    ;;;;;;;;;;;;;;;;;;;Modify situation;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    else If (FNI.Action=FILE_ACTION_MODIFIED){

                        ;DetectFileName=D:\Program Files\Epic Games\EvolandLegendaryEditdWwMI\atest.txt

                        FileFrom:=FileTo:=FileName
                        FileTo:=DetectFileName
                        If (FileName=DetectFileName){
                            TimeIntervals:=CurrentTimeTickCount-LastModifiedTimeTickCount
                            ; FileTo=Modified Yes%CurrentTimeTickCount%\,%LastModifiedTimeTickCount%\,%TimeIntervals%
                            FileTo=Modified in %TimeIntervals% ms, not backup.
                            EndLoop:=1
                            //one minutes backup one time
                            If (TimeIntervals> timeItervalBackup){
                                FileTo=Modified Yes2 ;%CurrentTimeTickCount% %LastModifiedTimeTickCount% %TimeIntervals%
                                LastModifiedTimeTickCount:=CurrentTimeTickCount

                                BackupInfo:=GetBackUpFilePath(DetectFileName,CopyTag)
                                CopyFile(DetectFileName,BackupInfo.file,BackupInfo.path)
                                ofname:=BackupInfo.OriginalFName
                                nfname:=BackupInfo.NewFileNmae
                                ; ResultMessage=Copyed "%ofname%" to"%nfname%"
                                ResultMessage=Auto Backup
                                FileTo:=BackupInfo.file
                            }
                        }
                        ;;;;;;;;;;;;;;;;;;;Modify situation end;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                    } else If (FNI.Action=FILE_ACTION_RENAMED_OLD_NAME){
                        FileFrom:=FileName
                    } else If (FNI.Action=FILE_ACTION_RENAMED_NEW_NAME){
                        FileTo:=FileName
                    }
                }
                If (FNI.Action != 4 && (FileTo . FileFrom) !="")
                    ; pre define @[LP].FUNC:=ReportToFunction
                @[LP].Func(CurrentModifiedTimeString,FileFrom=""?FileFromOptional:FileFrom,FileTo,ResultMessage)
                ,FileFrom:="",FileFromOptional:="",FileTo:=""
            }

        } Until (EndLoop==1 || !FNI.NextEntryOffset || ((FNI[""]+FNI.NextEntryOffset) > (@[LP].FNI[""]+sizeof_FNI-12)))
        DllCall("ResetEvent","UInt",@[LP].O.hEvent)
        DllCall("ReadDirectoryChangesW","UInt",@[LP].hD,"UInt",@[LP].FNI[""],"UInt",sizeof_FNI
        ,"Int",@[LP].sD,"UInt",@[LP].CNG,"UInt",0,"UInt",@[LP].O[""],"UInt",0)
        timer:=DllCall("SetTimer","Uint",0,"UInt",timer,"UInt",timeIterval,"UInt",WatchDirectory)
        Return
    }
Return
}
