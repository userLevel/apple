/*	makeData 	Convert binary data in input file to hex characters in output.				Reads 'argv[1]'; Writes to 'argv[1].h'				Each input byte is written as TWO hexadecimal characters,                prefixed by '0x' and separated by commas. This allows them                to be used as C array initializers. Fifteen input bytes are                written to each output line (except perhaps the last).				A prefix line will contain a comment naming the input file.				Peter Watson, May 1993.Example:	Input data:	0123456789AB...CDEF		(512 input bytes in file 'fred')			Output	  :	/* Data from input file 'fred' * /			            char binData[512] = {						0x01,0x23,0x45,0x67,0x89,0xAB,...,            			0xCD,0xEF                        };Future plans:1) Support -A flag to allow 'assembler' format output to be generated2) Support -H flag to add a header (and trailer) allowing the output file   to be separately compiled.*/#pragma lint -1#include <stdio.h>									/* File I/O functions */#include <string.h>									/* String functions   */#define  VER  "1.0"char *compiled = "Compiled on " __DATE__ " at " __TIME__;void            exit(int);							/* From <stdlib.h> */char hex[16] = "0123456789ABCDEF";					/* Hexadecimal translation*/char name[128];										/* Filename buffer */void main(int argc, char *argv[]){FILE  *inFile, *outFile;unsigned long		b,											/* Byte count */		l;											/* Line count */unsigned int		c;											/* Bytes written per line */char	ch;/*************************************************************************/puts("Convert binary file to hex chars - v"VER"  Copyright Peter Watson, 1993");if (argc < 2)  {	puts("Syntax : makeData inFile\n");    puts("Converted data will be written to 'inFile.h'");    exit(0);} /*if*//* Open the input and output files */if ((inFile = fopen(argv[1],"rb")) == NULL)	{ printf("\nUnable to open input file '%s'\n",argv[1]); exit(-1); }printf("\nReading file '%s'\n",argv[1]);strncpy(name,argv[1],sizeof(name)-3);  strcat(name,".h"); /* Build output name*/if ((outFile = fopen(name,"w")) == NULL)	{ printf("Unable to open output file '%s'\n",name); exit(-1); }printf("Writing file '%s'\n",name);/* Write header lines (containing the filename and filesize) */fprintf(outFile,"/* Data from input file '%s' */\n",argv[1]);fseek(inFile,0L,SEEK_END);				/* Point to offset to EOF */fprintf(outFile,"char binData[%lu] = {\n",ftell(inFile));fseek(inFile,0L,SEEK_SET);				/* Point to first byte in file */                                                    /*************************************************************************//* Loop through the input file character by character */b  = 0;										/* No character read yet */l  = 0;										/* No output lines yet	*/ch = getc(inFile);							/* Get the 1st character*/if (!feof(inFile)) {	b++;									/* Count the character	*/	putc('0',outFile); putc('x',outFile);	/* '0x' prefix			*/    putc(hex[ch>>4],outFile);				/* Write high nibble	*/    putc(hex[ch&0xF],outFile);				/* Write low  nibble	*/	c = 1;									/* One output field		*/	ch = getc(inFile);						/* Get next character	*/}  else                   	puts("Input file is empty!");while (!feof(inFile)) {	b++;									/* Count the character	*/    putc(',',outFile);						/* Write separator		*/	if (c++ == 15)  {    	putc('\n',outFile);					/* Start a new line		*/		putchar('.');						/* Keep the user amused	*/	    c = 1;								/* One output field		*/        l++;								/* Add another line		*/    }/*if*/	putc('0',outFile); putc('x',outFile);	/* '0x' prefix			*/    putc(hex[ch>>4],outFile);				/* Write high nibble	*/    putc(hex[ch&0xF],outFile);				/* Write low  nibble	*/	ch = getc(inFile);						/* Get next character	*/} /*while*/                   if (c)  {   	putc('\n',outFile);						/* Complete last line	*/    l++;}/*if*/putchar('\n');/*************************************************************************//* Tell the user the results, clean up and go home */if (b)  {	fprintf(outFile,"};\n");	printf("\nConverted %lu bytes to %lu lines of data\n",b,l);}/*if*/fclose(inFile);fclose(outFile);} /*main*/