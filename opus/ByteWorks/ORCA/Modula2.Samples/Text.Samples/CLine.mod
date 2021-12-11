(*$Keep 'CLine'*)(*--------------------------------------------------------------*)(*                                                              *)(*  Command Line                                                *)(*                                                              *)(*  On the Apple IIGS, all EXE programs can expect three things *)(*  to be passed to them by the shell: a user ID number for use *)(*  with tool kits, an eight character shell ID which           *)(*  identifies the shell that executed the program, and the     *)(*  text from the command line itself.  This program shows how  *)(*  to access these values from Modula-2, printing them to the  *)(*  screen.  Be sure and execute the program with some text     *)(*  after the name - for example,                               *)(*                                                              *)(*       CLINE Hello, world.                                    *)(*                                                              *)(*  By Mike Westerfield                                         *)(*                                                              *)(*  Copyright 1993						*)(*  Byte Works, Inc.                                            *)(*                                                              *)(*--------------------------------------------------------------*)MODULE CLine;FROM InOut IMPORT WriteLn, WriteString, WriteInt;FROM M2Lib IMPORT UserID, CommandLine;BEGINWriteString('User ID: '); WriteInt(UserID(), 1); WriteLn;WriteString('Shell ID: '); WriteString(CommandLine^.shellID); WriteLn;WriteString('Command line: '); WriteString(CommandLine^.value); WriteLn;END CLine.