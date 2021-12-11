/***************************************************************** Frame** This is a frame for other programs.  It contains a basic* event loop, a menu bar, an about box, and supports NDAs.* It also supports multiple windows via a document record.****************************************************************/#pragma lint -1#include <stdlib.h>#include <string.h>#include <stdio.h>#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#include <Resources.h>#include <Memory.h>#include <StdFile.h>#include <Locator.h>#include <MiscTool.h>#include <Print.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define appleAbout      257#define fileNew         260#define fileOpen        261#define fileClose       255#define fileSave        262#define fileSaveAs      263#define filePageSetup   264#define filePrint       265#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254#define maxName 80                      /* max length of a window title */typedef struct documentStruct {         /* information about our document */   struct documentStruct *next;         /* next document */   GrafPortPtr wPtr;                    /* window pointer */   char wName[maxName+1];               /* window name */   BOOLEAN onDisk;                      /* does the file exist on disk? */   Handle fileName;                     /* file name handle or NULL */   Handle pathName;                     /* full path name handle or NULL */   PrRecHndl prHandle;                  /* print record */   } documentStruct;typedef documentStruct *documentPtr;    /* document pointer */BOOLEAN done;                           /* are we done, yet? */documentPtr documents;                  /* our documents */int untitledNum;                        /* number for the next untitled window */EventRecord myEvent;                    /* event record *//***************************************************************** GetString** Get a string from the resource fork** Parameters:*    resourceID - resource ID of the rCString resource** Returns: pointer to the string; NULL for an error** Notes: The string is in a locked resource handle.  The caller*    should call FreeString when the string is no longer needed.*    Failure to do so is not catastrophic; the memory will be*    deallocated when the program is shut down.****************************************************************/char *GetString (int resourceID){Handle hndl;                            /* resource handle */hndl = LoadResource(rCString, resourceID);if (toolerror() == 0) {   HLock(hndl);   return (char *) (*hndl);   }return NULL;}/***************************************************************** Free a resource string** Parameters:*    resourceID - resource ID of the rCString to free****************************************************************/void FreeString (int resourceID){ReleaseResource(-3, rCString, resourceID);}/***************************************************************** FlagError** Flag an error** Parameters:*    error - error message number*    tError - toolbox error code; 0 if none****************************************************************/void FlagError (int error, int tError){#define errorAlert 2000                 /* alert resource ID */#define errorBase 2000                  /* base resource ID for fortunes */char *substArray;                       /* substitution "array" */char *errorString;                      /* pointer to the error string */                                        /* form the error string */errorString = GetString(errorBase + error);substArray = NULL;if (errorString != NULL) {   substArray = malloc(strlen(substArray)+9);   if (substArray != NULL)      strcpy(substArray, errorString);   FreeString(errorBase + error);   }if (substArray != NULL) {   if (tError != 0)                     /* add the tool error number */      sprintf(&substArray[strlen(substArray)], " ($%04X)", tError);                                        /* show the alert */   AlertWindow(awCString+awResource, (Pointer) &substArray, errorAlert);   free(substArray);   }#undef errorAlert#undef errorBase}/***************************************************************** DrawContents** Draw the contents of the active port****************************************************************/#pragma databank 1void DrawContents (void){PenNormal();                            /* use a "normal" pen */}#pragma databank 0/***************************************************************** LoadDocument** Load a document file from disk** Parameters:*    dPtr - pointer to the document to load** Returns: TRUE if successful, else FALSE****************************************************************/BOOLEAN LoadDocument (documentPtr dPtr){return TRUE;}/***************************************************************** SaveDocument** Save a document file to disk** Parameters:*    dPtr - pointer to the document to save****************************************************************/void SaveDocument (documentPtr dPtr){}/***************************************************************** GetPageCount** Get the size of the document in pages** Parameters:*    dPtr - document to get the size of*    h, v - (returned) pointers to size in pages****************************************************************/void GetPageCount (documentPtr dPtr, unsigned *h, unsigned *v){*h = 1;*v = 1;}/***************************************************************** PrintDocument** Do the actual printing of the document** Parameters:*    dPtr - document to print****************************************************************/void PrintDocument (documentPtr dPtr){unsigned h, v;                          /* size of document in pages */unsigned x, y;                          /* page loop counters */PrStatusRec status;                     /* printer status */GrafPortPtr prPort;                     /* printer's GrafPort *//* get ready to print */prPort = PrOpenDoc(dPtr->prHandle, NULL);if (toolerror() != 0) {   FlagError(6, toolerror());   return;   }GetPageCount(dPtr, &h, &v);/* main print loop */for (x = 1; x <= h; ++x)   for (y = 1; y <= v; ++y) {      PrOpenPage(prPort, NULL);      if (toolerror() != 0)         FlagError(6, toolerror());      else {         /* print here */         PenNormal();         MoveTo(10, 10); LineTo(100, 100);         MoveTo(10, 100); LineTo(100, 10);         /* done printing */         PrClosePage(prPort);         }      }PrCloseDoc(prPort);/* spooling loop */if (PrError() == 0)   PrPicFile(dPtr->prHandle, NULL, &status);}/***************************************************************** CloseDocument** Close a document and its associated window** Parameters:*    dPtr - pointer to the document to close; may be NULL****************************************************************/void CloseDocument (documentPtr dPtr){documentPtr lPtr;                       /* pointer to the previous document */if (dPtr != NULL) {   CloseWindow(dPtr->wPtr);             /* close the window */   if (documents == dPtr)               /* remove dPtr from the list when... */      documents = dPtr->next;           /* ...dPtr is the first document */   else {                               /* ...dPtr is not the first document */      lPtr = documents;      while (lPtr->next != dPtr)         lPtr = lPtr->next;      lPtr->next = dPtr->next;      }   if (dPtr->fileName != NULL)          /* dispose of the name buffers */      DisposeHandle(dPtr->fileName);   if (dPtr->pathName != NULL)      DisposeHandle(dPtr->pathName);   if (dPtr->prHandle != NULL)          /* dispose of the print record */      DisposeHandle((Handle) dPtr->prHandle);   free(dPtr);                          /* dispose of the document record */   }}/***************************************************************** FindDocument** Find the document for wPtr** Parameters:*    wPtr  pointer to the window for which to find a document** Returns: Document pointer; NULL if there isn't one****************************************************************/documentPtr FindDocument (GrafPortPtr wPtr){BOOLEAN done;                           /* used to test for loop termination */documentPtr dPtr;                       /* used to trace the document list */dPtr = documents;done = dPtr == NULL;while (!done)   if (dPtr->wPtr == wPtr)      done = TRUE;   else {      dPtr = dPtr->next;      done = dPtr == NULL;      }return dPtr;}/***************************************************************** GetUntitledName** Create a name for an untitled window** Returns: Pointer to the new window name****************************************************************/char *GetUntitledName (void){#define untitled 101                    /* Resource number for "Untitled " */static char name[maxName];              /* window name */char *sPtr;                             /* pointer to the resource string */documentPtr dPtr;                       /* used to trace the document list */int number;                             /* new value for untitledNum */dPtr = documents;                       /* if there are no untitled          */number = 1;                             /*  documents then reset untitledNum */while (dPtr != NULL)   if (!dPtr->onDisk) {      number = untitledNum;      dPtr = NULL;      }   else      dPtr = dPtr->next;untitledNum = number;strcpy(name, "  ");                     /* pad on the left with spaces */sPtr = GetString(untitled);             /* set the base name */if (sPtr == NULL)   strcat(name, "Untitled ");else {   strncat(name, sPtr, maxName-10);   FreeString(untitled);   }                                        /* add the untitled number */sprintf(&name[strlen(name)], "%d", untitledNum);strcat(name, "  ");                     /* pad on the right with spaces */++untitledNum;                          /* update untitledNum */return name;                            /* return the name */}/***************************************************************** NewDocument** Open a new window, returning the pointer** Parameters:*    wName - name for the new window** Returns: Document pointer; NULL for an error****************************************************************/documentPtr NewDocument (char *wName){#define wrNum 1001                      /* window resource number */documentPtr dPtr;                       /* new document pointer */dPtr = malloc(sizeof(documentStruct)); /* allocate the record */if (dPtr != NULL) {   dPtr->onDisk = FALSE;                /* not on disk */   dPtr->wName[0] = strlen(wName);      /* set up the name */   strncpy(&dPtr->wName[1], wName, maxName);   dPtr->fileName = NULL;               /* no file name handle */   dPtr->pathName = NULL;               /* no path name handle */   dPtr->wPtr =                         /* open the window */      NewWindow2(dPtr->wName, 0, DrawContents, NULL, 0x02, wrNum, rWindParam1);   if (dPtr->wPtr == NULL) {      FlagError(1, toolerror());        /* handle a window error */      free(dPtr);      dPtr = NULL;      }   else {      dPtr->next = documents;           /* put the document in the list */      documents = dPtr;                                        /* allocate a print record */      dPtr->prHandle = (PrRecHndl) NewHandle(140, userid(), 0, NULL);      if (dPtr->prHandle != NULL) {         PrDefault(dPtr->prHandle);         if (toolerror() != 0) {            DisposeHandle((Handle) dPtr->prHandle);            dPtr->prHandle = NULL;            }         }      }   }else   FlagError(2, 0);                     /* handle an out of memory error */return dPtr;#undef wrNum}/***************************************************************** DoAbout** Draw our about box****************************************************************/void DoAbout (void){#define alertID 1                       /* alert string resource ID */AlertWindow(awCString+awResource, NULL, alertID);#undef alertID}/***************************************************************** DoNew** Open a new document window****************************************************************/void DoNew (void){NewDocument(GetUntitledName());}/***************************************************************** DoOpen** Open a file****************************************************************/void DoOpen (void){#define posX 80                         /* X position of the dialog */#define posY 50                         /* Y position of the dialog */#define titleID 102                     /* prompt string resource ID */documentPtr dPtr;                       /* pointer to the new document */SFTypeList2 fileTypes;                  /* list of valid file types */Handle gsosNameHandle;                  /* handle of the file name */ResultBuf255Ptr gsosNamePtr;            /* pointer to the GS/OS file name */int i;                                  /* loop/index variable */int len;                                /* GS/OS name length */char name[maxName];                     /* new document name */SFReplyRec2 reply;                      /* reply record */fileTypes.numEntries = 2;               /* set up the allowed file types */fileTypes.fileTypeEntries[0].flags = 0x8000;fileTypes.fileTypeEntries[0].fileType = 0xB0;fileTypes.fileTypeEntries[1].flags = 0x8000;fileTypes.fileTypeEntries[1].fileType = 0x04;reply.nameRefDesc = 3;                  /* get the file to open */reply.pathRefDesc = 3;SFGetFile2(posX, posY, refIsResource, titleID, NULL, &fileTypes, &reply);if (toolerror() != 0)   FlagError(3, toolerror());           /* handle an error */else if (reply.good) {                  /* form the file name */   gsosNameHandle = (Handle) reply.nameRef;   HLock(gsosNameHandle);   gsosNamePtr = (ResultBuf255Ptr) (*gsosNameHandle);   strcpy(name, "  ");   len = gsosNamePtr->bufString.length;   if (len > maxName-5)      len = maxName-5;   for (i = 0; i < len; ++i)      name[2+i] = gsosNamePtr->bufString.text[i];   name[2+i] = (char) 0;   strcat(name, "  ");   HUnlock(gsosNameHandle);   dPtr = NewDocument(name);            /* get a document record */   if (dPtr == NULL) {                  /* in case of error, dispose of the names */      DisposeHandle((Handle) reply.nameRef);      DisposeHandle((Handle) reply.pathRef);      }   else {                               /* otherwise save the names */      dPtr->fileName = (Handle) reply.nameRef;      dPtr->pathName = (Handle) reply.pathRef;      if (LoadDocument(dPtr))           /* read the file */         dPtr->onDisk = TRUE;           /* file is on disk */      else                              /* handle a read error */         CloseDocument(dPtr);      }   }#undef posX#undef posY#undef titleID}/***************************************************************** DoSaveAs** Save a document to a new name****************************************************************/void DoSaveAs (void){#define posX 80                         /* X position of the dialog */#define posY 50                         /* Y position of the dialog */#define titleID 103                     /* prompt string resource ID */documentPtr dPtr;                       /* document to save */int dummyName;                          /* used for a null file name prompt */Handle gsosNameHandle;                  /* handle of the file name */ResultBuf255Ptr gsosNamePtr;            /* pointer to the GS/OS file name */int i;                                  /* loop/index variable */int len;                                /* GS/OS name length */SFReplyRec2 reply;                      /* reply record */dPtr = FindDocument(FrontWindow());if (dPtr != NULL) {   reply.nameRefDesc = 3;               /* get the new file name */   reply.pathRefDesc = 3;   if (dPtr->fileName == NULL) {      dummyName = 0;      SFPutFile2(posX, posY, refIsResource, (Ref) titleID, refIsPointer,         (Ref) &dummyName, &reply);      }   else      SFPutFile2(posX, posY, refIsResource, titleID, refIsPointer,         (Ref) (((long) (*dPtr->fileName)) + 2), &reply);   if (toolerror() != 0)      FlagError(3, toolerror());        /* handle an error */   else if (reply.good) {                                        /* form the new window name */      gsosNameHandle = (Handle) reply.nameRef;      HLock(gsosNameHandle);      gsosNamePtr = (ResultBuf255Ptr) (*gsosNameHandle);      strcpy(dPtr->wName, "   ");      len = gsosNamePtr->bufString.length;      if (len > maxName-6)         len = maxName-6;      for (i = 0; i < len; ++i)         dPtr->wName[2+i] = gsosNamePtr->bufString.text[i];      dPtr->wName[2+i] = (char) 0;      strcat(dPtr->wName, "  ");      dPtr->wName[0] = (char) (strlen(dPtr->wName)-1);      HUnlock(gsosNameHandle);      SetWTitle(dPtr->wName, dPtr->wPtr);                                        /* save the names */      dPtr->fileName = (Handle) reply.nameRef;      dPtr->pathName = (Handle) reply.pathRef;      dPtr->onDisk = TRUE;              /* file is on disk */      SaveDocument(dPtr);               /* save the file */      }   }#undef posX#undef posY#undef titleID}/***************************************************************** DoSave** Save a document to the existing disk file****************************************************************/void DoSave (void){documentPtr dPtr;                       /* document to save */dPtr = FindDocument(FrontWindow());if (dPtr != NULL)   if (dPtr->onDisk)      SaveDocument(dPtr);   else      DoSaveAs();}/***************************************************************** DoPageSetup** Set up the printer options****************************************************************/void DoPageSetup (void){documentPtr dPtr;                       /* document to save */dPtr = FindDocument(FrontWindow());     /* get the document */if (dPtr == NULL)   return;if (dPtr->prHandle == NULL) {           /* make sure there is a print record */   dPtr->prHandle = (PrRecHndl) NewHandle(140, userid(), 0, NULL);   if (dPtr->prHandle == NULL) {      FlagError(6, toolerror());      return;      }   PrDefault(dPtr->prHandle);   if (toolerror() != 0) {      FlagError(6, toolerror());      DisposeHandle((Handle) dPtr->prHandle);      dPtr->prHandle = NULL;      }   }if (dPtr->prHandle != NULL)             /* update the print record */   PrStlDialog(dPtr->prHandle);}/***************************************************************** DoPrint** Print the document****************************************************************/void DoPrint (void){documentPtr dPtr;                       /* document to save */dPtr = FindDocument(FrontWindow());     /* get the document */if (dPtr == NULL)   return;if (dPtr->prHandle == NULL) {           /* make sure there is a print record */   dPtr->prHandle = (PrRecHndl) NewHandle(140, userid(), 0, NULL);   if (dPtr->prHandle == NULL) {      FlagError(6, toolerror());      return;      }   PrDefault(dPtr->prHandle);   if (toolerror() != 0) {      FlagError(6, toolerror());      DisposeHandle((Handle) dPtr->prHandle);      dPtr->prHandle = NULL;      }   }if (dPtr->prHandle != NULL)             /* print the document */   if (PrJobDialog(dPtr->prHandle))      PrintDocument(dPtr);}/***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:     DoAbout();                                      break;   case fileNew:        DoNew();                                        break;   case fileOpen:       DoOpen();                                       break;   case fileClose:      CloseDocument(FindDocument(FrontWindow()));     break;   case fileSave:       DoSave();                                       break;   case fileSaveAs:     DoSaveAs();                                     break;   case filePageSetup:  DoPageSetup();                                  break;   case filePrint:      DoPrint();                                      break;   case fileQuit:       done = TRUE;                                    break;   case editUndo:                                                       break;   case editCut:                                                        break;   case editCopy:                                                       break;   case editPaste:                                                      break;   case editClear:                                                      break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();#undef menuID}/***************************************************************** CheckMenus** Check the menus to see if they should be dimmed****************************************************************/void CheckMenus (void){if (documents == NULL) {   DisableMItem(filePageSetup);   DisableMItem(filePrint);   }else {   EnableMItem(filePageSetup);   EnableMItem(filePrint);   }}/***************************************************************** InitGlobals** Initialize the global variables****************************************************************/void InitGlobals (void){documents = NULL;}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */Ref startStopParm;                      /* tool start/shutdown parameter */startStopParm =                         /* start up the tools */   StartUpTools(userid(), 2, 1);if (toolerror() != 0)   SysFailMgr(toolerror(), "\pCould not start tools: ");InitMenus();                            /* set up the menu bar */InitCursor();                           /* start the arrow cursor */InitGlobals();                          /* initialize our global variables */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   CheckMenus();   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();                                break;      case wInGoAway:           CloseDocument(FindDocument(                                   (GrafPortPtr) myEvent.wmTaskData));                                break;      }   }ShutDownTools(1, startStopParm);        /* shut down the tools */}