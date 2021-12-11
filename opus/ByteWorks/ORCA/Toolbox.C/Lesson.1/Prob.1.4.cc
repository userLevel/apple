/***************************************************************** Mouse Position** Show the current mouse position****************************************************************/#pragma lint -1#include <stdio.h>#include <orca.h>#include <Event.h>#include <QuickDraw.h>BOOLEAN done;                           /* are we done, yet? */EventRecord myEvent;                    /* event record */int h = -1, v;                          /* old position (to avoid flicker) *//***************************************************************** WriteMousePos** Write the position of the mouse.****************************************************************/void WriteMousePos (void){Rect r;                                 /* rectangle for area to erase */if ((h != myEvent.where.h) || (v != myEvent.where.v)) {   SetSolidPenPat(black);               /* erase any old stuff */   r.h1 = 0;  r.h2 = 150;   r.v1 = 0;  r.v2 = 15;   PaintRect(&r);   MoveTo(10, 10);                      /* write the position */   h = myEvent.where.h;   v = myEvent.where.v;   printf("%d, %d", h, v);   }}/***************************************************************** Main program****************************************************************/int main (void){startdesk(640);                         /* start the tools */PenNormal();                            /* set up normal pen parameters */InitCursor();                           /* start the arrow cursor */done = FALSE;                           /* we aren't done, yet */while (!done) {                                        /* handle the events */   if (GetNextEvent(everyEvent, &myEvent))      if (myEvent.what == keyDownEvt)         done = TRUE;   WriteMousePos();   }enddesk();}