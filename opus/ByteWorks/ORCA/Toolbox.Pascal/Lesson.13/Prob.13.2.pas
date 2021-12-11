{---------------------------------------------------------------}{                                                               }{  Control Explorer                                             }{                                                               }{  Explores how controls work.                                  }{                                                               }{---------------------------------------------------------------}program ControlExplorer;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr, SFToolSet, ToolLocator,     MscToolSet;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileClose     = 255;   fileQuit      = 256;   appleAbout    = 257;   ctlBeepOnce   = 2;                   {control IDs}   ctlBeepTwice  = 3;   ctlTitle      = 4;   type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;var   wPtr: grafPortPtr;                   {our window}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   startStopParm: longint;              {tool start/shutdown parameter}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   var      r: rect;                          {work rectangle}   begin {DrawContents}   DrawControls(GetPort);               {draw the controls}   end; {DrawContents}   {$databank+}   procedure InitWindow;   { Set up the program window                                  }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   var      i: integer;                       {loop/index variable}   begin {InitWindow}   wPtr := NewWindow2(@' ', 0, @DrawContents, nil, $02, wrNum, rWindParam1);   end; {InitWindow}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                      }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileClose:   ;      fileQuit:    done := true;      editUndo:    ;      editCut:     ;      editCopy:    ;      editPaste:   ;      editClear:   ;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}   procedure HandleControl;   { Take action after a control has been selected                 }   begin {HandleControl}   if (myEvent.taskData4 & $FFFF8000) = 0 then      case ord(myEvent.taskData4) of         ctlBeepOnce:    SysBeep;         ctlBeepTwice:   begin SysBeep; SysBeep; end;         otherwise:      ;         end; {case}   end; {HandleControl}begin {ControlExplorer}startStopParm :=                        {start up the tools}   StartUpTools(userID, 2, 1);if ToolError <> 0 then   SysFailMgr(ToolError, @'Could not start tools: ');InitMenus;                              {set up the menu bar}InitWindow;                             {set up the program window}InitCursor;                             {show the cursor}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInControl: HandleControl;      otherwise: ;      end; {case}until done;ShutDownTools(1, startStopParm);        {shut down the tools}end. {ControlExplorer}