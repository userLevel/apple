{---------------------------------------------------------------}{                                                               }{  Slide Show                                                   }{                                                               }{  This program lets you load, view and save screen dump        }{  picture files.                                               }{                                                               }{---------------------------------------------------------------}program SlideShow;uses Common, QuickDrawII, EventMgr, WindowMgr, ControlMgr, DeskMgr,     DialogMgr, MenuMgr, ResourceMgr, MemoryMgr, SFToolSet, GSOS;const   return        = 13;                  {return key code}    appleMenu     = 1;                   {Menu ID #s (also resource ID #s)}   fileMenu      = 2;   editMenu      = 3;   editUndo      = 250;   editCut       = 251;   editCopy      = 252;   editPaste     = 253;   editClear     = 254;   fileOpen      = 261;   fileClose     = 255;   fileSave      = 262;   fileSaveAs    = 263;   fileQuit      = 256;   appleAbout    = 257;type   long = record                        {for splitting 4 bytes to 2 bytes}      case boolean of         true : (long: longint);         false: (lsw,msw: integer);      end;   documentPtr = ^documentRecord;       {document pointer}   documentRecord = record              {information about our document}      next: documentPtr;                {next document}      wPtr: grafPortPtr;                {window pointer}      wName: pString;                   {window name}      onDisk: boolean;                  {does the file exist on disk?}      fileName: handle;                 {file name handle or nil}      pathName: handle;                 {full path name handle or nil}      pictureHandle: handle;            {handle of the picture}      end;var   documents: documentPtr;              {our documents}   done: boolean;                       {tells if the program should stop}   event: integer;                      {event #; returned by GetNextEvent}   myEvent: eventRecord;                {last event returned in event loop}   untitledNum: integer;                {number for the next untitled window}   procedure InitGlobals;   { Initialize the global variables                            }   begin {InitGlobals}   documents := nil;   end; {InitGlobals}   procedure InitMenus;   { Initialize the menu bar.                                   }   const      menuID = 1;                       {menu bar resource ID}    var      height: integer;                  {height of the largest menu}      menuBarHand: menuBarHandle;       {for 'handling' the menu bar}    begin {InitMenus}                                        {create the menu bar}   menuBarHand := NewMenuBar2(refIsResource, menuID, nil);   SetSysBar(menuBarHand);   SetMenuBar(nil);   FixAppleMenu(1);                     {add desk accessories}   height := FixMenuBar;                {draw the completed menu bar}   DrawMenuBar;   end; {InitMenus}   function GetPString (resourceID: integer): pStringPtr;   { Get a string from the resource fork                        }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString resource       }   {                                                            }   { Returns: pointer to the string; nil for an error           }   {                                                            }   { Notes: The string is in a locked resource handle.  The     }   {    caller should call FreePString when the string is no    }   {    longer needed.  Failure to do so is not catastrophic;   }   {    the memory will be deallocated when the program is shut }   {    down.                                                   }   const      rPString = $8006;                 {resource type for p-strings}   var      hndl: handle;                     {resource handle}   begin {GetPString}   hndl := LoadResource(rPString, resourceID);   if ToolError <> 0 then      GetPString := nil   else begin      HLock(hndl);      GetPString := pStringPtr(hndl^);      end; {else}   end; {GetPString}   procedure FreePString (resourceID: integer);   { Free a resource string                                     }   {                                                            }   { Parameters:                                                }   {    resourceID - resource ID of the rPString to free        }   const      rPString = $8006;                 {resource type for p-strings}   begin {FreePString}                  ReleaseResource(-3, rPString, resourceID);   end; {FreePString}   procedure FlagError (error, tError: integer);   { Flag an error                                              }   {                                                            }   { Parameters:                                                }   {    error - error message number                            }   {    tError - toolbox error code; 0 if none                  }   const      errorAlert = 2000;                {alert resource ID}      errorBase = 2000;                 {base resource ID for error messages}   var      str: pString;                     {wprk string}      substArray: pStringPtr;           {substitution "array"}      button: integer;                  {button pushed}      function HexDigit (value: integer): char;      { Returns a hexadecimal digit for the value               }      {                                                         }      { Parameters:                                             }      {    value - value to form a digit from; only the least   }      {       significant 4 bits are used                       }      {                                                         }      { Returns: Hexadecimal character                          }      begin {HexDigit}      value := value & $000F;      if value > 9 then         HexDigit := chr(value-10 + ord('A'))      else         HexDigit := chr(value + ord('0'));      end; {HexDigit}   begin {FlagError}                                        {form the error string}   substArray := GetPString(errorBase + error);   str := substArray^;   FreePString(errorBase + error);   substArray := @str;   if tError <> 0 then begin            {add the tool error number}      str := concat(         str,         ' ($',         HexDigit(tError >> 12),         HexDigit(tError >> 8),         HexDigit(tError >> 4),         HexDigit(tError),         ')'         );      end; {if}                                        {show the alert}   button := AlertWindow($0005, @substArray, ord4(errorAlert));   end; {FlagError}   procedure CloseDocument (dPtr: documentPtr);   { Close a document and its associated window                    }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to close; may be nil        }   var      lPtr: documentPtr;                {pointer to the previous document}   begin {CloseDocument}   if dPtr <> nil then begin      CloseWindow(dPtr^.wPtr);          {close the window}      if documents = dPtr then          {remove dPtr from the list when...}         documents := dPtr^.next        {...dPtr is the first document}      else begin                        {...dPtr is not the first document}         lPtr := documents;         while lPtr^.next <> dPtr do            lPtr := lPtr^.next;         lPtr^.next := dPtr^.next;         end; {else}      if dPtr^.fileName <> nil then     {dispose of the name buffers}         DisposeHandle(dPtr^.fileName);      if dPtr^.pathName <> nil then         DisposeHandle(dPtr^.pathName);      if dPtr^.pictureHandle <> nil then {dispose of the picture buffer}         DisposeHandle(dPtr^.pictureHandle);      dispose(dPtr);                    {dispose of the document record}      end; {if}   end; {CloseDocument}   function FindDocument (wPtr: grafPortPtr): documentPtr;   { Find the document for wPtr                                    }   {                                                               }   { Parameters:                                                   }   {    wPtr - pointer to the window for which to find a document  }   {                                                               }   { Returns: Document pointer; nil if there isn't one             }   var      done: boolean;                    {used to test for loop termination}      dPtr: documentPtr;                {used to trace the document list}   begin {FindDocument}   dPtr := documents;   done := dPtr = nil;   while not done do      if dPtr^.wPtr = wPtr then         done := true      else begin         dPtr := dPtr^.next;         done := dPtr = nil;         end; {else}   FindDocument := dPtr;   end; {FindDocument}   {$databank+}   procedure DrawContents;   { Draw the contents of the active port                       }   var      dPtr: documentPtr;                {document to draw}      info: locInfo;                    {record for PPToPort}   begin {DrawContents}   dPtr := FindDocument(GetPort);   if dPtr <> nil then begin      HLock(dPtr^.pictureHandle);      with info do begin         portSCB := $00;         ptrToPixelImage := dPtr^.pictureHandle^;         width := 160;         with boundsRect do begin            h1 := 0; h2 := 320;            v1 := 0; v2 := 200;            end; {with}         end; {with}      PPToPort(info, info.boundsRect, 0, 0, modeCopy);      HUnlock(dPtr^.pictureHandle);      end; {if}                                     end; {DrawContents}   {$databank+}   function LoadDocument (dPtr: documentPtr): boolean;   { Load a document file from disk                                }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to save                     }   {                                                               }   { Returns: true if successful, else false                       }      var      clRec: closeOSDCB;                {CloseGS record}      opRec: openOSDCB;                 {OpenGS record}      port: grafPortPtr;                {caller's grafPort}      r: rect;                          {our port rect}      rdRec: readWriteOSDCB;            {ReadGS record}   begin {LoadDocument}   LoadDocument := true;                {assume we will succeed}   opRec.pcount := 12;                  {open the file}   HLock(dPtr^.pathName);   opRec.pathName := pointer(ord4(dPtr^.pathName^)+2);   opRec.requestAccess := 1;   opRec.resourceNumber := 0;   opRec.optionList := nil;   OpenGS(opRec);   if ToolError <> 0 then begin      FlagError(4, ToolError);      LoadDocument := false;      end {if}   else begin      dPtr^.pictureHandle :=            {allocate memory for the file}         NewHandle(opRec.dataEOF, userID, $8000, nil);      if ToolError <> 0 then begin         FlagError(2, ToolError);         LoadDocument := false;         end {if}      else begin         rdRec.pcount := 4;             {read the file}         rdRec.refnum := opRec.refnum;         rdRec.dataBuffer := dPtr^.pictureHandle^;         rdRec.requestCount := opRec.dataEOF;         ReadGS(rdRec);         if ToolError <> 0 then begin            FlagError(4, ToolError);            LoadDocument := false;            DisposeHandle(dPtr^.pictureHandle);            dPtr^.pictureHandle := nil;            end {if}         else begin            HUnlock(dPtr^.pictureHandle); {let the picture move in memory}            port := GetPort;            {force an update}            SetPort(dPtr^.wPtr);            GetPortRect(r);            InvalRect(r);            SetPort(port);            end; {else}         end; {else}      clRec.pcount := 1;                {close the file}      clRec.refnum := opRec.refnum;      CloseGS(clRec);      end; {else}   HUnlock(dPtr^.pathName);             {unlock the name handle}   end; {LoadDocument}   procedure GetUntitledName (var name: pString);   { Create a name for an untitled window                          }   {                                                               }   { Parameters:                                                   }   {    name - (returned) name for the window                      }   const      untitled = 101;                   {Resource number for "Untitled "}   var      dPtr: documentPtr;                {used to trace the document list}      number: integer;                  {new value for untitledNum}      sPtr: pStringPtr;                 {pointer to the resource string}   begin {GetUntitledName}   dPtr := documents;                   {if there are no untitled         }   number := 1;                         { documents then reset untitledNum}   while dPtr <> nil do      if not dPtr^.onDisk then begin         number := untitledNum;         dPtr := nil;         end {if}      else         dPtr := dPtr^.next;   untitledNum := number;   sPtr := GetPString(untitled);        {set the base name}   if sPtr = nil then      name := 'Untitled '   else begin      name := sPtr^;      FreePString(untitled);      end; {else}   name := concat(name, cnvis(untitledNum)); {add the untitled number}   name := concat('  ', name, '  ');    {pad with spaces}   untitledNum := untitledNum+1;        {update untitledNum}   end; {GetUntitledName}   function NewDocument (wName: pString): documentPtr;   { Open a new document                                           }   {                                                               }   { Parameters:                                                   }   {    wName - name for the new window                            }   {                                                               }   { Returns: Document pointer; nil for an error                   }   const      rWindParam1 = $800E;              {resource ID}      wrNum = 1001;                     {window resource number}   var      dPtr: documentPtr;                {new document pointer}   begin {NewDocument}   new(dPtr);                           {allocate the record}   if dPtr <> nil then begin      dPtr^.onDisk := false;            {not on disk}      dPtr^.wName := wName;             {set up the name}      dPtr^.fileName := nil;            {no file name handle}      dPtr^.pathName := nil;            {no path name handle}      dPtr^.pictureHandle := nil;       {no picture handle}      dPtr^.wPtr :=                     {open the window}         NewWindow2(@dPtr^.wName, 0, @DrawContents, nil, $02, wrNum,            rWindParam1);      if dPtr^.wPtr = nil then begin         FlagError(1, ToolError);       {handle a window error}         dispose(dPtr);         dPtr := nil;         end {if}      else begin         dPtr^.next := documents;       {put the document in the list}         documents := dPtr;         end; {else}      end {if}   else      FlagError(2, 0);                  {handle an out of memory error}   NewDocument := dPtr;   end; {NewDocument}   procedure SaveDocument (dPtr: documentPtr);   { Save a document file to disk                                  }   {                                                               }   { Parameters:                                                   }   {    dPtr - pointer to the document to save                     }   var      clRec: closeOSDCB;                {CloseGS record}      crRec: createOSDCB;               {CreateGS record}      dsRec: destroyOSDCB;              {DestroyGS record}      opRec: openOSDCB;                 {OpenGS record}      wrRec: readWriteOSDCB;            {WriteGS record}   begin {SaveDocument}   HLock(dPtr^.pathName);               {lock the path name}   dsRec.pcount := 1;                   {destroy any old file}   dsRec.pathName := pointer(ord4(dPtr^.pathName^)+2);   DestroyGS(dsRec);   crRec.pcount := 5;                   {create a new file}   crRec.pathName := pointer(ord4(dPtr^.pathName^)+2);   crRec.access := $C3;   crRec.fileType := $C1;   crRec.auxType := 0;   crRec.storageType := 1;   CreateGS(crRec);   if ToolError <> 0 then      FlagError(5, ToolError)   else begin      opRec.pcount := 3;                {open the file}      opRec.pathName := pointer(ord4(dPtr^.pathName^)+2);      opRec.requestAccess := 2;      OpenGS(opRec);      if ToolError <> 0 then         FlagError(5, ToolError)      else begin         wrRec.pcount := 4;                {write the file}         wrRec.refnum := opRec.refnum;         HLock(dPtr^.pictureHandle^);         wrRec.dataBuffer := dPtr^.pictureHandle^;         wrRec.requestCount := $8000;         WriteGS(wrRec);         if ToolError <> 0 then            FlagError(5, ToolError);         HUnlock(dPtr^.pictureHandle^);         clRec.pcount := 1;                {close the file}         clRec.refnum := opRec.refnum;         CloseGS(clRec);         end; {else}      end; {else}   HUnlock(dPtr^.pathName);             {unlock the name handle}   end; {SaveDocument}   procedure HandleMenu;   { Handle a menu selection.                                   }    var      menuNum, menuItemNum: integer;    {menu number & menu item number}      procedure DoAbout;      { Draw our about box                                         }      const         alertID = 1;                   {alert string resource ID}      var         button: integer;               {button pushed}      begin {DoAbout}      button := AlertWindow($0005, nil, alertID);      end; {DoAbout}      procedure DoOpen;      { Open a file                                             }      const         posX = 20;                     {X position of the dialog}         posY = 50;                     {Y position of the dialog}         titleID = 102;                 {prompt string resource ID}      var         dPtr: documentPtr;             {pointer to the new document}         fileTypes: typeList5_0;        {list of valid file types}         gsosNameHandle: handle;        {handle of the file name}         gsosNamePtr: gsosOutStringPtr; {pointer to the GS/OS file name}         i: integer;                    {loop/index variable}         name: pString;                 {new document name}         reply: replyRecord5_0;         {reply record}      begin {DoOpen}      with fileTypes do begin           {set up the allowed file types}         numEntries := 1;         with fileAndAuxTypes[1] do begin            flags := $0000;            fileType := $C1;            auxType := $0000;            end; {with}         end; {with}      reply.nameVerb := 3;              {get the file to open}      reply.pathVerb := 3;      SFGetFile2(posX, posY, 2, titleID, nil, fileTypes, reply);      if ToolError <> 0 then         FlagError(3, ToolError)        {handle an error}      else if reply.good <> 0 then begin                                        {form the file name}         gsosNameHandle := pointer(reply.nameRef);         HLock(gsosNameHandle);         gsosNamePtr := pointer(gsosNameHandle^);         name := '  ';         for i := 1 to gsosNamePtr^.theString.size do            name := concat(name, gsosNamePtr^.theString.theString[i]);         name := concat(name, '  ');         HUnlock(gsosNameHandle);         dPtr := NewDocument(name);     {get a document record}         if dPtr = nil then begin       {in case of error, dispose of the names}            DisposeHandle(handle(reply.nameRef));            DisposeHandle(handle(reply.pathRef));            end {if}         else begin                     {otherwise save the names}            dPtr^.fileName := handle(reply.nameRef);            dPtr^.pathName := handle(reply.pathRef);            if LoadDocument(dPtr) then  {read the file}               dPtr^.onDisk := true     {file is on disk}            else                        {handle a read error}               CloseDocument(dPtr);            end; {else}         end; {else if}      end; {DoOpen}      procedure DoSaveAs;      { Save a document to a new name                           }      const         posX = 20;                     {X position of the dialog}         posY = 50;                     {Y position of the dialog}         titleID = 103;                 {prompt string resource ID}      var         dPtr: documentPtr;             {document to save}         dummyName: integer;            {used for a null file name prompt}         gsosNameHandle: handle;        {handle of the file name}         gsosNamePtr: gsosOutStringPtr; {pointer to the GS/OS file name}         i: integer;                    {loop/index variable}         reply: replyRecord5_0;         {reply record}      begin {DoSaveAs}      dPtr := FindDocument(FrontWindow);      if dPtr <> nil then begin         reply.nameVerb := 3;           {get the new file name}         reply.pathVerb := 3;         if dPtr^.fileName = nil then begin            dummyName := 0;            SFPutFile2(posX, posY, 2, titleID, 0, @dummyName, reply);            end {if}         else            SFPutFile2(posX, posY, 2, titleID, 0,               pointer(ord4(dPtr^.fileName^)+2), reply);         if ToolError <> 0 then            FlagError(3, ToolError)     {handle an error}         else if reply.good <> 0 then begin                                        {form the new window name}            gsosNameHandle := pointer(reply.nameRef);            HLock(gsosNameHandle);            gsosNamePtr := pointer(gsosNameHandle^);            dPtr^.wName := '  ';            for i := 1 to gsosNamePtr^.theString.size do               dPtr^.wName :=                  concat(dPtr^.wName, gsosNamePtr^.theString.theString[i]);            dPtr^.wName := concat(dPtr^.wName, '  ');            HUnlock(gsosNameHandle);            SetWTitle(dPtr^.wName, dPtr^.wPtr);                                        {save the names}            dPtr^.fileName := handle(reply.nameRef);            dPtr^.pathName := handle(reply.pathRef);            dPtr^.onDisk := true;       {file is on disk}            SaveDocument(dPtr);         {save the file}            end; {else if}         end; {if}      end; {DoSaveAs}      procedure DoSave;      { Save a document to the existing disk file               }      var         dPtr: documentPtr;             {document to save}      begin {DoSave}      dPtr := FindDocument(FrontWindow);      if dPtr <> nil then         if dPtr^.onDisk then            SaveDocument(dPtr)         else            DoSaveAs;      end; {DoSave}   begin {HandleMenu}                                        {separate the menu and item numbers}   menuNum := long(myEvent.taskData).msw;   menuItemNum := long(myEvent.taskData).lsw;   case menuItemNum of                  {go handle the menu}      appleAbout:  DoAbout;      fileOpen:    DoOpen;      fileClose:   CloseDocument(FindDocument(FrontWindow));      fileSave:    DoSave;      fileSaveAs:  DoSaveAs;      fileQuit:    done := true;      editUndo:    ;      editCut:     ;      editCopy:    ;      editPaste:   ;      editClear:   ;      otherwise:   ;      end; {case}   HiliteMenu(false, menuNum);          {unhighlight the menu}   end; {HandleMenu}begin {SlideShow}StartDesk(320);InitMenus;                              {set up the menu bar}InitCursor;                             {show the cursor}InitGlobals;                            {initialize our global variables}done := false;                          {main event loop}myEvent.taskMask := $001F7FFF;          {let task master do it all}repeat   event := TaskMaster(everyEvent, myEvent);   case event of                        {handle the events we need to}      wInSpecial,      wInMenuBar: HandleMenu;      wInGoAway:  CloseDocument(FindDocument(grafPortPtr(myEvent.taskData)));      otherwise: ;      end; {case}until done;EndDesk;end. {SlideShow}