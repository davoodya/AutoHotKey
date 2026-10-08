#Requires AutoHotkey v2.0
#SingleInstance Force

; ============================================================
; NewFile.ahk v2 — Komorebi/WHKD compatible
; Hotkey: Ctrl + Win + N  (FREE — verified no conflict with whkdrc)
; Creates a new empty file in the currently focused File Explorer
; tab (or Desktop) and immediately focuses its rename field, exactly
; like Ctrl+Shift+N does for a New Folder.
;
; WHY THIS VERSION:
;   v1 used Send("!d") to read the current path. In komorebi/whkd,
;   Alt+D is a GLOBAL hotkey (focus-last-workspace) so the synthetic
;   keystroke was swallowed by whkd and the script stalled.
;   v2 reads the path directly from the Shell COM object — zero
;   synthetic keystrokes, zero conflict with the window manager.
; ============================================================

GroupAdd "FileManagers", "ahk_class CabinetWClass" ; Windows Explorer
GroupAdd "FileManagers", "ahk_class TTOTAL_CMD"     ; Total Commander
GroupAdd "FileManagers", "ahk_class WindowClass_1" ; One Commander
GroupAdd "FileManagers", "ahk_class Progman"        ; Desktop
GroupAdd "FileManagers", "ahk_class WorkerW"        ; Desktop (alt)

#HotIf WinActive("ahk_group FileManagers")
^#n:: {
    activeHwnd := WinExist("A")
    currentPath := ""

    if WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW") {
        ; Desktop
        currentPath := A_Desktop
    } else {
        ; Read the path of the ACTIVE Explorer tab straight from the
        ; Shell COM object — no clipboard, no Send(), no hotkey clash.
        try {
            for window in ComObject("Shell.Application").Windows {
                if (window.HWND == activeHwnd) {
                    currentPath := window.Document.Folder.Self.Path
                    break
                }
            }
        }
    }

    if (currentPath == "" || !DirExist(currentPath))
        return

    ; Pick a free filename: NewFile.txt, NewFile (2).txt, ...
    baseName  := currentPath "\NewFile"
    ext       := ".txt"
    finalPath := baseName ext
    counter   := 2
    while FileExist(finalPath) {
        finalPath := baseName " (" counter ")" ext
        counter++
    }

    ; Create the file on disk (UTF-8, zero bytes)
    FileAppend "", finalPath, "UTF-8"

    ; Refresh the view so the new file appears, then select it and
    ; enter rename mode.
    if WinActive("ahk_class CabinetWClass") {
        Send("{F5}")
        Sleep(200)

        SplitPath finalPath, &fileName
        for window in ComObject("Shell.Application").Windows {
            if (window.HWND == activeHwnd) {
                try {
                    item := window.Document.Folder.ParseName(fileName)
                    window.Document.SelectItem(item, 1 | 4 | 8) ; focus + select + scroll into view
                    Sleep(80)
                    Send("{F2}")                                ; rename mode
                }
                break
            }
        }
    } else {
        Send("{F5}")
    }
}
#HotIf
