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
    
    if WinActive("ahk_class Progman") || WinActive("ahk_class WorkerW") {
        currentPath := A_Desktop
    } else {
        ; ذخیره محتوای فعلی کلیپ‌بورد
        oldClipboard := ClipboardAll()
        A_Clipboard := ""
        
        ; رفتن به آدرس‌بار با Alt+D (پایدارتر از Ctrl+L در ویندوز ۱۱)
        Send("!d") 
        Sleep(60)
        Send("^c")
        
        if ClipWait(0.5) {
            currentPath := A_Clipboard
        }
        
        ; بازیابی کلیپ‌بورد
        A_Clipboard := oldClipboard
        
        ; ترفند اصلی: زدن اینتر فوکوس را مستقیماً به لیست فایل‌های همان تب فعال برمی‌گرداند
        Send("{Enter}")
        Sleep(60)
    }
    
    ; بررسی معتبر بودن مسیر
    if (currentPath == "" || !DirExist(currentPath))
        return

    ; تعیین نام فایل جدید (NewFile.txt)
    baseName := currentPath "\NewFile"
    ext := ".txt"
    finalPath := baseName ext
    counter := 2
    
    while FileExist(finalPath) {
        finalPath := baseName " (" counter ")" ext
        counter++
    }
    
    ; ساخت فایل متنی خالی
    FileAppend "", finalPath, "UTF-8"
    
    ; عملیات رفرش و تغییر نام سریع
    if (isExplorer) {
        ; رفرش کردن تب فعلی
        Send("{F5}") 
        Sleep(250)   ; فرصت به ویندوز برای نمایش فایل در لیست
        
        ; گرفتن نام فایل بدون مسیر
        SplitPath finalPath, &fileName
        
        ; تایپ کردن حرف اول فایل برای پرش سریع روی آن (یک روش سنتی اما ۱۰۰٪ پایدار در تب‌ها)
        Send("N") 
        Sleep(50)
        
        ; حالا زدن کلید F2 برای تغییر نام
        Send("{F2}")
    } else {
        ; رفرش ساده برای سایر فایل منیجرها
        Send("{F5}") 
    }
}
#HotIf