;; Written by: Joe Glessner (jglessner@usip.edu) under the direction of Dr. James Johnson
;; University of the Sciences in Philadelphia
;; 2005
;; Updated to run on NetLogo_6.1.1 by Joe Glessner (jglessnd@gmail.com) 2019

globals [
         numTrav
         rand-infect
         isset
         time
         continue
         interval
         xcoord
         ycoord
         radius
         dead
         natDead
         file
         numPop
         pops
         livePatches
         cases
         usCities
         births
         popPercent
         states
         next
         firstCase
         drugCured
         sourceX
         sourceY
        ]
breed [
        people
        particle
       ]
people-own[
            weak
            recover
            inf-moves
            resist
            poorPer
            vaccinated
           ]

patches-own[
            Travelers
            Meanderers
            %Infected
            Density
            Source_Delay
            Source_Intensity
            Source_Size
            disease
            disp]

to startup
    export-all-plots "Pestilence_Data.csv"
    set file "Pestilence_Data.csv"
    ask patches[set pcolor white]
    import-pcolors "Images/Welcome.png"
    file-delete file
    file-open file
    file-type "first"
    file-close
end

;;--------------------------------------------------------------------------------------------------------

to Setup
without-interruption[
  ca
   set file "Pestilence_Data.csv"
  ask patches[set Travelers "-" set Meanderers "-" set %Infected "-" set Density "-" set Source_Delay "-"
              set Source_Intensity "-" set Source_Size "-"]
  ;;random-seed 311
  set states[]
  no-display ask people[ht]
  disp-back
  setPercentLoc
  set livePatches (count patches with [pcolor = white])
  set time 0
  set births 0
  set firstCase 999
  ;display
  ;;file-close
  if File_Output
   [file-close carefully [setup-file][user-message "The Excel SS must be closed while exporting data 1." stop]]
  setup-maps
  display ask people[st]
  ask people [set vaccinated false  ifelse random 100 < Poor [set poorPer true][set poorPer false]]
  set continue false
  ;loop[
  ;ifelse continue = false
  ; [if mouse-down?
   ; [ inspect patch-at mouse-xcor mouse-ycor ]]
   ;[stop]
  ;]
]
end

;;--------------------------------------------------------------------------------------------------------

to ClearTurtles let firstChar "a"
without-interruption[
  clear-all-plots
  ct
  set time 0
  set dead 0
  set natDead 0
  set cases 0
  set births 0
  set drugCured 0
  ask patches[set disp 0 if pcolor > red and pcolor < 20 [set pcolor white]
              if pxcor > 77  and pycor < -94 [ifelse any? patches with [pcolor = (white - .001)] [set pcolor white - .001][set pcolor white]]]
  setPercentLoc
  setup-maps
  ask people [set vaccinated false  ifelse random 100 < Poor [set poorPer true][set poorPer false] st]
]
end

;;--------------------------------------------------------------------------------------------------------

to place-pop let X 0 let Y 0
if continue [stop]  ;; Forces quit when 'Go' is clicked
if mouse-down?
    [ if [pcolor] of patch-at mouse-xcor mouse-ycor = white [set X mouse-xcor set Y mouse-ycor
            while [not ( is-number? ([travelers] of patch-at X Y))]                    ;;Make sure a number is entered to avoid errors
        [carefully[ask patch-at X Y [set travelers read-from-string user-input "Travelers"]][ask patch-at X Y [set travelers "-"] user-message "Invalid Input"]]
            while [not ( is-number? ([meanderers] of patch-at X Y))]
        [carefully[ask patch-at X Y [set meanderers read-from-string user-input "Meanderers"]][ask patch-at X Y [set meanderers "-"] user-message "Invalid Input"]]
            while [not ( is-number? ([%Infected] of patch-at X Y))]
        [carefully[ask patch-at X Y [set %Infected read-from-string user-input "Percent Infected (0-100)"]][ask patch-at X Y [set %Infected "-"] user-message "Invalid Input"]]
            while [not ( is-number? ([density] of patch-at X Y))]
        [carefully[ask patch-at X Y [set density read-from-string user-input "Density (0-100)"]][ask patch-at X Y [set density "-"] user-message "Invalid Input"]]
    ] ]
;setup-pops
end

;;--------------------------------------------------------------------------------------------------------

to Place-Source let X 0 let Y 0
if continue[stop]   ;; Forces quit when 'Go' is clicked
    if mouse-down?
  [ if [pcolor] of patch-at mouse-xcor mouse-ycor = white [set X mouse-xcor set Y mouse-ycor
    while [not ( is-number? ([source_delay] of patch-at X Y))]
              [carefully[ask patch-at X Y [set source_delay read-from-string user-input "Source Delay (year)"]][ask patch-at X Y [set source_delay "-"] user-message "Invalid Input"]]
    while [not ( is-number? ([source_intensity] of patch-at X Y))]
              [carefully[ask patch-at X Y [set source_intensity read-from-string user-input "Source Intensity (0-100)"]][ask patch-at X Y [set source_intensity "-"] user-message "Invalid Input"]]
    while [not ( is-number? ([source_size] of patch-at X Y))]
              [carefully[ask patch-at X Y [set source_size read-from-string user-input "Source Size (0-100)"]][ask patch-at X Y [set source_size "-"] user-message "Invalid Input"]]
  set sourceX X set sourceY Y
  ] ]

end

;;--------------------------------------------------------------------------------------------------------

to Go ;; Go/Stop button
  set continue true
  set isset 1
  setup-pops
  init-recover
  ;;user-message time
 carefully[
  ifelse File_Output and time < 1
    [file-close
     file-open file
     disp-header
      update-file][if File_Output[set interval interval + 1
         if interval = File_Time_Interval
           [
            file-close
            file-open file
            update-file
            set interval 0]
        ]
   ]]
  [user-message "The Excel SS must be closed while exporting data 2." stop]
  ;loop[
    ifelse count people > 0[ ;continue and
      ask people [
        change-dir
        move
        infect
        reproduce
        age
        if shade-of? color red
          [infect-area
          ]
      ]
      weather-area
      advance-time
      do-plots
     ;; if File_Output
     ;;   [set interval interval + 1
     ;;    if interval = File_Time_Interval
     ;;      [
     ;;       file-close
     ;;       file-open file
     ;;       update-file
      ;;      set interval 0]
      ;;  ]
    ]
    [without-interruption[
     if File_Output[
      ;;file-print " "
      file-close
      ]]
     stop
     ]
  ;]
  without-interruption[
  if File_Output[
  file-close
  ]]
end

;;--------------------------------------------------------------------------------------------------------

to Halt
    set continue false
end

;;--------------------------------------------------------------------------------------------------------
to import-ppm [pathname]
  ;; USER-CHOOSE-FILE returns false if the user cancels, so this
  ;; check is here to handle that case
  if not is-string? pathname
    [ stop ]
  carefully [
    file-open pathname
    import-ppm-contents
  ]
  []
  file-close
end
to import-ppm-contents
  ;; check magic number
  if read-pgm-entry != "P3" [
    user-message "This is not a valid ASCII format PGM file (magic number is not P3)"
    stop
  ]
  ;; get width, height, and white value
  let width read-from-string read-pgm-entry
  let height read-from-string read-pgm-entry
  let max-value read-from-string read-pgm-entry
  ;; read the actual pixel values
  let x 0
  let y 0
  while [y < height] [
    set x 0
    while [x < width][

       let value1 (read-from-string read-pgm-entry / max-value)
       let value2 (read-from-string read-pgm-entry / max-value)
       let value3 (read-from-string read-pgm-entry / max-value)
        ;; convert from image coordinates to patch coordinates
        ;; (in patch coordinates, the origin is in the center,
        ;; not the top left, and y coordinates increase going up,
        ;; not going down)
        let px x - max-pxcor
        let py max-pycor - y
        if width < 100
          [set py y - 100
           ifelse next = 0
             [set px  90 - x]
             [set px  100 - x]]
        ;; make sure we're not out of bounds
        if (abs px <= max-pxcor) and (abs py <= max-pycor) [
          ;; actually color the patch
          ask patch px py [
            set pcolor (rgb value1 value2 value3) ;scale-color white value 0 max-value
          ]
        ]
        set x x + 1
      ]
    set y y + 1
  ]
end
;; reads the next entry in a pgm file
;; - an error occurs if there are no more entries
;; - entries are separated by arbitrary whitespace
;; - characters on a line after "#" are comments
to-report read-pgm-entry
  ;; get next character
  let c file-read-characters 1
  ;; ignore leading whitespace
  while [whitespace-char? c]
    [ set c file-read-characters 1 ]
  ;; skip comments
  if c = "#" [
    ;; first skip the comment itself
    while [c != "\n" and c != "\r"] [
      set c file-read-characters 1
    ]
    ;; then skip linefeeds and/or newlines at end of comment
    while [c = "\n" or c = "\r"] [
      set c file-read-characters 1
    ]
  ]
  ;; read the entry
  let str ""
  while [not whitespace-char? c]
    [ set str str + c
      set c file-read-characters 1 ]
  report str
end
;; reports true if c is a single whitespace character
to-report whitespace-char? [c]
  report c = " " or
         c = "\t" or   ;; tab
         c = "\n" or   ;; newline
         c = "\r"      ;; linefeed
end
                                                                                ;;(C) 2004 Uri Wilensky.
to import-pgm [pathname]
  ;; USER-CHOOSE-FILE returns false if the user cancels, so this
  ;; check is here to handle that case
  if not is-string? pathname
    [ stop ]
  carefully [
    file-open pathname
    import-pgm-contents
  ]
  []
  file-close
