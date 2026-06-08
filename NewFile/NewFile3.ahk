#Requires AutoHotkey v2.0

; تعریف کلاس پنجره‌های مدیریت فایل
GroupAdd "FileManagers", "ahk_class CabinetWClass" ; Windows Explorer
GroupAdd "FileManagers", "ahk_class TTOTAL_CMD"     ; Total Commander
GroupAdd "FileManagers", "ahk_class WindowClass_1" ; One Commander
GroupAdd "FileManagers", "ahk_class Progman"        ; Desktop
GroupAdd "FileManagers", "ahk_class WorkerW"        ; Desktop Alternative

#HotIf WinActive("ahk_group FileManagers")
^!n:: {
    currentPath := ""
    isExplorer := WinActive("ahk_class CabinetWClass")
    activeHwnd := WinExist("A")
    
    if WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW") {
        currentPath := A_Desktop
    } else {
        ; ذخیره محتوای کلیپ‌بورد
        oldClipboard := ClipboardAll()
        A_Clipboard := ""
        
        ; گرفتن مسیر دقیق تب فعال بدون خطا
        Send("!d") 
        Sleep(60)
        Send("^c")
        
        if ClipWait(0.5) {
            currentPath := A_Clipboard
        }
        
        A_Clipboard := oldClipboard
        
        ; بازگرداندن فوکوس به لیست فایل‌ها با اینتر
        Send("{Enter}")
        Sleep(60)
    }
    
    if (currentPath == "" || !DirExist(currentPath))
        return

    ; تعیین نام فایل جدید
    baseName := currentPath "\NewFile"
    ext := ".txt"
    finalPath := baseName ext
    counter := 2
    
    while FileExist(finalPath) {
        finalPath := baseName " (" counter ")" ext
        counter++
    }
    
    ; ساخت فایل متنی
    FileAppend "", finalPath, "UTF-8"
    
    if (isExplorer) {
        ; رفرش کردن صفحه برای نشستن فایل در لیست
        Send("{F5}") 
        Sleep(250)
        
        SplitPath finalPath, &fileName
        
        ; ترفند اصلی: پیدا کردن تب فعال بر اساس تطابق آدرس کپی شده
        for window in ComObject("Shell.Application").Windows {
            if (window.HWND == activeHwnd) {
                try {
                    ; بررسی اینکه آیا این همان تبی است که مسیرش را کپی کردیم؟
                    if (InStr(window.Document.Folder.Self.Path, currentPath) || window.Document.Folder.Self.Path == currentPath) {
                        
                        ; انتخاب مستقیم و ۱۰۰٪ دقیق فایل بدون استفاده از کیبورد
                        item := window.Document.Folder.ParseName(fileName)
                        window.Document.SelectItem(item, 1 | 4 | 8) ; فوکوس، انتخاب و اسکرول به سمت فایل
                        
                        ; زدن کلید F2 برای ری‌نیم
                        Sleep(100)
                        Send("{F2}")
                        break
                    }
                }
            }
        }
    } else {
        Send("{F5}") 
    }
}
#HotIf