{---------------------------------------------------------------}{                                                               }{  Speak                                                        }{                                                               }{  A "plain vanilla" program that demonstrates all of the calls }{  available in the Speech Toolkit.                             }{                                                               }{  By Barbara Allred                                            }{                                                               }{  Copyright 1991 by Byte Works, Inc.                           }{  Copyright 1987 - 1991 by First Byte, Inc.                    }{                                                               }{---------------------------------------------------------------}{$keep 'Speak'}program Speak (input, output);uses Common, ToolLocator, IntegerMath, SpeechTools;var   answer: string;                      {user's response to queries}   done: boolean;                       {true if user wants to exit pgm}   toolRec: toolTable;                  {table of tools we need to start}   voice: Gender;                       {current global voice setting}   basePitch: Tone;                     {current global tone setting}   speed,                               {current global speed setting}   pitch,                               {current global pitch setting}   volume: ParmRange;                   {current global volume setting}{---------------------------------------------------------------}{                                                               }{  ConvertToPhonetics - Convert English text to phonetic        }{       representation.                                         }{                                                               }{---------------------------------------------------------------}procedure ConvertToPhonetics;var   phString: packed array[0..255] of char; {phonetic string}   sayString: packed array[0..255] of char; {English text to speak or parse}   size: integer;                       {length of string}   start: integer;                      {position in English string to begin}                                        { conversion                        }   stop: boolean;                       {true if user wants to exit}begin {ConvertToPhonetics}stop := false;{Outer loop lets user enter next string to convert.}{Entering null string signals it's time to exit.}repeat   writeln;   writeln('Enter string to translate to phonetics.  Press RETURN to exit.');   readln(sayString);   size  := length(sayString);   start := 0;   {Inner loop is necessary in the event that the }   { complete English string wasn't converted.    }   if size > 0 then begin      repeat         start := start+1;         start := Parse(sayString, phString, start);         write(phString);      until start = size;      writeln;      end {if}   else      stop := true;until stop;end; {ConvertToPhonetics}{---------------------------------------------------------------}{                                                               }{  DeleteWord - Removes entries from the current exceptions     }{       dictionary.                                             }{                                                               }{---------------------------------------------------------------}procedure DeleteWord;var   stop: boolean;                       {true if user wants to exit}   word: pString32;                     {dictionary entry}begin {DeleteWord}stop := false;writeln;repeat   writeln('Press RETURN for the dictionary entry to exit function.');   write('Word to delete from dictionary?  ');   readln(word);   if length(word) = 0 then      stop := true   else      DictDelete(word);   writeln;until stop;writeln;end; {DeleteWord}{---------------------------------------------------------------}{                                                               }{  DisplayDict - Displays current exceptions dictionary, one    }{       entry at a time.                                        }{                                                               }{---------------------------------------------------------------}procedure DisplayDict;var   answer: string;                      {user's response to queries}   flag: integer;                       {dict. initialization flag}   noErr: boolean;                      {true if no error has occurred}   stop: boolean;                       {true if user wants to exit}   word1, word2: pString32;             {dictionary entry}   wordPtr: pString32Ptr;               {pointer returned by DictDump function}begin {DisplayDict}writeln;{Before displaying the dictionary, let user initialize it.}repeat   noErr := true;   writeln('Before displaying the dictionary, lets initialize it.');   writeln('Enter 0 to reset dictionary to beginning.');   writeln('Enter 1 to delete current dictionary.');   writeln('Enter 2 to NOT initialize dictionary.');   writeln;   readln(flag);   if (flag < 0) or (flag > 2) then begin       noErr := false;       writeln;       writeln('Please enter either 0, 1, or 2.');       writeln;       end; {if}until noErr;if flag <> 2 then   DictInit(flag);{While there are still entries in the dictionary, }{ get and then display the next entry.            }stop := false;repeat   wordPtr := DictDump(word1, word2);   if length(word1) = 0 then      stop := true   else begin      writeln('Next entry:   ', word1, '   ', word2, '   Continue? (Y or N)');      readln(answer);      if (answer[1] = 'N') or (answer[1] = 'n') then         stop := true;      end; {else}until stop;writeln;end; {DisplayDict}{---------------------------------------------------------------}{                                                               }{  Init - Load the tools we need and initialize our data        }{       structures.                                             }{                                                               }{---------------------------------------------------------------}procedure Init;var   errNum: integer;                     {error number to report to user}   errString: packed array[1..5]   of char; {error number as a hex string}begin {Init}errString[1] := '$';                    {return error codes as hex numbers}with toolRec do begin   numToolsRequired := 4;   with tool[1] do begin      toolNumber := maleToolNum;      minVersion := 0;      end; {with}   with tool[2] do begin      toolNumber := femaleToolNum;      minVersion := 0;      end; {with}   with tool[3] do begin      toolNumber := parserToolNum;      minVersion := 0;      end; {with}   with tool[4] do begin      toolNumber := speechToolNum;      minVersion := 0;      end; {with}   end; {with}LoadTools(toolRec);                     {load the tools}errNum := toolError;if errNum <> 0 then begin               {report any error returned}   Int2Hex(errNum, pointer(@errString[2]), 4);   writeln('Unable to load tools: Error = ', errString);   done := true;   end {if}else begin                              {start the tools}   ParseStartUp(userID);   MaleStartUp;   FemaleStartUp;   SpeechStartUp;   done := false;                       {initialize globals}   voice := male;                       {these are the default settings for}   basePitch := bass;                   {the global speech parameters}   speed := 5;   volume := 5;   pitch := 5;   end; {else}end; {Init}{---------------------------------------------------------------}{                                                               }{  InsertWord - Insert new entries into exceptions dictionary.  }{                                                               }{---------------------------------------------------------------}procedure InsertWord;var   stop: boolean;                       {true if user wants to exit}   word1, word2: pString32;             {dictionary entry}begin {InsertWord}stop := false;writeln;repeat   writeln('Press RETURN for the dictionary entries to exit function.');   write('Enter English word to add to dictionary:  ');   readln(word1);   write('Enter phonetic representation of word to add to dictionary:  ');   readln(word2);   if (length(word1) = 0) or (length(word2) = 0) then      stop := true   else      DictInsert(word1, word2);   writeln;until stop;writeln;end; {InsertWord}{---------------------------------------------------------------}{                                                               }{  LoadDict - Load dictionary file from disk.                   }{                                                               }{---------------------------------------------------------------}procedure LoadDict;label 99;var   ch: char;                            {character from the file}   errNum: integer;                     {error number to report to user}   errString: packed array[1..5]   of char; {error number as a hex string}   f: text;                             {file variable}   i: integer;                          {loop/index variable}   pathname: string[255];               {name of the file}   word1, word2: pString32;             {dictionary entry}begin {LoadDict}{Get pathname of dictionary to open.}write('Enter pathname of dictionary to open:  ');readln(pathname);if length(pathname) = 0 then   goto 99;{Open the file for reading.}reset(f, pathname);errNum := toolError;if errNum <> 0 then begin               {report any error returned}   Int2Hex(errNum, pointer(@errString[2]), 4);   writeln('Unable to open file:  Error = ', errString);   goto 99;   end; {if}{Build the dictionary from the file.}DictInit(1);                            {clear current dict from memory}while not (eof(f)) do begin             {Loop:}   if eoln(f) then      readln(f)   else begin      read(f, ch);                      {read English word}      word1[0] := ch;      for i := 1 to ord(ch) do         read(f, word1[i]);      read(f, ch);                      {read phonetic word}      word2[0] := ch;      for i := 1 to ord(ch) do         read(f, word2[i]);      DictInsert(word1, word2);         {insert entry into dict}      end; {else}   end; {while}close(f);DictInit(0);                            {reset dict to top}99:end; {LoadDict}{---------------------------------------------------------------}{                                                               }{  SetSpeechGlobals - Set global speech parameters.             }{                                                               }{---------------------------------------------------------------}procedure SetSpeechGlobals;   function GetValue (min,max: integer): integer;   { Get a value, making sure it is in the given range          }   {                                                            }   { Parameters:                                                }   {    min - lowest allowed value                              }   {    max - highest allowed value                             }   {                                                            }   { Returns: Value read                                        }   var      value: integer;                   {value read}   begin {GetValue}   repeat      readln(value);      if (value < min) or (value > max) then begin         writeln('Please enter a value from ', min:1, ' to ', max:1, '.');         writeln;         write('  Value: ');         end; {if}   until (value >= min) and (value <= max);   GetValue := value;   end; {GetValue}begin {SetSpeechGlobals}write('Voice = ');                      {Read new global voice setting}if voice = male then   writeln('male ')else   writeln('female ');writeln('Enter 0 to change voice to male, 1 to change voice to female.');if GetValue(0,1) = 0 then   voice := maleelse   voice := female;writeln;                                {Read new global tone setting}write('Tone = ');if basePitch = bass then   writeln('bass ')else   writeln('treble ');writeln('Enter 0 to change tone to bass, 1 to change tone to treble.');if GetValue(0,1) = 0 then   basePitch := basselse   basePitch := treble;writeln;                                {Read new global volume setting}write('Volume = ', volume:1, '  ');volume := GetValue(0,9);writeln;                                {Read new global speed setting}write('Speed = ', speed:1, '  ');speed := GetValue(0,9);writeln;                                {Read new global pitch setting}write('Pitch = ', pitch:1, '  ');pitch := GetValue(0,9);                                        {set the globals}SetSayGlobals(voice, basePitch, pitch, speed, volume);writeln;end; {SetSpeechGlobals}{---------------------------------------------------------------}{                                                               }{  ShutDown - Shut down the tools we started; do any necessary  }{       clean-up before exiting.                                }{                                                               }{---------------------------------------------------------------}procedure ShutDown;begin {ShutDown}FemaleShutDown;                         {shut down speech tools}MaleShutDown;ParseShutDown;SpeechShutDown;end; {ShutDown}{---------------------------------------------------------------}{                                                               }{  SpeakPhonetics - Speak as many non-empty lines of phonetic   }{       text as the user wants.                                 }{                                                               }{---------------------------------------------------------------}procedure SpeakPhonetics;var   phString: packed array[0..255] of char; {phonetic string}   stop: boolean;                       {true if user wants to exit}begin {SpeakPhonetics}stop := false;repeat   writeln;   writeln('Enter phonetic string to speak.  Press RETURN to exit.');   readln(phString);   if length(phString) = 0 then      stop := true   else begin      if voice = male then         MaleSpeak(volume, speed, pitch, phString)      else         FemaleSpeak(volume, speed, pitch, phString);      end; {else}until stop;writeln;end; {SpeakPhonetics}{---------------------------------------------------------------}{                                                               }{  SpeakText - Speak as many non-empty lines of English text as }{       the user wants.                                         }{                                                               }{---------------------------------------------------------------}procedure SpeakText;var   sayString: packed array[0..255] of char; {English text to speak or parse}   stop: boolean;                       {true if user wants to exit}begin {SpeakText}stop := false;repeat   writeln;   writeln('Enter string to speak.  Press RETURN to exit.');   readln(sayString);   if length(sayString) = 0 then      stop := true   else      Say(sayString);until stop;writeln;end; {SpeakText}{---------------------------------------------------------------}{                                                               }{  WriteDict - Write dictionary to disk file.                   }{                                                               }{---------------------------------------------------------------}procedure WriteDict;label 99;var   errNum: integer;                     {error number to report to user}   errString: packed array[1..5]   of char; {error number as a hex string}   f: text;                             {file variable}   i: integer;                          {loop/index variable}   pathname: string[255];               {name of the file}   stop: boolean;                       {true if user wants to exit}   tmp: pString32Ptr;                   {pointer returned by DictDump}   word1, word2: pString32;             {dictionary entry}begin{Get pathname for dictionary file.}write('Enter pathname for dictionary file:  ');readln(pathname);if length(pathname) = 0 then   goto 99;{Open the file for writing.}rewrite(f, pathname);errNum := toolError;if errNum <> 0 then begin               {report any error returned}   Int2Hex(errNum, pointer(@errString[2]), 4);   writeln('Unable to open file:  Error = ', errString);   goto 99;   end; {if}{Write the dictionary to the file.}DictInit(0);                            {set dictionary to top}stop := false;repeat                                  {Loop:}   tmp := DictDump(word1, word2);       {get next dict entry}   if length(word1) = 0 then      stop := true   else begin      for i := 0 to length(word1) do    {write English word}         write(f, word1[i]);      for i := 0 to length(word2) do    {write phonetic word}         write(f, word2[i]);      end; {else}until stop;close(f);DictInit(0);                            {reset dict to top}99:end; {WriteDict}{---------------------------------------------------------------}{                                                               }{  Main program - Display "main menu" and call appropriate      }{       function until user selects Quit.                       }{                                                               }{---------------------------------------------------------------}begin{Splash screen.}writeln;writeln('Speak - A demonstration of the Talking Tools');writeln;writeln('Please wait while we load the tools.');writeln;{Initialize the program.}Init;{Main loop: bring up menu; get user's selection; handle selection.}while not done do begin   writeln('Enter desired function:  S to speak English string');   writeln('                         P to speak phonetic string');   writeln('                         C to convert to phonetics');   writeln('                         G to set global speech parameters');   writeln('                         A to activate dictionary');   writeln('                         T to deactivate dictionary');   writeln('                         D to display dictionary');   writeln('                         I to insert word into dictionary');   writeln('                         R to remove word from dictionary');   writeln('                         L to load dictionary from disk file');   writeln('                         W to write dictionary to disk file');   writeln('                         Q to quit program');   write('                         ');   readln(answer);   case answer[1] of      'S', 's': SpeakText;      'P', 'p': SpeakPhonetics;      'C', 'c': ConvertToPhonetics;      'G', 'g': SetSpeechGlobals;      'A', 'a': DictActivate(1);      'T', 't': DictActivate(0);      'D', 'd': DisplayDict;      'I', 'i': InsertWord;      'R', 'r': DeleteWord;      'L', 'l': LoadDict;      'W', 'w': WriteDict;      'Q', 'q': done := true;      otherwise: begin                 writeln('Please enter one of S, P, C, G, A, T, D, I, R, L, W, or Q...');                 writeln;                 end;   end; {case}end; {while}{Shut down the program.}ShutDown;end.