end
to import-pgm-contents
  ;; check magic number
  if read-pgm-entry != "P2" [
    user-message "This is not a valid ASCII format PGM file (magic number is not P2)"
    stop
  ]
  ;; get width, height, and white value
  let width read-from-string read-pgm-entry
  let height read-from-string read-pgm-entry
  let max-value read-from-string read-pgm-entry
  ;; read the actual pixel values
  let x 0
  let y 0
  while [y < height] [
    set x 0
    while [x < width]
      [ let value read-from-string read-pgm-entry
        if Background = "Airport"
          [set value read-from-string read-pgm-entry
           set value read-from-string read-pgm-entry
          ]
        ;; convert from image coordinates to patch coordinates
        ;; (in patch coordinates, the origin is in the center,
        ;; not the top left, and y coordinates increase going up,
        ;; not going down)
        let px x - max-pxcor
        let py max-pycor - y
        ;if width < 100
          ;[set px x - 48               ;; Smaller Images
           ;ifelse next = 0
           ;[set py  49 - y]
           ;[set py  -29 - y]]
        ;; make sure we're not out of bounds
        if (abs px <= max-pxcor) and (abs py <= max-pycor) [
          ;; actually color the patch
          ask patch px py [
            set pcolor scale-color white value 0 max-value
          ]
        ]
        set x x + 1
      ]
    set y y + 1
  ]
end
;;--------------------------------------------------------------------------------------------------------
to init-recover
  ask turtles[
   if recover = true
     [set color blue + (color - red)
      set size size + .001
      set weak false
      set recover false]
  ]
end

;;--------------------------------------------------------------------------------------------------------

to setup-pops
ask patches[
 if disp = 0 and not (Travelers = "-") and not (Meanderers = "-") and not (%Infected = "-") and not (Density = "-")[
  if Travelers > 0 [
    output-print (word "Travelers:"   Travelers   ", Meanderers:"   Meanderers   ", %Infected:"   %Infected   ", Density:"   Density)
    sprout-people Travelers[
    set-char
    repeat (random(100 - Density)) [check-approp if not(is-number? (substring Background 0 1))  [check-approp-map] fd 1] ]]
  if Meanderers > 0 [
    sprout-people Meanderers
    [set-char
     repeat (random(100 - Density)) [check-approp if not(is-number? (substring Background 0 1))  [check-approp-map] fd 1]
     set shape "circle"

    ]]
    ask people [set vaccinated false  ifelse random 100 < Poor [set poorPer true][set poorPer false]]
    set disp true
  ]]

end

;;--------------------------------------------------------------------------------------------------------

to advance-time
  set time time + 1
  if any? people with [shade-of? color red] and firstCase = 999 [set firstCase time]
  if time = (firstCase + Vac_Delay) [set next 0
       ;can't get this to show up small in the corner as before, scales to full screen interupting background
       ;import-drawing "C:/Users/glessner/Desktop/Pestilence/Images/needle.png"
       if File_Output [file-open file]
                                     ask people[if not PoorPer and random 100 < Vac_Use and random 100 < Vac_Stock and random 100 < Vac_Effect[set vaccinated true]]]
  if time = (firstCase + PharmDelay) [no-display set next 1
       ;import-drawing "C:/Users/glessner/Desktop/Pestilence/Images/pill.png"
       if File_Output [file-open file]
                                       ask patches[if pxcor > 92 and pycor < -92 and pcolor > red and pcolor < 20 [set pcolor gray]] display
                                       ask people[if shade-of? color red and not(PoorPer) and random 100 < PharmUse and random 100 < PharmStock and random 100 < PharmEffect [
                                                                                                            set drugCured drugCured + 1
                                                                                                            set color blue + (color - red)
                                                                                                            set size size + .001
                                                                                                            set weak false]]]
  ask patches[
  if time = Source_Delay [sprout Source_Intensity[
      ;;user-message sourceX
      ;;user-message pxcor
      let mySource_Size Source_Size
       set shape "arrow" setxy sourceX sourceY repeat mySource_Size [infect-area check-approp-source fd 1] die]]
  ]
end

;;--------------------------------------------------------------------------------------------------------

to set-char
     set size 5
     set weak false
     ifelse random(100) < 43
     [set color ((.001 * (random (15))) + blue)]
     [set color ((.001 * (random (Healthy_Lifespan))) + blue)]
       if color >= (blue + (.001 * Procreation_Age))
         [set color color + 3]
     if random 100 < %Infected
       [become-infected]
end

;;--------------------------------------------------------------------------------------------------------

to setup-maps
if not (Background = 1) [
  if not(is-number? (substring Background 0 1))
        [while [not(states = [])] [ask patch(first states)(first (but-first states)) [set %Infected 0 set Density 50 sprout-people (People_Map * (first popPercent))
                                                                      [set-char if random 100 < 50 [set shape "circle"] repeat (random(100 - Density)) [ check-approp-map fd 1] ]
                                                  set states but-first states set states but-first states
                                                  set popPercent but-first popPercent]]]
]
end

;;--------------------------------------------------------------------------------------------------------

