{---------------------------------------------------------------}{                                                               }{  Scrapbook                                                    }{                                                               }{  Implements a scrap book.                                     }{                                                               }{---------------------------------------------------------------}program ScrapBook;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr, SFToolSet, ToolLocator,     MscToolSet, ScrapMgr;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   moveMenu      = 4;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileClose     = 255;   fileQuit      = 256;   appleAbout    = 257;   moveLast      = 260;   moveNext      = 261;   type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   scrapItemPtr = ^scrapItemRecord;     {scrap item pointer}   scrapItemRecord = record             {scrap item record}      next: scrapItemPtr;               {next scrap type entry}      scrapType: integer;               {scrap type}      scrapLength: longint;             {scrap length}      scrap: handle;                    {scrap contents}      end;   scrapPtr = ^scrapRecord;             {scrap record pointer}   scrapRecord = record                 {scrap record}      next, last: scrapPtr;             {next, last scrap record}      scrap: scrapItemPtr;              {points to first scrap type entry}      end;var   wPtr: grafPortPtr;                   {our window}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   scraps: scrapPtr;                    {head of scrap list}   frontScrap: scrapPtr;                {scrap being displayed}   startStopParm: longint;              {tool start/shutdown parameter}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   function GetPString (resourceID: integer): pStringPtr;   { Get a string from the resource fork                        }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString resource       }   {                                                            }   { Returns: pointer to the string; nil for an error           }   {                                                            }   { Notes: The string is in a locked resource handle.  The     }   {    caller should call FreePString when the string is no    }   {    longer needed.  Failure to do so is not catastrophic;   }   {    the memory will be deallocated when the program is shut }   {    down.                                                   }   const      rPString = $8006;                 {resource type for p-strings}   var      hndl: handle;                     {resource handle}   begin {GetPString}   hndl := LoadResource(rPString, resourceID);   if ToolError <> 0 then      GetPString := nil   else begin      HLock(hndl);      GetPString := pStringPtr(hndl^);      end; {else}   end; {GetPString}   procedure FreePString (resourceID: integer);   { Free a resource string                                     }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString to free        }   const      rPString = $8006;                 {resource type for p-strings}   begin {FreePString}                  ReleaseResource(-3, rPString, resourceID);   end; {FreePString}   procedure FlagError (error, tError: integer);   { Flag an error                                              }   {                                                            }   { Parameters:                                                }   {    error - error message number                            }   {    tError - toolbox error code; 0 if none                  }   const      errorAlert = 2000;                {alert resource ID}      errorBase = 2000;                 {base resource ID for error messages}   var      str: pString;                     {wprk string}      substArray: pStringPtr;           {substitution "array"}      button: integer;                  {button pushed}      function HexDigit (value: integer): char;      { Returns a hexadecimal digit for the value               }      {                                                         }      { Parameters:                                             }      {    value - value to form a digit from; only the least   }      {       significant 4 bits are used                       }      {                                                         }      { Returns: Hexadecimal character                          }      begin {HexDigit}      value := value & $000F;      if value > 9 then         HexDigit := chr(value-10 + ord('A'))      else         HexDigit := chr(value + ord('0'));      end; {HexDigit}   begin {FlagError}                                        {form the error string}   substArray := GetPString(errorBase + error);   str := substArray^;   FreePString(errorBase + error);   substArray := @str;   if tError <> 0 then begin            {add the tool error number}      str := concat(         str,         ' ($',         HexDigit(tError >> 12),         HexDigit(tError >> 8),         HexDigit(tError >> 4),         HexDigit(tError),         ')'         );      end; {if}                                        {show the alert}   button := AlertWindow($0005, @substArray, ord4(errorAlert));   end; {FlagError}   {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   var      iPtr: scrapItemPtr;               {pointer to a scrap type entry}      procedure DrawNoScrap;      { Draw a message saying there are no scraps               }      begin {DrawNoScrap}      MoveTo(10, 50);      DrawString(@'The scrapbook is empty');      end; {DrawNoScrap}      procedure DrawNoScrapType;      { Draw a message saying there are no useable scrap types  }      begin {DrawNoScrapType}      MoveTo(10, 50);      DrawString(@'(No text or picture scrap)');      end; {DrawNoScrapType}      procedure DrawTextScrap (iPtr: scrapItemPtr);      { Draw a text scrap                                       }      {                                                         }      { Parameters:                                             }      {    iPtr - pointer to scrap to draw                      }      var         info: fontInfoRecord;          {info about the font}         left: longint;                 {# characters left to print}         r: rect;                       {window rectangle}         tPtr: ptr;                     {pointer to the next character}         v: integer;                    {base line position}         procedure PrintLine;         { Print one line                                       }         var            cPtr: ^byte;                {next character}            len, len2: integer;         {length of characters to print}         begin {PrintLine}         if left > 0 then begin            if tPtr^ = return then               tPtr := pointer(ord4(tPtr)+1)            else begin               len := 1;               cPtr := pointer(ord4(tPtr)+1);               while (TextWidth(tPtr, len) < (r.h2 - r.h1 - 20))                  and (len < left)                  and (cPtr^ <> return) do begin                  len := len+1;                  cPtr := pointer(ord4(cPtr)+1);                  end; {while}               if (cPtr^ <> return) and (len <> left) then begin                  len2 := len-1;                  cPtr := pointer(ord4(cPtr)-1);                  while (chr(cPtr^) <> ' ') and (len2 <> 0) do begin                     len2 := len2-1;                     cPtr := pointer(ord4(cPtr)-1);                     end; {while}                  if len2 <> 0 then                     len := len2;                  end; {if}               DrawText(tPtr, len);               left := left - len;               tPtr := pointer(ord4(tPtr)+len);               if tPtr^ = return then                  tPtr := pointer(ord4(tPtr)+1);               end; {else}            end; {if}         end; {PrintLine}      begin {DrawTextScrap}      GetFontInfo(info);      GetPortRect(r);      v := info.ascent + info.leading;      HLock(iPtr^.scrap);      tPtr := iPtr^.scrap^;      left := iPtr^.scrapLength;      while (v + info.descent) < (r.v2 - r.v1) do begin         MoveTo(10, v);         PrintLine;         v := v + info.ascent + info.leading + info.descent;         end; {while}      Hunlock(iPtr^.scrap);      end; {DrawTextScrap}      procedure DrawPictureScrap (iPtr: scrapItemPtr);      { Draw a picture scrap                                    }      {                                                         }      { Parameters:                                             }      {    iPtr - pointer to scrap to draw                      }      var         r: rect;                       {our port rectangle}      begin {DrawPictureScrap}      GetPortRect(r);      DrawPicture(iPtr^.scrap, r);      end; {DrawPictureScrap}      function FindScrap (iPtr: scrapItemPtr; scrapType: integer): scrapItemPtr;      { Find the scrap entry for a particular scrap type        }      {                                                         }      { Parameters:                                             }      {    iPtr - points to the first scrap to check            }      {    scrapType - scrap type to find                       }      {                                                         }      { Returns: pointer to scrap type, nil for none            }      var         done: boolean;                 {for loop termination test}      begin {FindScrap}      done := false;      repeat         if iPtr = nil then            done := true         else if iPtr^.scrapType = scrapType then            done := true         else            iPtr := iPtr^.next;      until done;      FindScrap := iPtr;      end; {FindScrap}   begin {DrawContents}   if frontScrap <> nil then begin      iPtr := FindScrap(frontScrap^.scrap, 1);      if iPtr <> nil then         DrawPictureScrap(iPtr)      else begin         iPtr := FindScrap(frontScrap^.scrap, 0);         if iPtr <> nil then            DrawTextScrap(iPtr)         else            DrawNoScrapType;         end; {else}      end {if}   else      DrawNoScrap;   end; {DrawContents}   {$databank+}   procedure InitWindow;   { Set up the program window                                  }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitWindow}   wPtr := NewWindow2(@'  ScrapBook 1.0  ', 0, @DrawContents, nil, $02, wrNum,      rWindParam1);   end; {InitWindow}   procedure LoadScrapFile;   { Load the scrapbook file                                    }   var      count: integer;                   {# scrap types in the scrap}      done: boolean;                    {loop termination test}      f: file of byte;                  {scrap file variable}      function ReadWord: integer;      { Read a word (integer) from the file                     }      {                                                         }      { Returns: integer read                                   }      var         i1, i2: integer;               {bytes read from the file}      begin {ReadWord}      read(f, i1, i2);      ReadWord := i1 | (i2 << 8);      end; {ReadWord}      function ReadLong: longint;      { Read a long (longint) from the file                     }      {                                                         }      { Returns: longint read                                   }      var         value: record            case boolean of               true:  (l: longint);               false: (b1, b2, b3, b4: byte);            end;      begin {ReadLong}      read(f, value.b1, value.b2, value.b3, value.b4);      ReadLong := value.l;      end; {ReadLong}      procedure ReadScrap (count: integer);      { Read a scrap from the file                              }      {                                                         }      { Parameters:                                             }      {    count - number of scrap types                        }      var         iPtr: scrapItemPtr;               {pointer to the scrap type being added}         length: longint;                  {length of the scrap}         p1: ptr;                          {used to copy a handle}         sPtr: scrapPtr;                   {pointer to the scrap being pasted}      begin {ReadScrap}      new(sPtr);                        {set up a scrap record}      if sPtr <> nil then begin         sPtr^.last := nil;         sPtr^.next := nil;         sPtr^.scrap := nil;         repeat                         {loop over all scrap types}            new(iPtr);                  {save a scrap type}            if iPtr <> nil then begin               iPtr^.scrapType := ReadWord;               length := ReadLong;               iPtr^.scrapLength := length;               iPtr^.scrap := NewHandle(length, UserID, $8000, nil);               if iPtr^.scrap = nil then begin                  FlagError(2, ToolError);                  done := true;                  dispose(iPtr);                  end {if}               else begin                  p1 := iPtr^.scrap^;                  while length <> 0 do begin                     read(f, p1^);                     p1 := pointer(ord4(p1)+1);                     length := length - 1;                     end; {while}                  HUnlock(iPtr^.scrap);                  iPtr^.next := sPtr^.scrap;                  sPtr^.scrap := iPtr;                  end; {else}               end {if}            else begin               FlagError(2, 0);               done := true;               end; {else}            count := count - 1;         until (count = 0) or done;         if sPtr^.scrap <> nil then begin            if frontScrap = nil then    {place the scrap in the buffer}               scraps := sPtr            else begin               sPtr^.last := frontScrap;               frontScrap^.next := sPtr;               end; {else}            frontScrap := sPtr;            end {if}         else            dispose(sPtr);         end {if}      else begin         FlagError(2, 0);         done := true;         end; {else}      end; {ReadScrap}   begin {LoadScrapFile}   scraps := nil;                       {nothing in the scrap list}   reset(f, 'ScrapBook');               {open the scrap file}   frontScrap := nil;                   {read the scraps}   done := false;   while not done do begin      count := ReadWord;      if count = 0 then         done := true      else         ReadScrap(count);      end; {while}   frontScrap := scraps;                {display the first scrap}   end; {LoadScrapFile}   procedure SaveScrapFile;   { Save the scrapbook file                                    }   var      f: file of byte;                  {scrap file variable}      iPtr: scrapItemPtr;               {pointer to the scrap type being saved}      sPtr: scrapPtr;                   {pointer to the scrap being saved}      function CountScraps (iPtr: scrapItemPtr): integer;      { Count the number of scrap types                         }      {                                                         }      { Parameters:                                             }      {    iPtr - scrap type list                               }      {                                                         }      { Returns: number of types in the scrap list              }            var         count: integer;                {number of scrap types}      begin {CountScraps}      count := 0;      while iPtr <> nil do begin         iPtr := iPtr^.next;         count := count + 1;         end; {while}      CountScraps := count;      end; {CountScraps}      procedure WriteLong (l: longint);      { Write a longint to the file                             }      {                                                         }      { Parameters:                                             }      {    l - longint to write                                 }      begin {WriteLong}      write(f, ord(l & $000000FF));      write(f, ord((l >> 8) & $000000FF));      write(f, ord((l >> 16) & $000000FF));      write(f, ord(l >> 24));      end; {WriteLong}      procedure WriteWord (w: integer);      { Write an integer (word) to the file                     }      {                                                         }      { Parameters:                                             }      {    l - integer to write                                 }      begin {WriteWord}      write(f, w & $00FF);      write(f, w >> 8);      end; {WriteWord}      procedure WriteScrap (iPtr: scrapItemPtr);      { Write a scrap item to the file                          }      {                                                         }      { Parameters:                                             }      {    iPtr - scrap to write                                }      var         length: longint;               {length of the scrap}         p: ptr;                        {next byte in the scrap}      begin {WriteScrap}      WriteWord(iPtr^.scrapType);      WriteLong(iPtr^.scrapLength);      HLock(iPtr^.scrap);      p := iPtr^.scrap^;      length := iPtr^.scrapLength;      while length <> 0 do begin         write(f, p^);         p := pointer(ord4(p)+1);         length := length-1;         end; {while}      Hunlock(iPtr^.scrap);      end; {WriteScrap}   begin {SaveScrapFile}   rewrite(f, 'ScrapBook');   sPtr := scraps;   while sPtr <> nil do begin      WriteWord(CountScraps(sPtr^.scrap));      iPtr := sPtr^.scrap;      while iPtr <> nil do begin         WriteScrap(iPtr);         iPtr := iPtr^.next;         end; {while}      sPtr := sPtr^.next;      end; {while}   WriteWord(0);   end; {SaveScrapFile}   procedure DoClear;   { Clear the current scrap from the scrapbook                 }   var      iPtr: scrapItemPtr;               {pointer to the scrap type being removed}      port: grafPortPtr;                {caller's grafPort}      r: rect;                          {our port rect}      sPtr: scrapPtr;                   {pointer to the scrap being removed}   begin {DoClear}   if frontScrap <> nil then begin      sPtr := frontScrap;               {remove the scrap from the list}      if sPtr^.last = nil then         scraps := sPtr^.next      else         sPtr^.last^.next := sPtr^.next;      if sPtr^.next <> nil then         sPtr^.next^.last := sPtr^.last;      if sPtr^.next <> nil then         {set up the new front scrap}         frontScrap := sPtr^.next      else         frontScrap := sPtr^.last;      port := GetPort;                  {force an update}      SetPort(wPtr);      GetPortRect(r);      EraseRect(r);      InvalRect(r);      SetPort(port);      while sPtr^.scrap <> nil do begin {dispose of the scrap items}         iPtr := sPtr^.scrap;         sPtr^.scrap := iPtr^.next;         DisposeHandle(iPtr^.scrap);         dispose(iPtr);         end; {while}      dispose(sPtr);                    {dispose of the scrap record}      end; {if}   end; {DoClear}                          procedure DoCopy;   { Copy the current scrap from the scrapbook                  }   var      iPtr: scrapItemPtr;               {pointer to the scrap type being copied}   begin {DoCopy}   if frontScrap <> nil then begin      ZeroScrap;                        {dump the current scrap}      iPtr := frontScrap^.scrap;        {spool through the scrap types}      while iPtr <> nil do begin         HLock(iPtr^.scrap);            {copy one scrap type}         with iPtr^ do            PutScrap(scrapLength, scrapType, scrap^);         HUnlock(iPtr^.scrap);         iPtr := iPtr^.next;         end; {while}      end; {if}   end; {DoCopy}   procedure DoCut;   { Cut the current scrap from the scrapbook                   }   begin {DoCut}   DoCopy;   DoClear;   end; {DoCut}   procedure DoLast;   { Move to the previous scrap                                 }   var      port: grafPortPtr;                {caller's grafPort}      r: rect;                          {our port rect}   begin {DoLast}   if frontScrap <> nil then      if frontScrap^.last <> nil then begin         frontScrap := frontScrap^.last; {move to the previous scrap}         port := GetPort;               {force an update}         SetPort(wPtr);         GetPortRect(r);         EraseRect(r);         InvalRect(r);         SetPort(port);         end; {if}   end; {DoLast}   procedure DoNext;   { Move to the next scrap                                     }   var      port: grafPortPtr;                {caller's grafPort}      r: rect;                          {our port rect}   begin {DoNext}   if frontScrap <> nil then      if frontScrap^.next <> nil then begin         frontScrap := frontScrap^.next; {move to the previous scrap}         port := GetPort;               {force an update}         SetPort(wPtr);         GetPortRect(r);         EraseRect(r);         InvalRect(r);         SetPort(port);         end; {if}   end; {DoNext}   procedure DoPaste;   { Paste a new scrap into the scrapbook                       }   var      index: integer;                   {scrap index}      iPtr: scrapItemPtr;               {pointer to the scrap type being added}      p1, p2: ptr;                      {used to copy a handle}      port: grafPortPtr;                {caller's grafPort}      r: rect;                          {our port rect}      scrap: scrapBuffer;               {scrap buffer}      sPtr: scrapPtr;                   {pointer to the scrap being pasted}         begin {DoPaste}   new(sPtr);                           {set up a scrap record}   if sPtr <> nil then begin      sPtr^.last := nil;      sPtr^.next := nil;      sPtr^.scrap := nil;      index := 1;                       {loop over all scrap types}      repeat         GetIndScrap(index, scrap);         if ToolError = 0 then begin            index := index + 1;            new(iPtr);                  {save a scrap type}            if iPtr <> nil then begin               iPtr^.scrap := NewHandle(scrap.scrapSize, UserID, $8000, nil);               if iPtr^.scrap = nil then begin                  FlagError(2, ToolError);                  dispose(iPtr);                  end {if}               else begin                  iPtr^.scrapLength := scrap.scrapSize;                  iPtr^.scrapType := scrap.scrapType;                  HLock(scrap.scrapHandle);                  p1 := iPtr^.scrap^;                  p2 := scrap.scrapHandle^;                  while scrap.scrapSize <> 0 do begin                     p1^ := p2^;                     p1 := pointer(ord4(p1)+1);                     p2 := pointer(ord4(p2)+1);                     scrap.scrapSize := scrap.scrapSize - 1;                     end; {while}                  HUnlock(scrap.scrapHandle);                  HUnlock(iPtr^.scrap);                  iPtr^.next := sPtr^.scrap;                  sPtr^.scrap := iPtr;                  end; {else}               end {if}            else               FlagError(2, 0);            end; {if}      until ToolError <> 0;      if sPtr^.scrap <> nil then begin         if frontScrap = nil then begin {place the scrap in the buffer}            scraps := sPtr;            frontScrap := sPtr;            end {if}         else begin            sPtr^.next := frontScrap^.next;            if sPtr^.next <> nil then               sPtr^.next^.last := sPtr;            sPtr^.last := frontScrap;            frontScrap^.next := sPtr;            frontScrap := sPtr;            end; {else}         port := GetPort;               {force an update}         SetPort(wPtr);         GetPortRect(r);         EraseRect(r);         InvalRect(r);         SetPort(port);         end {if}      else         dispose(sPtr);      end {if}   else      FlagError(2, 0);   end; {DoPaste}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileClose:   done := true;      fileQuit:    done := true;      editUndo:    ;      editCut:     DoCut;      editCopy:    DoCopy;      editPaste:   DoPaste;      editClear:   DoClear;      moveLast:    DoLast;      moveNext:    DoNext;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}   procedure CheckMenus;   { Check the menus to see if they should be dimmed            }   begin {CheckMenus}   if frontScrap = nil then begin      DisableMItem(moveLast);      DisableMItem(moveNext);      end {if}   else begin      if frontScrap^.last = nil then         DisableMItem(moveLast)      else         EnableMItem(moveLast);      if frontScrap^.next = nil then         DisableMItem(moveNext)      else         EnableMItem(moveNext);      end; {else}   end; {CheckMenus}begin {ScrapBook}startStopParm :=                        {start up the tools}   StartUpTools(userID, 2, 1);if ToolError <> 0 then   SysFailMgr(ToolError, @'Could not start tools: ');InitMenus;                              {set up the menu bar}InitWindow;                             {set up the program window}LoadScrap;                              {load the current scrap}LoadScrapFile;                          {load the scrap file}InitCursor;                             {show the cursor}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   CheckMenus;   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInGoAway:  done := true;      otherwise: ;      end; {case}until done;UnloadScrap;                            {save the current scrap}SaveScrapFile;                          {save the scrap file}ShutDownTools(1, startStopParm);        {shut down the tools}end. {ScrapBook}