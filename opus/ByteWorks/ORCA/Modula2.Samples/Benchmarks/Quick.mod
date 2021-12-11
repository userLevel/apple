(*$Keep 'Quick'*)(*$StackSize 30000*)(*--------------------------------------------------------------*)(*                                                              *)(*  QuickSort                                                   *)(*                                                              *)(*  Creates an array of long integers, then sorts the array.    *)(*                                                              *)(*  Due to the amount of stack space required, this program     *)(*  cannot be executed from the desktop environment.  It must   *)(*  be executed from the text based shell.                      *)(*                                                              *)(*--------------------------------------------------------------*)MODULE Quick;FROM InOut IMPORT WriteString, WriteLn, WriteInt;CONST  maxNum  = 999;                        (*size of array to sort - 1*)  count   = 10;                         (*# of iterations*)  modulus = 00020000H;                  (*for random number generator*)  c       = 13849;  a       = 25173;TYPE  arrayType = ARRAY[0..maxNum] OF LONGINT;VAR  i,j: INTEGER;                         (*loop variables*)  seed: LONGINT;                        (*seed for random number generator*)  buffer: arrayType;                    (*array to sort*)  pass: BOOLEAN;                        (*for checking the array*)  PROCEDURE Quick(lo,hi: INTEGER; VAR base: arrayType);  VAR    i,j: INTEGER;    pivot,temp: LONGINT;  BEGIN    IF hi > lo THEN      pivot := base[hi];      i := lo-1;      j := hi;      REPEAT	REPEAT i := i+1 UNTIL base[i] >= pivot;	REPEAT j := j-1 UNTIL base[j] <= pivot;	temp := base[i];	base[i] := base[j];	base[j] := temp;      UNTIL j <= i;      base[j] := base[i];      base[i] := base[hi];      base[hi] := temp;      Quick(lo,i-1,base);      Quick(i+1,hi,base);    END;  END Quick;  PROCEDURE Random(size: LONGINT): LONGINT;  BEGIN    seed := seed*a+c;    RETURN seed MOD size;  END Random;BEGINseed := 7;WriteString('Filling array and sorting ');WriteInt(count, 1);WriteString(' times.');WriteLn;FOR i := 1 TO count DO  FOR j := 0 TO maxNum DO    buffer[j] := ABS(Random(modulus));  END;  Quick(0,maxNum,buffer);END;WriteString('Done.');WriteLn;pass := TRUE;FOR i := 0 TO maxNum-1 DO  IF buffer[i] > buffer[i+1] THEN    pass := FALSE;  END;END;IF pass THEN  WriteString('The last array is sorted properly.')ELSE  WriteString('The last array is NOT sorted properly!');END;WriteLn;END Quick.