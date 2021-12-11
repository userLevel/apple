{---------------------------------------------------------------}{                                                               }{  Font Sampler                                                 }{                                                               }{  View and print an font.                                      }{                                                               }{---------------------------------------------------------------}program FontSampler;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr, SFToolSet, ToolLocator,     MscToolSet, PrintMgr, FontMgr;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   fontMenu      = 4;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileNew       = 260;   fileClose     = 255;   filePageSetup = 264;   filePrint     = 265;   fileQuit      = 256;   appleAbout    = 257;   fontChooseFont = 270;type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   documentPtr = ^documentRecord;       {document pointer}   documentRecord = record              {information about our document}      next: documentPtr;                {next document}      wPtr: grafPortPtr;                {window pointer}      wName: pString;                   {window name}      prHandle: handle;                 {print record}      fID: fontID;                      {window's font}      end;var   currentFont: fontID;                 {current font}   documents: documentPtr;              {our documents}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   startStopParm: longint;              {tool start/shutdown parameter}   untitledNum: integer;                {number for the next untitled window}   procedure InitGlobals;   { Initialize the global variables                            }   begin {InitGlobals}   documents := nil;                    {no documents}   currentFont.famNum := 0;             {default to the system font}   currentFont.fontStyle := 0;   currentFont.fontSize := 0;   end; {InitGlobals}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   function GetPString (resourceID: integer): pStringPtr;   { Get a string from the resource fork                        }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString resource       }   {                                                            }   { Returns: pointer to the string; nil for an error           }   {                                                            }   { Notes: The string is in a locked resource handle.  The     }   {    caller should call FreePString when the string is no    }   {    longer needed.  Failure to do so is not catastrophic;   }   {    the memory will be deallocated when the program is shut }   {    down.                                                   }   const      rPString = $8006;                 {resource type for p-strings}   var      hndl: handle;                     {resource handle}   begin {GetPString}   hndl := LoadResource(rPString, resourceID);   if ToolError <> 0 then      GetPString := nil   else begin      HLock(hndl);      GetPString := pStringPtr(hndl^);      end; {else}   end; {GetPString}   procedure FreePString (resourceID: integer);   { Free a resource string                                     }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString to free        }   const      rPString = $8006;                 {resource type for p-strings}   begin {FreePString}                  ReleaseResource(-3, rPString, resourceID);   end; {FreePString}   procedure FlagError (error, tError: integer);   { Flag an error                                              }   {                                                            }   { Parameters:                                                }   {    error - error message number                            }   {    tError - toolbox error code; 0 if none                  }   const      errorAlert = 2000;                {alert resource ID}      errorBase = 2000;                 {base resource ID for error messages}   var      str: pString;                     {wprk string}      substArray: pStringPtr;           {substitution "array"}      button: integer;                  {button pushed}      function HexDigit (value: integer): char;      { Returns a hexadecimal digit for the value               }      {                                                         }      { Parameters:                                             }      {    value - value to form a digit from; only the least   }      {       significant 4 bits are used                       }      {                                                         }      { Returns: Hexadecimal character                          }      begin {HexDigit}      value := value & $000F;      if value > 9 then         HexDigit := chr(value-10 + ord('A'))      else         HexDigit := chr(value + ord('0'));      end; {HexDigit}   begin {FlagError}                                        {form the error string}   substArray := GetPString(errorBase + error);   str := substArray^;   FreePString(errorBase + error);   substArray := @str;   if tError <> 0 then begin            {add the tool error number}      str := concat(         str,         ' ($',         HexDigit(tError >> 12),         HexDigit(tError >> 8),         HexDigit(tError >> 4),         HexDigit(tError),         ')'         );      end; {if}                                        {show the alert}   button := AlertWindow($0005, @substArray, ord4(errorAlert));   end; {FlagError}   procedure CloseDocument (dPtr: documentPtr);   { Close a document and its associated window                    }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to close; may be nil        }   var      lPtr: documentPtr;                {pointer to the previous document}   begin {CloseDocument}   if dPtr <> nil then begin      CloseWindow(dPtr^.wPtr);          {close the window}      if documents = dPtr then          {remove dPtr from the list when...}         documents := dPtr^.next        {...dPtr is the first document}      else begin                        {...dPtr is not the first document}         lPtr := documents;         while lPtr^.next <> dPtr do            lPtr := lPtr^.next;         lPtr^.next := dPtr^.next;         end; {else}      if dPtr^.prHandle <> nil then     {dispose of the print record}         DisposeHandle(dPtr^.prHandle);      dispose(dPtr);                    {dispose of the document record}      end; {if}   end; {CloseDocument}   function FindDocument (wPtr: grafPortPtr): documentPtr;   { Find the document for wPtr                                    }   {                                                               }   { Parameters:                                                   }   {    wPtr - pointer to the window for which to find a document  }   {                                                               }   { Returns: Document pointer; nil if there isn't one             }   var      done: boolean;                    {used to test for loop termination}      dPtr: documentPtr;                {used to trace the document list}   begin {FindDocument}   dPtr := documents;   done := dPtr = nil;   while not done do      if dPtr^.wPtr = wPtr then         done := true      else begin         dPtr := dPtr^.next;         done := dPtr = nil;         end; {else}   FindDocument := dPtr;   end; {FindDocument}   procedure DrawFonts (dPtr: documentPtr);   { Draw the font display for a document                       }   {                                                            }   { Parameters:                                                }   {    dPtr - document to draw                                 }   const      headerH = 10;                     {location of header string}      headerV = 15;      tableH  = 10;                     {location of table's topline}      tableV  = 20;   var      base: integer;                    {baseline for the top line of the table}      dv, dh: integer;                  {size of one character}      info: fontInfoRecord;             {info about the font}      row, col: integer;                {loop variables}      str: pString;                     {font header string}   begin {DrawFonts}   if dPtr <> nil then begin      SetForeColor(0);                  {print black text on a white background}      SetBackColor(3);      SetTextMode(modeCopy);      InstallFont(fontID(0), 0);        {write the header info}      str := concat('famNum = ', cnvis(dPtr^.fID.famNum),         '  fontSize = ', cnvis(dPtr^.fID.fontSize),         '  fontStyle =');      with dPtr^.fID do         if fontStyle = 0 then            str := concat(str, ' plain text')         else begin            if (fontStyle & 1) <> 0 then               str := concat(str, ' bold');            if (fontStyle & 2) <> 0 then               str := concat(str, ' italic');            if (fontStyle & 4) <> 0 then               str := concat(str, ' underline');            if (fontStyle & 8) <> 0 then               str := concat(str, ' outline');            if (fontStyle & 16) <> 0 then               str := concat(str, ' shadow');            end; {else}      MoveTo(headerH, headerV);      DrawString(str);      InstallFont(dPtr^.fID, 0);        {install the window's font}      GetFontInfo(info);                {get info needed to format the font table}      base := tableV + info.ascent;      dv := info.descent + info.ascent + info.leading;      dh := info.widMax*2;      for row := 0 to 15 do             {print the font table}         for col := 0 to 15 do begin            MoveTo(tableH + dh*col, base + dv*row);            DrawChar(chr(col*16 + row));            end; {for}      end; {if}   end; {DrawFonts}      {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   begin {DrawContents}   DrawFonts(FindDocument(GetPort));   end; {DrawContents}   {$databank+}   procedure GetUntitledName (var name: pString);   { Create a name for an untitled window                          }   {                                                               }   { Parameters:                                                   }   {    name - (returned) name for the window                      }   const      untitled = 101;                   {Resource number for "Untitled "}   var      dPtr: documentPtr;                {used to trace the document list}      sPtr: pStringPtr;                 {pointer to the resource string}   begin {GetUntitledName}   if documents = nil then              {if there are no untitled         }      untitledNum := 1;                 { documents then reset untitledNum}   sPtr := GetPString(untitled);        {set the base name}   if sPtr = nil then      name := 'Untitled '   else begin      name := sPtr^;      FreePString(untitled);      end; {else}   name := concat(name, cnvis(untitledNum)); {add the untitled number}   name := concat('  ', name, '  ');    {pad with spaces}   untitledNum := untitledNum+1;        {update untitledNum}   end; {GetUntitledName}   function NewDocument (wName: pString): documentPtr;   { Open a new document                                           }   {                                                               }   { Parameters:                                                   }   {    wName - name for the new window                            }   {                                                               }   { Returns: Document pointer; nil for an error                   }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   var      dPtr: documentPtr;                {new document pointer}   begin {NewDocument}   new(dPtr);                           {allocate the record}   if dPtr <> nil then begin      dPtr^.wName := wName;             {set up the name}      dPtr^.fID := currentFont;         {use the current default font}      dPtr^.wPtr :=                     {open the window}         NewWindow2(@dPtr^.wName, 0, @DrawContents, nil, $02, wrNum,            rWindParam1);      if dPtr^.wPtr = nil then begin         FlagError(1, ToolError);       {handle a window error}         dispose(dPtr);         dPtr := nil;         end {if}      else begin         dPtr^.next := documents;       {put the document in the list}         documents := dPtr;                                        {allocate a print record}         dPtr^.prHandle := NewHandle(140, userID, 0, nil);         if dPtr^.prHandle <> nil then begin            PrDefault(dPtr^.prHandle);            if ToolError <> 0 then begin               DisposeHandle(dPtr^.prHandle);               dPtr^.prHandle := nil;               end; {if}            end; {if}         end; {else}      end {if}   else      FlagError(2, 0);                  {handle an out of memory error}   NewDocument := dPtr;   end; {NewDocument}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}      procedure DoNew;      { Open a new document window                              }      var         dPtr: documentPtr;             {pointer to the new document}         name: pString;                 {new document name}      begin {DoNew}      GetUntitledName(name);      dPtr := NewDocument(name);      end; {DoNew}      procedure DoPageSetup;      { Set up the printer options                              }      var         changed: boolean;              {did the print record change?}         dPtr: documentPtr;             {document to save}      begin {DoPageSetup}      dPtr := FindDocument(FrontWindow); {get the document}      if dPtr <> nil then begin                                        {make sure there is a print record}         if dPtr^.prHandle = nil then begin            dPtr^.prHandle := NewHandle(140, userID, 0, nil);            if dPtr^.prHandle <> nil then begin               PrDefault(dPtr^.prHandle);               if ToolError <> 0 then begin                  FlagError(6, ToolError);                  DisposeHandle(dPtr^.prHandle);                  dPtr^.prHandle := nil;                  end; {if}               end {if}            else               FlagError(6, ToolError);            end; {if}         if dPtr^.prHandle <> nil then  {update the print record}            changed := PrStlDialog(dPtr^.prHandle);         end; {if}      end; {DoPageSetup}      procedure DoPrint;      { Print the document                                      }      var         dPtr: documentPtr;             {document to save}         procedure PrintDocument;         { Do the actual printing of the document               }         var            h, v: integer;              {size of document in pages}            x, y: integer;              {page loop counters}            status: prStatusRec;        {printer status}            prPort: grafPortPtr;        {printer's grafPort}            procedure GetPageCount (dPtr: documentPtr; var h, v: integer);            { Get the size of the document in pages             }            {                                                   }            { Parameters:                                       }            {    dPtr - document to get the size of             }            {    h, v - (returned) size in pages                }            begin {GetPageCount}            h := 1;            v := 1;            end; {GetPageCount}         begin {PrintDocument}         {main print loop}         prPort := PrOpenDoc(dPtr^.prHandle, nil);         if ToolError <> 0 then            FlagError(6, ToolError)         else begin            GetPageCount(dPtr, h, v);            for x := 1 to h do               for y := 1 to v do begin                  PrOpenPage(prPort, nil);                  if ToolError <> 0 then                     FlagError(6, ToolError)                  else begin                     {print here}                     DrawFonts(dPtr);                     {done printing}                     PrClosePage(prPort);                     end; {else}                  end; {for}            PrCloseDoc(prPort);            end; {else}         {spooling loop}         if PrError = 0 then            PrPicFile(dPtr^.prHandle, nil, @status);         end; {PrintDocument}      begin {DoPrint}      dPtr := FindDocument(FrontWindow); {get the document}      if dPtr <> nil then begin                                        {make sure there is a print record}         if dPtr^.prHandle = nil then begin            dPtr^.prHandle := NewHandle(140, userID, 0, nil);            if dPtr^.prHandle <> nil then begin               PrDefault(dPtr^.prHandle);               if ToolError <> 0 then begin                  FlagError(6, ToolError);                  DisposeHandle(dPtr^.prHandle);                  dPtr^.prHandle := nil;                  end; {if}               end {if}            else               FlagError(6, ToolError);            end; {if}         if dPtr^.prHandle <> nil then  {print the document}            if PrJobDialog(dPtr^.prHandle) then               PrintDocument;         end; {if}      end; {DoPrint}      procedure DoChooseFont;      { Pick a new font                                         }      var         dPtr: documentPtr;             {pointer to the front document}         longFont: longint;             {ChooseFont can't return a record...}         port: grafPortPtr;             {caller's grafPort}         r: rect;                       {window's grafPort rect}      begin {DoChooseFont}                                        {pick the new font}      longFont := ChooseFont(currentFont, 0);      currentFont := fontID(longFont);      dPtr := FindDocument(FrontWindow); {change the front window's font}      if dPtr <> nil then begin         dPtr^.fID := currentFont;         port := GetPort;         SetPort(dPtr^.wPtr);         GetPortRect(r);         EraseRect(r);         InvalRect(r);         SetPort(port);         end; {if}      end; {DoChooseFont}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileNew:     DoNew;      fileClose:   CloseDocument(FindDocument(FrontWindow));      filePageSetup: DoPageSetup;      filePrint:   DoPrint;      fileQuit:    done := true;      editUndo:    ;      editCut:     ;      editCopy:    ;      editPaste:   ;      editClear:   ;      fontChooseFont: DoChooseFont;            otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}   procedure CheckMenus;   { Check the menus to see if they should be dimmed            }   begin {CheckMenus}   if documents = nil then begin      DisableMItem(filePageSetup);      DisableMItem(filePrint);      end {if}   else begin      EnableMItem(filePageSetup);      EnableMItem(filePrint);      end; {else}   end; {CheckMenus}begin {FontSampler}startStopParm :=                        {start up the tools}   StartUpTools(userID, 2, 1);if ToolError <> 0 then   SysFailMgr(ToolError, @'Could not start tools: ');InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}InitGlobals;                            {initialize our global variables}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   CheckMenus;   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInGoAway:  CloseDocument(FindDocument(grafPortPtr(myEvent.taskData)));      otherwise: ;      end; {case}until done;ShutDownTools(1, startStopParm);        {shut down the tools}end. {FontSampler}