*******************************************************************************							     **	  HodgePodge:  An example Apple IIGS Desktop application 	     **							     **	  Written in 65816 Assembler by the Apple IIGS Tools Team	     **  Modified by Ben Koning for "Programmer's Introduction to the Apple IIGS"  **							     **	      Copyright (c) 1986-87 by Apple Computer, Inc.		     **							     **   ----------------------------------------------------------------------   **							     **   Modified to use the ORCA/M macros and format by Byte Works, Inc.	     **	      Copyright (c) 1989 by Byte Works, Inc.			     **							     **   ASM65816 Code file "EVENT.ASM" -- TaskMaster call; Dispatching to all    **			other routines; Menu dimming.	     **							     ************************************************************************************************************************************************* Event** This contains the main event loop.******************************************************************MainEvent start	 using GlobalDataAgain	 lda   QuitFlag			Has Quit been select?	 bne   AllDone			  ... if so, stop the loop.	 jsr   CheckFrontW		Handle the menu dis/enable	 ph2   #0	 ph2   #$FFFF	 ph4   #eventRecord	 _TaskMaster	 pla	 beq   Again			No event? loop.	 asl   a 			Multiply by two...	 tax				  use for index into...	 jsr   (TaskTable,x)		  dispatch table to execute events.	 bra   Again			Loop.AllDone	 rts;; Event manager events;TaskTable anop	 dc    i'ignore' 		0 null	 dc    i'ignore' 		1 mouse down	 dc    i'ignore' 		2 mouse up	 dc    i'ignore' 		3 key down	 dc    i'ignore' 		4 undefined	 dc    i'ignore' 		5 auto-key down	 dc    i'ignore' 		6 update event	 dc    i'ignore' 		7 undefined	 dc    i'DoActivate'		8 activate	 dc    i'ignore' 		9 switch	 dc    i'ignore' 		10 desk acc	 dc    i'ignore' 		11 device driver	 dc    i'ignore' 		12 ap	 dc    i'ignore' 		13 ap	 dc    i'ignore' 		14 ap	 dc    i'ignore' 		15 ap;; Task master events;	 dc    i'ignore' 		0 in desk	 dc    i'DoMenu' 		1 in MenuBar	 dc    i'ignore' 		2 in system window	 dc    i'ignore' 		3 in content of window	 dc    i'ignore' 		4 in drag	 dc    i'ignore' 		5 in grow	 dc    i'DoCloseItem'		6 in goaway -- same as "Close" item	 dc    i'ignore' 		7 in zoom	 dc    i'ignore' 		8 in info bar	 dc    i'DoMenu' 		9 in special menu item	 dc    i'ignore' 		10 in OpenNDA	 dc    i'ignore' 		11 in frame	 dc    i'ignore' 		in drop	 end****************************************************************** CheckFrontW** Checks to see if front window has changed and if* so deals with various menu enables and disables.* called by main event loop, and activate events.******************************************************************CheckFrontW start	 using MenuData	 using GlobalData	 ph4   #0	 _FrontWindow	 pl4   thisWindow		get the current front window	 lda   thisWindow		Check to see if it is	 cmp   lastWindow		  still the same window as	 bne   Changed			  last time	 lda   thisWindow+2	 cmp   lastWindow+2	 bne   ChangedExit1	 rts				No Change No problem....Else.Changed	 anop	 lda   thisWindow		lastWindow := thisWindow	 sta   lastWindow	 lda   thisWindow+2	 sta   lastWindow+2	 jsr   typeThisW 		set thisWType=type of the new front;					  window	 lda   thisWType 		arriving here, the window has changed.	 cmp   lastWType 		it's type may not have changed.	 beq   Exit1			Branch taken if the latter is true.!ok so start changing menus	 cmp   #0			is there a front window	 bne   ThereIs1			take this branch if there is.	 jsr   SetupForNoW		if no front window then disable	 bra   FinishUp			various thing I care about and go;					  Finish upThereIs1 anop	 cmp   #1			is it a system (Da)	 bne   NotSysW			taken if not.	 jsr   SetUpForDaW		else it is a da. do what's needed	 bra   FinishUp			  and do the exit stuffNotSysW	 jsr   SetUpForAppW		A-reg = Wtype. Go deal w/menu stuff! And drop into exit stuffFinishUp lda   needToUpdate		has the menu bar changed	 beq   ReallyDone		taken if not. else	 _DrawMenuBar			we need to re-draw the menu	 stz   needToUpdate		  and say we did it.ReallyDone lda thisWType 		lastWType := thisWType	 sta   lastWType	 rts;; figure out the type of the front window.; 0= there is no window. 1= it's a DA window. 2= App Font Win. 3= App Pic Win.;TypeThisW anop	 lda   thisWindow		was there a window at all ?	 ora   thisWindow+2	 sta   thisWType 		if no front window then ThisWtype=0	 beq   doneEarly 		taken if there really was no front win	 ph2   #0			get and save whether or not	 ph4   thisWindow		  this is a	 _GetSysWFlag			  system window or not.	 pla	 beq   WasApp			0 means not a sys window	 lda   #1			it's a sys (da) window so	 sta   thisWType 		set lastwtype = 1DoneEarly rtsWasApp	 anop				it's an app win. find out what kind.	 ph4   #0			space for get ref con in a sec	 ph4   thisWindow		else I have the window ptr	 _GetWrefCon			get refcon it has handle to data	 pla				recon handle to	 sta   temp			temp and A/X	 plx	 stx   temp+2	 jsr   DeRef			lock it down for a sec	 sta   0	 stx   2	 ldy   #oFlag			check if picture	 lda   [0],y			get window type	 beq   PicW	  lda  #2			it's a font window so...	  sta  ThisWType 		  say so and	  bra  OuttaHere 		  splitPicW	 lda   #3			it's a pic window. so	 sta   thisWType 		  say so and split.OuttaHere lda  temp	 ldx   temp+2	 jsr   Unlock			unlock the refcon handle.	 rtstemp	       ds     4thisWindow     ds     4lastWindow     ds     4	       end****************************************************************** DoQuitItem** Sets quit flag.*****************************************************************doQuitItem start	 using GlobalData	 lda   #True	 sta   quitFlag	 rts	 end******************************************************************** DoActivate** Handles activation of windows and adjusts the edit meun* based on window type.*******************************************************************DoActivate start	 using GlobalData	 lda   eventModifiers	 and   #1	 beq   End			don't care about deactivate ?	 jsr   CheckFrontWEnd	 rts	 end******************************************************************** SetUpForAppW** Sets the edit menu items up for the application window:* that is disabling them. And sets the other file menu items* accordingly.*******************************************************************SetUpForAppW  start	 using GlobalData	 using MenuData	 ph4   #0			get ready to call changeMitems	 ph2   #saveID			We gonna do save item. but we need	 lda   ThisWType 		to figure out whether it should be	 cmp   #3			  enabled or not. is it a font window ?	 bne   NoSaveEnable		  if so dont enable the save item.	 ph2   #True			else push true for enable	 bra   ContNoSaveEnable ph2  #FalseCont	 ph2   #closeWID	 ph2   #True	 lda   printAvail	 beq   SkipPrint  	 ph2   #printID	 ph2   #True	 ph2   #setUpID	 ph2   #TrueSkipPrint jsr  ChangeMItems	 lda   lastWType	 cmp   #1			was it a da last ?	 bne   Exit			if not we don't need to do whats next	 ph2   #$0080			disable edit menu	 ph2   #editMenuID	 _SetMenuFlag	 lda   #True			set update flag so I only redraw	 sta   needToUpdate		the menu bar onceExit	 rts	 end******************************************************************** SetUpForNoW** Sets the edit menu items up for the desk acc window:* that is enabling edit menu, and close in file menu.* accordingly.********************************************************************SetUpForNoW start	 using GlobalData	 using MenuData	 ph4   #0			end of list mark first...	 ph2   #saveID			  disble save	 ph2   #False			  i desire disable.	 ph2   #printID	 ph2   #False	 ph2   #setUpID	 ph2   #False	 ph2   #closeWID	 ph2   #False			enable	 jsr   ChangeMItems	 lda   lastWType 		what was it last	 cmp   #1			was it a DA last ?	 bne   Exit			if not we don't need to do whats next	 ph2   #$0080			disable edit menu	 ph2   #editMenuID	 _SetMenuFlag	 lda   #True			set update flag so I only redraw	 sta   needToUpdate		  the menu bar onceExit	 rts	 end******************************************************************** SetUpForDaW** Sets the edit menu items up for the desk acc window:* that is enabling edit menu, and close in file menu.* accordingly.********************************************************************SetUpForDaW start	 using GlobalData	 using MenuData	 ph4   #0			end of list mark first...	 ph2   #saveID			  disble save	 ph2   #False			  i desire disable.	 ph2   #printID	 ph2   #False	 ph2   #setUpID	 ph2   #False	 ph2   #closeWID	 ph2   #True			enable	 jsr   ChangeMItems	 lda   lastWType 		what was it last	 cmp   #1			was it a DA window last ?	 beq   Exit			if so we don't need to do whats next	 ph2   #$ff7f			enable edit menu	 ph2   #editMenuID	 _SetMenuFlag	 lda   #True			set update flag so I only redraw	 sta   needToUpdate		  the menu bar onceExit	 rts	 end******************************************************************** ChangeMItems** Enables/Disables the various menu items according to the* flags pushed on stack.** Entry Stack Looks like:**		 0			;long indicator of end of items*		 ItemID			;word item id*		 Enable/Disable Flag	;(word) true = enable*		 .*		 ItemID			;word item id*		 Enable/Disable Flag	;(word) true = enable*		 .*		 Return			;word*	 Sp =>*******************************************************************ChangeMItems start	 pla	 sta   RtaTemp			save returnLp	 lda   3,s			check for end of list mark	 beq   Done			if so split	 pla	 bne   DoEnable			taken if we should enable items	 _DisableMItem			else disable them	 bra   Lp			  and start overDoEnable _EnableMItem			enable item	 bra   Lp			one more timeDone	 pla				pull end of list mark	 pla	 ph2   RtaTemp			push return address	 rtsRtaTemp	   ds  2EnableFlag ds  2	 end	 append Menu.Asm