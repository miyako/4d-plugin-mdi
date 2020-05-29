//%attributes = {}
MDI SET TITLE ("abcde")
$title:=MDI Get title

MDI SET POSITION (HWND_TOP;0;0;900;900;SWP_NOACTIVATE)
MDI GET POSITION ($x;$y;$width;$height)

  //MDI MAXIMIZE
  //MDI MINIMIZE
  //MDI RESTORE

MDI SET CLOSE BOX ENABLED (0)

$close:=MDI Get close box enabled   //enabled when closing the structure/project
