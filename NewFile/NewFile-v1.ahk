#HotIf WinActive("ahk_class CabinetWClass") || WinActive("ahk_class ExploreWClass") || WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW")
^!n:: {
    ; پیدا کردن مسیر فعلی ویندوز اکسپلورر یا دسکتاپ
    currentPath := ""
    if WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW") {
        currentPath := A_Desktop
    } else {
        for window in ComObject("Shell.Application").Windows {
            if window.HWND == WinExist("A") {
                currentPath := window.Document.Folder.Self.Path
                break
            }
        }
    }
    
    if (currentPath == "")
        return

    ; تعیین نام فایل جدید
    baseName := currentPath "\NewFile"
    ext := ".txt"
    finalPath := baseName ext
    counter := 2
    
    ; اگر فایل از قبل وجود داشت، شماره اضافه کن (مثل متن جدید (2).txt)
    while FileExist(finalPath) {
        finalPath := baseName " (" counter ")" ext
        counter++
    }
    
    ; ساخت فایل خالی
    FileAppend "", finalPath, "UTF-8"
    
    ; رفرش کردن اکسپلورر و انتخاب فایل جدید برای تغییر نام
    Send("{F5}")
    Sleep(200)
    
    ; پیدا کردن نام فایل بدون مسیر برای فوکوس روی آن
    SplitPath finalPath, &fileName
    for window in ComObject("Shell.Application").Windows {
        if window.HWND == WinExist("A") {
            try {
                item := window.Document.Folder.ParseName(fileName)
                window.Document.SelectItem(item, 1 | 4 | 8) ; انتخاب و فوکوس
                Send("{F2}") ; زدن کلید F2 برای تغییر نام
            }
            break
        }
    }
}
#HotIf