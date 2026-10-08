#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; File Manager Groups
; ============================================================

GroupAdd "FileManagers", "ahk_class CabinetWClass" ; Windows Explorer
GroupAdd "FileManagers", "ahk_class TTOTAL_CMD"    ; Total Commander
GroupAdd "FileManagers", "ahk_class WindowClass_1" ; One Commander
GroupAdd "FileManagers", "ahk_class Progman"       ; Desktop
GroupAdd "FileManagers", "ahk_class WorkerW"       ; Desktop


; ============================================================
; CTRL + ALT + N
; Create New Text File in Current Explorer Tab
; ============================================================

#HotIf WinActive("ahk_group FileManagers")

^!n::
{
    activeClass := WinGetClass("A")
    currentPath := ""

    ; --------------------------------------------------------
    ; Desktop
    ; --------------------------------------------------------

    if (activeClass = "Progman" || activeClass = "WorkerW")
    {
        currentPath := A_Desktop
    }

    ; --------------------------------------------------------
    ; Windows Explorer
    ; --------------------------------------------------------

    else if (activeClass = "CabinetWClass")
    {
        currentPath := GetCurrentExplorerTabPath()

        if (currentPath = "")
            return
    }

    ; --------------------------------------------------------
    ; Other File Managers
    ; --------------------------------------------------------

    else
    {
        oldClipboard := ClipboardAll()
        A_Clipboard := ""

        Send("!d")
        Sleep(100)
        Send("^c")

        if ClipWait(0.5)
            currentPath := A_Clipboard

        A_Clipboard := oldClipboard

        Send("{Enter}")
        Sleep(100)
    }


    ; --------------------------------------------------------
    ; Validate Directory
    ; --------------------------------------------------------

    if (currentPath = "" || !DirExist(currentPath))
        return


    ; --------------------------------------------------------
    ; Generate Unique Filename
    ; --------------------------------------------------------

    baseName := currentPath "\NewFile"
    finalPath := baseName ".txt"
    fileName := "NewFile.txt"

    counter := 2

    while FileExist(finalPath)
    {
        fileName := "NewFile (" counter ").txt"
        finalPath := currentPath "\" fileName
        counter++
    }


    ; --------------------------------------------------------
    ; Create File
    ; --------------------------------------------------------

    try
    {
        FileAppend("", finalPath, "UTF-8")
    }
    catch
    {
        MsgBox(
            "Unable to create file:`n`n" finalPath,
            "Create New File",
            "Iconx"
        )
        return
    }


    ; --------------------------------------------------------
    ; Windows Explorer
    ; --------------------------------------------------------

    if (activeClass = "CabinetWClass")
    {
        ; Allow Explorer to register the new file
        Sleep(200)

        ; Refresh CURRENT TAB
        Send("{F5}")
        Sleep(300)

        ; ----------------------------------------------------
        ; IMPORTANT:
        ; Return focus from Address Bar / Navigation Pane
        ; to Explorer's File View.
        ; ----------------------------------------------------

        FocusExplorerFileView()
        Sleep(150)

        ; ----------------------------------------------------
        ; Select the newly-created file
        ; ----------------------------------------------------

        SendText(fileName)
        Sleep(250)

        ; ----------------------------------------------------
        ; Rename
        ; ----------------------------------------------------

        Send("{F2}")
    }

    ; --------------------------------------------------------
    ; Desktop / Other File Managers
    ; --------------------------------------------------------

    else
    {
        Send("{F5}")
        Sleep(200)

        SendText(fileName)
        Sleep(150)

        Send("{F2}")
    }
}

#HotIf


; ============================================================
; Get Current Explorer TAB Path
; ============================================================

GetCurrentExplorerTabPath()
{
    oldClipboard := ClipboardAll()

    try
    {
        A_Clipboard := ""

        ; Focus Address Bar of CURRENT TAB
        Send("^l")
        Sleep(100)

        ; Copy current path
        Send("^c")

        if !ClipWait(0.8)
        {
            A_Clipboard := oldClipboard
            Send("{Esc}")
            return ""
        }

        path := A_Clipboard

        ; Return from Address Bar
        Send("{Esc}")
        Sleep(100)

        A_Clipboard := oldClipboard

        ; Remove file:// prefix if present
        if InStr(path, "file:///")
            path := StrReplace(path, "file:///", "")

        ; Decode spaces
        path := StrReplace(path, "%20", " ")

        return path
    }
    catch
    {
        A_Clipboard := oldClipboard
        Send("{Esc}")
        return ""
    }
}


; ============================================================
; Focus Explorer File View
; ============================================================

FocusExplorerFileView()
{
    hwnd := WinExist("A")

    ; Explorer's main file-list control.
    ; Different Windows 11 builds can expose slightly
    ; different DirectUIHWND controls, so try several.

    controls := [
        "DirectUIHWND3",
        "DirectUIHWND2",
        "DirectUIHWND1"
    ]

    for control in controls
    {
        try
        {
            ControlFocus(control, "ahk_id " hwnd)

            ; Verify that the control actually received focus
            focused := ControlGetFocus("ahk_id " hwnd)

            if (focused = control)
                return true
        }
        catch
        {
            continue
        }
    }

    ; --------------------------------------------------------
    ; Keyboard fallback
    ;
    ; Shift+Tab several times can move focus from the
    ; navigation area toward the main File View.
    ; --------------------------------------------------------

    Send("+{Tab}")
    Sleep(50)

    Send("+{Tab}")
    Sleep(50)

    Send("+{Tab}")
    Sleep(50)

    return false
}