program MousePosition (output);uses Common, QuickDrawII, EventMgr;var   done: boolean;                       {are we done, yet?}   myEvent: eventRecord;                {event record}   h, v: integer;                       {old position (to avoid flicker)}   procedure WriteMousePos;   { Write the position of the mouse                            }   var      r: rect;                          {rectangle for area to erase}   begin {WriteMousePos}   if (h <> myEvent.eventWhere.h) or (v <> myEvent.eventWhere.v) then begin      SetSolidPenPat(black);            {erase any old stuff}      r.left := 0;  r.right := 150;      r.top := 0;   r.bottom := 15;      PaintRect(r);      MoveTo(10, 10);                   {write the position}      h := myEvent.eventWhere.h;      v := myEvent.eventWhere.v;      write(h, ', ', v);      end; {if}   end; {WriteMousePos}beginStartDesk(640);PenNormal;InitCursor;done := false;h := -1;repeat   if GetNextEvent(everyEvent, myEvent) then      if myEvent.eventWhat = keyDownEvt then         done := true;   WriteMousePos;until done;EndDesk;end.