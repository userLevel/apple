{---------------------------------------------------------------}{                                                               }{  Polygons                                                     }{                                                               }{  Create and draw an arrow with a polygon                      }{                                                               }{---------------------------------------------------------------}program Polygons (input);uses Common, QuickDrawII;var   i: integer;                           {loop/index variable}   pat: pattern;                         {striped pen pattern}   poly: polyHandle;                     {polygon}   r: rect;                              {work rectangle}beginStartGraph(320);PenNormal;{create the polygon}poly := OpenPoly;if ToolError <> 0 then   poly := nilelse begin   MoveTo(10, 23);   LineTo(35, 23);   LineTo(35, 10);   LineTo(55, 35);   LineTo(35, 60);   LineTo(35, 48);   LineTo(10, 48);   LineTo(10, 23);   ClosePoly;   if ToolError <> 0 then begin      KillPoly(poly);      poly := nil;      end; {if}   end; {else}{paint the screen gray}SetSolidPenPat(14);r.h1 := 0; r.h2 := 320;r.v1 := 0; r.v2 := 200;PaintRect(r);{create a striped pen pattern}for i := 0 to 31 do   pat[i] := $F7;{Draw the various polygons}SetSolidPenPat(4);PaintPoly(poly);OffSetPoly(poly, 60, 30);ErasePoly(poly);OffSetPoly(poly, 60, 30);FillPoly(poly, pat);OffSetPoly(poly, 60, 30);FramePoly(poly);OffSetPoly(poly, 60, 30);InvertPoly(poly);{wait for a keypress}readln;EndGraph;end.