100 rem110 rem Check extreme ranges for < > <= >= operators120 rem130 sum = 0140 if -30000 < 30000 then sum = sum + 1150 if -30000 <= 30000 then sum = sum + 2160 if 30000 > -30000 then sum = sum + 4170 if 30000 >= -30000 then sum = sum + 8180 if 30000 < -30000 then sum = sum + 16190 if 30000 <= -30000 then sum = sum + 32200 if -30000 > 30000 then sum = sum + 64210 if -30000 >= 30000 then sum = sum + 128220 if sum = 15 then print "Passed C007"230 if sum # 15 then print "Failed C007"