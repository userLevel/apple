/*	dWrite: Write one or more blocks from a file to a disk device.	Syntax: dWrite deviceNum startBlk [endBlk | * | .count]							[-f file] [-o offsetBlk] [-z zByte]			-f file			- name of GSOS path to file to read from.				            - (Superseded) If file = "0", writes blocks of zero			-o offsetBlk	- Starting block to read from in file.			-z zByte		- Write blocks of 'zByte'	Note: Assumes enough memory is available to hold all data to be written.	V1.0	Copyright by Peter Watson, Sep 1993.	V1.1	Syntax like 'dRead'; '*'=file EOF; '-z'; multiblock i/o. Jan 95	V1.2	Support '.count' alternative to end_block. Oct 1996			Originally based on dRead, which may explain any 'funny' code.			Compiled using ORCA/C 2.10*/#include <types.h>#include <stdio.h>#include <stdlib.h>#include <orca.h>#include <gsos.h>#include <string.h>#include <ctype.h>#include <limits.h>#pragma lint -1#pragma expand 0#define VER		"1.2"char *helloMsg = \	"\nDisk Block Writer v" VER "  Copyright 1993-1996 by Peter Watson\n";char *USAGE = \"Usage: DWRITE devNum startBlk [endBlk] [-f file] [-o offsetBlk] [-z zapByte]\n"\"              (if 'endBlk' = '*', writes until end-of-file on 'file')\n" \"              (if 'endBlk' = '.nn', writes 'nn' blocks)\n" \"              (if 'zapByte' is specified, writes blocks of 'zapByte' instead)";char *Licence[] =	"This program contains material from the ORCA/C ",					"Run-Time Libraries, copyright 1987-1993",					"by Byte Works, Inc.  Used with permission.";extern int STOP_PAUSE2(void);			/* Pause on keypress or <oa-.>		*/VersionRecGS vRec = {1,0};				/* For GetVersionGS request			*/DIORecGS ioRec	  = {6,0,NULL,0,0,512L,0};/* For DWriteGS request			*/char	*buf;							/* Pointer to malloc'ed buffer		*/boolean	zero;							/* If true, write blocks of zapByte	*/word	zapByte;						/* Byte to fill blocks with if 'zero'*/#define DIGITS "0123456789"				/* Decimal digits					*/#define HEXDIGITS DIGITS"abcdefABCDEF"	/* Hexadecimal digits				*//*******************************************************/int main(int argc, char *argv[]){FILE		*fPtr;						/* File pointer					*/word		devNum;						/* Device number				*/longword	firstBlk,					/* First block to dump			*/			lastBlk,					/* Last block to dump			*/			bCount,						/* Count of blocks to dump		*/			bufsize,					/* Size of I/O buffer (and file)*/			offset;						/* Starting point for file read	*/longword	x, ver, blk, count;word		i, j, err;					/* Work variables				*/char 		ch, *b,			*fileName;					/* Pointer to filename parameter*/puts(helloMsg);err		= 0;							/* Assume no error	*/buf		= NULL;							/* No buffer yet	*/fPtr	= NULL;							/* No file yet		*/offset	= 0;							/* Start at the beginning */zero	= false;						/* Don't zero blocks */zapByte	= 0;							/* Fill zapped blocks with nulls */fileName= "";							/* Filename initially null *//* If we have enough parameters, parse for our known options */if ((argc < 5) || (*argv[1] == '?'))  {	printf(USAGE);	goto cleanup;} /*if*/GetVersionGS(&vRec);                /* Get ProDOS / GS/OS version no. */ver = vRec.version & majorRelNumMask;/* Isolate major release info    */ver = ver >> 8;                     /* Make it a 'normal' integer     */if (toolerror() || ver < 2)  {	puts("GS/OS is required to execute this program!");	goto cleanup;} /*if*//************************************************************************//* Support ProSel shell commands: Final parameter terminates with 0x0d!	*/b  = argv[argc-1];					/* Last parameter's...				*/while (*b++); b--;					/*				   ...last character*/if (*b == 0x0d)						/* Final parameter is non-standard	*/	*b = '\0';						/* Make it standard!				*//*************************//* Get the device number */b = argv[1];if (*b == '.')  {	if ((*(b+1) == 'D') || (*(b+1) == 'd'))		devNum = (word)strtoul(b+2, NULL, 10);	/* Get number */	else devNum = 0;} else	devNum = (word)strtoul(b, NULL, 10);		/* Get number */if (!devNum)  {	puts("Error: Invalid device number!");	err = -1;	goto cleanup;}/*if*//*********************************//* Get the starting block number */if ((argc < 3) || (*argv[2] == '-'))  {	/* Switch? */	*buf = '\0';	printf("Enter starting block number >");	gets(buf);	if (*buf == '\0')							/* He changed his mind */		goto cleanup;	b = buf;} else	b = argv[2];firstBlk = ULONG_MAX;								/* Same as strtoul error */if (*b == '$')  {	if (strspn(b+1, HEXDIGITS) == strlen(b+1))		/* Good hex string */		firstBlk = (longword)strtoul(b+1, NULL, 16);/* Get hex number */} else  {	if (strspn(b, DIGITS) == strlen(b))				/* Good decimal string */		firstBlk = (longword)strtoul(b, NULL, 10);	/* Get decimal number */}/*else*/if (firstBlk == ULONG_MAX)  {	puts("Error: Starting block number invalid!");	err = -1;	goto cleanup;}/*if*//* Nb: The pointer 'b' is reused below if no ending_block is entered! *//*********************************//* Get the ending block number */if (argc < 1)  {	*buf = '\0';	printf("Enter ending block number >");	gets(buf);	if (*buf == '\0')			/* He changed his mind */	goto cleanup;	b = buf;} elseif ((argc < 4) || (*argv[3] == '-'))	/* Switch? */	;							/* ie. reuse 'starting block' parm */else	b = argv[3];lastBlk = ULONG_MAX;								/* Same as strtoul error */if (*b == '*')	lastBlk = 0xffffff;								/* ie. File eof */elseif (*b == '$')  {	if (strspn(b+1, HEXDIGITS) == strlen(b+1))		/* Good hex string */		lastBlk = (longword)strtoul(b+1, NULL, 16);	/* Get hex number */}  elseif (*b == '.')  {				/* Block count, not end block */	bCount = -1;	if (*(b+1) == '$')  {		if (strspn(b+2, HEXDIGITS) == strlen(b+2))	/* Good hex string */			bCount = (longword)strtoul(b+2, NULL, 16);/* Get hex number */	} else {		if (strspn(b+1, DIGITS) == strlen(b+1))		/* Good decimal string */			bCount = (longword)strtoul(b+1, NULL, 10);/* Get decimal number */	}/*else*/	if (bCount == -1)  {		puts("Error: Block count number invalid!");		err = -1;		goto cleanup;	}/*if*/	lastBlk = firstBlk + bCount - 1;}  else  {	if (strspn(b, DIGITS) == strlen(b))				/* Good decimal string */		lastBlk = (longword)strtoul(b, NULL, 10);	/* Get decimal number */}/*else*/if (lastBlk == ULONG_MAX)  {	puts("Error: Ending block number invalid!");	err = -1;	goto cleanup;}/*if*/if (lastBlk < firstBlk)  {	puts("Error: Ending block number less than starting block number!");	err = -1;	goto cleanup;}/*if*//*********************//* Find any switches */for (i=3; i<argc; i++)  {	/* Check all parms */	if (*argv[i] == '-')	/* Found a switch */		switch (ch = toupper(argv[i][1]))  {			case 'O' :	b = argv[++i];						if (i >= argc || !*b)  {							puts("Error: Missing offset value!");							puts(USAGE);							err = -1;							goto cleanup;						}/*if*/						if (*b == '$')							offset = strtoul(b+1, NULL, 16);	/* Hex */						else							offset = strtoul(b, NULL, 10);		/* Decimal */						printf("File will be read starting at block %lu\n\n", \								offset);						offset = offset << 9;	/* Blocks -> bytes */						break;			case 'F' :	b = argv[++i];						if (i >= argc || !*b)  {							puts("Error: Missing filename parameter!");							puts(USAGE);							err = -1;							goto cleanup;						}/*if*/						fileName = b;						break;			case 'Z' :	b = argv[++i];						if (i >= argc || !*b)  {							puts("Error: Missing zap block byte parameter!");							puts(USAGE);							err = -1;							goto cleanup;						}/*if*/						zapByte = 256;		/* Impossible 'byte' value */						if (*b == '$')  {							if (strspn(b+1, HEXDIGITS) == strlen(b+1))								zapByte = (word)strtoul(b+1, NULL, 16);						} else  {							if (strspn(b, DIGITS) == strlen(b))								zapByte = (word)strtoul(b, NULL, 10);						}/*else*/						if (zapByte > 255)  {							puts("Error: Invalid zap block byte!");							err = -1;							goto cleanup;						} /*if*/						zero = true;						break;			default  :	printf("Error: Unknown switch character '%c'!\n", ch);						puts(USAGE);						err = -1;						goto cleanup;						break;		} /*switch*/}/*for*/if (!zero)								/* If not already set by '-z' */	zero = !strcmp(fileName, "0");		/* Write zero blocks? */if (zero && lastBlk == 0xffffff)  {	puts("Error: Cannot specify '*' for end block with '0' file option!");	err = -1;	goto cleanup;}/*if*//****************************************************//* Open the file and move to the appropriate offset */bufsize = (lastBlk - firstBlk + 1) << 9;if (!zero)  {	fPtr = fopen(fileName, "rb");	if (fPtr == NULL)  {		printf("Error: Unable to open file '%s'!\n", fileName);		err = -1;		goto cleanup;	}/*if*/	fseek(fPtr, 0L, SEEK_END);	if (lastBlk == 0xffffff)  {				/* End_Block = '*' */		bufsize = ftell(fPtr) - offset;		/* How big a buffer do we need? */		lastBlk = firstBlk + (bufsize >> 9) - 1;	}  else	if (offset+bufsize > ftell(fPtr))  {		puts("Error: Offset (plus blocks to be written) > file length!");		err = -1;		goto cleanup;	}/*if*/	if (fseek(fPtr, offset, SEEK_SET))  {		blk = offset>>9;		printf("Error: Unable to find block $%lX (%lu) in file!\n", blk, blk);		err = -1;		goto cleanup;	}/*if*/}/*if*//***************************//* Allocate the I/O buffer */buf = malloc(bufsize);				/* Allocate an I/O buffer */if (buf == NULL)  {	printf("Error: Unable to allocate memory buffer of %lu bytes!\n", bufsize);	goto cleanup;}/*if*/if (zero)	memset(buf, zapByte, bufsize);	/* Clear to zapByte's for 'zero' option *//*******************//* Write a message */printf("Writing block");if (firstBlk < lastBlk)	printf("s %lu ($%lX) to", firstBlk, firstBlk);printf(" %lu ($%lX) to device %u ", lastBlk, lastBlk, devNum);if (zapByte)	printf("as all $%0.2X bytes\n\n", zapByte);elseif (zero)	printf("as all zeroes\n\n");else	printf("from file '%s'\n\n", fileName);/**********************************//* Read the file (unless zeroing) */if (!zero)  {	count = fread(buf, 1L, bufsize, fPtr);	/* Read bufsize 1-byte elements */	if (!count)  {		printf("Error: File '%s' is empty!\n", fileName);		err = -1;		goto cleanup;	}/*if*/	if (count < bufsize)  {		blk = ((bufsize - count) >> 9);		printf("Error: File '%s' is %lu block(s) too short!\n", fileName, blk);		err = -1;		goto cleanup;	}/*if*/	if (ferror(fPtr))  {		blk = ((offset + count) >> 9);		printf("Error reading block $%lX from '%s'!\n", blk, fileName);		err = -1;		goto cleanup;	}/*if*/}/*if*/if (STOP_PAUSE2())				/* User pressed <Command-.> */	goto cleanup;/*********//* Write */ioRec.buffer		= buf;		/* Put buffer ptr in dWrite parm list */ioRec.devNum 		= devNum;	/* Put devnum in dWrite parm list */ioRec.startingBlock = firstBlk;ioRec.requestCount	= bufsize;	/* Do it all! */Write_Block:							/* Retry on 'disk switched' errors */DWriteGS(&ioRec);						/* Write the block */if (err = toolerror())  {	blk = firstBlk + (ioRec.transferCount >> 9);	/* Error block number */	switch (err)  {		case devNotFound:				/* Device not found		*/		case invalidDevNum:				/* Invalid device number*/			printf("Error: Device %u not found!\n", devNum);			goto cleanup;		case drvrWrtProt :				/* Write protected 		*/			puts("Error: Disk is write protected! Remove protection and retry.");			goto cleanup;		case drvrDiskSwitch:		    /* Disk switched error	*/			goto Write_Block;			/* Simply try again		*/		case drvrOffLine:				/* No disk in drive		*/			puts("Error: No disk in drive!");			goto cleanup;		case drvrBadBlock:				/* Bad block			*/		case outOfRange:				/* Parm out of range	*/			printf("Error: Block $%lX (%lu) does not exist!\n", blk, blk);			goto cleanup;		case notBlockDev:				/* Not a block device	*/			printf("Error: Device %u is not a block device!\n", devNum);		goto cleanup;		default :			printf("Error $%0.4X writing block $%lX (%lu)!\n", err, blk, blk);			goto cleanup;	}/*switch*/}/*if*//************************//* Clean up and go home */cleanup:if (fPtr != NULL)						/* If file is open, close it */	fclose(fPtr);if (buf != NULL)						/* If buffer allocated, free it */	free(buf);exit(err);}/*main*//*******************************************************/