{$keep 'ErrorExit'}{$names+}{--------------------------------------------------------------}{                                                              }{  Error Trap                                                  }{                                                              }{  You can call the library routines that handle run-time      }{  errors from your own program.  One of these, called         }{  SystemPrintError, will print out a text run-time error      }{  message.  You pass a single integer parameter, which is     }{  the run-time error number.  This procedure is generally     }{  called from an error trap subroutine - see the sample       }{  program ERRORTRAP.PAS for an example of how to trap errors. }{  In this program SystemPrintError is used to list the        }{  current run-time error messages.                            }{                                                              }{  The second procedure is called SystemErrorLocation.  If     }{  the names+ directive has been used, SystemErrorLocation     }{  will print a traceback, showing where you are and how you   }{  got there.  (See TRACE.PAS for more on tracebacks.)  This   }{  can be very handy when debugging a program.                 }{                                                              }{  By Mike Westerfield                                         }{                                                              }{  Copyright 1987-1990                                         }{  Byte Works, Inc.                                            }{                                                              }{--------------------------------------------------------------}program ErrorExit(output);var  i: integer;  procedure SystemErrorLocation; extern;  {a library procedure that prints the current location & a traceback}  procedure SystemPrintError(i: integer); extern;  {a library procedure that prints an error message}beginwriteln('Run time error messages:');writeln;for i := 1 to 15 do begin  write(i:3,': ');  SystemPrintError(i);  end;writeln;writeln('Exiting with traceback:');writeln;SystemErrorLocation;end.