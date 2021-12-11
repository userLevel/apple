/***************************************************************** Frame** This is a frame for other programs.  It contains a basic* event loop, a menu bar, an about box, and supports NDAs.* It also supports multiple windows via a document record.****************************************************************/#pragma lint -1#include <stdlib.h>#include <string.h>#include <stdio.h>#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#include <Resources.h>#include <Memory.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define appleAbout      257#define fileNew         260#define fileOpen        261#define fileClose       255#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254typedef struct pointStruct {            /* one point in the document */   struct pointStruct *next;            /* next point */   Point p;                             /* point location */   } pointStruct;typedef pointStruct *pointStructPtr;    /* point struct pointer */#define maxName 80                      /* max length of a window title */typedef struct documentStruct {         /* information about our document */   struct documentStruct *next;         /* next document */   GrafPortPtr wPtr;                    /* window pointer */   char wName[maxName+1];               /* window name */   BOOLEAN onDisk;                      /* does the file exist on disk? */   pointStructPtr points;               /* points in the window */   } documentStruct;typedef documentStruct *documentPtr;    /* document pointer */BOOLEAN done;                           /* are we done, yet? */documentPtr documents;                  /* our documents */int untitledNum;                        /* number for the next untitled window */EventRecord myEvent;                    /* event record *//***************************************************************** GetString** Get a string from the resource fork** Parameters:*    resourceID - resource ID of the rCString resource** Returns: pointer to the string; NULL for an error** Notes: The string is in a locked resource handle.  The caller*    should call FreeString when the string is no longer needed.*    Failure to do so is not catastrophic; the memory will be*    deallocated when the program is shut down.****************************************************************/char *GetString (int resourceID){Handle hndl;                            /* resource handle */hndl = LoadResource(rCString, resourceID);if (toolerror() == 0) {   HLock(hndl);   return (char *) (*hndl);   }return NULL;}/***************************************************************** Free a resource string** Parameters:*    resourceID - resource ID of the rCString to free****************************************************************/void FreeString (int resourceID){ReleaseResource(-3, rCString, resourceID);}/***************************************************************** FlagError** Flag an error** Parameters:*    error - error message number*    tError - toolbox error code; 0 if none****************************************************************/void FlagError (int error, int tError){#define errorAlert 2000                 /* alert resource ID */#define errorBase 2000                  /* base resource ID for fortunes */char *substArray;                       /* substitution "array" */char *errorString;                      /* pointer to the error string */                                        /* form the error string */errorString = GetString(errorBase + error);substArray = NULL;if (errorString != NULL) {   substArray = malloc(strlen(substArray)+9);   if (substArray != NULL)      strcpy(substArray, errorString);   FreeString(errorBase + error);   }if (substArray != NULL) {   if (tError != 0)                     /* add the tool error number */      sprintf(&substArray[strlen(substArray)], " ($%04X)", tError);                                        /* show the alert */   AlertWindow(awCString+awResource, (Pointer) &substArray, errorAlert);   free(substArray);   }#undef errorAlert#undef errorBase}/***************************************************************** CloseDocument** Close a document and its associated window** Parameters:*    dPtr - pointer to the document to close; may be NULL****************************************************************/void CloseDocument (documentPtr dPtr){documentPtr lPtr;                       /* pointer to the previous document */pointStructPtr pp;                      /* used to free point list */if (dPtr != NULL) {   CloseWindow(dPtr->wPtr);             /* close the window */   if (documents == dPtr)               /* remove dPtr from the list when... */      documents = dPtr->next;           /* ...dPtr is the first document */   else {                               /* ...dPtr is not the first document */      lPtr = documents;      while (lPtr->next != dPtr)         lPtr = lPtr->next;      lPtr->next = dPtr->next;      }   while (dPtr->points != NULL) {       /* dispose of the point records */      pp = dPtr->points;      dPtr->points = pp->next;      free(pp);      }   free(dPtr);                          /* dispose of the document record */   }}/***************************************************************** FindDocument** Find the document for wPtr** Parameters:*    wPtr  pointer to the window for which to find a document** Returns: Document pointer; NULL if there isn't one****************************************************************/documentPtr FindDocument (GrafPortPtr wPtr){BOOLEAN done;                           /* used to test for loop termination */documentPtr dPtr;                       /* used to trace the document list */dPtr = documents;done = dPtr == NULL;while (!done)   if (dPtr->wPtr == wPtr)      done = TRUE;   else {      dPtr = dPtr->next;      done = dPtr == NULL;      }return dPtr;}/***************************************************************** DrawContents** Draw the contents of the active port****************************************************************/#pragma databank 1void DrawContents (void){documentPtr dPtr;                       /* document to draw */pointStructPtr pp;                      /* used to trace the point list */dPtr = FindDocument(GetPort());         /* find the proper document */if (dPtr != NULL) {   PenNormal();                         /* use a "normal" pen */   pp = dPtr->points;                   /* draw all of the points */   while (pp != NULL) {      MoveTo(pp->p.h, pp->p.v);      LineTo(pp->p.h, pp->p.v);      pp = pp->next;      }   }}#pragma databank 0/***************************************************************** GetUntitledName** Create a name for an untitled window** Returns: Pointer to the new window name****************************************************************/char *GetUntitledName (void){#define untitled 101                    /* Resource number for "Untitled " */static char name[maxName];              /* window name */char *sPtr;                             /* pointer to the resource string */documentPtr dPtr;                       /* used to trace the document list */int number;                             /* new value for untitledNum */dPtr = documents;                       /* if there are no untitled          */number = 1;                             /*  documents then reset untitledNum */while (dPtr != NULL)   if (!dPtr->onDisk) {      number = untitledNum;      dPtr = NULL;      }   else      dPtr = dPtr->next;untitledNum = number;sPtr = GetString(untitled);             /* set the base name */if (sPtr == NULL)   strcpy(name, "Untitled ");else {   strncpy(name, sPtr, maxName-6);   FreeString(untitled);   }                                        /* add the untitled number */sprintf(&name[strlen(name)], "%d", untitledNum);++untitledNum;                          /* update untitledNum */return name;                            /* return the name */}/***************************************************************** NewDocument** Open a new window, returning the pointer** Parameters:*    wName - name for the new window** Returns: Document pointer; NULL for an error****************************************************************/documentPtr NewDocument (char *wName){#define wrNum 1001                      /* window resource number */documentPtr dPtr;                       /* new document pointer */dPtr = malloc(sizeof(documentStruct)); /* allocate the record */if (dPtr != NULL) {   dPtr->onDisk = FALSE;                /* not on disk */   dPtr->wName[0] = strlen(wName);      /* set up the name */   strncpy(&dPtr->wName[1], wName, maxName);   dPtr->points = NULL;                 /* no points, yet */   dPtr->wPtr =                         /* open the window */      NewWindow2(dPtr->wName, 0, DrawContents, NULL, 0x02, wrNum, rWindParam1);   if (dPtr->wPtr == NULL) {      FlagError(1, toolerror());        /* handle a window error */      free(dPtr);      dPtr = NULL;      }   else {      dPtr->next = documents;           /* put the document in the list */      documents = dPtr;      }   }else   FlagError(2, 0);                     /* handle an out of memory error */return dPtr;#undef wrNum}/***************************************************************** DoAbout** Draw our about box****************************************************************/void DoAbout (void){#define alertID 1                       /* alert string resource ID */AlertWindow(awCString+awResource, NULL, alertID);#undef alertID}/***************************************************************** DoNew** Open a new document window****************************************************************/void DoNew (void){NewDocument(GetUntitledName());}/***************************************************************** AddPoint** Add a point to the document** Parameters:*    wPtr - window pointer for the document*    p - point position in global coordinates****************************************************************/void AddPoint (GrafPortPtr wPtr, Point p){documentPtr dPtr;                       /* wPtr's document */GrafPortPtr port;                       /* caller's GrafPort */pointStructPtr pp;                      /* new point record */port = GetPort();                       /* switch to our GrafPort */SetPort(wPtr);dPtr = FindDocument(wPtr);              /* get the document */if (dPtr != NULL) {   pp = malloc(sizeof(pointStruct));    /* allocate a new point */   if (pp == NULL)      FlagError(2, 0);                  /* handle an out of memory error */   else {      GlobalToLocal(&p);                /* convert to local coordinates */      pp->next = dPtr->points;          /* place the point in the document */      dPtr->points = pp;      pp->p = p;      PenNormal();                      /* draw the point */      MoveTo(p.h, p.v);      LineTo(p.h, p.v);      }   }SetPort(port);                          /* restore caller's grafport */}/***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:     DoAbout();                                      break;   case fileNew:        DoNew();                                        break;   case fileOpen:       DoNew();                                        break;   case fileClose:      CloseDocument(FindDocument(FrontWindow()));     break;   case fileQuit:       done = TRUE;                                    break;   case editUndo:                                                       break;   case editCut:                                                        break;   case editCopy:                                                       break;   case editPaste:                                                      break;   case editClear:                                                      break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();#undef menuID}/***************************************************************** InitGlobals** Initialize the global variables****************************************************************/void InitGlobals (void){documents = NULL;}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */startdesk(640);                         /* start the tools */InitMenus();                            /* set up the menu bar */InitCursor();                           /* start the arrow cursor */InitGlobals();                          /* initialize our global variables */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();                                break;      case wInGoAway:           CloseDocument(FindDocument(                                   (GrafPortPtr) myEvent.wmTaskData));                                break;      case wInContent:          AddPoint(FrontWindow(), myEvent.where);                                break;      }   }enddesk();}