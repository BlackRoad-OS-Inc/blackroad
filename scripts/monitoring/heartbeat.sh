#!/bin/bash
# ECG HEARTBEAT MONITOR

awk 'BEGIN {
  w = 78; h = 30
  
  # ECG waveform pattern (simplified PQRST)
  # Flat -> P wave -> flat -> Q dip -> R spike -> S dip -> flat -> T wave -> flat
  wlen = 80
  for (i = 0; i < wlen; i++) {
    x = i / wlen
    
    if (x < 0.1) wave[i] = 0
    else if (x < 0.15) wave[i] = sin((x - 0.1) * 3.14159 / 0.05) * 0.15  # P wave
    else if (x < 0.22) wave[i] = 0
    else if (x < 0.25) wave[i] = -0.1  # Q
    else if (x < 0.28) wave[i] = 0.9   # R spike
    else if (x < 0.32) wave[i] = -0.2  # S
    else if (x < 0.45) wave[i] = 0
    else if (x < 0.55) wave[i] = sin((x - 0.45) * 3.14159 / 0.1) * 0.25  # T wave
    else wave[i] = 0
  }
  
  # Scrolling buffer
  for (x = 0; x < w; x++)
    buf[x] = 0
  
  t = 0
  bpm = 72
  
  while (1) {
    # Shift buffer left
    for (x = 0; x < w - 1; x++)
      buf[x] = buf[x + 1]
    
    # Add new sample
    waveIdx = int((t * bpm / 60) % wlen)
    buf[w-1] = wave[waveIdx]
    
    # Clear screen buffer
    for (y = 0; y < h; y++)
      for (x = 0; x < w; x++)
        scr[y,x] = " "
    
    # Draw grid
    for (x = 0; x < w; x += 5)
      for (y = 0; y < h; y++)
        scr[y,x] = "\033[90m│\033[0m"
    for (y = 0; y < h; y += 3)
      for (x = 0; x < w; x++)
        if (scr[y,x] == " ") scr[y,x] = "\033[90m─\033[0m"
        else scr[y,x] = "\033[90m┼\033[0m"
    
    # Draw baseline
    baseline = int(h * 0.55)
    for (x = 0; x < w; x++)
      if (scr[baseline,x] == " " || scr[baseline,x] == "\033[90m│\033[0m")
        scr[baseline,x] = "\033[32m─\033[0m"
    
    # Draw waveform
    prevY = -1
    for (x = 0; x < w; x++) {
      val = buf[x]
      y = int(baseline - val * h * 0.4)
      
      if (y >= 0 && y < h) {
        # Bright green for main trace
        scr[y,x] = "\033[92m█\033[0m"
        
        # Connect vertical gaps
        if (prevY >= 0 && prevY != y) {
          startY = (prevY < y) ? prevY : y
          endY = (prevY > y) ? prevY : y
          for (cy = startY; cy <= endY; cy++)
            if (scr[cy,x] == " " || scr[cy,x] == "\033[90m│\033[0m" || scr[cy,x] == "\033[90m─\033[0m")
              scr[cy,x] = "\033[92m▌\033[0m"
        }
        
        prevY = y
      }
    }
    
    # Beep indicator (flash on R wave)
    beep = (wave[waveIdx] > 0.5) ? "\033[91m♥\033[0m" : "\033[90m♡\033[0m"
    
    # Render
    printf "\033[H"
    printf "\033[92m╔══════════════════════════════════════════════════════════════════════════╗\033[0m\n"
    printf "\033[92m║\033[0m \033[97mECG MONITOR\033[0m  %s  \033[93mBPM: %d\033[0m                                              \033[92m║\033[0m\n", beep, bpm
    printf "\033[92m╠══════════════════════════════════════════════════════════════════════════╣\033[0m\n"
    
    for (y = 0; y < h; y++) {
      printf "\033[92m║\033[0m"
      for (x = 0; x < w; x++)
        printf "%s", scr[y,x]
      printf "\033[92m║\033[0m\n"
    }
    
    printf "\033[92m╚══════════════════════════════════════════════════════════════════════════╝\033[0m\n"
    
    t += 0.02
    system("sleep 0.02")
  }
}'
