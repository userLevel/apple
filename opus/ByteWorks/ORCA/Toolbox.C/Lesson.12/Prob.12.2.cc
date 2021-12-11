/***************************************************************** Scrapbook** Implements a scrap book.****************************************************************/#pragma lint -1#include <stdlib.h>#include <stdio.h>#include <string.h>#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#include <Resources.h>#include <Locator.h>#include <MiscTool.h>#include <Memory.h>#include <QDAux.h>#include <Scrap.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define moveMenu        4#define appleAbout      257#define fileClose       255#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254#define moveLast        260#define moveNext        261typedef struct scrapItemStruct {        /* scrap item structure */   struct scrapItemStruct *next;        /* next scrap type entry */   unsigned scrapType;                  /* scrap type */   unsigned long scrapLength;           /* scrap length */   Handle scrap;                        /* scrap contents */   } scrapItemStruct;typedef scrapItemStruct *scrapItemPtr;  /* scrap item pointer */typedef struct scrapStruct {            /* scrap structure */   struct scrapStruct *next, *last;     /* last, next scrap structure */   scrapItemPtr scrap;                  /* points to first scrap type entry */   } scrapStruct;typedef scrapStruct *scrapPtr;          /* scrap pointer */BOOLEAN done;                           /* are we done, yet? */EventRecord myEvent;                    /* event record */GrafPortPtr wPtr;                       /* window pointer */scrapPtr scraps;                        /* head of scrap list */scrapPtr frontScrap;                    /* scrap being displayed *//***************************************************************** GetString** Get a string from the resource fork** Parameters:*    resourceID - resource ID of the rCString resource** Returns: pointer to the string; NULL for an error** Notes: The string is in a locked resource handle.  The caller*    should call FreeString when the string is no longer needed.*    Failure to do so is not catastrophic; the memory will be*    deallocated when the program is shut down.****************************************************************/char *GetString (int resourceID){Handle hndl;                            /* resource handle */hndl = LoadResource(rCString, resourceID);if (toolerror() == 0) {   HLock(hndl);   return (char *) (*hndl);   }return NULL;}/***************************************************************** Free a resource string** Parameters:*    resourceID - resource ID of the rCString to free****************************************************************/void FreeString (int resourceID){ReleaseResource(-3, rCString, resourceID);}/***************************************************************** FlagError** Flag an error** Parameters:*    error - error message number*    tError - toolbox error code; 0 if none****************************************************************/void FlagError (int error, int tError){#define errorAlert 2000                 /* alert resource ID */#define errorBase 2000                  /* base resource ID for fortunes */char *substArray;                       /* substitution "array" */char *errorString;                      /* pointer to the error string */                                        /* form the error string */errorString = GetString(errorBase + error);substArray = NULL;if (errorString != NULL) {   substArray = malloc(strlen(substArray)+9);   if (substArray != NULL)      strcpy(substArray, errorString);   FreeString(errorBase + error);   }if (substArray != NULL) {   if (tError != 0)                     /* add the tool error number */      sprintf(&substArray[strlen(substArray)], " ($%04X)", tError);                                        /* show the alert */   AlertWindow(awCString+awResource, (Pointer) &substArray, errorAlert);   free(substArray);   }#undef errorAlert#undef errorBase}/***************************************************************** ReadScrap** Read a scrap from the file** Parameters:*    f - file to read from*    count - number of scrap types** Returns: TRUE if an error occurred, else FALSE****************************************************************/BOOLEAN ReadScrap (FILE *f, int count){BOOLEAN error = FALSE;                  /* did an error occur? */scrapItemPtr iPtr;                      /* pointer to the scrap type being added */scrapPtr sPtr;                          /* pointer to the scrap being pasted */unsigned long length;                   /* length of the scrap */sPtr = malloc(sizeof(scrapStruct));     /* set up a scrap record */if (sPtr != NULL) {   sPtr->last = NULL;   sPtr->next = NULL;   sPtr->scrap = NULL;   do {                                 /* loop over all scrap types */      iPtr = malloc(sizeof(scrapItemStruct)); /* save a scrap type */      if (iPtr != NULL) {         fread(&iPtr->scrapType, sizeof(int), 1, f);         fread(&length, sizeof(long), 1, f);         iPtr->scrapLength = length;         iPtr->scrap = NewHandle(length, userid(), 0x8000, NULL);         if (iPtr->scrap == NULL) {            FlagError(2, toolerror());            error = TRUE;            free(iPtr);            }         else {            fread(*(iPtr->scrap), length, 1, f);            HUnlock(iPtr->scrap);            iPtr->next = sPtr->scrap;            sPtr->scrap = iPtr;            }         }      else {         FlagError(2, 0);         error = TRUE;         }      --count;      }   while ((count != 0) && (!error));   if (sPtr->scrap != NULL) {      if (frontScrap == NULL)           /* place the scrap in the buffer */         scraps = sPtr;      else {         sPtr->last = frontScrap;         frontScrap->next = sPtr;         }      frontScrap = sPtr;      }   else      free(sPtr);   }else {   FlagError(2, 0);   error = TRUE;   }return error;}/***************************************************************** LoadScrapFile** Load the scrapbook file****************************************************************/void LoadScrapFile (void){unsigned count;                         /* # scrap types in the scrap */BOOLEAN done;                           /* loop termination test */FILE *f;                                /* scrap file variable */scraps = NULL;                          /* nothing in the scrap list */f = fopen("ScrapBook", "r");            /* open the scrap file */frontScrap = NULL;                      /* read the scraps */if (f != NULL) {   done = FALSE;   while (!done) {      fread(&count, sizeof(int), 1, f);      if (count == 0)         done = TRUE;      else         done = ReadScrap(f, count);      }   fclose(f);   }frontScrap = scraps;                    /* display the first scrap */}/***************************************************************** CountScraps** Count the number of scrap types** Parameters:*    iPtr - scrap type list** Returns: number of types in the scrap list****************************************************************/unsigned int CountScraps (scrapItemPtr iPtr){int count;                              /* number of scrap types */count = 0;while (iPtr != NULL) {   iPtr = iPtr->next;   ++count;   }return count;}/***************************************************************** WriteScrap** Write a scrap item to the file** Parameters:*    f - file to write to*    iPtr - scrap to write****************************************************************/void WriteScrap (FILE *f, scrapItemPtr iPtr){unsigned long length;                   /* length of the scrap */fwrite(&iPtr->scrapType, sizeof(int), 1, f);fwrite(&iPtr->scrapLength, sizeof(long), 1, f);HLock(iPtr->scrap);fwrite(*(iPtr->scrap), iPtr->scrapLength, 1, f);HUnlock(iPtr->scrap);}/***************************************************************** SaveScrapFile** Save the scrapbook file****************************************************************/void SaveScrapFile (void){FILE *f;                                /* scrap file variable */scrapItemPtr iPtr;                      /* pointer to the scrap type being saved */scrapPtr sPtr;                          /* pointer to the scrap being saved */unsigned count;                         /* number of scraps */f = fopen("ScrapBook", "wb");sPtr = scraps;while (sPtr != NULL) {   count = CountScraps(sPtr->scrap);   fwrite(&count, sizeof(int), 1, f);   iPtr = sPtr->scrap;   while (iPtr != NULL) {      WriteScrap(f, iPtr);      iPtr = iPtr->next;      }   sPtr = sPtr->next;   }count = 0;fwrite(&count, sizeof(int), 1, f);}/***************************************************************** DrawNoScrap** Draw a message saying there are no scraps****************************************************************/void DrawNoScrap (void){MoveTo(10, 50);DrawCString("The scrapbook is empty");}/***************************************************************** DrawNoScrapType** Draw a message saying there are no useable scrap types****************************************************************/void DrawNoScrapType (void){MoveTo(10, 50);DrawCString("(No text or picture scrap)");}/***************************************************************** DrawTextScrap** Draw a text scrap** Parameters:*    iPtr - pointer to scrap to draw****************************************************************/void DrawTextScrap (scrapItemPtr iPtr){char *tPtr;                             /* pointer to the next character */FontInfoRecord info;                    /* info about the font */Long left;                              /* # characters left to print */Rect r;                                 /* window rectangle */unsigned v;                             /* base line position */char *cPtr;                             /* next character */unsigned len, len2;                     /* length of characters to print */GetFontInfo(&info);GetPortRect(&r);v = info.ascent + info.leading;HLock(iPtr->scrap);tPtr = *(iPtr->scrap);left = iPtr->scrapLength;while ((v + info.descent) < (r.v2 - r.v1)) {   MoveTo(10, v);   if (left > 0) {      if (*tPtr == '\r')         ++tPtr;      else {         len = 1;         cPtr = tPtr+1;         while ((TextWidth(tPtr, len) < (r.h2 - r.h1 - 20))            && (len < left)            && (*cPtr != '\r')) {            ++len;            ++cPtr;            }         if ((*cPtr != '\r') && (len != left)) {            len2 = len-1;            --cPtr;            while ((*cPtr != ' ') && (len2 != 0)) {               --len2;               --cPtr;               }            if (len2 != 0)               len = len2;            }         DrawText(tPtr, len);         left = left - len;         tPtr = tPtr + len;         if (*tPtr == '\r')            ++tPtr;         }      }   v = v + info.ascent + info.leading + info.descent;   }HUnlock(iPtr->scrap);}/***************************************************************** DrawPictureScrap** Draw a picture scrap** Parameters:*    iPtr - pointer to scrap to draw****************************************************************/void DrawPictureScrap (scrapItemPtr iPtr){Rect r;                                 /* our port rectangle */GetPortRect(&r);DrawPicture(iPtr->scrap, &r);}/***************************************************************** FindScrap** Find the scrap entry for a particular scrap type** Parameters:*    iPtr - points to the first scrap to check*    scrapType - scrap type to find** Returns: pointer to scrap type, NULL for none****************************************************************/scrapItemPtr FindScrap (scrapItemPtr iPtr, unsigned scrapType){BOOLEAN done;                           /* for loop termination test */done = FALSE;do {   if (iPtr == NULL)      done = TRUE;   else if (iPtr->scrapType == scrapType)      done = TRUE;   else      iPtr = iPtr->next;   }while (!done);return iPtr;}/***************************************************************** DrawContents** Draw the contents of the active port****************************************************************/#pragma databank 1void DrawContents (void){scrapItemPtr iPtr;                      /* pointer to a scrap type entry */if (frontScrap != NULL) {   iPtr = FindScrap(frontScrap->scrap, 1);   if (iPtr != NULL)      DrawPictureScrap(iPtr);   else {      iPtr = FindScrap(frontScrap->scrap, 0);      if (iPtr != NULL)         DrawTextScrap(iPtr);      else         DrawNoScrapType();      }   }else   DrawNoScrap();}#pragma databank 0/***************************************************************** DoAbout** Draw our about box****************************************************************/void DoAbout (void){#define alertID 1                       /* alert string resource ID */AlertWindow(awCString+awResource, NULL, alertID);#undef alertID}/***************************************************************** DoClear** Clear the current scrap from the scrapbook****************************************************************/void DoClear (void){scrapItemPtr iPtr;                      /* pointer to the scrap type being removed */GrafPortPtr port;                       /* caller's GrafPort */Rect r;                                 /* our port rect */scrapPtr sPtr;                          /* pointer to the scrap being removed */if (frontScrap != NULL) {   sPtr = frontScrap;                   /* remove the scrap from the list */   if (sPtr->last == NULL)      scraps = sPtr->next;   else      sPtr->last->next = sPtr->next;   if (sPtr->next != NULL)      sPtr->next->last = sPtr->last;   if (sPtr->next != NULL)              /* set up the new front scrap */      frontScrap = sPtr->next;   else      frontScrap = sPtr->last;   port = GetPort();                    /* force an update */   SetPort(wPtr);   GetPortRect(&r);   EraseRect(&r);   InvalRect(&r);   SetPort(port);   while (sPtr->scrap != NULL) {        /* dispose of the scrap items */      iPtr = sPtr->scrap;      sPtr->scrap = iPtr->next;      DisposeHandle(iPtr->scrap);      free(iPtr);      }   free(sPtr);                          /* dispose of the scrap record */   }}/***************************************************************** DoCopy** Copy the current scrap from the scrapbook****************************************************************/void DoCopy (void){scrapItemPtr iPtr;                      /* pointer to the scrap type being copied */if (frontScrap != NULL) {   ZeroScrap();                         /* dump the current scrap */   iPtr = frontScrap->scrap;            /* spool through the scrap types */   while (iPtr != NULL) {      HLock(iPtr->scrap);               /* copy one scrap type */      PutScrap(iPtr->scrapLength, iPtr->scrapType, *(iPtr->scrap));      HUnlock(iPtr->scrap);      iPtr = iPtr->next;      }   }}/***************************************************************** DoCut** Cut the current scrap from the scrapbook****************************************************************/void DoCut (void){DoCopy();DoClear();}/***************************************************************** DoLast** Move to the previous scrap****************************************************************/void DoLast (void){GrafPortPtr port;                       /* caller's GrafPort */Rect r;                                 /* our port rect */if (frontScrap != NULL)   if (frontScrap->last != NULL) {      frontScrap = frontScrap->last;    /* move to the previous scrap */      port = GetPort();                 /* force an update */      SetPort(wPtr);      GetPortRect(&r);      EraseRect(&r);      InvalRect(&r);      SetPort(port);      }}/***************************************************************** DoNext** Move to the next scrap****************************************************************/void DoNext (void){GrafPortPtr port;                       /* caller's GrafPort */Rect r;                                 /* our port rect */if (frontScrap != NULL)   if (frontScrap->next != NULL) {      frontScrap = frontScrap->next;    /* move to the previous scrap */      port = GetPort();                 /* force an update */      SetPort(wPtr);      GetPortRect(&r);      EraseRect(&r);      InvalRect(&r);      SetPort(port);      }}/***************************************************************** DoPaste** Paste a new scrap into the scrapbook****************************************************************/void DoPaste (void){char *p1, *p2;                          /* used to copy a handle */GrafPortPtr port;                       /* caller's GrafPort */Rect r;                                 /* our port rect */scrapInfo scrap;                        /* scrap buffer */scrapItemPtr iPtr;                      /* pointer to the scrap type being added */scrapPtr sPtr;                          /* pointer to the scrap being pasted */unsigned index;                         /* scrap index */sPtr = malloc(sizeof(scrapStruct));     /* set up a scrap record */if (sPtr != NULL) {   sPtr->last = NULL;   sPtr->next = NULL;   sPtr->scrap = NULL;   index = 1;                           /* loop over all scrap types */   do {      GetIndScrap(index, (Ptr) &scrap);      if (toolerror() == 0) {         ++index;         iPtr = malloc(sizeof(scrapItemStruct)); /* save a scrap type */         if (iPtr != NULL) {            iPtr->scrap = NewHandle(scrap.scrapSize, userid(), 0x8000, NULL);            if (iPtr->scrap == NULL) {               FlagError(2, toolerror());               free(iPtr);               }            else {               iPtr->scrapLength = scrap.scrapSize;               iPtr->scrapType = scrap.scrapType;               HLock(scrap.scrapHandle);               p1 = *(iPtr->scrap);               p2 = *(scrap.scrapHandle);               while (scrap.scrapSize != 0) {                  *p1 = *p2;                  ++p1;                  ++p2;                  --scrap.scrapSize;                  }               HUnlock(scrap.scrapHandle);               HUnlock(iPtr->scrap);               iPtr->next = sPtr->scrap;               sPtr->scrap = iPtr;               }            }         else            FlagError(2, 0);         }      }   while (toolerror() == 0);   if (sPtr->scrap != NULL) {      if (frontScrap == NULL) {         /* place the scrap in the buffer */         scraps = sPtr;         frontScrap = sPtr;         }      else {         sPtr->next = frontScrap->next;         if (sPtr->next != NULL)            sPtr->next->last = sPtr;         sPtr->last = frontScrap;         frontScrap->next = sPtr;         frontScrap = sPtr;         }      port = GetPort();                 /* force an update */      SetPort(wPtr);      GetPortRect(&r);      EraseRect(&r);      InvalRect(&r);      SetPort(port);      }   else      free(sPtr);   }else   FlagError(2, 0);}/***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:     DoAbout();                                      break;   case fileClose:      done = TRUE;                                    break;   case fileQuit:       done = TRUE;                                    break;   case editUndo:                                                       break;   case editCut:        DoCut();                                        break;   case editCopy:       DoCopy();                                       break;   case editPaste:      DoPaste();                                      break;   case editClear:      DoClear();                                      break;   case moveLast:       DoLast();                                       break;   case moveNext:       DoNext();                                       break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();#undef menuID}/***************************************************************** InitWindows** Set up the program window****************************************************************/void InitWindow (void){#define wrNum 1001                      /* window resource number */wPtr = NewWindow2("\p  ScrapBook 1.0  ", 0, DrawContents, NULL, 0x02, wrNum, rWindParam1);#undef wrNum}/***************************************************************** CheckMenus** Check the menus to see if they should be dimmed****************************************************************/void CheckMenus (void){if (frontScrap == NULL) {   DisableMItem(moveLast);   DisableMItem(moveNext);   }else {   if (frontScrap->last == NULL)      DisableMItem(moveLast);   else      EnableMItem(moveLast);   if (frontScrap->next == NULL)      DisableMItem(moveNext);   else      EnableMItem(moveNext);   }}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */Ref startStopParm;                      /* tool start/shutdown parameter */startStopParm =                         /* start up the tools */   StartUpTools(userid(), 2, 1);if (toolerror() != 0)   SysFailMgr(toolerror(), "\pCould not start tools: ");InitMenus();                            /* set up the menu bar */InitWindow();                           /* set up the program window */LoadScrap();                            /* load the current scrap */LoadScrapFile();                        /* load the scrap file */InitCursor();                           /* start the arrow cursor */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   CheckMenus();   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();                                break;      case wInGoAway:           done = TRUE;      }   }UnloadScrap();                          /* save the current scrap */SaveScrapFile();                        /* save the scrap file */ShutDownTools(1, startStopParm);        /* shut down the tools */}