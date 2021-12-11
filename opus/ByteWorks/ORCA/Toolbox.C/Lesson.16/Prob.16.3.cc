/***************************************************************** Instrument Sampler** Load and try ASIF instruments.****************************************************************/#pragma lint -1#include <stdlib.h>#include <string.h>#include <stdio.h>#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#include <Resources.h>#include <StdFile.h>#include <Locator.h>#include <MiscTool.h>#include <NoteSyn.h>#include <Sound.h>#include <Memory.h>#include <GSOS.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define appleAbout      257#define fileOpen        261#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254#define keyWidth        18              /* key size */#define keyHeight       50#define numKeys         21              /* number of keys on the keyboard */#define baseKey 36                      /* Midi key # for any C note */typedef char chunkType[5];              /* chunk ID type */BOOLEAN done;                           /* are we done, yet? */EventRecord myEvent;                    /* event record */GrafPortPtr wPtr;                       /* our window */Handle instrumentHandle;                /* instrument file handle */Instrument *instrumentPtr;              /* instrument record *//***************************************************************** GetString** Get a string from the resource fork** Parameters:*    resourceID - resource ID of the rCString resource** Returns: pointer to the string; NULL for an error** Notes: The string is in a locked resource handle.  The caller*    should call FreeString when the string is no longer needed.*    Failure to do so is not catastrophic; the memory will be*    deallocated when the program is shut down.****************************************************************/char *GetString (int resourceID){Handle hndl;                            /* resource handle */hndl = LoadResource(rCString, resourceID);if (toolerror() == 0) {   HLock(hndl);   return (char *) (*hndl);   }return NULL;}/***************************************************************** Free a resource string** Parameters:*    resourceID - resource ID of the rCString to free****************************************************************/void FreeString (int resourceID){ReleaseResource(-3, rCString, resourceID);}/***************************************************************** FlagError** Flag an error** Parameters:*    error - error message number*    tError - toolbox error code; 0 if none****************************************************************/void FlagError (int error, int tError){#define errorAlert 2000                 /* alert resource ID */#define errorBase 2000                  /* base resource ID for fortunes */char *substArray;                       /* substitution "array" */char *errorString;                      /* pointer to the error string */                                        /* form the error string */errorString = GetString(errorBase + error);substArray = NULL;if (errorString != NULL) {   substArray = malloc(strlen(substArray)+9);   if (substArray != NULL)      strcpy(substArray, errorString);   FreeString(errorBase + error);   }if (substArray != NULL) {   if (tError != 0)                     /* add the tool error number */      sprintf(&substArray[strlen(substArray)], " ($%04X)", tError);                                        /* show the alert */   AlertWindow(awCString+awResource, (Pointer) &substArray, errorAlert);   free(substArray);   }#undef errorAlert#undef errorBase}/***************************************************************** GetByte** Read a byte from the file buffer** Parameters:*    p - pointer to the byte (updated)** Returns: Byte from the file****************************************************************/unsigned GetByte (unsigned char **p){unsigned val;val = **p;++(*p);return val;}/***************************************************************** GetInt** Read an unsigned integer from the file** Parameters:*    p - pointer to the value (updated)** Returns: value****************************************************************/unsigned GetInt (unsigned char **p){return GetByte(p) | (GetByte(p) << 8);}/***************************************************************** GetLong2** Read a reverse order longint from the file** Parameters:*    p - pointer to the value (updated)** Returns: value****************************************************************/long GetLong2 (unsigned char **p){long value;                             /* value */value = GetByte(p);value = (value << 8) | GetByte(p);value = (value << 8) | GetByte(p);value = (value << 8) | GetByte(p);return value;}/***************************************************************** GetType** Read a type from the file buffer** Parameters:*    p - pointer to the byte (updated)*    id - (output) type read****************************************************************/void GetType (unsigned char **p, chunkType id){id[0] = (char) GetByte(p);id[1] = (char) GetByte(p);id[2] = (char) GetByte(p);id[3] = (char) GetByte(p);id[4] = 0;}/***************************************************************** FindChunk** Locate a chunk in an ASIF file** Parameters:*    p - pointer to the start of the first chunk*    chunk - character type for the chunk to find*    len - number of bytes left in the file** Returns: Pointer to the chunk; NULL if not found.****************************************************************/unsigned char *FindChunk (unsigned char *p, chunkType chunk, unsigned long len){chunkType id;                           /* chunk type for the current chunk */unsigned char *ptr;                     /* pointer to return */unsigned long disp;                     /* length of the data in the chunk */do {   GetType(&p, id);   disp = GetLong2(&p);   ptr = p;   p += disp;   len -= disp;   if (len <= 0)      if (id != chunk) {         p = NULL;         ptr = NULL;         }   }while ((p != NULL) && (strcmp(chunk, id) != 0));return ptr;}/***************************************************************** SetUpInstrument** Set up the instrument****************************************************************/void SetUpInstrument (void){unsigned char *cPtr;                    /* chunk pointer */BOOLEAN error;                          /* did we find an error? */unsigned numSamples;                    /* number of samples to skip */chunkType sType;                        /* super chunk type */unsigned char *sPtr;                    /* points to first chunk */unsigned long superLength;              /* length of the file */unsigned waveSize;                      /* size of the waveform */error = FALSE;                          /* no error found, yet */                                        /* verify that this is an ASIF file */sPtr = (unsigned char *) (*instrumentHandle);GetType(&sPtr, sType);if (strcmp(sType, "FORM") != 0)   error = TRUE;if (!error) {   superLength = GetLong2(&sPtr);   GetType(&sPtr, sType);   if (strcmp(sType, "ASIF") != 0)      error = TRUE;   }if (!error) {                           /* find the instrument */   cPtr = FindChunk(sPtr, "INST", superLength);   if (cPtr == NULL)      error = TRUE;   else {      instrumentPtr = (Instrument *) (((unsigned long) cPtr) + *cPtr + 3);      instrumentPtr->theEnvelope.st1BkPt = 127;      instrumentPtr->theEnvelope.st1Increment = 0x3F80;      instrumentPtr->theEnvelope.st2BkPt = 100;      instrumentPtr->theEnvelope.st2Increment = 0x00B3;      instrumentPtr->theEnvelope.st3BkPt = 90;      instrumentPtr->theEnvelope.st3Increment = 0x0006;      instrumentPtr->theEnvelope.st4BkPt = 0;      instrumentPtr->theEnvelope.st4Increment = 0x0126;      instrumentPtr->releaseSegment = 3;      instrumentPtr->vibratoDepth = 80;      instrumentPtr->vibratoSpeed = 40;      }   }if (!error) {                           /* find and load the waveform */   cPtr = FindChunk(sPtr, "WAVE", superLength);   if (cPtr == NULL)      error = TRUE;   else {      cPtr = cPtr + (*cPtr + 1);      waveSize = GetInt(&cPtr);      numSamples = GetInt(&cPtr);      cPtr = cPtr + (numSamples*12);      asm {sei};      WriteRamBlock(cPtr, 0, waveSize);      asm {cli};      }   }if (error) {                            /* handle any error found */   FlagError(11, 0);   DisposeHandle(instrumentHandle);   instrumentHandle == NULL;   }}/***************************************************************** ReadASIFFile** Load an ASIF instrument file** Parameters:*    name - handle of a GS/OS output name****************************************************************/void ReadASIFFile (ResultBuf255Hndl name){RefNumRecGS clRec;                      /* CloseGS record */OpenRecGS opRec;                        /* OpenGS record */IORecGS rdRec;                          /* ReadGS record */if (instrumentHandle != NULL) {         /* get rid of any old instrument */   DisposeHandle(instrumentHandle);   instrumentHandle == NULL;   }opRec.pCount = 12;                      /* open the file */HLock((Handle) name);opRec.pathname = (GSString255Ptr) (((long) (*name)) + 2);opRec.requestAccess = 1;opRec.resourceNumber = 0;opRec.optionList = NULL;OpenGS(&opRec);if (toolerror() != 0)   FlagError(4, toolerror());else {                                  /* allocate memory for the file */   instrumentHandle = NewHandle(opRec.eof, userid(), 0xC000, NULL);   if (toolerror() != 0)      FlagError(2, toolerror());   else {      rdRec.pCount = 4;                 /* read the file */      rdRec.refNum = opRec.refNum;      rdRec.dataBuffer = (Pointer) (*instrumentHandle);      rdRec.requestCount = opRec.eof;      ReadGS(&rdRec);      if (toolerror() != 0) {         FlagError(4, toolerror());         DisposeHandle((Handle) instrumentHandle);         instrumentHandle = NULL;         }      else         SetUpInstrument();      }   clRec.pCount = 1;                    /* close the file */   clRec.refNum = opRec.refNum;   CloseGS(&clRec);   }HUnlock((Handle) name);                 /* unlock the name handle */}/***************************************************************** DrawContents** Draw the contents of the active port****************************************************************/#pragma databank 1void DrawContents (void){unsigned i;                             /* loop variable */unsigned key;                           /* sharp key number */Rect r;                                 /* rectangle inclosing sharp keys */PenNormal();                            /* draw black lines */SetPenSize(2,1);r.h1 = keyWidth - keyWidth/4;           /* set up initial sharp key rect */r.h2 = r.h1 + keyWidth/2 + 1;r.v1 = 0;r.v2 = keyHeight/2;for (i = 1; i < numKeys; ++i) {         /* for each key... */   MoveTo(i*keyWidth, 0);               /* draw the lines separating keys */   LineTo(i*keyWidth, keyHeight);   key = (i-1)%7;                       /* draw the sharp (black) keys */   if ((key == 0) || (key == 1) || (key == 3) || (key == 4) || (key == 5))      if (i != numKeys-1)         PaintRect(&r);   r.h1 = r.h1 + keyWidth;              /* set sharp key rectangle for next key */   r.h2 = r.h2 + keyWidth;   }}#pragma databank 0/***************************************************************** DoAbout** Draw our about box****************************************************************/void DoAbout (void){#define alertID 1                       /* alert string resource ID */AlertWindow(awCString+awResource, NULL, alertID);#undef alertID}/***************************************************************** DoOpen** Open a file****************************************************************/void DoOpen (void){#define posX 80                         /* X position of the dialog */#define posY 50                         /* Y position of the dialog */#define titleID 102                     /* prompt string resource ID */SFTypeList2 fileTypes;                  /* list of valid file types */SFReplyRec2 reply;                      /* reply record */fileTypes.numEntries = 1;               /* set up the allowed file types */fileTypes.fileTypeEntries[0].flags = 0x0000;fileTypes.fileTypeEntries[0].fileType = 0xD8;fileTypes.fileTypeEntries[0].auxType = 0x0002;reply.nameRefDesc = 3;                  /* get the file to open */reply.pathRefDesc = 3;SFGetFile2(posX, posY, refIsResource, titleID, NULL, &fileTypes, &reply);if (toolerror() != 0)   FlagError(3, toolerror());           /* handle an error */else if (reply.good) {                                        /* read the file */   ReadASIFFile((ResultBuf255Hndl) reply.pathRef);                                        /* dispose of the name buffers */   DisposeHandle((Handle) reply.nameRef);   DisposeHandle((Handle) reply.pathRef);   }#undef posX#undef posY#undef titleID}/***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:     DoAbout();                                      break;   case fileOpen:       DoOpen();                                       break;   case fileQuit:       done = TRUE;                                    break;   case editUndo:                                                       break;   case editCut:                                                        break;   case editCopy:                                                       break;   case editPaste:                                                      break;   case editClear:                                                      break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();#undef menuID}/***************************************************************** InitWindow** Set up the program window****************************************************************/void InitWindow (void){#define wrNum 1001                      /* window resource number */wPtr = NewWindow2("\p  Instrument Sampler  ", 0, DrawContents, NULL, 0x02,   wrNum, rWindParam1);#undef wrNum}/***************************************************************** KeyNum** Find the key number for a given horizontal disp on the keyboard** Parameters:*    h - position on the keyboard** Returns: key number****************************************************************/unsigned KeyNum (int h){unsigned key;                           /* working key number */key = baseKey + 12*(h/keyWidth/7);      /* get key + octave displacement */switch (h/keyWidth%7) {                 /* add key disp */   case 0: ;            break;          /* C - leftmost key */   case 1: key += 2;    break;          /* D */   case 2: key += 4;    break;          /* E */   case 3: key += 5;    break;          /* F */   case 4: key += 7;    break;          /* G */   case 5: key += 9;    break;          /* A */   case 6: key += 11;   break;          /* B */   }return key;}/***************************************************************** FindKey** Return the key number of a click in the content region** Parameters:*    p - click location** Returns: Key number****************************************************************/unsigned FindKey (Point p){unsigned key;                           /* sharp key number */if (p.v < keyHeight / 2)                /* handle shart keys */   if ((p.h + keyWidth / 4) % keyWidth <= keyWidth / 2 + 1) {      key = ((p.h - keyWidth / 2) / keyWidth % 7);      if ((key == 0) || (key == 1) || (key == 3) || (key == 4) || (key == 5))         return KeyNum(p.h - keyWidth / 2) + 1;      }return KeyNum(p.h);                     /* handle non-sharp keys */}/***************************************************************** PlayNote** Play a note** Parameters:*    p - location of key to play****************************************************************/void PlayNote (Point p){#define volume 120                      /* volume */GrafPortPtr port;                       /* caller's grafport */unsigned generator;                     /* generator for this note */unsigned generator2;                    /* generator for swaping notes */unsigned note;                          /* note number */port = GetPort();                       /* use local coordinate system */SetPort(wPtr);GlobalToLocal(&p);                      /* convert to local coordinates */if (instrumentHandle == NULL)   FlagError(10, 0);else {   generator = AllocGen(100);           /* get a generator */   if (toolerror() == 0) {      note = FindKey(p);                /* figure out which key was pressed */                                        /* start the note */      NoteOn(generator, note, volume, (Pointer) instrumentPtr);      while (StillDown(0)) {            /* wait until the mouse is released,   */         GetMouse(&p);                  /*  switching notes if the mouse moves */         if (FindKey(p) != note) {            generator2 = AllocGen(100);            if (toolerror() == 0) {               NoteOff(generator, note);               generator = generator2;               note = FindKey(p);               NoteOn(generator, note, volume, (Pointer) instrumentPtr);               }            }         }      NoteOff(generator, note);         /* start the note decay */      }   }SetPort(port);                          /* restor caller's port */#undef volume}/***************************************************************** InitGlobals** Initialize the global variables****************************************************************/void InitGlobals (void){instrumentHandle = NULL;                /* no instrument loaded */}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */Ref startStopParm;                      /* tool start/shutdown parameter */startStopParm =                         /* start up the tools */   StartUpTools(userid(), 2, 1);if (toolerror() != 0)   SysFailMgr(toolerror(), "\pCould not start tools: ");InitMenus();                            /* set up the menu bar */InitWindow();                           /* set up the program window */InitCursor();                           /* start the arrow cursor */InitGlobals();                          /* initialize our global variables */AllNotesOff();                          /* make sure all notes are off */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();                   break;      case wInGoAway:           done = TRUE;                    break;      case wInContent:          PlayNote(myEvent.where);        break;      }   }AllNotesOff();                          /* make sure all notes are off */ShutDownTools(1, startStopParm);        /* shut down the tools */}