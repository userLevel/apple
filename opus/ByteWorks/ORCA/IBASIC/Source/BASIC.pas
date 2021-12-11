{---------------------------------------------------------------}{                                                               }{  BASIC 1.0.2                                                  }{                                                               }{  A native code integer BASIC compiler for the Apple IIGS.     }{                                                               }{  By Mike Westerfield                                          }{                                                               }{  Copyright 1996                                               }{  By the Byte Works, Inc.                                      }{                                                               }{---------------------------------------------------------------}{                                                               }{  Version 1.0.2, November 1996, Mike Westerfield               }{                                                               }{  1.  Added minNumFor and the code that uses it to fix a bug   }{      involving GOSUBs nested inside FOR loops that call       }{      subroutines which also have FOR loops.                   }{  2.  Changed Get_LInfo to GetLInfo in Scanner.pas to match    }{      the current naming conventions.                          }{                                                               }{---------------------------------------------------------------}{                                                               }{  Version 1.0.1, November 1991, Mike Westerfield               }{                                                               }{  1.  Fixed bug in GenDebugSymbols that caused crashes/hangs   }{      when a program was created with no symbols and compiled  }{      with debug code on.                                      }{  2.  Changes NewHandle call in StartSegment so the memory     }{      would not cross a bank boundary.                         }{  3.  Strings that are not specifically DIMed now default to   }{      10 characters.                                           }{  4.  The compiler now allows blank lines.  This happens to    }{      sidestep a nasty scanner problem when an error occurs    }{      at the end of a file due to an extraneous blank line.    }{                                                               }{---------------------------------------------------------------}program BASIC_Compiler (output);uses Common;{$libprefix '0/obj/'}uses BASICCom, Scanner, Parser;begin {BASIC_Compiler}writeln('Integer BASIC 1.0.2');         {write the header}writeln('Copyright 1991, 1996, Byte Works, Inc.');writeln;InitCommon;                             {initialize the globals area}InitScanner;                            {initialize the scanner}InitParser;                             {initialize the parser}Compile;                                {compile the program}writeln;                                {write the trailer}writeln(numErrors:1, ' errors found.');if maxErrorLevel <> 0 then   writeln(maxErrorLevel:1, ' was the highest error level.');ShutDownScanner;                        {shut down the scanner}end. {BASIC_Compiler}