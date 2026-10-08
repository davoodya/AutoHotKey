#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; File Manager Detection
; ============================================================

GroupAdd "FileManagers", "ahk_class CabinetWClass" ; Windows Explorer
GroupAdd "FileManagers", "ahk_class TTOTAL_CMD"    ; Total Commander
GroupAdd "FileManagers", "ahk_class WindowClass_1" ; One Commander
GroupAdd "FileManagers", "ahk_class Progman"       ; Desktop
GroupAdd "FileManagers", "ahk_class WorkerW"       ; Desktop Alternative


; ============================================================
; Create New Text File
; CTRL + ALT + N
; ============================================================

#HotIf WinActive("ahk_group FileManagers")

^!n::
{
    activeHwnd := WinExist("A")
    activeClass := WinGetClass("A")
    currentPath := ""

    ; --------------------------------------------------------
    ; Windows Desktop
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
        currentPath := GetExplorerPath(activeHwnd)
    }

    ; --------------------------------------------------------
    ; Other File Managers
    ; Fallback method
    ; --------------------------------------------------------

    else
    {
        oldClipboard := ClipboardAll()
        A_Clipboard := ""

        Send("!d")
        Sleep(80)
        Send("^c")

        if ClipWait(0.5)
            currentPath := A_Clipboard

        A_Clipboard := oldClipboard

        Send("{Enter}")
        Sleep(80)
    }


    ; --------------------------------------------------------
    ; Validate Path
    ; --------------------------------------------------------

    if (currentPath = "" || !DirExist(currentPath))
        return


    ; --------------------------------------------------------
    ; Generate Unique File Name
    ; --------------------------------------------------------

    baseName := currentPath "\NewFile"
    finalPath := baseName ".txt"
    counter := 2

    while FileExist(finalPath)
    {
        finalPath := baseName " (" counter ").txt"
        counter++
    }


    ; --------------------------------------------------------
    ; Create Empty UTF-8 Text File
    ; --------------------------------------------------------

    try
    {
        FileAppend("", finalPath, "UTF-8")
    }
    catch
    {
        MsgBox(
            "Unable to create the file.`n`n"
            "Path:`n" finalPath,
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
        Sleep(150)

        try
        {
            shell := ComObject("Shell.Application")

            for window in shell.Windows
            {
                try
                {
                    ; Match the actual Explorer window
                    if (window.HWND != activeHwnd)
                        continue

                    folder := window.Document.Folder
                    folderPath := folder.Self.Path

                    ; Make sure this is the correct folder
                    if (folderPath != currentPath)
                        continue

                    SplitPath(finalPath, &fileName)

                    ; Get newly-created file
                    item := folder.ParseName(fileName)

                    if item
                    {
                        ; Select + focus + scroll into view
                        window.Document.SelectItem(
                            item,
                            1 | 4 | 8
                        )

                        Sleep(150)

                        ; Rename
                        Send("{F2}")
                    }

                    break
                }
                catch
                {
                    continue
                }
            }
        }
        catch
        {
            ; Explorer COM failed.
            ; File was already created, so simply refresh Explorer.
            Send("{F5}")
        }
    }

    ; --------------------------------------------------------
    ; Other File Managers / Desktop
    ; --------------------------------------------------------

    else
    {
        Send("{F5}")
        Sleep(200)
    }
}

#HotIf


; ============================================================
; Get Current Explorer Folder Path
; ============================================================

GetExplorerPath(hwnd)
{
    try
    {
        shell := ComObject("Shell.Application")

        ; Find the Explorer instance belonging to the
        ; currently active Explorer window.
        for window in shell.Windows
        {
            try
            {
                if (window.HWND = hwnd)
                {
                    path := window.Document.Folder.Self.Path

                    if (path != "")
                        return path
                }
            }
            catch
            {
                continue
            }
        }
    }
    catch
    {
        return ""
    }

    return ""
}