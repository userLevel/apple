{---------------------------------------------------------------}{                                                               }{  Frame                                                        }{                                                               }{  This is a frame for other programs.  It contains a basic     }{  event loop, a menu bar, an about box, and supports NDAs.     }{  It also supports multiple windows via a document record.     }{                                                               }{---------------------------------------------------------------}program Frame;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileNew       = 260;   fileOpen      = 261;   fileClose     = 255;   fileQuit      = 256;   appleAbout    = 257;type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   documentPtr = ^documentRecord;       {document pointer}   documentRecord = record              {information about our document}      next: documentPtr;                {next document}      wPtr: grafPortPtr;                {window pointer}      wName: pString;                   {window name}      onDisk: boolean;                  {does the file exist on disk?}      end;var   documents: documentPtr;              {our documents}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   untitledNum: integer;                {number for the next untitled window}   procedure InitGlobals;   { Initialize the global variables                            }   begin {InitGlobals}   documents := nil;   end; {InitGlobals}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   function GetPString (resourceID: integer): pStringPtr;   { Get a string from the resource fork                        }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString resource       }   {                                                            }   { Returns: pointer to the string; nil for an error           }   {                                                            }   { Notes: The string is in a locked resource handle.  The     }   {    caller should call FreePString when the string is no    }   {    longer needed.  Failure to do so is not catastrophic;   }   {    the memory will be deallocated when the program is shut }   {    down.                                                   }   const      rPString = $8006;                 {resource type for p-strings}   var      hndl: handle;                     {resource handle}   begin {GetPString}   hndl := LoadResource(rPString, resourceID);   if ToolError <> 0 then      GetPString := nil   else begin      HLock(hndl);      GetPString := pStringPtr(hndl^);      end; {else}   end; {GetPString}   procedure FreePString (resourceID: integer);   { Free a resource string                                     }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString to free        }   const      rPString = $8006;                 {resource type for p-strings}   begin {FreePString}                  ReleaseResource(-3, rPString, resourceID);   end; {FreePString}   procedure FlagError (error, tError: integer);   { Flag an error                                              }   {                                                            }   { Parameters:                                                }   {    error - error message number                            }   {    tError - toolbox error code; 0 if none                  }   const      errorAlert = 2000;                {alert resource ID}      errorBase = 2000;                 {base resource ID for error messages}   var      str: pString;                     {wprk string}      substArray: pStringPtr;           {substitution "array"}      button: integer;                  {button pushed}      function HexDigit (value: integer): char;      { Returns a hexadecimal digit for the value               }      {                                                         }      { Parameters:                                             }      {    value - value to form a digit from; only the least   }      {       significant 4 bits are used                       }      {                                                         }      { Returns: Hexadecimal character                          }      begin {HexDigit}      value := value & $000F;      if value > 9 then         HexDigit := chr(value-10 + ord('A'))      else         HexDigit := chr(value + ord('0'));      end; {HexDigit}   begin {FlagError}                                        {form the error string}   substArray := GetPString(errorBase + error);   str := substArray^;   FreePString(errorBase + error);   substArray := @str;   if tError <> 0 then begin            {add the tool error number}      str := concat(         str,         ' ($',         HexDigit(tError >> 12),         HexDigit(tError >> 8),         HexDigit(tError >> 4),         HexDigit(tError),         ')'         );      end; {if}                                        {show the alert}   button := AlertWindow($0005, @substArray, ord4(errorAlert));   end; {FlagError}   {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   var      r: rect;                          {port rectangle}   begin {DrawContents}   PenNormal;                           {use a "normal" pen}   GetPortRect(r);                      {get the size of our window}   MoveTo(r.h1,r.v1);                   {draw the X}   LineTo(r.h2, r.v2);   MoveTo(r.h1, r.v2);   LineTo(r.h2, r.v1);   end; {DrawContents}   {$databank+}   procedure CloseDocument (dPtr: documentPtr);   { Close a document and its associated window                    }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to close; may be nil        }   var      lPtr: documentPtr;                {pointer to the previous document}   begin {CloseDocument}   if dPtr <> nil then begin      CloseWindow(dPtr^.wPtr);          {close the window}      if documents = dPtr then          {remove dPtr from the list when...}         documents := dPtr^.next        {...dPtr is the first document}      else begin                        {...dPtr is not the first document}         lPtr := documents;         while lPtr^.next <> dPtr do            lPtr := lPtr^.next;         lPtr^.next := dPtr^.next;         end; {else}      dispose(dPtr);                    {dispose of the document record}      end; {if}   end; {CloseDocument}   function FindDocument (wPtr: grafPortPtr): documentPtr;   { Find the document for wPtr                                    }   {                                                               }   { Parameters:                                                   }   {    wPtr - pointer to the window for which to find a document  }   {                                                               }   { Returns: Document pointer; nil if there isn't one             }   var      done: boolean;                    {used to test for loop termination}      dPtr: documentPtr;                {used to trace the document list}   begin {FindDocument}   dPtr := documents;   done := dPtr = nil;   while not done do      if dPtr^.wPtr = wPtr then         done := true      else begin         dPtr := dPtr^.next;         done := dPtr = nil;         end; {else}   FindDocument := dPtr;   end; {FindDocument}   procedure GetUntitledName (var name: pString);   { Create a name for an untitled window                          }   {                                                               }   { Parameters:                                                   }   {    name - (returned) name for the window                      }   const      untitled = 101;                   {Resource number for "Untitled "}   var      dPtr: documentPtr;                {used to trace the document list}      number: integer;                  {new value for untitledNum}      sPtr: pStringPtr;                 {pointer to the resource string}   begin {GetUntitledName}   dPtr := documents;                   {if there are no untitled         }   number := 1;                         { documents then reset untitledNum}   while dPtr <> nil do      if not dPtr^.onDisk then begin         number := untitledNum;         dPtr := nil;         end {if}      else         dPtr := dPtr^.next;   untitledNum := number;   sPtr := GetPString(untitled);        {set the base name}   if sPtr = nil then      name := 'Untitled '   else begin      name := sPtr^;      FreePString(untitled);      end; {else}   name := concat(name, cnvis(untitledNum)); {add the untitled number}   untitledNum := untitledNum+1;        {update untitledNum}   end; {GetUntitledName}   function NewDocument (wName: pString): documentPtr;   { Open a new document                                           }   {                                                               }   { Parameters:                                                   }   {    wName - name for the new window                            }   {                                                               }   { Returns: Document pointer; nil for an error                   }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   var      dPtr: documentPtr;                {new document pointer}   begin {NewDocument}   new(dPtr);                           {allocate the record}   if dPtr <> nil then begin      dPtr^.onDisk := false;            {not on disk}      dPtr^.wName := wName;             {set up the name}      dPtr^.wPtr :=                     {open the window}         NewWindow2(@dPtr^.wName, 0, @DrawContents, nil, $02, wrNum,            rWindParam1);      if dPtr^.wPtr = nil then begin         FlagError(1, ToolError);       {handle a window error}         dispose(dPtr);         dPtr := nil;         end {if}      else begin         dPtr^.next := documents;       {put the document in the list}         documents := dPtr;         end; {else}      end {if}   else      FlagError(2, 0);                  {handle an out of memory error}   NewDocument := dPtr;   end; {NewDocument}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}      procedure DoNew;      { Open a new document window                              }      var         dPtr: documentPtr;             {pointer to the new document}         name: pString;                 {new document name}      begin {DoNew}      GetUntitledName(name);      dPtr := NewDocument(name);      end; {DoNew}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileNew:     DoNew;      fileOpen:    DoNew;      fileClose:   CloseDocument(FindDocument(FrontWindow));      fileQuit:    done := true;      editUndo:    ;      editCut:     ;      editCopy:    ;      editPaste:   ;      editClear:   ;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}begin {Frame}StartDesk(640);InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}InitGlobals;                            {initialize our global variables}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInGoAway:  CloseDocument(FindDocument(grafPortPtr(myEvent.taskData)));      otherwise: ;      end; {case}until done;EndDesk;end. {Frame}