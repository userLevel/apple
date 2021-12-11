{$keep 'Gamm'}{$optimize -1}{--------------------------------------------------------------}{                                                              }{  Gamm                                                        }{                                                              }{  Test the speed of floating point operations in a mix tha    }{  is typical of scientific and engineering applications.      }{                                                              }{  To get the best performance from the desktop development    }{  environment, be sure to turn debugging off from the         }{  Compile Dialog.  Use the Compile command from the Run menu  }{  to get the compile dialog.                                  }{                                                              }{--------------------------------------------------------------}program gamm(output);var  five,i,j,n,rep,ten,thirty: integer;  acc,acc1,divn,rn,root,x,y: real;  a,b,c: array[1..30] of real;beginwriteln('Start timing 15000 Gamm units');n := 50;five := 5;ten := 10;thirty := 30;rn := n;divn := 1.0/rn;x := 0.1;acc := 0.0;{initialize a and b}y := 1.0;for i := 1 to 30 do begin  a[i] := i;  b[i] := -y;  y := -y;  end;{one pass thru this loop corresponds to 300 gamm units}for rep := 1 to n do begin  {first addition/subtraction loop}  i := 30;  for j := 1 to 30 do begin    c[i] := a[i]+b[i];    i := i-1;    end;  {first polynomial loop}  y := 1.0;  for i := 1 to ten do    y := (y+c[i])*x;  acc1 := y*divn;  {first maximum element loop}  y := c[11];  for i := 12 to 20 do    if c[i] > y then      y := c[i];  {first square root loop}  root := 1.0;  for i := 1 to 5 do    root := 0.5*(root+y/root);  acc1 := acc1+root*divn;  {second addition/subtraction loop}  for i := 1 to 30 do    a[i] := c[i]-b[i];  {second polynomial loop}  y := 0.0;  for i := 1 to ten do    y := (y+a[i])*x;  {second square root loop}  root := 1.0;  for i := 1 to five do    root := 0.5*(root+y/root);  acc1 := acc1+root*divn;  {first multiplication loop}  for i := 1 to thirty do    c[i] := c[i]*b[i];  {second maximum element loop}  y := c[20];  for i := 21 to thirty do    if c[i] > y then      y := c[i];  {third square root loop}  root := 1.0;  for i := 1 to 5 do    root := 0.5*(root+y/root);  acc1 := acc1+root*divn;  {third polynomial loop}  y := 0.0;  for i := 1 to ten do    y := (y+c[i])*x;  acc1 := acc1+y*divn;  {third maximum element loop}  y := c[1];  for i := 2 to ten do    if c[i] > y then      y := c[i];  {fourth square root loop}  root := 1.0;  for i := 1 to 5 do    root := 0.5*(root+y/root);  acc1 := acc1+root*divn;  acc := acc+acc1;  end;writeln(n:12,'  ',acc:12:7,'  ',acc1:12:7);end.