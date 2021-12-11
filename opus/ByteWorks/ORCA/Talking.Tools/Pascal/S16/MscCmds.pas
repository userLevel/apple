{$keep 'MscCmds'}{------------------------------------------------------------------}{                                                                  }{ MsCmds - Commands to bring up the About box, print documents,    }{          and control the front window.                           }{                                                                  }{ Written by Barbara Allred                                        }{                                                                  }{ Copyright 1991, Byte Works, Inc.                                 }{ Copyright 1987-1991, First Byte, Inc.                            }{                                                                  }{------------------------------------------------------------------}unit MscCmds;interfaceuses   Common, SpeechTools, DialogMgr, SFToolSet, GSOS, ControlMgr, MemoryMgr, TextEdit,   PrintMgr, WindowMgr, MenuMgr, QuickDrawII;{$LibPrefix '0/'}uses   Globals, Error;function  MyWindow (var wInfo: windInfoRec): boolean;procedure DoAbout;function  DoClose: boolean;procedure DoPrint;procedure DoPSetUp;function  InitMscCmds: boolean;implementationvar   prHndl: prHandle;                    {print record handle}   aboutDlg: dialogTemplate;            {About item's dialog box}   item00Abt1: itemTemplate;            {  title}   item01Abt1: itemTemplate;            {  OK button}   item00pointerAbt1: packed array[0..100] of char; {  message}   item01colorsAbt1: bttnColors;        {OK button's color table}function WantToSave (wNum: integer): boolean; extern;{Located in FileCmds unit, which USES this unit.}{---------------------------------------------------------------}{                                                               }{ MyWindow - Checks if front window is one of ours.             }{                                                               }{ Returns:  True if it's one of ours                            }{                                                               }{---------------------------------------------------------------}function MyWindow {var wInfo: windInfoRec): boolean};label 99;var   wRefCon: refConRec;                  {front window's refCon}begin {MyWindow}{First check if any windows are up.  If not, return false.}if numWindows <= 0 then begin   MyWindow := false;   goto 99;   end; {if}{Check if the window is a system window.  If so, return false.}with wInfo do begin   currWindow := FrontWindow;   if GetSysWFlag(currWindow) then begin      MyWindow := false;      goto 99;      end; {if}   {It's one of ours, so set global info for this window.}   wRefCon.long := GetWRefCon(currWindow);   currWindNum := wRefCon.wNum;   currWindTyp := wRefCon.wTyp;   end; {with}MyWindow := true;99:end; {MyWindow}{---------------------------------------------------------------}{                                                               }{ DoAbout - Bring up the About box.                             }{                                                               }{---------------------------------------------------------------}procedure DoAbout;var   tmp: grafPortPtr;   i: integer;begin {DoAbout}{Create the About modal dialog.}tmp := GetNewModalDialog(aboutDlg);if toolError <> 0 then   HandleError(toolError, windErr)else begin   i := ModalDialog(nil);   if toolError <> 0 then      FatalErr(toolError);   CloseDialog(tmp);   end; {else}end; {DoAbout}{---------------------------------------------------------------}{                                                               }{ DoClose - Close front window.                                 }{                                                               }{ Output:                                                       }{    boolean - true if Cancel in save dialog chosen             }{                                                               }{---------------------------------------------------------------}function DoClose {: boolean};label 99;var   tmp: ctlRecHndl;                     {window's text edit control handle}   wInfo: windInfoRec;                  {window information for front wind}begin {DoClose}DoClose := false;                       {assume Cancel not selected}if MyWindow(wInfo) then begin           {ensure it's one of our windows}   {If not closing the dictionary window, then ensure we can open}   {a new text or phonetics window.  First check need to save    }   {window before closing it.                                    }   if wInfo.currWindTyp <> dictTyp then begin      tmp := userWind[wInfo.currWindNum].teHndl;      if (ord(tmp^^.ctlFlag) & isDirty) <> 0 then         if WantToSave(wInfo.currWindNum) then begin            DoClose := true;            goto 99;            end; {if}      {If the window is associated with a file, free any file memory.}      with userWind[wInfo.currWindNum] do         if fileFlag then begin            fileFlag := false;            if wPathHandle <> nil then               DisposeHandle(wPathHandle);               wPathHandle := nil;            wPathName := nil;            end; {if}      userWindows :=  userWindows - 1;  {one less user window up}      EnableMItem(newID);               {can now create new window}      EnableMItem(openID);              {can now open a file}      end; {if not dict window}   CloseWindow(wInfo.currWindow);       {close the window}   numWindows := numWindows - 1;        {one less window open}   {Set window record flag that window no longer open.}   userWind[wInfo.currWindNum].upFlag := false;   end; {if MyWindow}99:end; {DoClose}{---------------------------------------------------------------}{                                                               }{ DoPrint - Print a text window or the dictionary.              }{                                                               }{---------------------------------------------------------------}procedure DoPrint;label 99;const   thruPrinting = $2209;                {err code returned by TEPaintText when}                                        {  starting line # exceeds last line #}var   wInfo: windInfoRec;                  {information about front wind}   word1,                               {dictionary entry}   word2: pString32;   prPort: grafPortPtr;                 {Print Manager's grafPort}   savePort: grafPortPtr;               {curr grafPort saved/restored}   currLine: longint;                   {current line # to print}   lastLine: longint;                   {last line # to print}   firstPage: longint;                  {first page to begin printing}   finalPage: longint;                  {final page to print}   copies: integer;                     {# copies of document to print}   spool: boolean;                      {false = draft mode;          }                                        {true = spooled printing}   anError: boolean;                    {true if error detected}   printRecPtr: prRecPtr;               {pointer to print record}   prRect: Rect;                        {printing rectangle}   tmp: longint;                        {temporaries}   tmp2: pString32Ptr;   answer: boolean;   i, j: integer;begin {DoPrint}savePort := GetPort;                    {save caller's grafPort}if not MyWindow(wInfo) then             {ensure window is one of ours}   goto 99;answer := PrJobDialog(prHndl);          {bring up Print Job dialog}if toolError <> 0 then begin   HandleError(toolError, printErr);   goto 99;   end; {if}if not answer then                      {want to print document?}   goto 99;printRecPtr := prHndl^;                 {dereference print record handle}{Set up page rectangle based on printed page size calculated by Print Manager}{as derived from Job and Page setup dialogs.                                 }with printRecPtr^ do begin   with prInfo.rPage do begin      prRect.v1 := v1;      prRect.h1 := h1;      prRect.v2 := v2;      prRect.h2 := h2;      end; {with}   firstPage := prJob.iFstPage;         {get first page to print}   currLine := (firstPage - 1) * 60;    {calculate 1st line to print,}                                        {  counting lines from 0, and}                                        {  60 lines per page         }   prJob.iFstPage := 1;                 {set page # to 1 for Print Manager, since it}                                        {  counts ea. page it prints, starting at 1 }   finalPage := prJob.iLstPage;         {get last page to print}   lastLine := finalPage * 60;          {calculate last line to print}   {Ensure that starting page number not greater than ending page.}   tmp := finalPage - firstPage;   if tmp < 0 then      goto 99;   prJob.iLstPage := hiLow(tmp).lo + 1; {reset last page to print for}                                        { Print Mgr, relative to 1   }   copies := prJob.iCopies;             {get # copies to print}   firstPage := currLine;               {remember starting line # in case multiple}                                        { copies wanted and printing in draft mode}   {Determine whether printing in draft or spooled mode.}   if prJob.bJDocLoop = 0 then      spool := false   else begin      spool := true;      copies := 1;                      {PrPicFile handles multiple copies}      end; {else}   {Ensure requested starting line number is in document.}   if wInfo.currWindTyp = dictTyp then  {if window = dict, check dict size}      begin      if listTempl.listSize < ord(currLine) then         goto 99;      {Position dictionary at first entry to print.}      if nextEntry >= ord(currLine)     {check if can reach entry from}         then begin                     {  current position in dict   }         DictInit(0);         nextEntry := 0;         end; {if}      while nextEntry < ord(currLine) do begin         tmp2 := DictDump(word1, word2);         if length(word1) = 0 then            goto 99;         nextEntry := nextEntry + 1;         end; {while}      end {if dict}   {If the window is a text file, we find the number of lines in the document}   {by calling Text Edit's TEGetTextInfo, which returns a textInfo record.   }   else begin      TEGetTextInfo(textInfo, 2, userWind[wInfo.currWindNum].teHndl);      if toolError <> 0 then begin         HandleError(toolError, teErr);         goto 99;         end; {if}      if currLine > textInfo.lineCount then         goto 99;      end; {if not dict}   end; {with printRecPtr}{Call Print Manager to open the document for printing; get Print Manager's}{printing grafPort.                                                       }anError := false;{Outer print loop, to print multiple copies in draft mode.}repeat   prPort := PrOpenDoc(prHndl, nil);   if toolError <> 0 then begin      HandleError(toolError, printErr);      anError := true;      end {if}   else begin      {Inner print loop, to print each page in the document.}      repeat         PrOpenPage(prPort, nil);       {init. grafPort, no scaling rect. passed}         if toolError <> 0 then begin            HandleError(toolError, printErr);            anError := true;            end {if}         else begin            PenNormal;                  {set pen to standard state}            {What is drawn into the printer's grafPort depends on window's type.}            if wInfo.currWindTyp = dictTyp then begin               i := 0;               j := 10;                 {j = horizontal offset into page}               while i < 60 do begin                  tmp2 := DictDump(word1, word2); {dump next entry}                  if length(word1) = 0 then begin {check end of dict}                     currLine := -1;    {signal end of doc}                     DictInit(0);       {reset dict to top}                     nextEntry := 0;                     i := 60;                     end {if}                  else begin            {draw this entry}                     MoveTo(10, j);                     DrawString(word1);                     MoveTo(170, j);                     DrawString(word2);                     nextEntry := nextEntry+1; {move to next entry}                     currLine := currLine+1; {move to next line}                     j := j+10;                     i := i+1;                     end; {else}                  end {while}               end {if window = dict}            else begin               MoveTo(0, 0);            {move to top left of drawing rect}               {Call TEPaintText to draw text into Print Mgr's grafPort}               currLine := TEPaintText(prPort, currLine, prRect, 0,                  userWind[wInfo.currWindNum].teHndl);               if (toolError <> 0) and (toolError <> thruPrinting) then begin                  HandleError(toolError, printErr);                  anError := true;                  end; {if}               end; {window not dict}            end; {no error from PrOpenPage}         PrClosePage(prPort);           {close this printed page}         if (toolError <> 0) and (not anError) then begin            HandleError(toolError, printErr);            anError := true;            end; {if}                                        {end page-printing loop}      until (currLine = -1) or (currLine > lastLine) or (anError);      end; {no error from PrOpenDoc}   PrCloseDoc(prPort);                  {close document for printing}   if (toolError <> 0) and (not anError) then begin      HandleError(toolError, printErr);      anError := true;      end; {if}   copies := copies - 1;                {one less copy to print}   currLine := firstPage;               {reset for next copy}until (copies = 0) or (anError);        {end print copies loop}{Handle spooled printing.}if (spool) and (not anError) then begin   PrPicFile(prHndl, nil, nil);         {let Print Mgr alloc new grafPort, prStatusRec}   if toolError <> 0 then      HandleError(toolError, printErr);   end; {if}99:SetPort(savePort);                      {restore original grafPort}end; {DoPrint}{---------------------------------------------------------------}{                                                               }{ DoPSetUp - Handle Page setUp command.                         }{                                                               }{---------------------------------------------------------------}procedure DoPSetUp;var   i: boolean;begin {DoPSetUp}{Bring up Print Style dialog.}i :=  PrStlDialog(prHndl);if toolError <> 0 then   HandleError(toolError, printErr);end; {DoPSetUp}{---------------------------------------------------------------}{                                                               }{ InitMscCmds - Initialize MscCmds unit.                        }{                                                               }{---------------------------------------------------------------}function InitMscCmds {: boolean};label 99;begin {InitMscCmds}InitMscCmds := true;                    {assume all is well to start}{Create print record:  allocate memory for print record, then initialize.}prHndl := prHandle(NewHandle(ord4(140), myID, $C010, nil));if toolError <> 0 then begin   HandleError(toolError, memErr);   InitMscCmds := false;   goto 99;   end; {if}prDefault(prHndl);if toolError <> 0 then begin   HandleError(toolError, printErr);   InitMscCmds := false;   goto 99;   end; {if}{Initialize the About dialog box.}item00pointerAbt1 := concat('Speak It 1.0.2', chr($0D), chr($0D),                            'A simple demo to show how to', chr($0D),                            'use Talking Tools.', chr($0D),                            'Written by Barbara Allred');with aboutDlg do begin   with dtBoundsRect do begin      v1 := $2B;      h1 := $C4;      v2 := $9C;      h2 := $1B9;      end; {with}   dtVisible := true;   dtRefCon := 0;   dtItemList[1] := @item00Abt1;   dtItemList[2] := @item01Abt1;   dtItemList[3] := nil;   end; {with}with item00Abt1 do begin   itemID := $64;   with itemRect do begin      v1 := 4;      h1 := 8;      v2 := 72;      h2 := 241;      end; {with}   itemType := $F;   itemDescr := @item00PointerAbt1;   itemValue := length(item00PointerAbt1);   itemFlag := 0;   itemColor := nil;   end; {with}with item01Abt1 do begin                {About dialog's OK button}   itemID := 1;   with itemRect do begin      v1 := 89;      h1 := 94;      v2 := 102;      h2 := 149;      end; {with}   itemType := $A;   itemDescr := @okTitle;   itemValue := 0;   itemFlag := 1;   itemColor := @item01ColorsAbt1;   end; {with}with item01colorsAbt1 do begin          {OK button's color table}   bttnOutline := $10;   bttnNorBack := $D0;   bttnSelBack := $70;   bttnNorText := $E8;   bttnSelText := $B9;   end; {with}99:end; {InitMscCmds}end. {MscCmds unit}