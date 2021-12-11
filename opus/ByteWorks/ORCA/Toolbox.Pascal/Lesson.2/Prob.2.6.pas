{---------------------------------------------------------------}{                                                               }{  Quit                                                         }{                                                               }{---------------------------------------------------------------}program Quit;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr;const   return        = 13;                  {return key code}    File_Quit     = 256;                 {Menu ID #s}type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;var   done: boolean;                       {tells if the program should stop}   event: integer;                      {event type returned by TaskMaster}   myEvent: eventRecord;                {last event returned in event loop}   procedure InitMenus;   { Initialize the menu bar.                                   }    var      height: integer;                  {height of the largest menu}      menuHand: menuHandle;             {for 'handling' windows}      s: textPtr;                       {for building menus}    begin {InitMenus}   new(s);                              {create the file menu}   s^ := concat('>> File \N2',chr(return));   s^ := concat(s^,'--Quit\N256*Qq',chr(return));   s^ := concat(s^,'.',chr(return));   menuHand := NewMenu(s);   InsertMenu(menuHand,0);   new(s);                              {create the apple menu}   s^ := concat('>>@\XN1',chr(return));   s^ := concat(s^,'--About...\N257',chr(return));   s^ := concat(s^,'.',chr(return));   menuHand := NewMenu(s);   InsertMenu(menuHand,0);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}    procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}   begin {HandleMenu}                                        {get the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      file_Quit:   done := true;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}begin {Quit}StartDesk(640);InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let TaskMaster do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of      wInSpecial,      wInMenuBar: HandleMenu;      otherwise: ;      end; {case}until done;EndDesk;end. {Quit}