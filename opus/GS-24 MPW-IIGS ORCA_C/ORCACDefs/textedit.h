/********************************************** TextEdit Tool Set** Copyright Apple Computer, Inc.1986-90* All Rights Reserved** Copyright 1992, Byte Works, Inc.*********************************************/#ifndef __TYPES__#include <TYPES.h>#endif#ifndef __TEXTEDIT__#define __TEXTEDIT__/* Error Codes */#define teAlreadyStarted 0x2201#define teNotStarted 0x2202#define teInvalidHandle 0x2203#define teInvalidVerb 0x2204#define teInvalidFlag 0x2205#define teInvalidPCount 0x2206#define teInvalidRect 0x2207#define teBufferOverflow 0x2208#define teInvalidLine 0x2209#define teInvalidCall 0x220A/* TE Verbs */#define NullVerb 0x0000#define PStringVerb 0x0001#define CStringVerb 0x0002#define C1InputVerb 0x0003#define C1OutputVerb 0x0004#define HandleVerb 0x0005#define PointerVerb 0x0006#define NewPStringVerb 0x0007#define fEqualLineSpacing 0x8000#define fShowInvisibles 0x4000#define teInvalidDescriptor 0x2204#define teInvalidParameter 0x220B#define teInvalidTextBox2 0x220C#define teNeedsTools 0x220D  /* 8717 */#define teEqualLineSpacing 0x8000#define teShowInvisibles 0x4000/* Justification Values */#define leftJust 0x0000#define rightJust 0xFFFF#define centerJust 0x0001#define fullJust 0x0002/* TERuler.tabType Codes */#define noTabs 0x0000#define stdTabs 0x0001                  /* Tabs every tabTerminator pixels */#define absTabs 0x0002                  /* Tabs at absolute location specified by theTabs array *//* TEParamBlock.flags Codes */#define fCtlInvis 0x0080#define fRecordDirty 0x0040/* TE Tab Codes */#define teLeftTab 0x0000#define teCenterTab 0x0001#define teRightTab 0x0002#define teDecimalTab 0x0003/* TEParamBlock.textFlags Codes */#define fNotControl 0x80000000L         /* TextEdit record is not a control */#define fSingleFormat 0x40000000L       /* Only one ruler is allowed for record */#define fSingleStyle 0x20000000L        /* Only one style is allowed for record */#define fNoWordWrap 0x10000000L         /* No word wrap is performed */#define fNoScroll 0x08000000L           /* The text cannot scroll */#define fReadOnly 0x04000000L           /* The text cannot be edited */#define fSmartCutPaste 0x02000000L      /* Record supports intelligent cut and paste */#define fTabSwitch 0x01000000L          /* Tab key switches user to next TextEdit record on the screen */#define fDrawBounds 0x00800000L         /* TextEdit draw a box around text */#define fColorHilight 0x00400000L       /* Use color table for highlighting */#define fGrowRuler 0x00200000L          /* Adjust right margin whenever window size changes */#define fDisableSelection 0x00100000L   /* User cannot select or edit text */#define fDrawInactiveSelection 0x00080000L /* TextEdit displays a box around an inactive selection *//* Descriptor Codes */#define teCtlColorIsPtr 0x0000#define teCtlColorIsHandle 0x0004#define teCtlColorIsResource 0x0008#define teCtlStyleIsPtr 0x0000#define teCtlStyleIsHandle 0x0001#define teCtlStyleIsResource 0x0002#define teRefIsPtr 0x0000#define teRefIsHandle 0x0001#define teRefIsResource 0x0002#define teRefIsNewHandle 0x0003#define teDataIsPString 0x0000#define teDataIsCString 0x0001#define teDataIsC1Input 0x0002#define teDataIsC1Output 0x0003#define teDataIsTextBox2 0x0004#define teDataIsTextBlock 0x0005#define teTextIsPtr 0x0000#define teTextIsHandle 0x0008#define teTextIsResource 0x0010#define teTextIsNewHandle 0x0018/* TEGetLastError clearFlag Codes */#define fLeaveError 0x0000              /* Leave the last error code intact */#define fClearError 0xFFFF              /* Clear the last error code *//* Other Constants */#define teInvis 0x4000#define tePartialLines 0x8000L#define teDontDraw 0x4000#define teUseFont 0x0020#define teUseSize 0x0010#define teUseForeColor 0x0008#define teUseBackColor 0x0004#define teUseUserData 0x0002#define teUseAttributes 0x0001#define teReplaceFont 0x0040#define teReplaceSize 0x0020#define teReplaceForeColor 0x0010#define teReplaceBackColor 0x0008#define teReplaceUserField 0x0004#define teReplaceAttributes 0x0002#define teSwitchAttributes 0x0001/* Filter Procedure Commands */#define doEraseRect 0x0001#define doEraseBuffer 0x0002#define doRectChanged 0x0003#define doKeyStroke 0x0004/* TEScroll descriptors */#define teScrollAbsTop 0x0000           /* 0 */#define teScrollAbsCenter 0x0001        /* 1 */#define teScrollLineTop 0x0002          /* 2 */#define teScrollLineCenter 0x0003       /* 3 */#define teScrollAbsUnit 0x0004          /* 4 */#define teScrollRelUnit 0x0005          /* 5 */struct TETextBlock {   struct TETextBlock **nextHandle;     /* Handle to next TextBlock in list */   struct TETextBlock **prevHandle;     /* Handle to previous TextBlock in list */   LongWord textLength;                 /* Number of bytes of theText */   Word flags;   Word reserved;                       /* Reserved */   Byte theText[1];                     /* textLength bytes of text  */   };typedef struct TETextBlock TETextBlock, *TETextBlockPtr, **TETextBlockHndl;struct TETextList {   TETextBlockHndl cachedHandle;        /* Handle to current TextBlock */   LongWord cachedOffset;               /* Text offset of the start of the current TextBlock */   };typedef struct TETextList TETextList, *TETextListPtr, **TETextListHndl;struct TEColorTable {   Word contentColor;   Word outlineColor;   Word hiliteForeColor;   Word hiliteBackColor;   Word vertColorDescriptor;   LongWord vertColorRef;   Word horzColorDescriptor;   LongWord horzColorRef;   Word growColorDescriptor;   LongWord growColorRef;   };typedef struct TEColorTable TEColorTable, *TEColorTablePtr, **TEColorTableHndl;struct TEBlockEntry {   Handle text;   Handle length;   Word flags;   };typedef struct TEBlockEntry TEBlockEntry;struct TEBlocksRecord {   LongWord start;   Word index;   TEBlockEntry blocks[1];   };typedef struct TEBlocksRecord TEBlocksRecord, *TEBlocksPtr, **TEBlocksHndl;struct TabItem {   Word tabKind;   Word tabData;   };typedef struct TabItem TabItem;struct TESuperItem {   LongWord itemLength;   LongWord itemData;   };typedef struct TESuperItem TESuperItem, *TESuperItemPtr, **TESuperItemHndl;struct TESuperBlock {   struct TESuperBlock **nextHandle;   struct TESuperBlock **prevHandle;   LongWord textLength;   LongWord reserved;   TESuperItem theItems[1];   };typedef struct TESuperBlock TESuperBlock, *TESuperBlockPtr, **TESuperBlockHndl;struct TESuperHandle {   TESuperBlockHndl cachedHandle;   LongWord cachedOffset;   Word cachedIndex;   Word itemsPerBlock;   };typedef struct TESuperHandle TESuperHandle, *TESuperHandlePtr, **TESuperHandleHndl;struct TERuler {   Word leftMargin;   Word leftIndent;   Word rightMargin;   Word just;   Word extraLS;   Word flags;   LongWord userData;   Word tabType;   TabItem theTabs[1];   Word tabTerminator;   };typedef struct TERuler TERuler, *TERulerPtr, **TERulerHndl;struct TEStyle {   FontID styleFontID;   Word foreColor;   Word backColor;   LongWord userData;   };typedef struct TEStyle TEStyle, *TEStylePtr, **TEStyleHndl;struct TEStyleGroup {   Word count;   TEStyle styles[1];   };typedef struct TEStyleGroup TEStyleGroup, *TEStyleGroupPtr, **TEStyleGroupHndl;struct StyleItem {   LongWord dataLength;                 /* Number of text characters using the style */   LongWord dataOffset;                 /* Byte offset into theStyleList entry */   };typedef struct StyleItem StyleItem, *StyleItemPtr, **StyleItemHndl;typedef long TERulerRef;/*    The following data structure (TEFormat) is for reference only!    It contains embedded variable length fields.*/struct TEFormat {   Word version;   LongWord rulerListLength;   TERuler theRulerList[1];   LongWord styleListLength;   TEStyle theStyleList[1];   LongWord numberOfStyles;   StyleItem theStyles[1];   };typedef struct TEFormat TEFormat, *TEFormatPtr, **TEFormatHndl;typedef struct TETextRef {   Ptr TETextDesc;   } TETextRef,*TETextRefPtr, **TETextRefHndl;typedef struct TEStyleRef {   Ptr TEStyleDesc;   } TEStyleRef,*TEStyleRefPtr,**TEStyleRefHndl;typedef long TEColorRef;struct TEParamBlock {   Word pCount;   LongWord controlID;   Rect boundsRect;   LongWord procRef;   Word flags;   Word moreflags;   LongWord refCon;   LongWord textFlags;   Rect indentRect;   CtlRecHndl vertBar;   Word vertAmount;   CtlRecHndl horzBar;   Word horzAmount;   TEStyleRef styleRef;   Word textDescriptor;   TETextRef textRef;   LongWord textLength;   LongWord maxChars;   LongWord maxLines;   Word maxCharsPerLine;   Word maxHeight;   TEColorRef colorRef;   Word drawMode;   ProcPtr filterProcPtr;   };typedef struct TEParamBlock TEParamBlock, *TEParamBlockPtr, **TEParamBlockHndl;struct TEInfoRec {   LongWord charCount;   LongWord lineCount;   LongWord formatMemory;   LongWord totalMemory;   LongWord styleCount;   LongWord rulerCount;   };typedef struct TEInfoRec TEInfoRec;struct TEHooks {   ProcPtr charFilter;   ProcPtr wordWrap;   ProcPtr wordBreak;   ProcPtr drawText;   ProcPtr eraseText;   };typedef struct TEHooks TEHooks;struct TEKeyRecord {   Word theChar;   Word theModifiers;   Handle theInputHandle;   LongWord cursorOffset;   Word theOpCode;   };typedef struct TEKeyRecord TEKeyRecord, *TEKeyRecordPtr, **TEKeyRecordHndl;struct TERecord {   CtlRecHndl ctrlNext;   WindowPtr inPort;   Rect boundsRect;   Byte ctrlFlag;   Byte ctrlHilite;   Word lastErrorCode;   ProcPtr ctrlProc;   ProcPtr ctrlAction;   ProcPtr filterProc;   LongWord ctrlRefCon;   TEColorTablePtr colorRef;   LongWord textFlags;   LongWord textLength;   TETextList blockList;   LongWord ctrlID;   Word ctrlMoreFlags;   Word ctrlVersion;   Rect viewRect;   LongWord totalHeight;   TESuperHandle lineSuper;   TESuperHandle styleSuper;   Handle styleList;   Handle rulerList;   Boolean lineAtEndFlag;   LongWord selectionStart;   LongWord selectionEnd;   Word selectionActive;   Word selectionState;   LongWord caretTime;   Boolean nullStyleActive;   TEStyle nullStyle;   LongWord topTextOffset;   Word topTextVPos;   CtlRecHndl vertScrollBar;   LongWord vertScrollPos;   LongWord vertScrollMax;   Word vertScrollAmount;   CtlRecHndl horzScrollBar;   LongWord horzScrollPos;   LongWord horzScrollMax;   Word horzScrollAmount;   CtlRecHndl growBoxHandle;   LongWord maximumChars;   LongWord maximumLines;   Word maxCharsPerLine;   Word maximumHeight;   Word textDrawMode;   ProcPtr wordBreakHook;   ProcPtr wordWrapHook;   ProcPtr keyFilter;   Rect theFilterRect;   Word theBufferVPos;   Word theBufferHPos;   TEKeyRecord theKeyRecord;   LongWord cachedSelcOffset;   Word cachedSelcVPos;   Word cachedSelcHPos;   Rect mouseRect;   LongWord mouseTime;   Word mouseKind;   Point lastClick;   Word savedHPos;   LongWord anchorPoint;   };typedef struct TERecord TERecord, *TERecordPtr, **TERecordHndl;extern pascal void TEBootInit(void) inline(0x0122,dispatcher);extern pascal void TEStartUp(Word, Word) inline(0x0222,dispatcher);extern pascal void TEShutDown(void) inline(0x0322,dispatcher);extern pascal Word TEVersion(void) inline(0x0422,dispatcher);extern pascal void TEReset(void) inline(0x0522,dispatcher);extern pascal Word TEStatus(void) inline(0x0622,dispatcher);extern pascal void TEActivate(Handle) inline(0x0F22,dispatcher);extern pascal void TEClear(Handle) inline(0x1922,dispatcher);extern pascal void TEClick(EventRecordPtr, Handle) inline(0x1122,dispatcher);extern pascal void TECompactRecord(Handle) inline(0x2822,dispatcher);extern pascal void TECopy(Handle) inline(0x1722,dispatcher);extern pascal void TECut(Handle) inline(0x1622,dispatcher);extern pascal void TEDeactivate(Handle) inline(0x1022,dispatcher);extern pascal ProcPtr TEGetDefProc(void) inline(0x2222,dispatcher);extern pascal ProcPtr TEGetInternalProc(void) inline(0x2622,dispatcher);extern pascal Word TEGetLastError(Word, Handle) inline(0x2722,dispatcher);extern pascal void TEGetRuler(Word, Ref, Handle) inline(0x2322,dispatcher);extern pascal void TEGetSelection(Pointer, Pointer, Handle) inline(0x1C22,dispatcher);extern pascal Word TEGetSelectionStyle(TEStylePtr, Handle, Handle) inline(0x1E22,dispatcher);extern pascal LongWord TEGetText(Word, Ref, Long, Word, Ref, Handle) inline(0x0C22,dispatcher);extern pascal void TEGetTextInfo(Pointer, Word, Handle) inline(0x0D22,dispatcher);extern pascal void TEIdle(Handle) inline(0x0E22,dispatcher);extern pascal void TEInsert(Word, Ref, Long, Word, Ref, Long) inline(0x1A22,dispatcher);extern pascal void TEKey(EventRecordPtr, Handle) inline(0x1422,dispatcher);extern pascal void TEKill(Handle) inline(0x0A22,dispatcher);extern pascal TERecordHndl TENew(TEParamBlockPtr) inline(0x0922,dispatcher);extern pascal void TEOffsetToPoint(Long, Long *, Long *, Handle) inline(0x2022,dispatcher);extern pascal LongWord TEPaintText(GrafPortPtr, Long, Rect *, Word, Handle) inline(0x1322,dispatcher);extern pascal void TEPaste(Handle) inline(0x1822,dispatcher);extern pascal LongWord TEPointToOffset(Long, Long, Handle) inline(0x2122,dispatcher);extern pascal void TEReplace(Word, Ref, Long, Word, Ref, Handle) inline(0x1B22,dispatcher);extern pascal void TEScroll(Word, Long, Long, Handle) inline(0x2522,dispatcher);extern pascal void TESetRuler(Word, Ref, Handle) inline(0x2422,dispatcher);extern pascal void TESetSelection(Pointer, Pointer, Handle) inline(0x1D22,dispatcher);extern pascal void TESetText(Word, Ref, Long, Word, Ref, Handle) inline(0x0B22,dispatcher);extern pascal void TEStyleChange(Word, TEStylePtr, Handle) inline(0x1F22,dispatcher);extern pascal void TEUpdate(Handle) inline(0x1222,dispatcher);/* This call appeared in Apple's interfaces, but is not documented.extern pascal void TEInsertPageBreak() inline(0x1522,dispatcher);*/#endif