/***************************************************************** Frame** This program implements all of the support required for desk* accessories.****************************************************************/#pragma lint -1#include <orca.h>#include <Event.h>#include <Menu.h>#include <QuickDraw.h>#include <Window.h>#include <Desk.h>#define appleMenu       1               /* Menu ID #s (also resource ID #s) */#define fileMenu        2#define editMenu        3#define appleAbout      257#define fileClose       255#define fileQuit        256#define editUndo        250#define editCut         251#define editCopy        252#define editPaste       253#define editClear       254BOOLEAN done;                           /* are we done, yet? */EventRecord myEvent;                    /* event record *//***************************************************************** HandleMenu** Initialize the menu bar.****************************************************************/void HandleMenu (void){int menuNum, menuItemNum;               /* menu number & menu item number */menuNum = myEvent.wmTaskData >> 16;menuItemNum = myEvent.wmTaskData;switch (menuItemNum) {                  /* go handle the menu */   case appleAbout:                     break;   case fileClose:                      break;   case fileQuit:       done = TRUE;    break;   case editUndo:                       break;   case editCut:                        break;   case editCopy:                       break;   case editPaste:                      break;   case editClear:                      break;   }HiliteMenu(FALSE, menuNum);             /* unhighlight the menu */}/***************************************************************** InitMenus** Initialize the menu bar.****************************************************************/void InitMenus (void){#define menuID 1                        /* menu bar resource ID */int height;                             /* height of the largest menu */MenuBarRecHndl menuBarHand;             /* for 'handling' the menu bar */                                        /* create the menu bar */menuBarHand = NewMenuBar2(refIsResource, menuID, NULL);SetSysBar(menuBarHand);SetMenuBar(NULL);FixAppleMenu(1);                        /* add desk accessories */height = FixMenuBar();                  /* draw the completed menu bar */DrawMenuBar();}/***************************************************************** Main program****************************************************************/int main (void){int event;                              /* event type returned by TaskMaster */startdesk(640);                         /* start the tools */InitMenus();                            /* set up the menu bar */InitCursor();                           /* start the arrow cursor */done = FALSE;                           /* main event loop */myEvent.wmTaskMask = 0x001F7FFF;        /* let TaskMaster do it all */while (!done) {   event = TaskMaster(everyEvent, &myEvent);   switch (event) {      case wInSpecial:      case wInMenuBar:          HandleMenu();           break;      }   }enddesk();}