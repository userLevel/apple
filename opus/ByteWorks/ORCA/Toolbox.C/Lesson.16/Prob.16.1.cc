/***************************************************************** Blaster Sound****************************************************************/#pragma lint -1#include <stdio.h>#include <math.h>#include <orca.h>#include <Sound.h>#include <Resources.h>#include <Memory.h>#include <Locator.h>#include <MiscTool.h>#define twoPi 6.28318531                /* 2*pi */int main (void){float sinTable[100];                    /* sine table (for speed) */Ref startStopParm;                      /* tool start/shutdown parameter */SoundParamBlock soundBlocks[10];        /* sound parameter blocks */unsigned i;                             /* loop/index variable */static unsigned char sound[4096];       /* sound block */startStopParm =                         /* start up the tools */   StartUpTools(userid(), 2, 1);if (toolerror() != 0)   SysFailMgr(toolerror(), "\pCould not start tools: ");printf("Setting up the sound...\n");    /* put a sine wave in the buffer */for (i = 0; i < 100; ++i)   sinTable[i] = sin(i/100.0*twoPi)*120.0 + 128.0;for (i = 0; i < 4096; ++i)   sound[i] = sinTable[i%100] * (1.0 - i/4096.0);soundBlocks[0].waveStart = sound;       /* set up the sound parameter blocks */soundBlocks[0].waveSize = 16;soundBlocks[0].freqOffset = 32.0 * 40960.0 / 1645.0;soundBlocks[0].docBuffer = 0;soundBlocks[0].bufferSize = 4;soundBlocks[0].nextWavePtr = &soundBlocks[1];soundBlocks[0].volSetting = 250;for (i = 1; i < 9; ++i) {   soundBlocks[i] = soundBlocks[0];   soundBlocks[i].nextWavePtr = &soundBlocks[i+1];   }soundBlocks[9] = soundBlocks[0];soundBlocks[9].nextWavePtr = NULL;printf("Playing the sound...\n");       /* start the sound */FFStartSound(0x0201, (Pointer) &soundBlocks[0]);while (!FFSoundDoneStatus(2)) ;         /* wait for the sound to finish */ShutDownTools(1, startStopParm);        /* shut down the tools */}