{---------------------------------------------------------------}{                                                               }{  Frame                                                        }{                                                               }{  This is a frame for other programs.  It contains a basic     }{  event loop, a menu bar, an about box, and supports NDAs.     }{                                                               }{---------------------------------------------------------------}program Frame;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileNew       = 260;   fileOpen      = 261;   fileClose     = 255;   fileQuit      = 256;   appleAbout    = 257;type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;var   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   wPtr: grafPortPtr;                   {most recently opened window}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}    function NewDocument: grafPortPtr;   { Open a new window, returning the pointer                   }   {                                                            }   { Returns: Window's window pointer; nil for an error         }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   begin {NewDocument}   NewDocument :=      NewWindow2(@'MyWindow', 0, nil, nil, $02, wrNum, rWindParam1);   end; {NewDocument}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileNew:     wPtr := NewDocument;      fileOpen:    wPtr := NewDocument;      fileClose:   ;      fileQuit:    done := true;      editUndo:    ;      editCut:     ;      editCopy:    ;      editPaste:   ;      editClear:   ;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}begin {Frame}StartDesk(640);InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      otherwise: ;      end; {case}until done;EndDesk;end. {Frame}