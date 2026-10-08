#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; File Manager Groups
; ============================================================

GroupAdd "FileManagers", "ahk_class CabinetWClass"
GroupAdd "FileManagers", "ahk_class TTOTAL_CMD"
GroupAdd "FileManagers", "ahk_class WindowClass_1"
GroupAdd "FileManagers", "ahk_class Progman"
GroupAdd "FileManagers", "ahk_class WorkerW"


; ============================================================
; CTRL + ALT + N
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
    ; Validate
    ; --------------------------------------------------------

    if (currentPath = "" || !DirExist(currentPath))
        return


    ; --------------------------------------------------------
    ; Generate Unique File Name
    ; --------------------------------------------------------

    baseName := currentPath "\NewFile"
    fileName := "NewFile.txt"
    finalPath := currentPath "\" fileName

    counter := 2

    while FileExist(finalPath)
    {
        fileName := "NewFile (" counter ").txt"
        finalPath := currentPath "\" fileName
        counter++

        finalPath := currentPath "\" fileName
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


    ; ========================================================
    ; WINDOWS EXPLORER
    ; ========================================================

    if (activeClass = "CabinetWClass")
    {
        Sleep(250)

        ; Refresh current Explorer TAB
        Send("{F5}")
        Sleep(400)

        ; ----------------------------------------------------
        ; Select file using Windows Explorer Shell COM
        ; ----------------------------------------------------

        if SelectExplorerFile(finalPath)
        {
            Sleep(250)

            ; F2 now operates on the selected Explorer item.
            Send("{F2}")
        }
        else
        {
            ; ------------------------------------------------
            ; Final fallback:
            ; use Explorer's built-in search-by-name selection.
            ; ------------------------------------------------

            SelectFileByName(fileName)

            Sleep(200)

            Send("{F2}")
        }

        return
    }


    ; ========================================================
    ; OTHER FILE MANAGERS / DESKTOP
    ; ========================================================

    Send("{F5}")
    Sleep(200)

    SelectFileByName(fileName)

    Sleep(150)

    Send("{F2}")
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

        ; Address bar of CURRENT TAB
        Send("^l")
        Sleep(100)

        Send("^c")

        if !ClipWait(0.8)
        {
            A_Clipboard := oldClipboard
            Send("{Esc}")
            return ""
        }

        path := A_Clipboard

        Send("{Esc}")
        Sleep(100)

        A_Clipboard := oldClipboard

        ; Normalize path
        if InStr(path, "file:///")
            path := StrReplace(path, "file:///", "")

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
; Select Explorer File
; ============================================================

SelectExplorerFile(fullPath)
{
    SplitPath(
        fullPath,
        &fileName,
        &directory
    )

    try
    {
        shell := ComObject("Shell.Application")

        for window in shell.Windows
        {
            try
            {
                ; Explorer HWND
                if (window.HWND != WinExist("A"))
                    continue

                folder := window.Document.Folder

                ; Current folder
                folderPath := folder.Self.Path

                if (folderPath != directory)
                    continue

                ; Find file
                item := folder.ParseName(fileName)

                if !item
                    continue

                ; ------------------------------------------------
                ; Select the item directly.
                ; Flags:
                ;   1 = Select
                ;   4 = Deselect others
                ;   8 = Ensure visible
                ; ------------------------------------------------

                window.Document.SelectItem(
                    item,
                    1 | 4 | 8
                )

                Sleep(150)

                return true
            }
            catch
            {
                continue
            }
        }
    }
    catch
    {
        return false
    }

    return false
}


; ============================================================
; Select File By Name
; ============================================================

SelectFileByName(fileName)
{
    ; Explorer filename incremental search.
    ;
    ; IMPORTANT:
    ; We first force Explorer to leave any command/address
    ; control and then send the filename.

    Send("{Esc}")
    Sleep(50)

    ; Press F6 enough times to cycle through Explorer UI.
    ; File View is one of the targets in the cycle.

    Send("{F6}")
    Sleep(50)

    Send("{F6}")
    Sleep(50)

    Send("{F6}")
    Sleep(50)

    Send("{F6}")
    Sleep(50)

    ; Select the file by typing its exact name.
    SendText(fileName)

    Sleep(250)
}


; ============================================================
; End
; ============================================================