# 4d-plugin-mdi
4D plugin to resize the MDI window

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|||<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|

### Commands

```c
// --- MDI
MDI_Get_title
MDI_SET_TITLE
MDI_USE_ICON_FILE
MDI_MAXIMIZE
MDI_MINIMIZE
MDI_SET_CLOSE_BOX_ENABLED
MDI_Get_close_box_enabled
MDI_RESTORE
MDI_SET_POSITION
MDI_GET_POSITION
```

### Examples

```
MDI GET POSITION ($x;$y;$width;$height)
GET WINDOW RECT($l;$t;$r;$b;Current form window)
MDI SET POSITION (HWND_TOPMOST;$l;$t;$r-$l;$b-$t;SWP_NOACTIVATE)
DELAY PROCESS(Current process;60*2.5)
MDI SET POSITION (HWND_TOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```

**注記**: ```MDI SET POSITION```の第1引数は，配置順序のハンドルまたは定数，第6引数は，ウィンドウ位置のオプションです。[SetWindowPos](https://msdn.microsoft.com/ja-jp/library/cc411206.aspx)を参照してください。

* HWND_BOTTOM 1
* HWND_NOTOPMOST -2
* HWND_TOP 0
* HWND_TOPMOST -1
* SWP_ASYNCWINDOWPOS 16384
* SWP_DEFERERASE 8192
* SWP_DRAWFRAME 32
* SWP_HIDEWINDOW 128
* SWP_NOACTIVATE 16
* SWP_NOCOPYBITS 256
* SWP_NOMOVE 2
* SWP_NOOWNERZORDER 512
* SWP_NOREDRAW 8
* SWP_NOSENDCHANGING 1024
* SWP_NOSIZE 1
* SWP_NOZORDER 4
* SWP_SHOWWINDOW 64
