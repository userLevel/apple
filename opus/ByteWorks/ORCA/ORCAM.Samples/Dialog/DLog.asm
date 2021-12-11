	 keep  dlog******************************************************************************** DLog1** (C)  Copyright Apple Computer, Inc. 1988* All rights reserved.** by Jim Mensch* 7/11/88** Demo of the Apple IIgs Dialog manager. This program shows how to create and * work using standard dialog boxes, both Modal and Modeless. It also has a demo* of simple alerts. The dialogs used are from the examples in the toolbox ref* manual volume 1. The Modal example implements a save current value feature.** Files: 	  System macros and equates*		  Standard.Asm**** Modification History:** Version 1.0	  Jim Mensch**      7/11/88**      Initial release*********************************************************************************								     **	      Apple IIGS Source Code Sampler, Volume I		     **								     **	      Copyright (c) Apple Computer, Inc. 1988		     **			All Rights Reserved			     **								     **	     Written by Apple II Developer Tech Support		     **								     **								     **								     **  ----------------------------------------------------------------  **								     **     This program and its derivatives are licensed only for	     **     use on Apple computers.					     **								     **     Works based on this program must contain and		     **     conspicuously display this notice. 			     **								     **     This software is provided for your evaluation and to	     **     assist you in developing software for the Apple IIGS	     **     computer.							     **								     **     This is not a distribution license. Distribution of	     **     this and other Apple software requires a separate		     **     license. Contact the Software Licensing Department of	     **     Apple Computer, Inc. for details.				     **								     **     DISCLAIMER OF WARRANTY					     **								     **     THE SOFTWARE IS PROVIDED "AS IS" WITHOUT			     **     WARRANTY OF ANY KIND, EITHER EXPRESS OR IMPLIED,		     **     WITH RESPECT TO ITS MERCHANTABILITY OR ITS FITNESS 	     **     FOR ANY PARTICULAR PURPOSE.  THE ENTIRE RISK AS TO 	     **     THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH	     **     YOU.  SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU (AND	     **     NOT APPLE OR AN APPLE AUTHORIZED REPRESENTATIVE)		     **     ASSUME THE ENTIRE COST OF ALL NECESSARY SERVICING, 	     **     REPAIR OR CORRECTION.					     **								     **     Apple does not warrant that the functions			     **     contained in the Software will meet your requirements	     **     or that the operation of the Software will be		     **     uninterrupted or error free or that defects in the 	     **     Software will be corrected.				     **								     **     SOME STATES DO NOT ALLOW THE EXCLUSION			     **     OF IMPLIED WARRANTIES, SO THE ABOVE EXCLUSION MAY		     **     NOT APPLY TO YOU.	 THIS WARRANTY GIVES YOU SPECIFIC	     **     LEGAL RIGHTS AND YOU MAY ALSO HAVE OTHER RIGHTS		     **     WHICH VARY FROM STATE TO STATE.				     **								     **								     ***********************************************************************		  MCOPY dlog.macros		  copy 13/ainclude/e16.quickdraw		  copy 13/ainclude/e16.control		  copy 13/ainclude/e16.dialog		  copy 13/ainclude/e16.memory		  copy 13/ainclude/e16.windowDPHandle 	  gequ 0 	     ; handle to Tool Direct Page areaDPPointer	  gequ DPHandle+4    ; Pointer to Tool Direct Page areaDeRef		  gequ DPPointer+4   ; Temprary Handle dereference areaScreenMode	  gequ $80	     ; used to set scan line SCBScreenWidth	  gequ 640	     ; used to set mouse 		 clamps 	     CloseItem	  gequ 255	     ; menu item number for close item		  EJECT********************************************************************************DLog		  start** Description:	  This is the main routine of the program. It simply calls*		  all the other major parts of the program.*** Inputs:	  None** Outputs:	  None** External Refs:** Entry Points:	  None********************************************************************************		  using Globals		  jsr InitTools		  jsr InitApp		  _ShowCursor		  jsr EventLoop		  jsr CloseTools		  _Quit QuitParms		  end		  EJECT********************************************************************************Globals		  data** Description:	  Global data for use in all routines of this demo. This area*		  also contains the data used by Standard.Asm*** Inputs:	  None** Outputs:	  None** External Refs:  None** Entry Points:********************************************************************************** Standard global data********************************************************************************TitleString	  str 'Apple IIgs Dialog Mgr Example Application'AutString	  str 'By Mensch Apple DTS (c)1988 Apple Computer'VersString	  str 'Version: 1.0'MenuHeight	  ds 2		    ; Stored height of menu barMyID		  ds 2		    ; Application IDMyDP		  ds 2		    ; My direct page storageQuitFlag 	  ds 2QuitParms	  dc i4'0'	     ; Pathname of next app		  dc i2'$00'	     ; flagsEventdata	  ANOPEventWhat	  ds 2EventMessage	  ds 4EventWhen	  ds 4EventWhere	  ds 4EventModifiers	  ds 2TaskData 	  ds 4TaskMask 	  dc i4'$0000FFFF'		  EJECT********************************************************************************* Application specific global data********************************************************************************; This is a list of pointers to the text that is used to create our menus. It; is used by InitApp to find all of the menu templates and use them to create; our menubar. This loop loads MenuPtrLen-4 into an index, gets the; corresponding menu template pointer in this table, and uses that in a; NewMenu call. It then decrements the index by 4, and repeats the startees; until the index is negative.MenuPtr		  dc i4'AppMenu'		  dc i4'FileMenu'		  dc i4'EditMenu'MenuPtrLen	  equ *-MenuPtr; Menu list: menu items should be numbered consecutivly starting from 250.; As a convention, use 256 as about and 257 as Quit.AppMenu		  dc c'$$@\N1',i1'0'		  dc c'--About Simple Dialog...\N256V',i1'0'		  dc c'.'FileMenu 	  dc c'$$  File  \N2',i1'0'		  dc c'--Modal Dialog Sample...\N258',i1'0'		  dc c'--Modeless Dialog Sample...\N259',i1'0'		  dc c'--Close\N255DV',i1'0'		  dc c'--Quit\N257*Qq',i1'0'		  dc c'.'EditMenu 	  dc c'$$  Edit  \N3',i1'0'		  dc c'--Undo\N250*ZzVD',i1'0'		  dc c'--Cut\N251*XxD',i1'0'		  dc c'--Copy\N252*CcD',i1'0'		  dc c'--Paste\N253*VvD',i1'0'		  dc c'--Clear\N254D',i1'0'		  dc c'.'; ModalTemplate is the template described in the Toolbox reference to be used; using the getNewModalDialog callModalTemplate	  ANOP		  dc i2'30,30,120,330' ; for 320 use 30,30,130,290		  dc i2'$FFFF'	     ; visible		  dc i4'0'		  dc i4'MTOKButton'  ; the ok button for this dialog		  dc i4'MTCancelButton'		       ; cancel button		  dc i4'MTTitle1'    ; title string of the dialog		  dc i4'MTTitle2'    ; Title string of the Edit item		  dc i4'MTRadio1'    ; Standard paper item		  dc i4'MTRadio2'    ; legal pad item		  dc i4'MTCheck'     ; stop printing item		  dc i4'MTEdit'	     ; edit box for page title		  dc i4'0'	     ; end of the item listOKBTitle 	  str 'Ok'CancelBTitle	  str 'Cancel'MTTitle1Str	  str 'Print the document'MTTitle2Str	  str 'Title:'MTCheckStr	  str 'Stop printing after each page'MTRadio1Str	  str '8 1/2" x 11" paper'MTRadio2Str	  str '8 1/2" x 14" paper'MTDefaultStr	  ds 65MTOKButton	  ANOP		  dc i2'1'	     ; Item ID		  dc i2'30,240,45,295'		       ; Item rectangle		  dc i2'ButtonItem'  ; Item type		  dc i4'OKBTitle'    ; Item Descriptor ( 		 title )		  dc i2'0'	     ; Initial value		  dc i2'0'	     ; item flag ( 0 for 		 default )		  dc i4'0'	     ; no color tableMTCancelButton	  ANOP		  dc i2'2'		  dc i2'10,240,25,295'		  dc i2'ButtonItem'		  dc i4'CancelBTitle'		  dc i2'0'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; no color tableMTTitle1 	  ANOP		  dc i2'3'		  dc i2'10,10,20,239'		  dc i2'StatText+ItemDisable'		  dc i4'MTTitle1Str'		  dc i2'0'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; no color tableMTTitle2 	  ANOP		  dc i2'4'		  dc i2'67,10,77,60'		  dc i2'StatText+ItemDisable'		  dc i4'MTTitle2Str'		  dc i2'0'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; no color tableMTRadio1 	  ANOP		  dc i2'5'		  dc i2'25,10,34,239'		  dc i2'RadioItem'		  dc i4'MTRadio1Str'MTRad1Def	  dc i2'1'	     ; default to on		  dc i2'1'	     ; family 1		  dc i4'0'MTRadio2 	  ANOP		  dc i2'6'		  dc i2'35,10,49,239'		  dc i2'RadioItem'		  dc i4'MTRadio2Str'MTRad2Def	  dc i2'0'	     ; default to off		   		  dc i2'1'	     ; family 1		  dc i4'0'MTCheck		  ANOP		  dc i2'7'		  dc i2'50,10,64,280'		  dc i2'CheckItem'		  dc i4'MTCheckStr'MTCheckDef	  dc i2'0'		  dc i2'0'		  dc i4'0'MTEdit		  ANOP		  dc i2'8'		  dc i2'65,65,80,280'		  dc i2'editLine'		  dc i4'MTDefaultStr'		  dc i2'60'	     ; max length		  dc i2'0'		  dc i4'0'BColorTab	  ANOP		    ; color table for use using color buttons		  dc i2'$0050'	     ; bttnOutline blue/red		  dc i2'$00F0'	     ; bttnNorBack white 		 background		  dc i2'$00A0'	     ; bttnSelBack yellow/green		  dc i2'$00F0'	     ; bttnNorText Black 		 text on White		  dc i2'$00A0'	     ; bttnSelText Black 		 on yellow/green;;   Modeless Dialog		    Data ;ModelessPtr	  ds 4MLRect		  dc i2'30,30,110,330'		       ; for 320 use 30,30,130,290MLTitle		  str 'Change'DLogHit		  ds 4DLogItemHit	  ds 4		  end		  copy Standard.Asm		  		  EJECT********************************************************************************InitApp		  start** Description:	  This routine is called once after the tools are started.*		  This is where you would create objects your program will*		  need at the very start, or initialize variables that require*		  an Initial default value.*** Inputs:	  None** Outputs:	  None** External Refs:		  using Globals** Entry Points:	  None********************************************************************************		  Stz QuitFlag	    ; initialize the quit flag		  stz ModelessPtr   ; zero the modeless			pointer to signify		  stz ModelessPtr+2 ; it is not already up		  rts		  end		  EJECT********************************************************************************EventLoop	  start** Description:	  Main event loop. Handles all user events and calls various*		  routines based on them. This routine ends when the user *		  selects Quit.*		  *** Inputs:	  None** Outputs:	  None** External Refs:		  using Globals*		  Import ModeLessEvent*		  Import MenuSelect*		  Import DoClose*		  Import Ignore** Entry Points:	  None********************************************************************************		  		  PushWord #0	    ; room for result		  PushWord #$FFFF   ; handle all tasks		  PushLong #Eventdata ; pointer to event data storage		  _TaskMaster		  ; Now that an event has occured we have to see if it is a dialog event. I do; this by setting up a table of all possible events and specifying for each; event type, whether it should be tested as a dialog event. If it turns out to; be a dialog event, I change the EventType variable to 15 (app event 4); and starteed using my normal event dispatch. This will cause the event to be; passed to my dialog event handler.		  pla		    ; get the event type		  sta EventType	    ; save it for after			dialog select		  tax		    ; use as index into			dlog event flags		  lda DlogEFlags,x  ; to see if its an event dialogs		  and #$00FF	    ; might want		  bne EL0010	    ; nope branch around this!		  PushWord #0		  PushLong #Eventdata		  _IsDialogEvent		  pla		  beq EL0010	    ; false do nothing		  lda #15	    ; if true dispatch application event		  sta EventType	    ; #15 to signal a dialog eventEL0010		  anop		  lda EventType		  asl a		    ; multiply by 2		  tax		  jsr (TaskTable,x)		  lda QuitFlag		  beq EventLoop		  rtsEventType	  ds 2TaskTable	  dc i2'ModelessEvent' ; 0 Null		  dc i2'Ignore'	     ; 1 MouseDown		  dc i2'Ignore'	     ; 2 Mouse Up		  dc i2'Ignore'	     ; 3 KeyDown		  dc i2'Ignore'	     ; 4 Undefined		  dc i2'Ignore'	     ; 5 AutoKey		  dc i2'Ignore'	     ; 6 Update		  dc i2'Ignore'	     ; 7 undefined		  dc i2'Ignore'	     ; 8 activate		  dc i2'Ignore'	     ; 9 Switch		  dc i2'Ignore'	     ; 10 desk acc		  dc i2'Ignore'	     ; 11 device driver		  dc i2'Ignore'	     ; 12 ap		  dc i2'Ignore'	     ; 13 ap		  dc i2'Ignore'	     ; 14 ap		  dc i2'ModelessEvent' ; 15 ap		  dc i2'Ignore'	     ; TASK 0 indesk		  dc i2'MenuSelect'  ; TASK 1 in menuBar		  dc i2'Ignore'	     ; TASK 2 in system window		  dc i2'Ignore'	     ; TASK 3 in content		  dc i2'Ignore'	     ; TASK 4 in Drag		  dc i2'Ignore'	     ; TASK 5 in grow		  dc i2'DoClose'     ; TASK 6 in goaway		  dc i2'Ignore'	     ; TASK 7 in zoom		  dc i2'Ignore'	     ; TASK 8 in info bar		  dc i2'MenuSelect'  ; TASK 9 in special menu		  dc i2'Ignore'	     ; TASK 10 in NDA		  dc i2'Ignore'	    ; TASK 11 in frame		  dc i2'Ignore'	     ; TASK 12 in drop	       DLogEFlags	  anop		  dc i1'0'	      ; null event		  dc i1'0'	      ; 1 MouseDown		  dc i1'0'	      ; 2 Mouse Up		  dc i1'0'	      ; 3 KeyDown		  dc i1'1'	      ; 4 Undefined		  dc i1'0'	      ; 5 AutoKey		  dc i1'0'	      ; 6 Update		  dc i1'1'	      ; 7 undefined		  dc i1'0'	      ; 8 activate		  dc i1'1'	      ; 9 Switch		  dc i1'1'	      ; 10 desk acc		  dc i1'1'	      ; 11 device driver		  dc i1'1'	      ; 12 ap		  dc i1'1'	      ; 13 ap		  dc i1'1'	      ; 14 ap		  dc i1'0'	      ; 15 ap		  dc i1'1'	      ; TASK 0 indesk		  dc i1'1'	      ; TASK 1 in menuBar		  dc i1'1'	      ; TASK 2 in system window		  dc i1'0'	      ; TASK 3 in content		  dc i1'1'	      ; TASK 4 in Drag		  dc i1'1'	      ; TASK 5 in grow		  dc i1'1'	      ; TASK 6 in goaway		  dc i1'1'	      ; TASK 7 in zoom		  dc i1'1'	      ; TASK 8 in info bar		  dc i1'1'	      ; TASK 9 in special menu		  dc i1'1'	      ; TASK 10 in NDA		  dc i1'1'	      ; TASK 11 in frame		  dc i1'1'	      ; TASK 12 in drop				  end		  EJECT********************************************************************************MenuSelect	  start** Description:	  This routine is called when TaskMaster returns a menu*		  event. It takes the menu item that was hit and calculates*		  an offset into the menu dispatch table. It then calls that*		  routine and unhilites the menu when it is done.** Inputs:	  TaskData holds menu item selected.** Outputs:	  NONE** External Refs:** Entry Points:	  NONE********************************************************************************		  using Globals		  lda TaskData	    ; Get the ID of the menu item selected.		  sec		    ; Turn it into an index by subtracting		  sbc #250	    ; the starting ID number (25) and mul-		  asl a		    ; tiplying by 2 (each table entry con-		  tax		    ; sists of 2 bytes).		  jsr (menuTable,x) ; Call the routine behind it.		  PushWord #0	    ; Routine done - unhilite the menubar.		  PushWord taskData+2		  _HiLiteMenu		  rtsMenuTable	  dc i2'Ignore'	     ; Undo Item (250)		  dc i2'Ignore'	     ; cut		  dc i2'Ignore'	     ; copy		  dc i2'Ignore'	     ; paste		  dc i2'Ignore'	     ; clear		  dc i2'DoClose'     ; close 		  dc i2'DoAbout'     ; about shell...		  dc i2'DoQuit'	     ; quit selected		  dc i2'DoModal'     ; example Modal Dialog		  dc i2'ShowModeless'		       ; example Modeless Dialog		  end		  EJECT********************************************************************************Ignore		  start** Description:	  Called when I want to ignore an event.*** Inputs:	  NONE** Outputs:	  NONE** External Refs:  NONE** Entry Points:	  NONE********************************************************************************		  rts		  end		  EJECT********************************************************************************DoQuit		  start** Description:	  Sets the quitflag to $FFFF so that the event loop will*		  know that the user wants to stop this app.*** Inputs:	  None** Outputs:	  None** External Refs:  None** Entry Points:	  None********************************************************************************		  using Globals		  lda #$FFFF		  sta QuitFlag		  rts		  end		  EJECT********************************************************************************DoClose		  start** Description:	  When the user selects the Close box of our modeless dialog or*		  the close menu Item. This routine will be called to put the dialog*		  away and clear the pointer to 0 to indicate that no Modeless dialog*		  is currently active.*** Inputs:	  None** Outputs:	  None** External Refs:  None** Entry Points:	  None********************************************************************************		  using Globals		  PushLong ModelessPtr		  _CloseDialog	    ; dump the dialog box		  stz ModelessPtr   ; zero the pointer to show that it 		  stz ModelessPtr+2 ; is put away!		  PushWord #CloseItem		      ; windows gone diable close		  _DisableMItem	    ; 		  rts		  end		  EJECT********************************************************************************ModelessEvent	  start** Description:	  This routine will be called every time an event occurs that*		  a modeless dialog should hear about. First, this routine *		  checks to see if any modeless dialog exists, if not it  *		  exits. If one does exist, this routine handles the event.*** Inputs:	  None	(All info passed in the event data)		** Outputs:	  None** External Refs:  None** Entry Points:	  None********************************************************************************		  using Globals		  lda ModelessPtr		  ora ModelessPtr+2 ; test to see if dialog exists first		  bne MLE0010	    ; if non-zero then its up		  rtsMLE0010		  anop		  PushWord #0	    ; room for result		  PushLong #Eventdata ; pointer to the event that occured		  PushLong #DlogHit ; Storage for the dialogs grafport 		  PushLong #DlogItemHit ; pointer to the item that was hit		  _DialogSelect		  pla		    ; anything hit?		  bne MLE0100	    ; if so handle the hit		  rts		    ; else DialogSelect			did what was neededMLE0100		  anop		  _Sysbeep	    ; beep on any selected item		  rts		    ; go back to the event loop		  end		  EJECT********************************************************************************ShowModeless	  start** Description:	  Called when the user wants to display the modeless dialog.*		  If the dialog is already displayed, this routine does nothing.*** Inputs:	  None** Outputs:	  None** External Refs:  None** Entry Points:	  None********************************************************************************		  using Globals		  lda ModelessPtr   ; first test to see			if box		  ora Modelessptr+2 ; is already up		  beq DML0010	    ; if 0 then its not			up		  rts		    ; if nonzero then it isDML0010		  anop		  PushLong #0	    ; room for result		  PushLong #MLRect  ; bounds rect pointer		  PushLong #MLTitle ; box title		  PushLong #-1	    ; behind pointer (-1, in front of all)		  pushWord #fTitle+fClose+fMove+fVis ; dFlag		  PushLong #0	    ; ref con of dialog		  PushLong #0	    ; zoomed rectangle,			0= no zooming		  _NewModelessDialog		  PullLong ModelessPtr ; store the result		in dialog ptr		  PushLong ModelessPtr ; now add the dialog items		  PushLong #MLINext ; first add the next button		  _GetNewDItem		  PushLong ModelessPtr		  PushLong #MLIAll		  _GetNewDItem		  PushLong ModelessPtr		  PushLong #MLIStat1		  _GetNewDItem		  PushLong ModelessPtr		  PushLong #MLIStat2		  _GetNewDItem		  PushLong ModelessPtr		  PushLong #MLIEdit1		  _GetNewDItem		  PushLong ModelessPtr		  PushLong #MLIEdit2		  _GetNewDItem		  PushWord #CloseItem		      ; we now have the dialog up so 		  _EnableMItem	    ; enable the close menu item		  rtsMLINextStr	  str 'Change Next'MLIAllStr	  str 'Change All'MLIStat1Str	  str 'Find Text:'MLIStat2Str	  str 'Change to:'MLIDefault	  str ''MLIEData1	  dc i1'31'	      ; data max will be 30 charactersMLIEData2	  dc i1'31'	      ; data max will be 30 charactersMLINext		  anop		    ; Item Templates		  dc i2'1'	     ; Item 1		  dc i2'55,10,70,120'		       ; bounding rectangle		  dc i2'ButtonItem'  ; Item Type		  dc i4'MLINextStr'  ; descriptor ( title )		  dc i2'0'	     ; initial value		  dc i2'0'	     ; item flag		  dc i4'BColorTab'   ; Custom color tableMLIAll		  anop		  dc i2'2'		  dc i2'55,180,70,290'		  dc i2'ButtonItem'		  dc i4'MLIAllStr'		  dc i2'0'		  dc i2'3'	     ; Single outline square dropshadow		  dc i4'BColorTab'   ; Custom color tableMLIStat1 	  anop		  dc i2'3'		  dc i2'12,10,22,90'		  dc i2'StatText+ItemDisable'		  dc i4'MLIStat1Str'		  dc i2'0'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; default color tableMLIStat2 	  anop		  dc i2'4'		  dc i2'32,10,42,90'		  dc i2'StatText+ItemDisable'		  dc i4'MLIStat2Str'		  dc i2'0'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; default color tableMLIEdit1 	  anop		  dc i2'5'		  dc i2'10,100,25,290'		  dc i2'EditLine+ItemDisable'		  dc i4'0'	     ; 0 for no default text		  dc i2'30'	     ; maximum length		  dc i2'0'	    ; item flag		  dc i4'0'	     ; default color tableMLIEdit2 	  anop		  dc i2'6'		  dc i2'30,100,45,290'		  dc i2'EditLine+ItemDisable'		  dc i4'MLIDefault'  ; default string		  dc i2'30'		  dc i2'0'	     ; item flag		  dc i4'0'	     ; default color table		  end		  EJECT********************************************************************************DoModal		  start** Description:	  Displays the modal Dialog and handles all events that*		  occur until the OK or Cancel buttons are pressed. If the*		  OK button is pressed, this routine also copies the current*		  data from some of the items into the item default area so*		  the next time the dialog box is brought up, it reflects the*		  users last selections.*** Inputs:	  None** Outputs:	  None*				    * External Refs:  None** Entry Points:	  None********************************************************************************		  using Globals		  PushLong #0	    ; room for result		  PushLong #ModalTemplate ; pointer to dialog template		  _GetNewModalDialog		  PullLong DialogHandle ; pull Dialog pointer for laterModalLoop	  anop		  PushWord #0	    ; Space for result		  PushLong #0	    ; Filter startedure ( 0 for none )		  _ModalDialog		  pla		  sta ItemHit		  cmp #3 	    ; test if its an exit condition		  blt ModalDone	    ; is so, then we are done			  cmp #7 	    ; see if the check box was hit		  bne ML0010	    ; if not test more		  brl ModalCheckHit ; the check box was			hitML0010		  anop		  blt ModalRadioHit ; one of the radio buttons was hit		  brl ModalLoop	    ; This should bever			happen!ModalDone	  anop		  cmp #1 	    ; was it the OK button?		  bne MD0020	    ; no, then Don't save or act on changes		  jsr SetIt	    ; else, reset defaultsMD0020		  anop		  PushLong DialogHandle ; get rid of the dialog box		  _CloseDialog		  rtsModalRadioHit	  anop; This routine sets the selected radio button. NOTE: since the radio buttons; have the same family number, this routine also resets the other buttons.		  Pushword #$FFFF   ; now set selected button		  PushLong DialogHandle		  PushWord ItemHit		  _SetDItemValue		  brl ModalLoopModalCheckHit	  anop		    ; Handle a hit in the check box		  PushWord #0		  PushLong DialogHandle		  PushWord ItemHit		  _GetDItemValue    ; first get the existing value		  pla		    ; retrieve the value		  and #$0001	    ; strip off all high bits		  eor #$0001	    ; and toggle bit 0		  pha		    ; now use it as the			new value		  PushLong DialogHandle		  PushWord ItemHit		  _SetDItemValue		  brl ModalLoopSetIt		  anop		   ; ok was hit so retrieve		  PushWord #0	    ; values and save them as default 		  PushLong DialogHandle ; in template for		next time		  PushWord #5		  _GetDItemValue		  PullWord MTRad1Def		  PushWord #0		  PushLong DialogHandle		  PushWord #6		  _GetDItemValue		  PullWord MTRad2Def		  PushWord #0		  PushLong DialogHandle		  PushWord #7		  _GetDItemValue		  PullWord MTCheckDef		  PushLong DialogHandle		  PushWord #8	    ; now retrieve the text and use it		  PushLong #MTDefaultStr		  _GetIText		  rtsItemHit		  ds 2DialogHandle	  ds 4		  end		  END