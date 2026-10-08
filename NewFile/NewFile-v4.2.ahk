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
    ; Explorer
    ; --------------------------------------------------------

    if (activeClass = "CabinetWClass")
    {
        ; Give Explorer a moment to register the new file
        Sleep(150)

        ; Refresh CURRENT TAB
        Send("{F5}")
        Sleep(300)

        ; Make sure focus is inside the file view
        Send("{Esc}")
        Sleep(50)

        ; ----------------------------------------------------
        ; Select newly-created file
        ; ----------------------------------------------------
        ;
        ; Explorer supports incremental filename selection.
        ; Typing the exact filename selects that file in the
        ; CURRENT TAB, without needing to identify the tab
        ; through Shell.Application.
        ;

        SendText(fileName)
        Sleep(200)

        ; ----------------------------------------------------
        ; Enter Rename Mode
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

        ; Select newly-created file
        SendText(fileName)
        Sleep(150)

        ; Rename
        Send("{F2}")
    }
}

#HotIf


; ============================================================
; Get Path of CURRENT Explorer TAB
; ============================================================

GetCurrentExplorerTabPath()
{
    oldClipboard := ClipboardAll()

    try
    {
        A_Clipboard := ""

        ; Ctrl+L focuses the address bar of the CURRENT TAB.
        Send("^l")
        Sleep(100)

        ; Copy current tab's path.
        Send("^c")

        if !ClipWait(0.8)
        {
            A_Clipboard := oldClipboard
            return ""
        }

        path := A_Clipboard

        ; Escape address bar and return to Explorer.
        Send("{Esc}")
        Sleep(100)

        A_Clipboard := oldClipboard

        ; Remove possible file:// prefix.
        if InStr(path, "file:///")
            path := StrReplace(path, "file:///", "")

        ; Decode common URL path formatting.
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