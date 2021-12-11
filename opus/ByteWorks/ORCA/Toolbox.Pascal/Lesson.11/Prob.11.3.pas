{---------------------------------------------------------------}{                                                               }{  Text Editor                                                  }{                                                               }{  This is a simple, TextEdit based text editor.                }{                                                               }{---------------------------------------------------------------}program TextEditor;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr, SFToolSet, ToolLocator,     MscToolSet, PrintMgr, FontMgr, TextEdit;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   fontMenu      = 4;   styleMenu     = 5;   sizeMenu      = 6;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileNew       = 260;   fileClose     = 255;   filePageSetup = 264;   filePrint     = 265;   fileQuit      = 256;   appleAbout    = 257;   fontFirst      = 1000;   stylePlain     = 280;   styleBold      = 281;   styleItalic    = 282;   styleUnderline = 283;   styleOutline   = 284;   styleShadow    = 285;   styleLeft      = 300;   styleRight     = 301;   styleFill      = 302;   styleCenter    = 303;   size9          = 290;   size10         = 291;   size12         = 292;   size14         = 293;   size18         = 294;   size24         = 295;type     long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   documentPtr = ^documentRecord;       {document pointer}   documentRecord = record              {information about our document}      next: documentPtr;                {next document}      wPtr: grafPortPtr;                {window pointer}      wName: pString;                   {window name}      prHandle: handle;                 {print record}      end;var   documents: documentPtr;              {our documents}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   lastFont: integer;                   {menu ID for checked font family}   myEvent: eventRecord;                {last event returned in event loop}   startStopParm: longint;              {tool start/shutdown parameter}   untitledNum: integer;                {number for the next untitled window}   procedure InitGlobals;   { Initialize the global variables                            }   begin {InitGlobals}   documents := nil;                    {no documents}   lastFont := 0;                       {menu ID for checked font family}   end; {InitGlobals}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(appleMenu);             {add desk accessories}   FixFontMenu(fontMenu, fontFirst, 0); {add fonts}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   function GetPString (resourceID: integer): pStringPtr;   { Get a string from the resource fork                        }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString resource       }   {                                                            }   { Returns: pointer to the string; nil for an error           }   {                                                            }   { Notes: The string is in a locked resource handle.  The     }   {    caller should call FreePString when the string is no    }   {    longer needed.  Failure to do so is not catastrophic;   }   {    the memory will be deallocated when the program is shut }   {    down.                                                   }   const      rPString = $8006;                 {resource type for p-strings}   var      hndl: handle;                     {resource handle}   begin {GetPString}   hndl := LoadResource(rPString, resourceID);   if ToolError <> 0 then      GetPString := nil   else begin      HLock(hndl);      GetPString := pStringPtr(hndl^);      end; {else}   end; {GetPString}   procedure FreePString (resourceID: integer);   { Free a resource string                                     }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString to free        }   const      rPString = $8006;                 {resource type for p-strings}   begin {FreePString}                  ReleaseResource(-3, rPString, resourceID);   end; {FreePString}   procedure FlagError (error, tError: integer);   { Flag an error                                              }   {                                                            }   { Parameters:                                                }   {    error - error message number                            }   {    tError - toolbox error code; 0 if none                  }   const      errorAlert = 2000;                {alert resource ID}      errorBase = 2000;                 {base resource ID for error messages}   var      str: pString;                     {wprk string}      substArray: pStringPtr;           {substitution "array"}      button: integer;                  {button pushed}      function HexDigit (value: integer): char;      { Returns a hexadecimal digit for the value               }      {                                                         }      { Parameters:                                             }      {    value - value to form a digit from; only the least   }      {       significant 4 bits are used                       }      {                                                         }      { Returns: Hexadecimal character                          }      begin {HexDigit}      value := value & $000F;      if value > 9 then         HexDigit := chr(value-10 + ord('A'))      else         HexDigit := chr(value + ord('0'));      end; {HexDigit}   begin {FlagError}                                        {form the error string}   substArray := GetPString(errorBase + error);   str := substArray^;   FreePString(errorBase + error);   substArray := @str;   if tError <> 0 then begin            {add the tool error number}      str := concat(         str,         ' ($',         HexDigit(tError >> 12),         HexDigit(tError >> 8),         HexDigit(tError >> 4),         HexDigit(tError),         ')'         );      end; {if}                                        {show the alert}   button := AlertWindow($0005, @substArray, ord4(errorAlert));   end; {FlagError}   procedure CloseDocument (dPtr: documentPtr);   { Close a document and its associated window                    }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to close; may be nil        }   var      lPtr: documentPtr;                {pointer to the previous document}   begin {CloseDocument}   if dPtr <> nil then begin      CloseWindow(dPtr^.wPtr);          {close the window}      if documents = dPtr then          {remove dPtr from the list when...}         documents := dPtr^.next        {...dPtr is the first document}      else begin                        {...dPtr is not the first document}         lPtr := documents;         while lPtr^.next <> dPtr do            lPtr := lPtr^.next;         lPtr^.next := dPtr^.next;         end; {else}      if dPtr^.prHandle <> nil then     {dispose of the print record}         DisposeHandle(dPtr^.prHandle);      dispose(dPtr);                    {dispose of the document record}      end; {if}   end; {CloseDocument}   function FindDocument (wPtr: grafPortPtr): documentPtr;   { Find the document for wPtr                                    }   {                                                               }   { Parameters:                                                   }   {    wPtr - pointer to the window for which to find a document  }   {                                                               }   { Returns: Document pointer; nil if there isn't one             }   var      done: boolean;                    {used to test for loop termination}      dPtr: documentPtr;                {used to trace the document list}   begin {FindDocument}   dPtr := documents;   done := dPtr = nil;   while not done do      if dPtr^.wPtr = wPtr then         done := true      else begin         dPtr := dPtr^.next;         done := dPtr = nil;         end; {else}   FindDocument := dPtr;   end; {FindDocument}   {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   begin {DrawContents}   DrawControls(GetPort);   end; {DrawContents}   {$databank+}   procedure GetUntitledName (var name: pString);   { Create a name for an untitled window                          }   {                                                               }   { Parameters:                                                   }   {    name - (returned) name for the window                      }   const      untitled = 101;                   {Resource number for "Untitled "}   var      dPtr: documentPtr;                {used to trace the document list}      sPtr: pStringPtr;                 {pointer to the resource string}   begin {GetUntitledName}   if documents = nil then              {if there are no untitled         }      untitledNum := 1;                 { documents then reset untitledNum}   sPtr := GetPString(untitled);        {set the base name}   if sPtr = nil then      name := 'Untitled '   else begin      name := sPtr^;      FreePString(untitled);      end; {else}   name := concat(name, cnvis(untitledNum)); {add the untitled number}   name := concat('  ', name, '  ');    {pad with spaces}   untitledNum := untitledNum+1;        {update untitledNum}   end; {GetUntitledName}   function NewDocument (wName: pString): documentPtr;   { Open a new document                                           }   {                                                               }   { Parameters:                                                   }   {    wName - name for the new window                            }   {                                                               }   { Returns: Document pointer; nil for an error                   }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   var      dPtr: documentPtr;                {new document pointer}   begin {NewDocument}   new(dPtr);                           {allocate the record}   if dPtr <> nil then begin      dPtr^.wName := wName;             {set up the name}      dPtr^.wPtr :=                     {open the window}         NewWindow2(@dPtr^.wName, 0, @DrawContents, nil, $02, wrNum,            rWindParam1);      if dPtr^.wPtr = nil then begin         FlagError(1, ToolError);       {handle a window error}         dispose(dPtr);         dPtr := nil;         end {if}      else begin         dPtr^.next := documents;       {put the document in the list}         documents := dPtr;                                        {allocate a print record}         dPtr^.prHandle := NewHandle(140, userID, 0, nil);         if dPtr^.prHandle <> nil then begin            PrDefault(dPtr^.prHandle);            if ToolError <> 0 then begin               DisposeHandle(dPtr^.prHandle);               dPtr^.prHandle := nil;               end; {if}            end; {if}         end; {else}      end {if}   else      FlagError(2, 0);                  {handle an out of memory error}   NewDocument := dPtr;   end; {NewDocument}   procedure GetCurrentID (var fID: fontID);   { Get the current font ID                                    }   {                                                            }   { Parameters:                                                }   {    fID - (returned) current font ID                        }   var      dPtr: documentPtr;                {front document}      flags: integer;                   {style flags}      port: grafPortPtr;                {caller's grafPort}      sHandle: handle;                  {style handle}      style: teStyle;                   {style record}   begin {GetCurrentID}   fID.famNum := 0;                     {set up a default in case of error}   fID.fontStyle := 0;   fID.fontSize := 0;   dPtr := FindDocument(FrontWindow);   {get the font in use}   if dPtr <> nil then begin      port := GetPort;      SetPort(dPtr^.wPtr);      sHandle := NewHandle(1, UserID, 0, nil);      if ToolError = 0 then begin         flags := TEGetSelectionStyle(style, sHandle, nil);         if ToolError = 0 then begin            if (flags & $0020) <> 0 then               fID.famNum := style.teFont.famNum;            if (flags & $0010) <> 0 then               fID.fontSize := style.teFont.fontSize;            if (flags & $0001) <> 0 then               fID.fontStyle := style.teFont.fontStyle;            end; {if}         DisposeHandle(sHandle);         end; {if}      SetPort(port);      end; {if}   end; {GetCurrentID}   procedure SetCurrentID (fID: fontID; flags: integer);   { Set the appropriate font ID to fID                         }   {                                                            }   { Parameters:                                                }   {    fID - new font ID                                       }   {    flags - flags telling which bits are valid              }   var      dPtr: documentPtr;                {front document}      port: grafPortPtr;                {caller's grafPort}      style: teStyle;                   {style record}   begin {SetCurrentID}   dPtr := FindDocument(FrontWindow);   if dPtr <> nil then begin      port := GetPort;      SetPort(dPtr^.wPtr);      style.teFont := fID;      TEStyleChange(flags, style, nil);      SetPort(port);      end; {if}   end; {SetCurrentID}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}      procedure DoNew;      { Open a new document window                              }      var         dPtr: documentPtr;             {pointer to the new document}         name: pString;                 {new document name}      begin {DoNew}      GetUntitledName(name);      dPtr := NewDocument(name);      end; {DoNew}      procedure DoPageSetup;      { Set up the printer options                              }      var         changed: boolean;              {did the print record change?}         dPtr: documentPtr;             {document to save}      begin {DoPageSetup}      dPtr := FindDocument(FrontWindow); {get the document}      if dPtr <> nil then begin                                        {make sure there is a print record}         if dPtr^.prHandle = nil then begin            dPtr^.prHandle := NewHandle(140, userID, 0, nil);            if dPtr^.prHandle <> nil then begin               PrDefault(dPtr^.prHandle);               if ToolError <> 0 then begin                  FlagError(6, ToolError);                  DisposeHandle(dPtr^.prHandle);                  dPtr^.prHandle := nil;                  end; {if}               end {if}            else               FlagError(6, ToolError);            end; {if}         if dPtr^.prHandle <> nil then  {update the print record}            changed := PrStlDialog(dPtr^.prHandle);         end; {if}      end; {DoPageSetup}      procedure DoPrint;      { Print the document                                      }      var         dPtr: documentPtr;             {document to save}         procedure PrintDocument;         { Do the actual printing of the document               }         var            h, v: integer;              {size of document in pages}            x, y: integer;              {page loop counters}            status: prStatusRec;        {printer status}            prPort: grafPortPtr;        {printer's grafPort}            procedure GetPageCount (dPtr: documentPtr; var h, v: integer);            { Get the size of the document in pages             }            {                                                   }            { Parameters:                                       }            {    dPtr - document to get the size of             }            {    h, v - (returned) size in pages                }            begin {GetPageCount}            h := 1;            v := 1;            end; {GetPageCount}         begin {PrintDocument}         {main print loop}         prPort := PrOpenDoc(dPtr^.prHandle, nil);         if ToolError <> 0 then            FlagError(6, ToolError)         else begin            GetPageCount(dPtr, h, v);            for x := 1 to h do               for y := 1 to v do begin                  PrOpenPage(prPort, nil);                  if ToolError <> 0 then                     FlagError(6, ToolError)                  else begin                     {print here}                     {done printing}                     PrClosePage(prPort);                     end; {else}                  end; {for}            PrCloseDoc(prPort);            end; {else}         {spooling loop}         if PrError = 0 then            PrPicFile(dPtr^.prHandle, nil, @status);         end; {PrintDocument}      begin {DoPrint}      dPtr := FindDocument(FrontWindow); {get the document}      if dPtr <> nil then begin                                        {make sure there is a print record}         if dPtr^.prHandle = nil then begin            dPtr^.prHandle := NewHandle(140, userID, 0, nil);            if dPtr^.prHandle <> nil then begin               PrDefault(dPtr^.prHandle);               if ToolError <> 0 then begin                  FlagError(6, ToolError);                  DisposeHandle(dPtr^.prHandle);                  dPtr^.prHandle := nil;                  end; {if}               end {if}            else               FlagError(6, ToolError);            end; {if}         if dPtr^.prHandle <> nil then  {print the document}            if PrJobDialog(dPtr^.prHandle) then               PrintDocument;         end; {if}      end; {DoPrint}      procedure DoFontFamily (id: integer);      { Pick a new font family                                  }      {                                                         }      { Parameters:                                             }      {    id - font family menu item ID                        }      var         fID: fontID;                   {current/new font ID}      begin {DoFontFamily}      fID.famNum := ItemID2FamNum(id);      if ToolError = 0 then         SetCurrentID(fID, $0040);      end; {DoFontFamily}      procedure DoFontSize (size: integer);      { Pick a new font size                                    }      {                                                         }      { Parameters:                                             }      {    size - new font size                                 }      var         fID: fontID;                   {current/new font ID}      begin {DoFontSize}      fID.fontSize := size;      SetCurrentID(fID, $0020);      end; {DoFontSize}      procedure DoPlainText;      { Change the style to plain text                          }      var         fID: fontID;                   {current/new font ID}      begin {DoPlainText}      fID.fontStyle := 0;      SetCurrentID(fID, $0002);      end; {DoPlainText}      procedure DoFontStyle (style: integer);      { Flip a style bit                                        }      {                                                         }      { Parameters:                                             }      {    style - style bit to flip                            }      var         fID: fontID;                   {current/new font ID}      begin {DoFontStyle}      GetCurrentID(fID);      fID.fontStyle := fID.fontStyle ! style;      SetCurrentID(fID, $0001);      end; {DoFontStyle}      procedure DoStyle (style: integer);      { Set the text style                                      }      {                                                         }      { Parameters:                                             }      {    style - new text style                               }      var         dPtr: documentPtr;             {active document}         port: grafPortPtr;             {caller's grafPort}         rulerHandle: handle;           {ruler handle}         rulerPtr: ^teRuler;            {pointer to the ruler record}      begin {DoStyle}      dPtr := FindDocument(FrontWindow);      if dPtr <> nil then begin         port := GetPort;         SetPort(dPtr^.wPtr);         TEGetRuler(3, @rulerHandle, nil);         if ToolError = 0 then begin            HLock(rulerHandle);            rulerPtr := pointer(rulerHandle^);            rulerPtr^.just := style;            TESetRuler(1, rulerHandle, nil);            DisposeHandle(rulerHandle);            end; {if}         SetPort(port);         end; {if}      end; {DoStyle}begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   if menuItemNum >= fontFirst then     {go handle the menu}      DoFontFamily(menuItemNum)   else      case menuItemNum of         appleAbout:  DoAbout;         fileNew:     DoNew;         fileClose:   CloseDocument(FindDocument(FrontWindow));         filePageSetup: DoPageSetup;         filePrint:   DoPrint;         fileQuit:    done := true;         editUndo:    ;         editCut:     ;         editCopy:    ;         editPaste:   ;         editClear:   ;         stylePlain:  DoPlainText;         styleBold:   DoFontStyle(1);         styleItalic: DoFontStyle(2);         styleUnderline: DoFontStyle(4);         styleOutline: DoFontStyle(8);         styleShadow: DoFontStyle(16);         styleLeft:   DoStyle(0);         styleRight:  DoStyle(-1);         styleFill:   DoStyle(2);         styleCenter: DoStyle(1);         size9:       DoFontSize(9);         size10:      DoFontSize(10);         size12:      DoFontSize(12);         size14:      DoFontSize(14);         size18:      DoFontSize(18);         size24:      DoFontSize(24);         otherwise:   ;         end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}   procedure CheckMenus;   { Check the menus to see if they should be dimmed            }   var      dPtr: documentPtr;                {active document}      fID: fontID;                      {active font ID}      newFont: integer;                 {new menu item ID for font family menu}      port: grafPortPtr;                {caller's grafPort}      rulerHandle: handle;              {ruler handle}      rulerPtr: ^teRuler;               {pointer to the ruler record}      style: integer;                   {text justification style}      procedure Outline (id: fontID; size, menuID: integer);      { Outline or un-outline a size menu item                  }      {                                                         }      { Parameters:                                             }      {    id - menu ID (style set to $FF, family correct)      }      {    size - size to check                                 }      {    menuID - menu ID to outline                          }      begin {Outline}      id.fontSize := size;      if CountFonts(id, $0A) = 0 then         SetMItemStyle(0, menuID)      else         SetMItemStyle(8, menuID);      end; {Outline}   begin {CheckMenus}   if documents = nil then begin        {print menus}      DisableMItem(filePageSetup);      DisableMItem(filePrint);      end {if}   else begin      EnableMItem(filePageSetup);      EnableMItem(filePrint);      GetCurrentID(fID);                {get the "active" font ID}      if lastFont <> 0 then             {check the current font family}         CheckMItem(false, lastFont);      newFont := FamNum2ItemID(fID.famNum);      if ToolError = 0 then begin         lastFont := newFont;         CheckMItem(true, lastFont);         end {if}      else         lastFont := 0;                                           {check the proper style items}      CheckMItem(fID.fontStyle = 0, stylePlain);      CheckMItem((fID.fontStyle & 1) <> 0, styleBold);      CheckMItem((fID.fontStyle & 2) <> 0, styleItalic);      CheckMItem((fID.fontStyle & 4) <> 0, styleUnderline);      CheckMItem((fID.fontStyle & 8) <> 0, styleOutline);      CheckMItem((fID.fontStyle & 16) <> 0, styleShadow);      CheckMItem(fID.fontSize = 9, size9); {check the poper size items}      CheckMItem(fID.fontSize = 10, size10);      CheckMItem(fID.fontSize = 12, size12);      CheckMItem(fID.fontSize = 14, size14);      CheckMItem(fID.fontSize = 18, size18);      CheckMItem(fID.fontSize = 24, size24);      fID.fontStyle := $FF;                {outline the appropriate sizes}      Outline(fID, 9, size9);      Outline(fID, 10, size10);      Outline(fID, 12, size12);      Outline(fID, 14, size14);      Outline(fID, 18, size18);      Outline(fID, 24, size24);      dPtr := FindDocument(FrontWindow);   {check the proper justification style}      if dPtr <> nil then begin         port := GetPort;         SetPort(dPtr^.wPtr);         TEGetRuler(3, @rulerHandle, nil);         if ToolError = 0 then begin            HLock(rulerHandle);            rulerPtr := pointer(rulerHandle^);            style := rulerPtr^.just;            TESetRuler(1, rulerHandle, nil);            DisposeHandle(rulerHandle);            CheckMItem(style = 0, styleLeft);            CheckMItem(style = -1, styleRight);            CheckMItem(style = 1, styleCenter);            CheckMItem(style = 2, styleFill);            end; {if}         SetPort(port);         end; {if}      end; {else}   end; {CheckMenus}begin {TextEditor}startStopParm :=                        {start up the tools}   StartUpTools(userID, 2, 1);if ToolError <> 0 then   SysFailMgr(ToolError, @'Could not start tools: ');InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}InitGlobals;                            {initialize our global variables}done := false;                          {main event loop}CheckMenus;                             {set up the initial menus}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInGoAway:  CloseDocument(FindDocument(grafPortPtr(myEvent.taskData)));      otherwise: ;      end; {case}   if event <> nullEvt then      CheckMenus;until done;ShutDownTools(1, startStopParm);        {shut down the tools}end. {TextEditor}