# 4d-plugin-mdi
Resize the MDI window.

### Platform

| carbon | cocoa | win32 | win64 |
|:------:|:-----:|:---------:|:---------:|
|||<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|<img src="https://cloud.githubusercontent.com/assets/1725068/22371562/1b091f0a-e4db-11e6-8458-8653954a7cce.png" width="24" height="24" />|

### Version

<img width="32" height="32" src="https://user-images.githubusercontent.com/1725068/73986501-15964580-4981-11ea-9ac1-73c5cee50aae.png"> <img src="https://user-images.githubusercontent.com/1725068/73987971-db2ea780-4984-11ea-8ada-e25fb9c3cf4e.png" width="32" height="32" />

### Examples

```
MDI GET POSITION ($x;$y;$width;$height)
GET WINDOW RECT($l;$t;$r;$b;Current form window)
MDI SET POSITION (HWND_TOPMOST;$l;$t;$r-$l;$b-$t;SWP_NOACTIVATE)
DELAY PROCESS(Current process;60*2.5)
MDI SET POSITION (HWND_TOPMOST;$x;$y;$width;$height;SWP_NOACTIVATE)
```

#### Remarks

Be careful when passing arguments to ```MDI SET POSITION```. ``$1`` is the "positioning" option (``HWND_*``) ``$6`` is the "z-order" option (``SWP_*``).  

```MDI SET POSITION```の第1引数は，配置順序のハンドルまたは定数，第6引数は，ウィンドウ位置のオプションです。[SetWindowPos](https://msdn.microsoft.com/ja-jp/library/cc411206.aspx)を参照してください。

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
