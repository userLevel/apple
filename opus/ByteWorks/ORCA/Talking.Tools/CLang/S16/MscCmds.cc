/***************************************************************** MscCmds - Commands to bring up the About dialog and handle*           printing.** Written by Barbara Allred and Mike Westerfield** Copyright 1991,1995, Byte Works, Inc.******************************************************************* Version 1.0.2** December 1995* Mike Westerfield**   1.	Added checks in DictCmds to make sure the englishText*	and phonenticText values were not used if their length*	was zero, fixing a crash bug that occurred if you clicked*	Speak in the dictionary dialog before creating a phonetic*	translation.**   2.	Corrected various type problems caused by the modern*	C interfaces.****************************************************************/#pragma keep "MscCmds"#pragma noroot#pragma optimize 9#include "globals.h"#include "error.h"PrRecHndl prHndl;                       /* print record handle */                                        /* About dialog */                                        /****************/char item00pointerAbt1[] =              /* the text */   "\pSpeak It 1.0.2\r"   "\r"   "A simple demo to show how to\r"   "use the speech tools."   "\r"   "\rWritten by Barbara Allred";ItemTemplate item00Abt1 = {             /* static text */   100, {4, 8, 72, 241},   15, (void *) &item00pointerAbt1, 93, 0, NULL   };ItemTemplate item01Abt1 = {             /* OK button */   1, {89, 94, 102, 149},   10, (void *) &okTitle, 0, 1, NULL   };DialogTemplate aboutDlg = {             /* About menu item's dialog box */   {43, 196, 156, 441},   -1, 0, &item00Abt1, &item01Abt1, NULL   };extern boolean WantToSave (int wNum);/* Located in FileCmds unit, which INCLUDES this unit. *//***************************************************************** InitMscCmds - Initialize the MscCmds module.** Returns - true if able to initialize module****************************************************************/boolean InitMscCmds (void){/* Create print record:  allocate memory for print record, then initialize. */prHndl = (void *) NewHandle(140L, myID, 0xC010, NULL);if (toolerror()) {   HandleError (toolerror(), memryErr);   return FALSE;   }PrDefault(prHndl);if (toolerror()) {   HandleError(toolerror(), printErr);   return FALSE;   }return TRUE;}/***************************************************************** MyWindow - Checks if front window is one of ours.** Parameters:*      wInfo - information about the front window** Returns - true if it's one of ours****************************************************************/boolean MyWindow (windInfoRec *wInfo){RefConRec wRefCon;                      /* window's number and type *//* First check if any windows are up.  If not, return FALSE. */if (numWindows <= 0)   return FALSE;/* Check if the window is a system window.  If so, return FALSE. */wInfo->currWindow = FrontWindow();if (GetSysWFlag(wInfo->currWindow))   return FALSE;/* It's one of ours, so set global info for this window. */wRefCon.l = GetWRefCon(wInfo->currWindow);wInfo->currWindNum = wRefCon.a.wNum;wInfo->currWindTyp = wRefCon.a.wTyp;return TRUE;}/***************************************************************** DoAbout - Handle About command.****************************************************************/void DoAbout (void){GrafPortPtr tmp;                        /* modal dialog grafPort *//* Create the About modal dialog. */tmp = GetNewModalDialog(&aboutDlg);if (toolerror())   HandleError(toolerror(), windErr);else {   ModalDialog(NULL);   if (toolerror())      FatalErr(toolerror());   CloseDialog(tmp);   }}/***************************************************************** DoClose - Close the front window.** Returns - true if Cancel in save dialog chosen****************************************************************/boolean DoClose (void){CtlRecHndl tmp;                         /* window's text edit control handle */windInfoRec wInfo;                      /* information about the front wind */if (MyWindow(&wInfo)) {                 /* ensure it's one of our windows */   /* If not closing the dictionary window, then ensure we can open */   /* a new text or phonetics window.  First check need to save */   /* window before closing it. */   if (wInfo.currWindTyp != dictTyp) {      tmp = userWind[wInfo.currWindNum].wCtl.teHndl;      if (((*tmp)->ctlFlag & isDirty))         if (WantToSave(wInfo.currWindNum))            return TRUE;      /* If the window is associated with a file, free any file memory. */      if (userWind[wInfo.currWindNum].fileFlag) {         userWind[wInfo.currWindNum].fileFlag = FALSE;         if (userWind[wInfo.currWindNum].wPathHandle != NULL)            DisposeHandle(userWind[wInfo.currWindNum].wPathHandle);         userWind[wInfo.currWindNum].wPathHandle = NULL;         userWind[wInfo.currWindNum].wPathName = NULL;         }      --userWindows;                    /* one less user window up */      EnableMItem(newID);               /* can now create new window */      EnableMItem(openID);              /* can now open a file */      }   CloseWindow(wInfo.currWindow);       /* close the window */   --numWindows;                        /* one less window open */   /* Set window record flag that window no longer open. */   userWind[wInfo.currWindNum].upFlg = FALSE;   }return FALSE;}/***************************************************************** DoPrint - Print a text window or the dictionary.****************************************************************/#define thruPrinting 0x2209        /* err code returned by TEPaintText when */                                   /*   starting line # exceeds last line # */void DoPrint (void){windInfoRec wInfo;                      /* information about the front window */char word1[33];                         /* dictionary entry */char word2[33];GrafPortPtr prPort;                     /* Print Manager's grafPort */GrafPortPtr savePort;                   /* curr grafPort saved/restored */long currLine;                          /* current line # to print */long lastLine;                          /* last line # to print */long firstPage;                         /* first page to begin printing */long finalPage;                         /* final page to print */int copies;                             /* # copies of document to print */boolean spool;                          /* false = draft mode; */                                        /* true = spooled printing */boolean anError;                        /* true if error detected */PrRecPtr printRecPtr;                   /* pointer to print record */Rect prRect;                            /* printing rectangle */long tmp;int answer;int i, j;savePort = GetPort();                   /* save caller's grafPort */if (!MyWindow(&wInfo))                  /* ensure window is one of ours */   return;answer = PrJobDialog(prHndl);           /* bring up Print Job dialog */if (toolerror()) {                      /* error returned by PrJobDialog? */   HandleError(toolerror(), printErr);   return;   }if (answer == 0)                        /* want to print document? */   return;printRecPtr = *prHndl;                  /* dereference print record handle *//* Set up page rectangle based on printed page size calculated by *//* Print Manager as derived from Job and Page setup dialogs.      */prRect.v1 = printRecPtr->prInfo.rPage.v1;prRect.h1 = printRecPtr->prInfo.rPage.h1;prRect.v2 = printRecPtr->prInfo.rPage.v2;prRect.h2 = printRecPtr->prInfo.rPage.h2;firstPage = printRecPtr->prJob.iFstPage; /* get first page to print */currLine = (firstPage - 1) * 60;        /* calculate 1st line to print, */                                        /*   counting lines from 0, and */                                        /*   60 lines per page          */printRecPtr->prJob.iFstPage = 1;        /* set page # to 1 for Print Mgr, since it */                                        /* counts ea. page it prints, starting at 1 */finalPage = printRecPtr->prJob.iLstPage; /* get last page to print */lastLine = finalPage * 60;              /* calculate last line to print *//*  Ensure that starting page number not greater than ending page */tmp = finalPage - firstPage;if (tmp < 0)   return;printRecPtr->prJob.iLstPage = tmp + 1;  /* reset last page to print for */                                        /*  Print Mgr, relative to 1 */copies = printRecPtr->prJob.iCopies;    /* get # copies to print */firstPage = currLine;                   /* remember starting line # in case multiple */                                        /*  copies wanted and printing in draft mode *//* Determine whether printing in draft or spooled mode. */if (printRecPtr->prJob.bJDocLoop == 0)   spool = FALSE;else {   spool = TRUE;   copies = 1;                          /* PrPicFile handles mult. copies */   }/* Ensure requested starting line number is in document. */if (wInfo.currWindTyp == dictTyp) {     /* if window = dict, check dict size */   if (listTempl.listSize < currLine)       return;    /* Position dictionary at first entry to print. */   if (nextEntry > currLine) {          /* check if can reach entry from */      DictInit(0);                      /*   current position in dict */      nextEntry = 0;      }   while (nextEntry < currLine) {       DictDump(word1, word2);       if (((int) word1[0]) == 0)           return;       ++nextEntry;       }   } /* if dict *//* If the window is a text file, we find the number of lines in the document *//* by calling Text Edit's TEGetTextInfo, which returns a textInfo record. */else {   TEGetTextInfo((Pointer) &textInfo, 2,      (Handle) userWind[wInfo.currWindNum].wCtl.teHndl);   if (toolerror()) {      HandleError(toolerror(), TEErr);      return;      }   if (currLine > textInfo.lineCount)      return;   }/* Call Print Manager to open the document for printing; get Print Manager's *//* printing grafPort. */anError = FALSE;/* Outer print loop, to print multiple copies in draft mode. */do {   prPort = PrOpenDoc(prHndl, NULL);   if (toolerror()) {      HandleError(toolerror(), printErr);      anError = TRUE;      }   else {      /* Inner print loop, to print each page in the document. */      do {         PrOpenPage(prPort, NULL);      /* init. grafPort, no scaling */         if (toolerror()) {             /*   rectangle passed         */            HandleError(toolerror(), printErr);            anError = TRUE;            }         else {            PenNormal();                /* set pen to standard state */            /* What is drawn into the printer's grafPort */            /* depends on window's type. */            if (wInfo.currWindTyp == dictTyp) {               i = 0;               j = 10;                  /* j = horizontal offset into page */               while (i < 60) {                  DictDump(word1, word2); /* get next entry */                  if (((int) word1[0]) == 0) { /* check end of dict */                     currLine = -1;     /* signal end of page*/                     DictInit(0);       /* reset dict to top */                     nextEntry = 0;                     i = 60;                     }                  else {                /* draw this entry */                     MoveTo(10, j);                     DrawString(word1);                     MoveTo(170, j);                     DrawString(word2);                     ++nextEntry;       /* move to next dict entry */                     ++currLine;        /* move to next line */                     j += 10;                     ++i;                     }                  } /* while */               } /* if window == dict */            else {               /* Call TEPaintText to draw text into Print Mgr's grafPort */               MoveTo(0, 0);            /* move to top left of drawing rect */               currLine = TEPaintText(prPort, (Long) currLine, &prRect, 0,                  (Handle) userWind[wInfo.currWindNum].wCtl.teHndl);               if ((toolerror()) && (toolerror() != thruPrinting)) {                  HandleError(toolerror(), printErr);                  anError = TRUE;                  }               }            } /* no error from PrOpenPage */         PrClosePage(prPort);           /* close this printed page */         if ((toolerror()) && (!anError)) {            HandleError(toolerror(), printErr);            anError = TRUE;            }         }                              /* end page-printing loop */      while ((currLine != -1) && (currLine <= lastLine) && (!anError));      } /* no error from PrOpenDoc */   PrCloseDoc(prPort);                  /* close document for printing */   if ((toolerror()) && (!anError)) {      HandleError(toolerror(), printErr);      anError = TRUE;      }   --copies;                            /* one less copy to print */   currLine = firstPage;                /* reset for next copy */   }while ((copies != 0) && (!anError));    /* end print copies loop *//* Handle spooled printing. */if ((spool) && (!anError)) {   PrPicFile(prHndl, NULL, NULL);       /* let Print Mgr alloc new */                                        /*   grafPort, prStatusRec */   if (toolerror())      HandleError(toolerror(), printErr);   }SetPort(savePort);                      /* restore original grafPort */}/***************************************************************** DoPSetUp - Handle Page setUp command.****************************************************************/void DoPSetUp (void){/* Bring up Print Style dialog. */PrStlDialog(prHndl);if (toolerror())   HandleError(toolerror(), printErr);}