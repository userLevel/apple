/***************************************************************** Control Explorer** Explores how controls work.****************************************************************/#pragma lint -1#include <math.h>#include <string.h>#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#include <Resources.h>#include <Locator.h>#include <MiscTool.h>#include <Control.h>#include <LineEdit.h>#include <List.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define appleAbout      257#define fileClose       255#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254#define moveLast        260#define moveNext        261#define ctlBeepOnce     2               /* control IDs */#define ctlBeepTwice    3#define ctlTitle        4#define ctlBoxRed       5#define ctlBoxGreen     6#define ctlBoxBlue      7#define ctlSound        8#define ctlTRed         9#define ctlTGreen       10#define ctlTBlue        11#define ctlSRed         12#define ctlSGreen       13#define ctlSBlue        14#define ctlRect         15#define ctlSavage       16#define ctlLeft         17#define ctlRight        18#define ctlLine1        19#define ctlLine2        20#define ctlList         21#define ctlPop          22#define cbase           1000#define ctlCalc         100#define ctlThermometer  101#define mixColor        1               /* color mixer box color */typedef struct listElement {            /* list record */   char *memPtr;   Byte memFlag;   } listElement;BOOLEAN done;                           /* are we done, yet? */EventRecord myEvent;                    /* event record */GrafPortPtr wPtr;                       /* window pointer */static Rect boxRect = {18,10,31,21};    /* color box rectangle */unsigned boxColor;                      /* box color */unsigned boxColor2;                     /* box color #2 */static Rect boxRect2 = {110,200,135,310}; /* box color rectangle #2 */BOOLEAN soundOn;                        /* is the sound turned on? */static Rect mixRect = {39,10,74,46};    /* color mixer rectangle */listElement stateList[10];              /* state list */char stateNames[10][14];/***************************************************************** DrawContents** Draw the contents of the active port****************************************************************/#pragma databank 1void DrawContents (void){PenNormal();DrawControls(GetPort());                /* draw the controls */SetSolidPenPat(boxColor);               /* draw the radio color box */PaintRect(&boxRect);SetSolidPenPat(0);FrameRect(&boxRect);SetSolidPenPat(boxColor2);              /* draw the popup color box */PaintRect(&boxRect2);SetSolidPenPat(0);FrameRect(&boxRect2);SetSolidPenPat(mixColor);               /* draw the color mixer rectangle */PaintRect(&mixRect);SetSolidPenPat(0);FrameRect(&mixRect);}#pragma databank 0/***************************************************************** DrawContents2** Draw the contents of the Savage alert****************************************************************/#pragma databank 1void DrawContents2 (void){DrawControls(GetPort());}#pragma databank 0/***************************************************************** ForceUpdate** Force an update of our window** Parameters:*    r - rectangle to update****************************************************************/void ForceUpdate (Rect r){GrafPortPtr port;                       /* caller's GrafPort */port = GetPort();SetPort(wPtr);InvalRect(&r);SetPort(port);}/***************************************************************** ScrollAction** Scroll bar action procedure** Parameters:*    part - scroll bar part code*    ctlHandle - scroll bar handle****************************************************************/#pragma databank 0pascal void ScrollAction (int part, CtlRecHndl ctlHandle){#define pageSize 1                      /* size of a page */#define maxPos 15                       /* max position for the scroll bar */int cdisp;                              /* color based bit shift displacement */int color;                              /* color table entry */int value, oldValue;                    /* control value */unsigned long ctlID;                    /* control ID */value = GetCtlValue(ctlHandle);oldValue = value;switch (part) {   case upArrow:        --value;                                        break;   case downArrow:      ++value;                                        break;   case pageUp:         value -= pageSize;                              break;   case pageDown:       value += pageSize;                              break;   case thumb:          value = oldValue; oldValue = value-1;           break;   }if (value < 0)   value = 0;else if (value > maxPos)   value = maxPos;if (value != oldValue) {   SetCtlValue(value, ctlHandle);   color = GetColorEntry(0, mixColor);   ctlID = GetCtlID(ctlHandle);   if (ctlID == ctlSRed)      cdisp = 0x0100;   else if (ctlID == ctlSGreen)      cdisp = 0x0010;   else      cdisp = 0x0001;   color = (color & ((cdisp*0x000F) ^ 0xFFFF)) | (cdisp * value);   SetColorEntry(0, mixColor, color);   }}#pragma databank 0/***************************************************************** InitWindows** Set up the program window****************************************************************/void InitWindow (void){#define wrNum 1001                      /* window resource number */unsigned i;                             /* loop/index variable */                                        /* open the window */wPtr = NewWindow2("\p ", 0, DrawContents, NULL, 0x02, wrNum, rWindParam1);                                        /* set up the scroll action procedure */SetCtlAction((LongProcPtr) ScrollAction, GetCtlHandleFromID(wPtr, ctlSRed));SetCtlAction((LongProcPtr) ScrollAction, GetCtlHandleFromID(wPtr, ctlSBlue));SetCtlAction((LongProcPtr) ScrollAction, GetCtlHandleFromID(wPtr, ctlSGreen));                                        /* set up the state list */strcpy(stateNames[0], "\pCalifornia");strcpy(stateNames[1], "\pColorado");strcpy(stateNames[2], "\pConnecticut");strcpy(stateNames[3], "\pNew Hampshire");strcpy(stateNames[4], "\pNew York");strcpy(stateNames[5], "\pNew Mexico");strcpy(stateNames[6], "\pNew Jersey");strcpy(stateNames[7], "\pAlaska");strcpy(stateNames[8], "\pAlabama");strcpy(stateNames[9], "\pArkansas");for (i = 0; i < 10; ++i) {   stateList[i].memPtr = stateNames[i];   stateList[i].memFlag = 0;   }NewList2(NULL, 1, (Ref) stateList, 0, 10, (Handle) GetCtlHandleFromID(wPtr, ctlList));SortList2(NULL, (Handle) GetCtlHandleFromID(wPtr, ctlList));DrawMember2(0, (Handle) GetCtlHandleFromID(wPtr, ctlList));#undef wrNum}/***************************************************************** DoAbout** Draw our about box****************************************************************/void DoAbout (void){#define alertID 1                       /* alert string resource ID */AlertWindow(awCString+awResource, NULL, alertID);#undef alertID}/***************************************************************** DoClear** Handle a clear command****************************************************************/void DoClear (void){CtlRecHndl ctl;                         /* target control handle */unsigned long id;                       /* control ID */GrafPortPtr port;                       /* caller's GrafPort */port = GetPort();SetPort(wPtr);ctl = FindTargetCtl();id = GetCtlID(ctl);if ((id == ctlLine1) || (id == ctlLine2))   LEDelete((LERecHndl) GetCtlTitle(ctl));SetPort(port);}/***************************************************************** DoCopy** Handle a copy command****************************************************************/void DoCopy (void){CtlRecHndl ctl;                         /* target control handle */unsigned long id;                       /* control ID */GrafPortPtr port;                       /* caller's GrafPort */port = GetPort();SetPort(wPtr);ctl = FindTargetCtl();id = GetCtlID(ctl);if ((id == ctlLine1) || (id == ctlLine2)) {   LECopy((LERecHndl) GetCtlTitle(ctl));   LEToScrap();   }SetPort(port);}/***************************************************************** DoCut** Handle a cut command****************************************************************/void DoCut (void){CtlRecHndl ctl;                         /* target control handle */unsigned long id;                       /* control ID */GrafPortPtr port;                       /* caller's GrafPort */port = GetPort();SetPort(wPtr);ctl = FindTargetCtl();id = GetCtlID(ctl);if ((id == ctlLine1) || (id == ctlLine2)) {   LECut((LERecHndl) GetCtlTitle(ctl));   LEToScrap();   }SetPort(port);}/***************************************************************** DoPaste** Handle a paste command****************************************************************/void DoPaste (void){CtlRecHndl ctl;                         /* target control handle */unsigned long id;                       /* control ID */GrafPortPtr port;                       /* caller's GrafPort */port = GetPort();SetPort(wPtr);ctl = FindTargetCtl();id = GetCtlID(ctl);if ((id == ctlLine1) || (id == ctlLine2)) {   LEFromScrap();   LEPaste((LERecHndl) GetCtlTitle(ctl));   }SetPort(port);}/***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:     DoAbout();                                      break;   case fileClose:                                                      break;   case fileQuit:       done = TRUE;                                    break;   case editUndo:                                                       break;   case editCut:        DoCut();                                        break;   case editCopy:       DoCopy();                                       break;   case editPaste:      DoPaste();                                      break;   case editClear:      DoClear();                                      break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();#undef menuID}/***************************************************************** Savage** Run the Savage benchmark****************************************************************/void Savage (void){#define wrNum 1002                      /* window resource number */CtlRecHndl ctlThermo;                   /* thermometer control handle */unsigned i;                             /* loop variable */float sum;                              /* savage sum */GrafPortPtr wPtr;                       /* alert GrafPort */wPtr = NewWindow2("\p ", 0, DrawContents2, NULL, 0x02, wrNum, rWindParam1);if (toolerror() == 0) {   DrawControls(wPtr);   ctlThermo = GetCtlHandleFromID(wPtr, ctlThermometer);   sum = 1.0;   for (i = 1; i <= 250; ++i) {      SetCtlValue(i, ctlThermo);      sum = tan(atan(exp(log(sqrt(sum*sum)))))+1.0;      }   CloseWindow(wPtr);   }}/***************************************************************** ColorLeft** Switch the color radio button left****************************************************************/void ColorLeft (void){if (GetCtlValue(GetCtlHandleFromID(wPtr, ctlBoxRed)) != 0) {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxBlue));   boxColor = 4;   }else if (GetCtlValue(GetCtlHandleFromID(wPtr, ctlBoxGreen)) != 0) {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxRed));   boxColor = 7;   }else {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxGreen));   boxColor = 10;   }ForceUpdate(boxRect);}/***************************************************************** ColorRight** Switch the color radio button right****************************************************************/void ColorRight (void){if (GetCtlValue(GetCtlHandleFromID(wPtr, ctlBoxGreen)) != 0) {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxBlue));   boxColor = 4;   }else if (GetCtlValue(GetCtlHandleFromID(wPtr, ctlBoxBlue)) != 0) {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxRed));   boxColor = 7;   }else {   SetCtlValue(1, GetCtlHandleFromID(wPtr, ctlBoxGreen));   boxColor = 10;   }ForceUpdate(boxRect);}/***************************************************************** PopUpColor** Set the pop-up box color based on the control value****************************************************************/void PopUpColor (void){switch (GetCtlValue(GetCtlHandleFromID(wPtr, ctlPop))-cbase-ctlPop) {   case 1: boxColor2 = 7;       break;   case 2: boxColor2 = 10;      break;   case 3: boxColor2 = 4;       break;   }ForceUpdate(boxRect2);}/***************************************************************** HandleControl** Take action after a control has been selected****************************************************************/void HandleControl (void){if ((myEvent.wmTaskData4 & 0xFFFF8000) == 0)   switch (myEvent.wmTaskData4) {      case ctlBeepOnce:         if (soundOn)            SysBeep();         break;      case ctlBeepTwice:         if (soundOn) {            SysBeep();            SysBeep();            }         break;      case ctlBoxRed:           boxColor = 7; ForceUpdate(boxRect);     break;      case ctlBoxGreen:         boxColor = 10; ForceUpdate(boxRect);    break;      case ctlBoxBlue:          boxColor = 4; ForceUpdate(boxRect);     break;      case ctlSound:            soundOn = !soundOn;                     break;      case ctlSavage:           Savage();                               break;      case ctlLeft:             ColorLeft();                            break;      case ctlRight:            ColorRight();                           break;      case ctlPop:              PopUpColor();                           break;      }}/***************************************************************** InitGLobals** Initialize the global variables****************************************************************/void InitGlobals (void){boxColor = 7;                           /* red box */soundOn = TRUE;                         /* the sound is on */SetColorEntry(0, mixColor, 0);          /* color mixer box is black */boxColor2 = 7;                          /* red box */}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */Ref startStopParm;                      /* tool start/shutdown parameter */startStopParm =                         /* start up the tools */   StartUpTools(userid(), 2, 1);if (toolerror() != 0)   SysFailMgr(toolerror(), "\pCould not start tools: ");InitMenus();                            /* set up the menu bar */InitGlobals();                          /* initialize our global variables */InitWindow();                           /* set up the program window */InitCursor();                           /* start the arrow cursor */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();                   break;      case wInControl:          HandleControl();                break;      }   }ShutDownTools(1, startStopParm);        /* shut down the tools */}