to disp-back
 let width 10
 ask patches [set pcolor white]
  if not(Background = "1") [
    ifelse (substring Background 1 2) = "A"
        [set width 10]
        [ifelse (substring Background 1 2) = "B"
          [set width 5]
          [ifelse (substring Background 2 3) = "A"
            [set width 10]
            [set width 5]
          ]
       ]

  if (substring Background 0 1 = "5") [
    ask patches [
      if (pxcor = 0) and ((abs(pycor) < max-pxcor - 40) or (abs(pycor) > max-pxcor - (40 - width)))
        [set pcolor black]
      if (abs(pxcor) = abs(pycor)) and (abs(pxcor) < max-pxcor - width)
        [set pcolor black]
    ]
  ]
  if (substring Background 0 1 = "2") [
    ask patches [
      if (abs(pxcor) + abs(pycor) = 70) and (abs(pycor) > (width / 2) and not(abs(pxcor) > 20 and abs(pxcor) < (20 + width))) or
         ((abs(pxcor) + abs(pycor) = 90) and (abs(pycor) < (90 - width)) and not((abs(pxcor) > 70 and abs(pxcor) < (70 + width))  or (abs(pxcor) > 28 and abs(pxcor) < (30 + width)))) or
         (abs(pxcor) = abs(pycor) and abs(pycor) < 36) or
         (abs(pxcor) = abs(pycor) and abs(pycor) > 45 + width)
        [set pcolor black]
    ]
  ]
  if (substring Background 0 1 = "3") [
    ask patches [
      if (abs(pxcor) = 50 and not(abs(pycor) < (width / 2)) and abs(pycor) < max-pxcor - width and not(abs(pycor) > 10 and abs(pycor) < 15)) or
         (pxcor = 0 and pxcor < max-pxcor - width and not(abs(pycor) > 10 and abs(pycor) < 15)and abs(pycor) < max-pxcor - width) or
         (abs(pycor) = 10 and abs(pxcor) < max-pxcor - width) or
         (abs(pycor) = 32  and not(abs(pxcor) < (50 + width) and abs(pxcor) > (50 - width))) or
         (abs(pycor) = 55 and abs(pxcor) < max-pxcor - width and not(abs(pxcor) < width)) or
         (abs(pycor) = 80 and not(abs(pxcor) < (50 + width) and abs(pxcor) > (50 - width)))
           [set pcolor black]
    ]
  ]
  if (substring Background 0 1 = "8") [
    ask patches [
       if (abs(pxcor) = 0 and pycor < max-pxcor - width) or
          (abs(pxcor) < 10 and abs(pxcor) > 10 and pycor = 80) or
          (abs(pxcor) = 10 and pycor > (75 + width)) or
          (abs(pxcor) < 20 and abs(pxcor) > 0 and pycor = 70) or
          (abs(pxcor) = 20 and pycor < max-pxcor - width and pycor > 69) or
          (abs(pxcor) < 30 and abs(pxcor) > width and pycor = 60) or
          (abs(pxcor) = 30 and pycor > 59) or
          (abs(pxcor) < 40 and abs(pxcor) > 0 and pycor = 50) or
          (abs(pxcor) = 40 and pycor < max-pxcor - width and pycor > 49) or
          (abs(pxcor) = 50 and pycor > 39) or
          (abs(pxcor) < 50 and abs(pxcor) > width and pycor = 40) or
          (abs(pxcor) < 60 and abs(pxcor) > 0 and pycor = 30) or
          (abs(pxcor) = 60 and pycor > 29 and pycor < max-pxcor - width) or
          (abs(pxcor) = 70 and pycor > 19) or
          (abs(pxcor) < 70 and abs(pxcor) > width and pycor = 20) or
          (abs(pxcor) < 80 and abs(pxcor) > 0 and pycor = 10) or
          (abs(pxcor) = 80 and pycor > 9 and pycor < max-pxcor - width) or
          (abs(pxcor) = max-pxcor - 10 and pycor > 1) or
          (abs(pxcor) < max-pxcor - 10 and abs(pxcor) > width and pycor = 2)
         [set pcolor black]
    ]
  ]
  if (substring Background 0 1 = "4") [
    set xcoord width
    set ycoord 85 + width
    repeat 16 - width
      [back-diag]
    set xcoord 1
    set ycoord 70
    repeat 32 - width
      [back-diag]
    set xcoord width
    set ycoord 50 + width
    repeat 51 - width
      [back-diag]
    set xcoord 1
    set ycoord 30
    repeat 73 - width
      [back-diag]
    set xcoord width
    set ycoord 6 + width
    repeat 95 - width
      [back-diag]
    set xcoord 17
    set ycoord 2
    repeat 82 - width
      [back-diag]
    set xcoord 35 + width
    set ycoord width
    repeat 66 - width
      [back-diag]
    set xcoord 58
    set ycoord 2
    repeat 44 - width
      [back-diag]
    set xcoord 75 + width
    set ycoord width
    repeat 26 - width
      [back-diag]
    ask patches [
      if (pycor = 1 and abs(pxcor) < max-pxcor - 8) or
         (pxcor = 0 and pycor < max-pxcor - 8)
        [set pcolor black]
    ]
  ]
  if (substring Background 0 2 = "10")[
   ask patches [
       if (abs(pxcor) = 0 and pycor < max-pxcor - width) or
          (abs(pxcor) < 10 and abs(pxcor) > 10 and abs(pycor) = 80) or
          (abs(pxcor) = 10 and abs(pycor) > (75 + width)) or
          (abs(pxcor) < 20 and abs(pxcor) > 0 and abs(pycor) = 70) or
          (abs(pxcor) = 20 and abs(pycor) < max-pxcor - width and abs(pycor) > 69) or
          (abs(pxcor) < 30 and abs(pxcor) > width and abs(pycor) = 60) or
          (abs(pxcor) = 30 and abs(pycor) > 59) or
          (abs(pxcor) < 40 and abs(pxcor) > 0 and abs(pycor) = 50) or
          (abs(pxcor) = 40 and abs(pycor) < max-pxcor - width and abs(pycor) > 49) or
          (abs(pxcor) = 50 and abs(pycor) > 39) or
          (abs(pxcor) < 50 and abs(pxcor) > width and abs(pycor) = 40) or
          (abs(pxcor) < 60 and abs(pxcor) > 0 and abs(pycor) = 30) or
          (abs(pxcor) = 60 and abs(pycor) > 29 and abs pycor < max-pxcor - width) or
          (abs(pxcor) = 70 and abs(pycor) > 19) or
          (abs(pxcor) < 70 and abs(pxcor) > width and abs(pycor) = 20) or
          (abs(pxcor) < 80 and abs(pxcor) > 0 and abs(pycor) = 10) or
          (abs(pxcor) = 80 and abs(pycor) > 9 and abs pycor < max-pxcor - width) or
          (abs(pxcor) = max-pxcor - 10 and abs(pycor) > (width / 2))
         [set pcolor black]
    ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
 ;no-display
    if Background = "USA"[
      set usCities[78 41 -79 -13 32 29 6 -67 75 27 -57 -24 -73 -21 -1 -41 -6 -64 45 38 -84 19 40 12 -87 25 61 -55 52 21 -3 -55 32 -20 71 20 29 39 85 46 66 -27 -72 -12 32 21 7 -56 67 28 70 37]
      ;no-display
      import-pcolors "Images/USA.png"
      adjust-color
      ;ask patches[
       ;         if pcolor > 7 and pcolor < 9.4 and pxcor < 51 [set pcolor gray + 2]
       ;         if pcolor > 7 and pcolor < 9.2 and pxcor >= 51[set pcolor gray + 2]
       ;         if pcolor > 9.2 [set pcolor white]
       ;         if (pcolor >= 0 and pcolor < 6) or pxcor = 100 or  pycor = -100[set pcolor white - .001]
     ;]
    ;ask patches with [pcolor = white - .001 or pcolor = gray + 2][if (any? patches in-radius 1 with [pcolor = white - .001]) and (any? patches in-radius 1 with [pcolor = white])[set pcolor black]]

      ;display
    ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if Background = "World"[
      import-pcolors "Images/World.png"
      adjust-color
    ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "South Am"[
    import-pcolors "Images/sa.png"
    ask patches[
                if pcolor > 3 and pcolor < 8.5 [set pcolor gray + 2]
                if (pcolor >= 0 and pcolor < 3) or pxcor = 100 or pycor = -100[set pcolor white - .001]
                if pcolor > 8.5 and not(pcolor = white - .001)[set pcolor white]
                if pxcor = -61 and pycor < -47 and pycor > -51 [set pcolor white]]
    ask patches with [not(pcolor = white - .001)][if any? patches in-radius 1 with [pcolor = white - .001] and any? patches in-radius 1 with [pcolor = white][set pcolor black]]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Europe"[
    import-pcolors "Images/Europe.png"
    ask patches[
                if (pcolor > 4 and pcolor < 8.4) [set pcolor gray + 2]
                if pcolor > 8.4 [set pcolor white]
                if (pcolor >= 0 and pcolor < 4) or (pxcor = 100 and not(pycor < 75 and pycor > -30)) or  pycor = -100[set pcolor white - .001]
               ]
    ask patches with [pcolor = white - .001 or pcolor = gray + 2][if any? patches in-radius 1 with [pcolor = white - .001] and any? patches in-radius 1 with [pcolor = white][set pcolor black]]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Asia"[
    import-pcolors "Images/Asia.png"
    ask patches[
                if (pcolor > 4 and pcolor < 8.6) [set pcolor gray + 2]
                if pcolor > 8.6 [set pcolor white]
                if (pcolor >= 0 and pcolor < 4) or pxcor = 100 or  pycor = -100 [set pcolor white - .001]]
    ask patches with [pcolor = white - .001 or pcolor = gray + 2][if any? patches in-radius 1 with [pcolor = white - .001] and any? patches in-radius 1 with [pcolor = white][set pcolor black]]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Africa"[
    import-pcolors "Images/Africa.png"
     ask patches[
                if (pcolor > 2.5 and pcolor < 8.4) [set pcolor gray + 2]
                if pcolor > 8.4 [set pcolor white]
                if (pcolor >= 0 and pcolor < 2.5) or pxcor = 100 or  pycor = -100[set pcolor white - .001]
     ]
    ask patches with [pcolor = white - .001 or pcolor = gray + 2][if any? patches in-radius 1 with [pcolor = white - .001] and any? patches in-radius 1 with [pcolor = white][set pcolor black]]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Australia"[
    import-pcolors "Images/Aust.png"
    adjust-color
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "North Am"[
    import-pcolors "Images/NA.png"
    adjust-color
   ]
   ;display
   ;ask patches with [ pcolor = gray + 2][if count patches with[pcolor = white] in-radius 1 < 2[set pcolor white]]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "PA"[
     import-pcolors "Images/PA.png"
      ask patches[
                if (pcolor > 3 and pcolor < 8.6) [set pcolor gray + 2]
                if pcolor > 8.6 [set pcolor white]
                if (pcolor >= 0 and pcolor < 3) or pxcor = 100 or  pycor = -100[set pcolor white - .001]
                if pxcor = -100 and pycor <= -52 and pycor >= -94 [set pcolor black]
     ]
    ask patches with [pcolor = white - .001 or pcolor = gray + 2][if (any? patches in-radius 1 with [pcolor = white - .001])and (any? patches in-radius 1 with [pcolor = white or pcolor = gray + 2 ]) [set pcolor black]]
     ;adjust-color
   ]
  ]
end

;;--------------------------------------------------------------------------------------------------------

to setPercentLoc
   if Background = "USA"[
      set popPercent[0.015426864	0.002231987	0.019559776	0.009373671	0.122231018	0.015669397	0.011931005	0.002827682	0.001884941	
                     0.059243456	0.030067157	0.004300415	0.004744547	0.043294398	0.021241118	0.010060945	0.009315347	0.014118324	
                     0.015377786	0.00448571	0.018927144	0.021850458	0.03443703	0.017370557	0.009885621	0.0195965	  0.003156302	
                     0.005949879	0.007950717	0.004425255	0.029622744	0.006481369	0.065475001	0.029085864	0.002160239	0.039021965	
                     0.011998938	0.01224083	0.042247791 0.003679932	0.014295899	0.002625128	0.020094852	0.07658644	0.008135519	
                     0.002116065	0.025403336	0.021126082	0.006181919 0.018760172	0.00172491]   ;;2004 US Census approximation Alphabetical
      set states[42 -38    -78 -58    -56 -20     19 -24    -81 -5    -30 8    85 43    73 19    73 19  ;;Delaware = DC = Maryland due to limited resolution
                 65 -68    55 -36     -26 -89     -58 52    29 22     40 16    14 29    -4 2     46 -1
                 20 -55    90 68      73 19       86 48     44 41     9 58     30 -38   18 2     -39 71
                 -9 25     -69 13     86 56       81 27     -34 -25   79 44    68 -10   -10 69   52 21
                 0 -21     -78 61     68 30       87 49     64 -23    -10 47   42 -15   -8 -53   -52 15
                 81 61     69 5       -72 84      60 10     25 49     -35 39
      ]]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    if Background = "World"[
      set popPercent[0.141193097 0.622400183 0.002854981 0.112828858 0.065664568 0.055058313
       ]
      set states[1 -6    42 21    87 -59    -12 47     -65 36    -52 -41
      ]
    ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "South Am"[
    set popPercent[0.107596578 0.026704693 0.483536427 0.044075707 0.115374644 0.039668136 0.000518538
                   0.002592689 0.01814882  0.07752139  0.001296344 0.00907441  0.073891626] ;;www.alsagerschool.co.uk Population in 2010 prediciton
    set states[-33 -31    -31 25    26 39    -56 -27    -67 79    -89 65    21 79    -4 79    -1 9    -73 43    9 79
               8 -19      -35 89
              ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Europe"[
    set popPercent[0.005060806  0.004681245  0.010374651  0.010880732  0.012778534  0.013031574  0.004934285  0.010248131  0.005566886
                   0.013031574  0.006832088  0.001644762  0.006579047  0.077683366  0.006579047  0.103366954  0.013411135  0.012525494
                   0.004681245  0.07274908   0.002783443  0.004554725  0.000632601  0.002909963  0.005819926  0.021255383  0.005946447
                   0.051114136  0.013031574  0.028087471  0.139245535  .000037956   0.006832088  0.002530403  0.050355016  0.011133772
                   0.009615531  0.097040947  0.062121388  0.074140802  0.014170256
    ]
    set states[0 -79    79 -82    -18 -50    26 -21    88 -82    -49 -35    -7 -65    17 -72    -12 -58    -15 -39
              -35 -6    18 8      22 48     -56 -55    74 -75    -33 -32    5 -84    -3 -53     -92 -24    -23 -72
              17 -2     12 -11    -45 -40    5 -77     27 -52    -45 -28    -18 60    -3 -28    -89 -83    16 -59
              74 -39    -23 -72    -3 -45    -18 -58   -74 -82    -12 40    -38 -53   50 -87    37 -41    -71 -18
              3 -66
              ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Asia"[
    set popPercent[0.007614504  0.000848604  0.001972432  0.034884521  0.000252288  .000091741  0.003600835  0.321483452  0.000412835
                   0.001192633  0.271255246  0.05513635   0.020228894  0.006972317  0.001605468 0.029265384  0.001444921  0.00410541
                   0.006536547  0.011398821  0.000573381  0.001215568  0.001651338  0.001146763 0.006077842  0.000710993  0.013348318
                   0.007064058  0.000802734  0.040457788  0.021536203  0.000160547  0.032361643 0.006697094  0.00091741   0.004885209
                   0.004701727  0.005504461  0.001903626  0.01532075   0.01759134   0.001215568 0.000665122  0.006742965  0.020320635
                   0.000596317  0.005527396
    ]
    set states[-30 -7     -67 6    -67 6     12 -27     12 -18     57 -69    40 -50    27 2      -80 -19  -68 9
               -7 -31     41 -87   -50 -13   -69 -13    -79 -22    83 15     -79 -21   -27 28    59 19    64 15
               -62 -22    -18 14   34 -34    -79 -13    57 -71     18 30     23 -32    1 -17     -44 -42  -23 -14
               72 -49     -56 -32  -72 22    -64 -36    38 -74     -1 -68    -76 -9    65 -21    -26 6    33 -44
               -82 1      -40 5    -48 -35   -35 12     46 -46     -77 -14   -56 -54
    ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Africa"[
    set popPercent[0.038924275  0.017389546  0.008795875  0.001617632  0.014356486  0.008290365  0.020018198  0.004246285  0.009705793
                   0.003336366  0.023253463  0.000909918  0.081589324  0.000606612  0.006066121  0.082094834  0.001415428  0.00151653
                   0.023152361  0.009604691  0.001415428  0.034273582  0.002426448  0.004549591  0.008998079  0.020321504  0.010817915
                   0.015165302  0.003336366  0.033869174  0.025376605  0.00252755   0.014963098  0.159134567  0.010211303  0.012334445
                   0.006167223  0.015873016  0.046203619  0.037306642  0.001617632  0.036497826  0.007481549  0.011525629  0.026690931
                   0.000303306  0.070063694  0.011626731  0.012031139
    ]
    set states[-44 71    1 -39    -45 22    19 -65    -56 29    37 -14    -15 9    8 14     2 35    -5 -7
               -67 16    71 29    33 70     -21 -1    60 39    62 20     -17 -7    -92 32   -55 17  -82 24
               -92 27    59 -3    28 -84    -77 12    -4 71    81 -57    47 -41    -59 44   -80 48  -68 82
               51 -53    0 -65    -25 41    -30 21    36 -10    -91 34    -84 18    90 17   21 -83   34 33
               39 -75    51 -22    -48 15    -27 90    44 0    -88 61    17 -13    31 -43   36 -54
       ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "Australia"[
    set popPercent[0.016124088  0.335712616  0.009932005  0.076545668  0.023990666  0.247324669  0.191947668  0.098422621
 ]                         ;Australian Bureau of Statistics 2003
    set states[78 -36    60 -26    -1 49    7 -9    62 -87    51 -53    51 33    -53 12
    ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "North Am"[
    set popPercent[0.001352341  0.000412929  0.06772029  0.00722625  0.024362787  0.018994715  0.012181394  0.000116394  0.023124001
                   0.017343001  0.011974929  0.000612656 0.197586333 0.009084429  0.005574536  0.602333014
    ]
    set states[-80 32    0 -81    -1 -7    7 -95    13 -71    25 -77    1 -87    61 55    -1 -84
               21 -76    4 -85    92 30    -17 -66  6 -89     11 -98    11 -38
    ]
   ]
 ;;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
   if Background = "PA"[
    set popPercent[0.007433564  0.104361238  0.005894608  0.014771696 0.004070009 0.030423936 0.01051571  0.005110392  0.048663168
                   0.014174923  0.012425481  0.00048644   0.004788026 0.011054263 0.035298355  0.003400767  0.006789482  0.003087194
                   0.005223574  0.007358163  0.01739867  0.020502963  0.044854782  0.002859038  0.022867988  0.012103521  0.000402734
                   0.010529471  0.00116122  0.003311768  0.003711896  0.007296198  0.00374007  0.001858228  0.017367809  0.038323909
                   0.007706423  0.009797775  0.025412314  0.025995326  0.009774731  0.003740396  0.009795006  0.00378518  0.01129276
                   0.061077575  0.001484889  0.021746179  0.007699339  0.003550347  0.123568384  0.003770198  0.001472186  0.012241295
                   0.003057229  0.006515972  0.00053383  0.003439281  0.003368848  0.003389286  0.004687301  0.003571599  0.016521139
                   0.003885823  0.030127137  0.002286449  0.031084547
    ]
    set states[13 -86    -82 -40    -64 -14    -92 -20    -30 -76    57 -43    -26 -39    35 62    86 -49   -78 -5
               -38 -38    -19 35    63 -6      -7 -8      63 -76    -62 15    -30 1      -3 20    40 5      -85 56
               11 -62    27 -44    75 -81     -35 33      -82 78    -70 -82    -56 42    -3 -83    -18 -83    -90 -86
               -14 -46   -51 -27   -47 11      7 -33      67 37      47 -71    -92 1     39 -47    68 -28    54 16
               18 27     -32 62    -90 25     0 -27       76 8      76 -57     31 4      77 -18    27 -5    11 -45
               84 -74    86 30     -10 59     47 -21     18 -17     -50 -77    35 35     60 64    11 60    18 -2
               -71 33    -56 63    -91 -61    77 52      -62 -53     53 41     30 -83
    ]
 ]
end

;;--------------------------------------------------------------------------------------------------------

to adjust-color
     ask patches[
                if (pcolor > 4 and pcolor < 8.4) [set pcolor gray + 2]
                if pcolor > 8.4 [set pcolor white]
                if (pcolor >= 0 and pcolor < 4) or pxcor = 100 or  pycor = -100[set pcolor white - .001]
     ]
    ask patches with [pcolor = white - .001 or pcolor = gray + 2][if (any? patches in-radius 1 with [pcolor = white - .001]) and (any? patches in-radius 1 with [pcolor = white])[set pcolor black]]
end

;;--------------------------------------------------------------------------------------------------------

to back-diag
  ask patch xcoord ycoord [set pcolor black]
  ask patch (- xcoord) ycoord [set pcolor black]
  set xcoord xcoord + 1
  set ycoord ycoord + 1
end

;;--------------------------------------------------------------------------------------------------------

to check-approp
    loop[
    ifelse (([pcolor] of (patch-ahead 1) = black) or
      ([pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = black and
        [pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = black)) or
    [pxcor] of (patch-ahead 1) = (- [pxcor] of (patch-here)) or
    [pycor] of (patch-ahead 1) = (- [pycor] of (patch-here)) or
    ((isset = 0) and (Background = "1") and ([pxcor] of (patch-ahead 1) = 0))
           [change-dir]
           [stop]
    ]
end

;;--------------------------------------------------------------------------------------------------------

to check-approp-map
    loop[
       ifelse (([pcolor] of (patch-ahead 1) = (gray + 2)) or
               ([pcolor] of (patch-ahead 1) = white - .001) or
               ([pcolor] of (patch-ahead 1) = black) or
         (([pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = (gray + 2) or
          [pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = (white - .001) or
          [pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = (black)) and
         (([pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = (gray + 2)) or
          [pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = (white - .001) or
          [pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = (black)))) or
          [pxcor] of (patch-ahead 1) = (- [pxcor] of (patch-here)) or
          [pycor] of (patch-ahead 1) = (- [pycor] of (patch-here))
           [change-dir]
           [stop]
    ]
end

;;--------------------------------------------------------------------------------------------------------

to check-approp-source
    loop[
       ifelse (([pcolor] of (patch-ahead 1) = white - .001) or
               ([pcolor] of (patch-ahead 1) = black) or
         (([pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = (white - .001) or
          [pcolor] of (patch-left-and-ahead (heading - (90 * (quad))) 1) = (black)) and
         ([pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = (white - .001) or
          [pcolor] of (patch-right-and-ahead (90 - (heading - (90 * (quad)))) 1) = (black)))) or
          [pxcor] of (patch-ahead 1) = (- [pxcor] of (patch-here)) or
          [pycor] of (patch-ahead 1) = (- [pycor] of (patch-here))
           [change-dir]
           [stop]
    ]
end

;;--------------------------------------------------------------------------------------------------------

to change-dir
  set heading (random 360)
end

;;--------------------------------------------------------------------------------------------------------

to-report quad
  if heading >= 0 and heading < 90
     [report 0]
  if heading >= 90 and heading < 180
     [report 1]
  if heading >= 180 and heading < 270
     [report 2]
  if heading >= 270 and heading < 360
     [report 3]
end

;;--------------------------------------------------------------------------------------------------------

to become-infected
       set cases cases + 1
       ifelse color < 106
         [if (color - blue) < (.001 * Susceptible_Below) or (color - blue) > (.001 * Susceptible_Above)
           [set weak true]]
         [if (color - blue) < 3 + (.001 * Susceptible_Below) or (color - blue) > 3 + (.001 * Susceptible_Above)
           [set weak true]]
       set color (((color) - blue) + red)
       set size (size + (.001 * (random Susceptible_Infection_Lifespan)))
       if random 100 < Deadly_Mutations
         [set color (color + .010)]
       ifelse random 100 < Percent_Recovery
         [set recover true]
         [set recover false]

end

;;--------------------------------------------------------------------------------------------------------

to infect
  set radius Infection_Radius
  check-radius
  if any? patches in-radius radius with [pcolor = gray + 2]  [set radius radius + 1]
  if shade-of? blue color and not(vaccinated) and (Contact_Infection > (random 100)) and
     (any? people in-radius radius with [shade-of? red color or shade-of? turquoise color] or
      (pcolor > red and pcolor < 20 and disease > (random 100))) and
     not(size <= 5 + .001 + (.001 * Recover_Immune_Time) and size > 5)
     [ifelse Contact_Infection - ((Contact_Infection - (100 - Max_Resistance)) * (resist * (1 / Contact_Resistance))) > random 100
       [ifelse color < 106
         [if (color - blue) < (.001 * Susceptible_Below) or (color - blue) > (.001 * Susceptible_Above)
           [set weak true]]
         [if (color - blue) < 3 + (.001 * Susceptible_Below) or (color - blue) > 3 + (.001 * Susceptible_Above)
           [set weak true]]
      ifelse %_Carriers > random 100
      [set color turquoise + (color - blue)]
      [set color red + (color - blue) set cases cases + 1]  ;; add current age
      set size 5
      if random 100 < Deadly_Mutations
       [set color (color + .010)]

      ifelse random 100 < Percent_Recovery
       [ifelse shade-of? red color
         [set color blue + (color - red)]
         [set color blue + (color - turquoise)]
        set size size + .001
        set weak false]
      [if time >= (firstCase + PharmDelay) and shade-of? red color[
      if not(PoorPer) and random 100 < PharmUse and random 100 < PharmStock and random 100 < PharmEffect [set drugCured drugCured + 1
                                                                                  set color blue + (color - red)
                                                                                  set size size + .001
                                                                                  set weak false]]]
      ]
     [if resist < Contact_Resistance [set resist resist + 1]]]
end

;;--------------------------------------------------------------------------------------------------------

to check-radius
loop[
      ifelse any? patches in-radius radius with [pcolor = black]
        [set radius radius - 1]
        [stop]
    ]
end

;;--------------------------------------------------------------------------------------------------------

to reproduce
let
       mat-blue-trav 0
       let mat-blue-meand 0
       let nei-mat-blue-trav 0
       let nei-mat-blue-meand 0
       let mat-turq-trav 0
       let mat-turq-meand 0
       let nei-mat-turq-trav 0
       let nei-mat-turq-meand 0
       let mat-red-trav 0
       let mat-red-meand 0
       let nei-mat-red-trav 0
       let nei-mat-red-meand 0
       let parentColor 0
       let randNum 0
       let myWho 0;; any? turtles in-radius includes calling turtle

  if radius > 5
    [set radius 5]
  set myWho who
  if ((random 100) < 25) and  ;; 50% chance of running into opposite sex also, no reproduction 2x a time interval
       count turtles in-radius radius < Carrying_Capacity and
       count turtles in-radius radius > 1
    [  ifelse shade-of? blue color [set parentColor blue][set parentColor turquoise]

       set mat-blue-trav ((shade-of? blue color and color >= blue + (.001 * Procreation_Age)) and shape = "default")
       set mat-blue-meand ((shade-of? blue color and color >= blue + (.001 * Procreation_Age)) and shape = "circle")
       set nei-mat-blue-trav any? turtles in-radius radius with
         [not (who = myWho) and (shade-of? blue color and color >= blue + (.001 * Procreation_Age)) and shape = "default"]
       set nei-mat-blue-meand any? turtles in-radius radius with
         [not (who = myWho) and (shade-of? blue color and color >= blue + (.001 * Procreation_Age)) and shape = "circle"]

       set mat-turq-trav (((shade-of? turquoise color and color >= turquoise + (.001 * Procreation_Age))) and shape = "default")
       set mat-turq-meand (((shade-of? turquoise color and color >= turquoise + (.001 * Procreation_Age))) and shape = "circle")
       set nei-mat-turq-trav any? turtles in-radius radius with
         [not (who = myWho) and ((shade-of? turquoise color and color >= turquoise + (.001 * Procreation_Age))) and shape = "default"]
       set nei-mat-turq-meand any? turtles in-radius radius with
         [not (who = myWho) and ((shade-of? turquoise color and color >= turquoise + (.001 * Procreation_Age)))and shape = "circle"]

       set mat-red-trav (shade-of? red color and color >= (red + (.001 * Procreation_Age)) and shape = "default")
       set mat-red-meand (shade-of? red color and color >= (red + (.001 * Procreation_Age)) and shape = "circle")
       set nei-mat-red-trav any? turtles in-radius radius with
         [not (who = myWho) and shade-of? red color and color >= red + (.001 * Procreation_Age) and shape = "default"]
       set nei-mat-red-meand any? turtles in-radius radius with
         [not (who = myWho) and shade-of? red color and color >= red + (.001 * Procreation_Age) and shape = "circle"]

       ifelse mat-blue-meand and nei-mat-blue-meand and (random 1000) < (Healthy_Meanderer_Fertility * Healthy_Meanderer_Fertility)
           [healthy-birth parentColor ]
       [ifelse ((mat-blue-meand and nei-mat-blue-trav) or (mat-blue-trav and nei-mat-blue-meand)) and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Meanderer_Fertility)
           [healthy-birth parentColor]
       [ifelse mat-blue-trav and nei-mat-blue-trav and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Traveler_Fertility)
           [healthy-birth parentColor]

       [ifelse mat-blue-meand and nei-mat-turq-meand and (random 1000) < (Healthy_Meanderer_Fertility * Healthy_Meanderer_Fertility)
           [if (random 100) < 50 [set parentColor turquoise] healthy-birth parentColor] ;;50% chance of inheritance of carrier
       [ifelse ((mat-blue-meand and nei-mat-turq-trav) or (mat-blue-trav and nei-mat-turq-meand)) and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Meanderer_Fertility)
           [if (random 100) < 50 [set parentColor turquoise] healthy-birth parentColor] ;;50% chance of inheritance of carrier
       [ifelse mat-blue-trav and nei-mat-turq-trav and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Traveler_Fertility)
           [if (random 100) < 50 [set parentColor turquoise] healthy-birth parentColor] ;;50% chance of inheritance of carrier

       [ifelse mat-turq-meand and nei-mat-turq-meand and (random 1000) < (Healthy_Meanderer_Fertility * Healthy_Meanderer_Fertility)
           [set randNum (random 100) ifelse randNum < 25 [infected-birth][if randNum < 50[set parentColor blue]] if randNum >= 25 [healthy-birth parentColor]] ;;1:2:1 Infected:Carrier:Healthy
       [ifelse ((mat-turq-trav and nei-mat-turq-meand) or (mat-turq-meand and nei-mat-turq-trav)) and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Meanderer_Fertility)
           [set randNum (random 100) ifelse randNum < 25 [infected-birth][if randNum < 50[set parentColor blue]] if randNum >= 25 [healthy-birth parentColor]] ;;1:2:1 Infected:Carrier:Healthy
       [ifelse mat-turq-trav and nei-mat-turq-trav and (random 1000) < (Healthy_Traveler_Fertility * Healthy_Traveler_Fertility)
           [set randNum (random 100) ifelse randNum < 25 [infected-birth][if randNum < 50[set parentColor blue]] if randNum >= 25 [healthy-birth parentColor]] ;;1:2:1 Infected:Carrier:Healthy

       [ifelse ((mat-blue-meand and nei-mat-red-meand) or (nei-mat-blue-meand and mat-red-meand)) and (random 1000) < (Healthy_Meanderer_Fertility * Infected_Meanderer_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth blue]
            [infected-birth]]
       [ifelse ((mat-blue-meand and nei-mat-red-trav) or (mat-red-meand and nei-mat-blue-trav)) and (random 1000) < (Healthy_Meanderer_Fertility * Infected_Traveler_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth blue]
            [infected-birth]]
       [ifelse ((mat-blue-trav and nei-mat-red-trav) or (nei-mat-blue-trav and mat-red-trav)) and (random 1000) < (Healthy_Traveler_Fertility * Infected_Traveler_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth blue]
            [infected-birth]]

       [ifelse ((mat-turq-meand and nei-mat-red-meand) or (nei-mat-turq-meand and mat-red-meand)) and (random 1000) < (Healthy_Meanderer_Fertility * Infected_Meanderer_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth turquoise]
            [infected-birth]]
       [ifelse ((mat-turq-meand and nei-mat-red-trav) or (mat-red-meand and nei-mat-turq-trav)) and (random 1000) < (Healthy_Meanderer_Fertility * Infected_Traveler_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth turquoise]
            [infected-birth]]
       [ifelse ((mat-turq-trav and nei-mat-red-trav) or (nei-mat-turq-trav and mat-red-trav)) and (random 1000) < (Healthy_Traveler_Fertility * Infected_Traveler_Fertility)
         [ifelse (random 100) < 50
            [healthy-birth turquoise]
            [infected-birth]]

       [ifelse mat-red-meand and nei-mat-red-meand and (random 1000) < (Infected_Meanderer_Fertility * Infected_Meanderer_Fertility)
         [infected-birth]
       [ifelse ((mat-red-meand and nei-mat-red-trav) or (mat-red-trav and nei-mat-red-meand))and (random 1000) < (Infected_Meanderer_Fertility * Infected_Traveler_Fertility)
         [infected-birth]
       [if mat-red-trav and nei-mat-red-trav and (random 1000) < (Infected_Traveler_Fertility * Infected_Traveler_Fertility)
         [infected-birth]]]]]]]]]]]]]]]]]]

    ]
end

;;--------------------------------------------------------------------------------------------------------

to healthy-birth[parentColor]
set births births + 1
hatch Healthy_Birth_Number
  [set color parentColor
   set weak false
   set size 5
   ifelse time >= (firstCase + Vac_Delay) and not PoorPer and random 100 < Vac_Use and random 100 < Vac_Stock and random 100 < Vac_Effect [set vaccinated true][set vaccinated false]]
end

;;--------------------------------------------------------------------------------------------------------

to infected-birth
set births births + 1
hatch Infected_Birth_Number
    [set color red
     set weak true
     set size 5
     set cases cases + 1
     ifelse random 100 < Percent_Recovery
       [set color blue + (color - red)
        set size size + .001
        set weak false]
      [if time >= (firstCase + PharmDelay)[
      if not(PoorPer) and random 100 < PharmUse and random 100 < PharmStock and random 100 < PharmEffect [set drugCured drugCured + 1
                                                                                  set color blue + (color - red)
                                                                                  set size size + .001
                                                                                  set weak false]]]
     if random 100 < Deadly_Mutations
        [set color (color + .010)]]
end

;;--------------------------------------------------------------------------------------------------------

to move
  if shade-of? blue color or shade-of? color turquoise [set inf-moves 0]
  ifelse shape = "default"
    [repeat (Traveler_Moves + inf-moves) ;; how many steps per move
      [ifelse not(is-number? (substring Background 0 1)) [check-approp-map][check-approp]
       fd 1]]
    [repeat (Meanderer_Moves + inf-moves)
      [ifelse not(is-number? (substring Background 0 1)) [check-approp-map][check-approp]
       fd 1]]
end

;;--------------------------------------------------------------------------------------------------------

to age let myMoves 0 let childColor "white"
  set color (color + .001)
  if shade-of? color red[
    ifelse shape = "default"
       [set myMoves Traveler_Moves]
       [set myMoves Meanderer_Moves]
    ifelse ((inf-moves + Infected_Moves) * -1) < myMoves [set inf-moves inf-moves + Infected_Moves]
                                                               [set inf-moves ((- myMoves) + 1)]
  ]
  if (color >= (blue + (.001 * Procreation_Age)) and color < 106) or
     (color >= (red + (.001 * Procreation_Age))  and color < 16) or
     (color >= (turquoise + (.001 * Procreation_Age))and color < 76)
     [set color color + 3]
  ifelse shade-of? blue color
    [if size > 5 [set size (size + .001)]
     ifelse color < 106
         [if color >= (blue + (.001 * Healthy_Lifespan))
           [die-maintain blue]]
         [if color >= ((blue + 3) + (.001 * Healthy_Lifespan))
           [die-maintain blue]]]
     [ifelse shade-of? turquoise color[
      if size > 5 [set size (size + .001)]
      ifelse color < 76
        [if color >= (turquoise + (.001 * Healthy_Lifespan * .75));;Carriers are somewhat effected by the disease (75% of healthy lifespan)
           [ die-maintain blue]];ifelse random 100 < 50 [set childColor turquoise][set childColor blue] die-maintain childColor]]
         [if color >= ((turquoise + 3) + (.001 * Healthy_Lifespan * .75))
           [ die-maintain blue]]];ifelse random 100 < 50 [set childColor turquoise][set childColor blue] die-maintain childColor]]]

     [set size (size + .001)
     ifelse color < 16
       [if color >= (red + (.001 * Healthy_Lifespan))
         [set natDead natDead + 1
         die-maintain red]]
       [if color >= ((red + 3) + (.001 * Healthy_Lifespan))
         [set natDead natDead + 1
          die-maintain red]]
     ifelse weak
       [if size >=  (5 + (.001 * Susceptible_Infection_Lifespan))
         [set dead dead + 1
          die-maintain red]]
       [if size >=  (5 + (.001 * Infection_Lifespan))
         [set dead dead + 1
          die-maintain red]]]
    ]
end

;;--------------------------------------------------------------------------------------------------------

to die-maintain[parentColor]
  if parentColor = blue [set natDead natDead + 1 ]                ;; Maintain status quo of countries
  set births births + 1
  hatch 1[
          set color blue
         if parentColor = red
           [become-infected]
          set weak false
          set size 5
          ifelse time >= (firstCase + Vac_Delay) and not PoorPer and random 100 < Vac_Use and random 100 < Vac_Stock and random 100 < Vac_Effect[set vaccinated true][set vaccinated false]
         ]
        die
end

;;--------------------------------------------------------------------------------------------------------
to infect-area
 if (pcolor = white or (pcolor > red and pcolor < 20))[set pcolor red + .001 set disease 100]

end

;;--------------------------------------------------------------------------------------------------------

to weather-area
  ask patches[
    if pcolor > red and pcolor < 20 [set pcolor pcolor + (4.5 / Residue-yr) set disease disease - (100 / Residue-yr)
                                    if pcolor > 19.5 [set pcolor white]]
  ]
end
;;--------------------------------------------------------------------------------------------------------
to do-plots
  set-current-plot "Healthy/ Infected"
  set-current-plot-pen "Healthy"
  plot count people with [shade-of? blue color]
  set-current-plot-pen "Infected"
  plot count people with [shade-of? red color]
  set-current-plot-pen "Carriers"
  plot count people with [shade-of? turquoise color]
  set-current-plot-pen "Inf Dead"
  plot dead
  set-current-plot-pen "Nat Dead"
  plot natDead
  ;;----------------------------------------------
  set-current-plot "Travelers (Arrows)"
  set-current-plot-pen "Healthy Adult"
  plot count turtles with [color > 106 and shape = "default"]
  set-current-plot-pen "Healthy Young"
  plot count turtles with [shade-of? blue color and color < 106 and shape = "default"]
  set-current-plot-pen "Infected Adult"
  plot count turtles with [shade-of? red color and color > 16 and shape = "default"]
  set-current-plot-pen "Infected Young"
  plot count turtles with [shade-of? red color and color < 16 and shape = "default"]
  set-current-plot-pen "Carrier Adult"
  plot count turtles with [shade-of? turquoise color and color > 76 and shape = "default"]
  set-current-plot-pen "Carrier Young"
  plot count turtles with [shade-of? turquoise color and color < 76 and shape = "default"]
  ;;----------------------------------------------
  set-current-plot "Meanderers (Circles)"
  set-current-plot-pen "Healthy Adult"
  plot count turtles with [color > 106 and shape = "circle"]
  set-current-plot-pen "Healthy Young"
  plot count turtles with [shade-of? blue color and color < 106 and shape = "circle"]
  set-current-plot-pen "Infected Adult"
  plot count turtles with [shade-of? red color and color > 16 and shape = "circle"]
  set-current-plot-pen "Infected Young"
  plot count turtles with [shade-of? red color and color < 16 and shape = "circle"]
  set-current-plot-pen "Carrier Adult"
  plot count turtles with [shade-of? turquoise color and color > 76 and shape = "circle"]
  set-current-plot-pen "Carrier Young"
  plot count turtles with [shade-of? turquoise color and color < 76 and shape = "circle"]
end

;;--------------------------------------------------------------------------------------------------------

to setup-file
let line 0
  file-close
  ;;user-message file
  file-open file
  set line file-read-line ;; You need to close the Excel SS if you get an error here.
  file-close
  if Clear_File or line = "first"
    [file-delete file]
  file-open file	
  if Clear_File or line = "first"
    [;file-print "This file MUST be closed while running the pestilence model. Do NOT save when prompted."
     ;file-print "To format: 1) Open 'Template' Excel document(Enable Macros) 2) View this window 3)Press Alt + F8 4) Select Template.xls!Macro1 and Run"
    ]
  if line = "first"
    [user-message "File output will be found on the Desktop in the Pestilence folder (The image with a,). This Excel file must be closed while running the Pestilence model. Do NOT save when prompted."]
  file-print "___P_____,____E____,____S____,____T___,____I____,____L____,____E____,____N_____,____C___,_____E___,_________,_________"
  file-close
end

;;--------------------------------------------------------------------------------------------------------

to disp-header
  file-type "Background: "                      file-print Background
  file-type "Contact Resistance: "              file-type Contact_Resistance             file-type ",,,"
  file-type ",% Carriers: "                     file-type %_Carriers                     file-type ",,"
  file-type ",Vac Delay: "                      file-type Vac_Delay                      file-print ","

  file-type "Max Resistance: "                  file-type Max_Resistance                 file-type ",,,"
  file-type ",Susceptible Below: "              file-type Susceptible_Below              file-type ",,"
  file-type ",Vac Stock: "                      file-type Vac_Stock                      file-print ","

  file-type "Susceptible Infection Lifespan: "  file-type Susceptible_Infection_Lifespan file-type ",,,"
  file-type ",Susceptible Above: "              file-type Susceptible_Above              file-type ",,"
  file-type ",Vac Use: "                        file-type Vac_Use                        file-print ","

  file-type "Infection Lifespan: "              file-type Infection_Lifespan             file-type ",,,"
  file-type ",Percent Recovery: "               file-type Percent_Recovery               file-type ",,"
  file-type ",Vac Effect: "                     file-type Vac_Effect                     file-print ","

  file-type "Healthy Meanderer Fertility: "     file-type Healthy_Meanderer_Fertility    file-type ",,,"
  file-type ",Recover Immune Time: "            file-type Recover_Immune_Time            file-type ",,"
  file-type ",Pharm Delay: "                    file-type PharmDelay                     file-print ","

  file-type "Infected Meanderer Fertility: "    file-type Infected_Meanderer_Fertility   file-type ",,,"
  file-type ",Deadly Mutations: "               file-type Deadly_Mutations               file-type ",,"
  file-type ",Pharm Stock: "                    file-type PharmStock                     file-print ","

  file-type "Healthy Traveler Fertility: "      file-type Healthy_Traveler_Fertility     file-type ",,,"
  file-type ",Procreation Age: "                file-type Procreation_Age                file-type ",,"
  file-type ",Pharm Use: "                      file-type PharmUse                       file-print ","

  file-type "Infected Traveler Fertility: "     file-type Infected_Traveler_Fertility    file-type ",,,"
  file-type ",Carrying Capacity: "              file-type Carrying_Capacity              file-type ",,"
  file-type ",Pharm Effect: "                   file-type PharmEffect                    file-print ","

  file-type "Healthy Birth Number: "            file-type Healthy_Birth_Number           file-type ",,,"
  file-type ",Meanderer Moves: "                file-type Meanderer_Moves                file-type ",,"
  file-type ",Poor: "                           file-type Poor                           file-print ","

  file-type "Infected Birth Number: "           file-type Infected_Birth_Number          file-type ",,,"
  file-type ",Traveler Moves: "                 file-type Traveler_Moves                 file-type ",,"
  file-type ",Residue-yr: "                     file-type Residue-yr                     file-print ","

  file-type "Healthy Lifespan: "                file-type Healthy_Lifespan               file-type ",,,"
  file-type ",Infected Moves: "                 file-type Infected_Moves                 file-print ",,,,"

  file-type "Contact Infection: "               file-type Contact_Infection              file-type ",,,"
  file-type ",Infection Radius: "               file-type Infection_Radius               file-print ",,,,"

  file-print ""
  ask patches[
              if not(Travelers = "-")
                [file-type "Population: ,x:" file-type pxcor file-type " y:" file-type pycor
                file-print (word ",Travelers: "   Travelers   ",,Meanderers: "   Meanderers   ",,%Infected: "   %Infected   ",,Density: "   Density)]
              if not(Source_Delay = "-")
                [file-type "Source: ,x:" file-type pxcor file-type " y:" file-type pycor
                 file-print (word ",Source Delay: "   Source_Delay   ",,Source Intensity: "   Source_Intensity   ",,Source Size: "   Source_Size)]
  ]
  file-print ""
  file-print "Time,Total,Healthy,Infected,Carriers,Susceptible,Infect Dead,Natural Dead,Births,Resistant,Vaccinated,Pharm Cured,% Area Infected,Case:Fatality"
  ;file-type "Healthy Adult Travelers,Healthy Young Travelers,"
  ;file-type "Infected Adult Travelers,Infected Young Travelers,Healthy Adult Meanderers,"
  ;file-type "Healthy Young Meanderers,Infected Adult Meanderers,"
  ;;file-print "Infected Young Meanderers"
end

;;--------------------------------------------------------------------------------------------------------

to update-file
  ;;user-message time
  file-type time file-type ","
  file-type count turtles file-type ","
  ifelse count turtles > 0
    [file-type count people with [shade-of? blue color] file-type ","
     file-type count people with [shade-of? red color] file-type ","
     file-type count people with[shade-of? turquoise color] file-type ","
    ]
    [file-type 0 file-type "," file-type 0 file-type "," file-type 0 file-type ","]
  file-type count people with [weak = true] file-type ","
  file-type dead file-type ","
  file-type natDead file-type ","
  file-type Births file-type ","
  file-type count people with [resist = Contact_Resistance] file-type ","
  file-type count people with [vaccinated] file-type ","
  file-type drugCured file-type ","
  file-type ((count patches with [pcolor > red and pcolor < 20]) / livePatches) * 100 file-type ","
  ifelse dead > 0[file-type cases / dead file-print ","][file-type 0 file-print ","]

  ;file-type count turtles with [color > 106 and shape = "default"] file-type ","
  ;file-type count turtles with [shade-of? blue color and color < 106 and shape = "default"] file-type ","
 ; file-type count turtles with [shade-of? red color and color > 16 and shape = "default"] file-type ","
 ; file-type count turtles with [shade-of? red color and color < 16 and shape = "default"] file-type ","
 ; file-type count turtles with [color > 106 and shape = "circle"] file-type ","
  ;file-type count turtles with [shade-of? blue color and color < 106 and shape = "circle"] file-type ","
  ;file-type count turtles with [shade-of? red color and color > 16 and shape = "circle"] file-type ","
  ;file-type count turtles with [shade-of? red color and color < 16 and shape = "circle"] file-print ""
end
@#$#@#$#@
GRAPHICS-WINDOW
443
10
853
421
-1
-1
2.0
1
10
1
1
1
0
1
1
1
-100
100
-100
100
0
0
1
ticks
30.0

BUTTON
93
10
195
43
Place Populations
place-pop
T
1
T
PATCH
NIL
NIL
NIL
NIL
1

BUTTON
27
10
93
43
Setup
Setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
93
43
195
76
Place Sources
Place-Source
T
1
T
PATCH
NIL
NIL
NIL
NIL
1

BUTTON
195
10
274
43
Go/Stop
Go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
274
10
349
43
Clear People
ClearTurtles
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

CHOOSER
0
43
93
88
Background
Background
"1" "2A" "2B" "3A" "3B" "4A" "4B" "USA" "World" "South Am" "Europe" "Asia" "Africa" "Australia" "North Am" "PA"
15

SLIDER
0
84
140
117
Contact_Resistance
Contact_Resistance
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
0
113
140
146
Max_Resistance
Max_Resistance
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
0
142
196
175
Susceptible_Infection_Lifespan
Susceptible_Infection_Lifespan
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
0
171
196
204
Infection_Lifespan
Infection_Lifespan
0
100
12.0
1
1
NIL
HORIZONTAL

SLIDER
0
200
196
233
Healthy_Meanderer_Fertility
Healthy_Meanderer_Fertility
0
100
25.0
1
1
NIL
HORIZONTAL

SLIDER
0
230
196
263
Infected_Meanderer_Fertility
Infected_Meanderer_Fertility
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
0
260
197
293
Healthy_Traveler_Fertility
Healthy_Traveler_Fertility
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
0
290
198
323
Infected_Traveler_Fertility
Infected_Traveler_Fertility
0
100
3.0
1
1
NIL
HORIZONTAL

SLIDER
0
320
196
353
Healthy_Birth_Number
Healthy_Birth_Number
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
0
349
196
382
Infected_Birth_Number
Infected_Birth_Number
0
20
1.0
1
1
NIL
HORIZONTAL

SLIDER
0
378
196
411
Healthy_Lifespan
Healthy_Lifespan
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
0
407
196
440
Contact_Infection
Contact_Infection
0
100
49.0
1
1
NIL
HORIZONTAL

SLIDER
0
436
172
469
File_Time_Interval
File_Time_Interval
0
100
1.0
1
1
NIL
HORIZONTAL

PLOT
0
469
300
618
Healthy/ Infected
Time (years)
Number
0.0
1.0
0.0
100.0
true
true
"" ""
PENS
"Healthy" 1.0 0 -13345367 true "" ""
"Infected" 1.0 0 -2674135 true "" ""
"Carriers" 1.0 0 -14835848 true "" ""
"Inf Dead" 1.0 0 -16777216 true "" ""
"Nat Dead" 1.0 0 -5825686 true "" ""

SLIDER
195
43
367
76
People_Map
People_Map
0
10000
1000.0
1
1
NIL
HORIZONTAL

SLIDER
195
72
367
105
%_Carriers
%_Carriers
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
195
101
367
134
Susceptible_Below
Susceptible_Below
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
195
130
367
163
Susceptible_Above
Susceptible_Above
0
100
71.0
1
1
NIL
HORIZONTAL

SLIDER
196
159
368
192
Percent_Recovery
Percent_Recovery
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
196
188
368
221
Recover_Immune_Time
Recover_Immune_Time
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
196
218
368
251
Deadly_Mutations
Deadly_Mutations
0
100
7.0
1
1
NIL
HORIZONTAL

SLIDER
196
247
368
280
Procreation_Age
Procreation_Age
0
30
16.0
1
1
NIL
HORIZONTAL

SLIDER
196
276
368
309
Carrying_Capacity
Carrying_Capacity
0
5
3.0
1
1
NIL
HORIZONTAL

SLIDER
196
306
368
339
Meanderer_Moves
Meanderer_Moves
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
196
335
368
368
Traveler_Moves
Traveler_Moves
0
100
19.0
1
1
NIL
HORIZONTAL

SLIDER
196
364
368
397
Infected_Moves
Infected_Moves
0
-100
-100.0
1
1
per year
HORIZONTAL

SLIDER
196
393
368
426
Infection_Radius
Infection_Radius
0
20
3.0
1
1
NIL
HORIZONTAL

SWITCH
172
436
270
469
Clear_File
Clear_File
0
1
-1000

SWITCH
270
436
370
469
File_Output
File_Output
0
1
-1000

PLOT
299
469
626
618
Travelers (Arrows)
Time (years)
Number
0.0
1.0
0.0
100.0
true
true
"" ""
PENS
"Healthy Adult" 1.0 0 -6968366 true "" ""
"Healthy Young" 1.0 0 -13345367 true "" ""
"Infected Adult" 1.0 0 -1403760 true "" ""
"Infected Young" 1.0 0 -2674135 true "" ""
"Carrier Adult" 1.0 0 -7680583 true "" ""
"Carrier Young" 1.0 0 -14835848 true "" ""

PLOT
626
469
950
618
Meanderers (Circles)
Time (years)
Number
0.0
1.0
0.0
100.0
true
true
"" ""
PENS
"Healthy Adult" 1.0 0 -6968366 true "" ""
"Healthy Young" 1.0 0 -13345367 true "" ""
"Infected Adult" 1.0 0 -1403760 true "" ""
"Infected Young" 1.0 0 -2674135 true "" ""
"Carrier Adult" 1.0 0 -7680583 true "" ""
"Carrier Young" 1.0 0 -14835848 true "" ""

MONITOR
367
55
443
100
Time (years)
time
1
1
11

MONITOR
367
97
443
142
Total
count people
0
1
11

MONITOR
367
139
443
184
Healthy
count people with [shade-of? blue color]
0
1
11

MONITOR
367
182
443
227
Infected
count people with [shade-of? red color]
0
1
11

MONITOR
367
224
443
269
Carriers
count people with[shade-of? turquoise color]
0
1
11

MONITOR
367
266
443
311
Susceptible
count people with [weak = true]
0
1
11

MONITOR
367
307
443
352
Infect Dead
dead
1
1
11

MONITOR
366
349
443
394
Natural Dead
natDead
1
1
11

MONITOR
367
390
443
435
NIL
Births
1
1
11

MONITOR
140
97
196
142
Resistant
count people with [resist = Contact_Resistance]
0
1
11

SLIDER
852
71
950
104
Vac_Use
Vac_Use
0
100
15.0
1
1
NIL
HORIZONTAL

SLIDER
852
100
950
133
Vac_Effect
Vac_Effect
0
100
80.0
1
1
NIL
HORIZONTAL

SLIDER
852
129
950
162
PharmDelay
PharmDelay
0
100
6.0
1
1
NIL
HORIZONTAL

SLIDER
852
158
950
191
PharmStock
PharmStock
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
852
186
950
219
PharmUse
PharmUse
0
100
30.0
1
1
NIL
HORIZONTAL

SLIDER
852
214
950
247
PharmEffect
PharmEffect
0
100
60.0
1
1
NIL
HORIZONTAL

SLIDER
852
242
950
275
Poor
Poor
0
100
12.0
1
1
%
HORIZONTAL

SLIDER
852
270
950
303
Residue-yr
Residue-yr
0
100
4.0
1
1
NIL
HORIZONTAL

MONITOR
852
302
950
347
Vaccinated
count people with [vaccinated]
0
1
11

MONITOR
852
341
950
386
Pharm Cured
drugCured
1
1
11

MONITOR
852
382
950
427
% Area Infected
((count patches with [pcolor > red and pcolor < 20]) / livePatches) * 100 ; Number of \"live\" patches
1
1
11

MONITOR
852
423
950
468
Case:Fatality
cases / dead
3
1
11

SLIDER
852
10
950
43
Vac_Delay
Vac_Delay
0
100
10.0
1
1
NIL
HORIZONTAL

SLIDER
852
40
950
73
Vac_Stock
Vac_Stock
0
100
50.0
1
1
NIL
HORIZONTAL

@#$#@#$#@
WHAT IS IT?
-----------
This program models the spread of an infectious disease.


HOW IT WORKS
------------
Organisms move randomly about. Travelers are meant to move more than meanderers. Move_Factor allows the user to select how many times farther travelers move than meanderers. When a healthy organism moves onto a patch within Infection_Radius patches of another organism that is infected there is a certain chance that it will also become infected ("Contact_Infection"). Various backgrounds provide the effect of natural boundaries between populations.

HOW TO USE IT
-------------
Click 'Setup' to display the chosen Background.
Click 'Place Populations' and click on the screen to be prompted about the 			characteristics of that population to create. This is not necessary when 		working with maps because the relative populations are already set up based off 	People_Map.
	-Characteristics prompted are:
	Travelers: The number of triangle shapes present.
	Meanderers: The number of circle shapes present.
	Percent_Infected: The percent of organisms that are infected.
	Density: The density that organisms will start.
Click 'Place Sources' and click the screen to enter characteristics of an infectious 		source to occur during the simulation. The source will fade away according to 		the value of Residue-yr.
	-Characteristics prompted are:
	Source_Delay: Which year the source will occur.
	Source_Intensity: The number of particles radiating from the epicenter.
	Source_Size: The radius of the source from its center.
Click 'Go' to begin the simulation.
Click 'Stop' to halt execution. 'Go' may be clicked again without data loss.
Click 'Clear People' to remove all people from the background. This also sets all 		variables to zero, including the time. This is useful because all populations 		and sources set will reoccur with desired changes.

Initial Conditions
Background: The boundary setup. The increasing number loosely represents a more 		    restrictive boundary.
Contact_Resistance: The number of infection opportunities escaped to produce 				    Max_Resistance. The individual builds up a percentage of resistance 		    after each opportunity until it reaches Max_Resistance after 			    the number of contacts is reached.
Max_Resistance: The optimal resistance obtained through evolutionary forces alleviating 		the threat to those exposed but not infected. Note that resistance is 			the opposite of Contact_Infection. So Contact_Infection is lowered 			it equals (100 - Max_Resistance) in individuals exposed 				Contact_Resistance times without being infected (Resistant).
%_Carriers: The percentage of people that become carriers of the disease rather than 		    infected. They can transmit the disease as if they were infected and live 		    75% of the Healthy Lifespan.
People_Map: The number of people that will represent the actual number of people on a 		    map. A percentage of this number is placed in a country depending on its 		    actual population percentage of the featured land mass.
Susceptible_Infection_Lifespan: The number of years before the organism dies once 					infected during the susceptible period (Above/Below).
Susceptible_Below: The age below which organisms are more susceptible to 				   the disease.  
Susceptible_Above: The age above which organisms are more susceptible to the disease.
Percent_Recovery: The percent chance that an infected organism will become healthy. 
Recover_Immune_Time: The time an organism is immune to the disease after recovery.
Infection_Lifespan: The number of years before the organism dies once infected. If its 			    age exceeds the Healthy_Lifespan it will die regardless.
Deadly_Mutations: The percent chance that an infected organism will experience a deadly 	          mutation that will take ten years off its life.
_ _Fertility: The percent chance that an organism will successfully reproduce given the 	      chance. If an infected organism breeds with a healthy one, the fertility 		      of each are multiplied together to produce an overall probability.
Procreation_Age: The age at which an organism can reproduce. (marked by a change to a 			 lighter color)
Healthy_Birth_Number: The number of offspring per procreation event. (assuming both 		              partners are healthy) 
Infected_Birth_Number: The number of offspring per procreation event. (assuming both 		               partners are infected) There is a 50% chance that the 				       Infected_Birth_Number will be produced in the case of a   			       healthy/infected reproduction.
Healthy_Lifespan: The number of years (Time) an organism will live assuming it is 			  healthy (blue). 
Carrying_Capacity: If this number of organisms is met in a radius of five (pixels), no 		           reproduction will take place.
Meanderer_Moves: How many "steps" meanderers take during the period of a year. 	                         (relative to pixel size)
Traveler_Moves: How many "steps" travelers take during the period of a year. 	
Infected_Moves: The amount of moves an infected individual loses each year.       
Contact_Infection: The percent chance that a healthy organism will be infected if it 			   comes in contact with an infected organism.
Infection_Radius: The radius that an infected organism must be in of a healthy organism 		  to infect it. Notice that contact infection plays a role.
Vac_Delay: The number of years after the emergence of the disease agent until a 		   successful vaccine is developed. A syringe appears at the bottom right 		   corner of the screen to indicate when the vaccine is available.
Vac_Stock: The percentage of people that have access to a vaccine once it is available.
Vac_Use: The percentage of the population that receives a vaccine when it is 			   available. Recipients of the vaccine are immune to the disease.
Vac_Effect: The percentage of vaccine users that become entirely immune to the disease.
PharmDelay: The number of years after the emergence of the disease agent until a 		     successful pharmaceutical drug is developed. A pill appears at the bottom 		     right corner of the screen to indicate when the drug is available.
PharmStock: The percentage of people that have access to pharmaceuticals once they 		    become available.
PharmUse: The percentage of the population that purchases pharmaceuticals to treat 		     the spreading disease. Note that people who recover on their own via 		     Percent_Recovery will not purchase drugs.
PharmEffect: The percentage of pharmaceutical users that are cured by usage.
Poor: The percentage of the population too poor to afford vaccines or pharmaceuticals.
Residue-yr: The number of years source fall out or infected person residue lasts in the  	    environment before fading away.
File_Output: To output values to an excel spreadsheet.
Clear_File: Deletes previous information instead of appending to past results.
File_Time_Interval: The interval that values are sent to the file.
Note: To copy the graphs right-click and select Copy Image



THINGS TO NOTICE
----------------
One important thing to understand is that infections do not proliferate themselves exclusively by reproducing. Their main sustenance is preying upon healthy individuals. Keep in mind that even though the infection radius may increase, barriers will prevent those on the other side of an infected organism even though they may be in the radius. Also, deadly mutations and recovery occur at the time of infection so that it only happens once even though this would happen at random times but the effect is the same. The varying fertilities allow the inclusion of the observation that meanderers often procreate more than travelers and to realize its affect on disease propagation. 


THINGS TO TRY
-------------
Try different backgrounds while keeping everything else the same. Observe how the different variables lead to a rapid or steady spread of disease. Be sure to keep all the variables in mind because one extreme value can offset the effect of the others drastically. Try any combination and examine the different equilibriums or lack thereof. The graphs also reveal a lot about trends. You can even utilize the spreadsheet formatted output for further graphical analysis.


EXTENDING THE MODEL
-------------------
Most variables were included that could reasonably fit on the screen. 


NETLOGO FEATURES
----------------
The graphical tools allow an immediate analysis of trends. 

RELATED MODELS
--------------
Virus is a more basic model. The HIV model is also based on a similar idea.

CREDITS AND REFERENCES
----------------------
Produced by Joe Glessner (jglessner@usip.edu) under the direction of Dr. James Johnson 
University of the Sciences in Philadelphia
2004
Updated to run on NetLogo_6.1.1 by Joe Glessner (jglessnd@gmail.com)
2019
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
