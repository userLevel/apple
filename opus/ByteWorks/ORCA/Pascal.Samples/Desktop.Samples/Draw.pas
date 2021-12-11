{$keep 'Draw'}{---------------------------------------------------------------}{                                                               }{  Draw                                                         }{                                                               }{  Draw is a (very) simple CAD program based on the Frame       }{  program.  With Draw, you can open new windows, close         }{  windows that are on the desktop, and draw lines using the    }{  mouse.  Multiple windows are supported.                      }{                                                               }{  Mike Westerfield                                             }{                                                               }{  Copyright 1989-1990                                          }{  Byte Works, Inc.                                             }{                                                               }{---------------------------------------------------------------}program Draw(output);uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr;const   return        = 13;                  {return key code}    Apple_About   = 257;                 {Menu ID #s}   File_Quit     = 256;   File_New      = 258;   File_Close    = 255;   maxWindows    = 4;                   {max # of drawing windows}   maxLines      = 50;                  {max # of lines in a window}type   alertKind = (norml,stop,note,caution); {kinds of alerts}   convert = record                     {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   windowRecord = record                {holds all info about one window}      wPtr: grafPortPtr;                {pointer to the window's port}      name: pString;                    {name of the window}      numLines: 0..maxLines;            {number of lines in this window}      lines: array[1..maxLines] of      {lines in the drawing}         record            p1,p2: point;         end;      end;var   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by TaskMaster}   lastEvent: eventRecord;              {last event returned in event loop}   windows: array[1..maxWindows] of windowRecord; {drawing windows}   procedure DoAlert (kind: alertKind; msg: pString);   { handle an alert box                                         }   {                                                             }   { parameters:                                                 }   {     kind - kind of alert                                    }   {     msg - alert message                                     }    var      message,button: itemTemplate;     {button & message items}      alertRec: alertTemplate;          {alert box}      junk: integer;                    {for receiving NoteAlert value}    begin {DoAlert}   SetForeColor(0);                     {set text colors}   SetBackColor(15);   with alertRec do begin               {initialize alert box}      with atBoundsRect do begin         v1 := 50; h1 := 180;         v2 := 107; h2 := 460;         end;      atAlertID := 2;      atStage1 := $80;      atStage2 := $80;      atStage3 := $80;      atStage4 := $80;      atItemList[1] := @button;      atItemList[2] := @message;      atItemList[3] := nil;      end;   with button do begin                 {initialize button item}      itemID := 1;      with itemRect do begin         v1 := 36; h1 := 15;         v2 := 0; h2 := 0;         end;      itemType := buttonItem;      itemDescr := @'OK';      itemValue := 0;      itemFlag := 0;      itemColor := nil;      end;   with message do begin                {initialize message item}      itemID := 100;      with itemRect do begin         v1 := 5; h1 := 100;         v2 := 90; h2 := 280;         end;      itemType := itemDisable+statText;      itemDescr := @msg;      itemValue := 0;      itemFlag := 0;      itemColor := nil;      end;   case kind of                         {handle the alert}      norml:      junk := Alert(alertRec,nil);      stop:       junk := StopAlert(alertRec,nil);      note:       junk := NoteAlert(alertRec,nil);      caution:    junk := CautionAlert(alertRec,nil);      end; {case}   end; {DoAlert}    procedure InitMenus;   { Initialize the menu bar. }    var      height: integer;                  {height of the largest menu}      menuHand: menuHandle;             {for 'handling' windows}      s: textPtr;                       {for builing menus}    begin {InitMenus}   new(s);                              {create the edit menu}   s^ := concat('>> Edit \N3',chr(return));   s^ := concat(s^,'--Undo\N250V*Zz',chr(return));   s^ := concat(s^,'--Cut\N251*Xx',chr(return));   s^ := concat(s^,'--Copy\N252*Cc',chr(return));   s^ := concat(s^,'--Paste\N253*Vv',chr(return));   s^ := concat(s^,'--Clear\N254',chr(return));   s^ := concat(s^,'.',chr(return));   menuHand := NewMenu(s);   InsertMenu(menuHand,0);   new(s);                              {create the file menu}   s^ := concat('>> File \N2',chr(return));   s^ := concat(s^,'--New\N258*Nn',chr(return));   s^ := concat(s^,'--Close\N255V',chr(return));   s^ := concat(s^,'--Quit\N256*Qq',chr(return));   s^ := concat(s^,'.',chr(return));   menuHand := NewMenu(s);   InsertMenu(menuHand,0);   new(s);                              {create the apple menu}   s^ := concat('>>@\XN1',chr(return));   s^ := concat(s^,'--About...\N257V',chr(return));   s^ := concat(s^,'.',chr(return));   menuHand := NewMenu(s);   InsertMenu(menuHand,0);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   procedure InitWindows;   { Initialize the window records. }   var      i: integer;                       {loop variable}   begin {InitWindows}   for i := 1 to maxWindows do          {initialize the window pointers}      windows[i].wPtr := nil;   windows[1].name := 'Paint 1';        {initialize the window names}   windows[2].name := 'Paint 2';   windows[3].name := 'Paint 3';   windows[4].name := 'Paint 4';   end; {InitWindows}   {$DataBank+}   procedure DrawWindow;   { Draw the contents of the current window. }   var      i: 1..maxWindows;                 {window's index}      j: 1..maxLines;                   {loop variable}   begin {DrawWindow}   i := ord(GetWRefCon(GetPort));   with windows[i] do begin      if numLines <> 0 then begin       {skip the work if there aren't any lines}         SetPenMode(modeCopy);          {set up to draw}         SetSolidPenPat(0);         SetPenSize(2, 1);         for j := 1 to numLines do      {draw each of the lines}            with lines[j] do begin               MoveTo(p1.h, p1.v);               LineTo(p2.h, p2.v);               end; {with}         end; {if}      end; {with}   end; {DrawWindow}   {$DataBank-}   procedure DoClose;   { Close the front drawing window (if there is one). }   var      i: integer;                       {index variable}   begin {DoClose}   if FrontWindow <> nil then begin      i := ord(GetWRefCon(FrontWindow)); {find out which window to close}      CloseWindow(windows[i].wPtr);     {close it}      windows[i].wPtr := nil;      EnableMItem(file_New);            {we have room for new windows, now}      end; {if}   end; {DoClose}    procedure HandleMenu(menuNum: integer);   { Handle a menu selection. }       procedure MenuAbout;      { Show About alert box. }        var         msg: pString;                  {alert message}        begin {MenuAbout}      msg := concat('Mini-Draw 1.0',chr(return),              'Copyright 1988-1990',chr(return),              'Byte Works, Inc.', chr(return),              chr(return),              'By Mike Westerfield');      DoAlert(note,msg);      end; {MenuAbout}      procedure DoNew;      { Open a new drawing window. }      var         i: integer;                    {index variable}         wParms: paramList;             {parameters for NewWindow}         msg: pString;                  {alert message}      begin {DoNew}      i := 1;                           {find an empty record}      while windows[i].wPtr <> nil do         i := i+1;      windows[i].numLines := 0;         {no lines drawn, yet}      with wParms do begin              {initialize the window record}         paramLength := 78;         wFrameBits := $DDA7;         wTitle := @windows[i].name;         wRefCon := i;         wZoom.h1 := 0; wZoom.h2 := 615;         wZoom.v1 := 25; wZoom.v2 := 188;         wColor := nil;         wYOrigin := 0; wXOrigin := 0;         wDataH := 0;         wDataW := 0;         wMaxH := 0;         wMaxW := 0;         wScrollVer := 10; wScrollHor := 10;         wPageVer := 0; wPageHor := 0;         wInfoRefCon := 0; wInfoHeight := 0;         wFrameDefProc := nil;         wInfoDefProc := nil;         wContDefProc := @DrawWindow;         wPosition.v1 := 25;         wPosition.h1 := 0;         wPosition.v2 := 188;         wPosition.h2 := 615;         wPlane := pointer(topMost);         wStorage := nil;         end; {with}      windows[i].wPtr := NewWindow(wParms); {open the window}      if ToolError <> 0 then begin         msg := 'Error opening the window.';         DoAlert(stop,msg);         windows[i].wPtr := nil;         end      else if i = 4 then                {don't allow more than 4 open windows}         DisableMItem(file_New);      end; {DoNew}   begin {HandleMenu}   case menuNum of                      {go handle the menu}      apple_About: MenuAbout;      file_Quit:   done := true;      file_New:    DoNew;      file_Close:  DoClose;      otherwise:   ;      end; {case}   HiliteMenu(false,convert(lastEvent.taskData).msw);   end; {HandleMenu}   procedure Sketch;   { Track the mouse, drawing lines to connect the points. }   var      endPoint: point;                  {the end point of the line}      firstPoint: point;                {the initial point}      i: 1..maxWindows;                 {window index}      sEvent: eventRecord;              {last event returned in event loop}      msg: pString;                     {for error messages}   begin {Sketch}   {get the window's index}   i := ord(GetWRefCon(FrontWindow));   {check for too many lines}   if windows[i].numLines = maxLines then begin      msg := concat('The window is full - ', chr(return),                    'more lines cannot be ', chr(return),                    'added.');      DoAlert(stop, msg);      end {if}   else begin      {initialize the pen}      StartDrawing(FrontWindow);      SetSolidPenPat(15);      SetPenSize(2, 1);      SetPenMode(modeXOR);      {record the initial pen location}      firstPoint := lastEvent.eventWhere;      GlobalToLocal(firstPoint);      with firstPoint do begin         MoveTo(h, v);         LineTo(h, v);         end; {with}      endPoint := firstPoint;      {follow the pen, rubber-banding the line}      while not GetNextEvent(mUpMask, sEvent) do begin         GlobalToLocal(sEvent.eventWhere);         with sEvent.eventWhere do            if (endPoint.h <> h) or (endPoint.v <> v) then begin               MoveTo(firstPoint.h, firstPoint.v);               LineTo(endPoint.h, endPoint.v);               MoveTo(firstPoint.h, firstPoint.v);               LineTo(h, v);               endPoint.h := h;               endPoint.v := v;               end; {if}         end; {while}      {erase the last XORed line}      MoveTo(firstPoint.h, firstPoint.v);      LineTo(endPoint.h, endPoint.v);      {if we have a line (not a point), record it in the window's line list}      if (firstPoint.h <> endPoint.h) or (firstPoint.v <> endPoint.v) then         begin         with windows[i] do begin            numLines := numLines+1;            lines[numLines].p1 := firstPoint;            lines[numLines].p2 := endPoint;            end; {with}         SetPenMode(modeCopy);         SetSolidPenPat(0);         MoveTo(firstPoint.h, firstPoint.v);         LineTo(endPoint.h, endPoint.v);         end; {if}      end; {else}   end; {Sketch}begin {Draw}StartDesk(640);InitMenus;                              {set up the menu bar}InitWindows;                            {initialize the window records}lastEvent.taskMask := $1FFF;            {let task master do most stuff}ShowCursor;                             {show the cursor}done := false;                          {main event loop}repeat   event := TaskMaster($076E, lastEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu(convert(lastEvent.taskData).lsw);      wInGoAway:  DoClose;      wInContent: Sketch;      otherwise: ;      end; {case}until done;EndDesk;end. {Draw}