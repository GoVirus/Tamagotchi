#lang racket

(require 2htdp/universe)
(require 2htdp/image)
(require 2htdp/image
         (only-in racket/gui/base play-sound))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Global Variables ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define screenHeight 432) ;True 16:9
(define screenWidth 768) ;True 16:9
(define fps 60)
(define totalFrames 30000)
(define assets "assets/")
(define background (rectangle 768 432 "solid" "white"))
(define showGrid #f)
(define gridX 12)
(define gridY 9)
(define centerPoint (circle 5 "solid" "blue"))

(define actualGUI empty)
(define actualSprite empty)
(define count 0)
(define search 0)

(define debug #f)
(define showFrames #t)
(define showFPS #t)
(define showSpriteName #t)
(define showGUIName #t)
(define showTimeline #t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; Game Variables ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define petName "Panda")

(define-struct pet ([name #:mutable] stats))

(define statFood   5)
(define statWash   5)
(define statGame   5)
(define statHeal   5)
(define statListen 5)
(define statHappy  10)

(define stats (vector statFood statWash statGame statHeal statListen statHappy))

(define panda (make-pet petName stats))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Debugging Tools ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (onOffDebug)
   (cond [(equal? debug #t) (set! debug #f)]
         [else (set! debug #t)]
   )
)

(define (setTrueFPS)
   (set! showFPS #t)
)

(define (setFalseFPS)
   (set! showFPS #f)
)

(define (setTrueTimeline)
   (set! showTimeline #t)
)

(define (setFalseTimeline)
   (set! showTimeline #f)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; GRID ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gridSizeX)
   (/ screenWidth gridX)
)

(define (gridSizeY)
   (/ screenHeight gridY)
)

(define (midGridSizeX)
   (/ (gridSizeX) 2)
)

(define (midGridSizeY)
   (/ (gridSizeY) 2)
)

(define (drawGrid)
  (define rectX (rectangle (gridSizeX) screenHeight "outline" "red"))
  (define rectY (rectangle screenWidth (gridSizeY) "outline" "red"))
  (overlay/xy
   (overlay/xy
    (beside rectX rectX rectX rectX rectX rectX rectX rectX rectX rectX rectX rectX)
    0 0
    (above rectY rectY rectY rectY rectY rectY rectY rectY rectY)
    )
   (alignScreenCenterX centerPoint) (alignScreenCenterY centerPoint) centerPoint)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;; GRID Helper Functions ;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (screenZeroX) 0)
(define (screenZeroY) 0)

(define (screenCenterX)
  (/ screenWidth 2)
)

(define (screenCenterY)
  (/ screenHeight 2)
)

(define (alignScreenCenterX img)
  (- (/ screenWidth 2) (/ (image-width img) 2))
)

(define (alignScreenCenterY img)
  (- (/ screenHeight 2) (/ (image-height img) 2))
)

(define (screenLeftX img)
  (+ 0 (/ (image-width img) 2))
)

(define (screenRightX img)
  (- screenWidth (/ (image-width img) 2))
)

(define (screenTopY img)
   (cond  [(image? img) (/ (image-height img) 2)])
)

(define (screenBottomY [x 0])
    (cond [(image? x) (- screenHeight (/ (image-height x) 2))]
          [(number? x) (- screenHeight x)]
          [else screenHeight]
          )
)

(define (screenOffsetY y)
  (* (gridSizeY) y)
)

(define (screenOffsetX x)
  (* (gridSizeX) x)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Structs ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct posn (x y))
(define-struct button (name img x y width height) #:transparent)

(define-struct gui    (name
                       x y
                      [start  #:mutable]                   
                      [end    #:mutable]
                       ui)    #:transparent)

(define-struct sprite (name
                       x y
                      [path   #:mutable] 
                      [frames #:mutable]
                       ext)   #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; States ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


(define emptyState  (sprite "Empty"  (screenCenterX) (screenCenterY) "" 1    ".png"))
(define eggState    (sprite "Egg"    (screenCenterX) (screenCenterY) "" 120  ".png"))
(define idleState   (sprite "Idle"   (screenCenterX) (screenCenterY) "" 120  ".png"))
(define happyState  (sprite "Happy"  (screenCenterX) (screenCenterY) "" 120  ".png"))
(define sadState    (sprite "Sad"    (screenCenterX) (screenCenterY) "" 120  ".png"))
(define sickState   (sprite "Sick"   (screenCenterX) (screenCenterY) "" 120  ".png"))
(define hungryState (sprite "Hungry" (screenCenterX) (screenCenterY) "" 120  ".png"))
(define dirtyState  (sprite "Diry"   (screenCenterX) (screenCenterY) "" 120  ".png"))
(define dedState    (sprite "Ded"    (screenCenterX) (screenCenterY) "" 120  ".png"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Messages ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define sadMessage    (sprite "SadCloud"    (screenCenterX) (screenCenterY) "" 1    ".png"))
(define happyMessage  (sprite "HappyCloud"  (screenCenterX) (screenCenterY) "" 120  ".png"))
(define hungryMessage (sprite "HungryCloud" (screenCenterX) (screenCenterY) "" 120  ".png"))
(define sickMessage   (sprite "SickCloud"   (screenCenterX) (screenCenterY) "" 120  ".png"))
(define dirtyMessage  (sprite "DirtyCloud"  (screenCenterX) (screenCenterY) "" 120  ".png"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Buttons ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define foodImage  (bitmap/file (string-append assets "img/ui/food.png")))
(define gameImage  (bitmap/file (string-append assets "img/ui/game.png")))
(define songImage  (bitmap/file (string-append assets "img/ui/song.png")))
(define healImage  (bitmap/file (string-append assets "img/ui/heal.png")))
(define washImage  (bitmap/file (string-append assets "img/ui/wash.png")))
(define sleepImage (bitmap/file (string-append assets "img/ui/sleep.png")))

(define eatButton    (button "Eat"        foodImage  0 0 75 75))
(define gameButton   (button "Game"       gameImage  0 0 75 75))
(define listenButton (button "Listen"     songImage  0 0 75 75))
(define healButton   (button "Heal"       healImage  0 0 75 75))
(define washButton   (button "Wash"       washImage  0 0 75 75))
(define sleepButton  (button "Sleep"      sleepImage 0 0 75 75))

(define newGameButton  (button "New Game"
                               (underlay/xy
                                  (rectangle 100 80 "outline" "black") 0 0
                                  (text "New Game" 20 "black"))
                               0 0 75 75))

(define continueButton (button "Continue"
                               (underlay/xy
                                  (rectangle 100 80 "outline" "black") 0 0
                                  (text "Continue" 20 "black"))
                               0 0 75 75))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Interface ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (debugUI w)
  
  (above (if showFrames
             (text (string-append "Frame: " (number->string w)) 12 "black")
                (text "" 10 "black"))
         (if showGUIName
             (text (string-append "GUI: " (gui-name actualGUI)) 12 "black")
                (text "" 10 "black"))
         (if showSpriteName
             (text (string-append "Sprite: " (sprite-name actualSprite)) 12 "black")
                (text "" 10 "black"))
         (if showFPS
             (text (string-append "FPS: " (number->string fps)) 12 "black")
                (text "" 10 "black"))
         (text (string-append "Count: " (number->string count)) 12 "black")
  )         
)

(define (introUI w)
  (above (text "Valentina" 40 "purple")
         (text "Santiago" 40 "purple")
         (text "Daniel" 40 "purple")
  )
)

(define (titleUI w)
  (above (text "Tamagotchi" 60 "purple")
         (text "Play" 40 "purple")
  )
)

(define (menuUI w)
  (overlay/offset
         (button-img newGameButton)
         0 50
         (button-img continueButton)
  )
)

(define (renameUI w)
  (above (text "Ingresa el nombre" 16 'black)
         (text petName 24 'black)
  )
)

(define (actionsUI w)
  (overlay/offset
      (overlay/xy
        (overlay/xy
           (overlay/xy
              (overlay/xy
                (overlay/xy
                (overlay/xy  (text
                                (string-append "Food "
                                   (number->string (vector-ref (pet-stats panda) 0)) "/5")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 20 (vector-ref (pet-stats panda) 0))  20 "solid" "red") 0 0
                                        (rectangle 100  20 "outline" "black")))
                110 0
                (overlay/xy  (text
                                (string-append "Clean "
                                   (number->string (vector-ref (pet-stats panda) 1)) "/5")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 20 (vector-ref (pet-stats panda) 1))  20 "solid" "red") 0 0
                                        (rectangle 100  20 "outline" "black"))))
                220 0
                (overlay/xy  (text
                                (string-append "Game "
                                   (number->string (vector-ref (pet-stats panda) 2)) "/5")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 20 (vector-ref (pet-stats panda) 2))  20 "solid" "red") 0 0
                                        (rectangle 100  20 "outline" "black"))))
                330 0
                (overlay/xy  (text
                                (string-append "Heal "
                                   (number->string (vector-ref (pet-stats panda) 3)) "/5")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 20 (vector-ref (pet-stats panda) 3))  20 "solid" "red") 0 0
                                        (rectangle 100  20 "outline" "black"))))
                 440 0
                (overlay/xy  (text
                                (string-append "Listen "
                                   (number->string (vector-ref (pet-stats panda) 4)) "/5")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 20 (vector-ref (pet-stats panda) 4))  20 "solid" "red") 0 0
                                        (rectangle 100  20 "outline" "black"))))
                 550 0
                 (overlay/xy (text
                                (string-append "Happy "
                                   (number->string (vector-ref (pet-stats panda) 5)) "/10")
                                12 "black") -25 0
                             (overlay/xy (rectangle (* 10 (vector-ref (pet-stats panda) 5))  20 "solid" "red") 0 0
                                         (rectangle 100  20 "outline" "black"))))
    0 350
   (overlay/xy
   (overlay/xy 
   (overlay/xy 
   (overlay/xy 
   (overlay/xy (button-img gameButton)
               110 0
               (button-img eatButton))
               220 0
               (button-img listenButton))
               330 0
               (button-img healButton))
               440 0
               (button-img washButton))
               550 0
               (button-img sleepButton))
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; GUIs ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define intro   (gui "Intro"   (screenCenterX) (screenCenterY)   0    620  introUI)) ;debug mod -> 0 180
(define title   (gui "Title"   (screenCenterX) (screenCenterY)   621  839  titleUI)) ;debug mod -> 180 240
(define menu    (gui "Menu"    (screenCenterX) (screenCenterY)   840  1060  menuUI)) ;debug mod -> 240 360
(define rename  (gui "Rename"  (screenCenterX) (screenCenterY)   1061 1280 renameUI)) ;debug mod -> 360 480
(define actions (gui "Actions" (screenCenterX) (screenCenterY)   1281 1400 actionsUI)) ;debug mod -> 480 600

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; (current-directory)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions Engine ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (waitSeconds x)
  (* x 28)
)

(define (waitMinutes x)
  (* 28 (* x 60))
)

(define (waitHours x)
  (* 24 (* 28 (* x 60)))
)

(define (framerate)
  (/ 1 fps)
)

(define (addOneCount)
  (set! count (+ 1 count))
)

(define (setZeroCount)
  (set! count 0)
)

(define (goTo w x)
  (cond [(gui? x)(gui-start x)])
)

(define (timelapse w x)
  (cond [(and (>= w (gui-start x)) (<= w (gui-end x)))  #t]  
        [else #f])
)

(define (isSprite? [x "Main"])
  (cond [(symbol? x)(equal? actualSprite x) #t]
        [(and (sprite? x)(equal? actualSprite (sprite-name x))) #t]
        [else #f]
  )
)

(define (isGUI? w x)
  (cond [(and (>= w (gui-start x)) (<= w (gui-end x)))  #t]  
        [else #f])
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions GUI ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (spritePath sprite)
  (cond [(sprite? sprite)
            (string-append assets "sprites/" (string-downcase (sprite-name sprite)) "/")]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Draw Functions GUI ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (drawBackground w img)
  img
)

(define (drawTimeline w)
  (place-image (isosceles-triangle 15 -15 "solid" "red")
               w screenHeight
               (rectangle 768 15 "outline" "black")
  )
)

(define (drawNotification w)
  (place-image (isosceles-triangle 15 -15 "solid" "red")
               w screenHeight
               (rectangle 768 15 "outline" "black")
  )
)

(define (drawGui w ui)
   (cond [(empty? ui) empty-image]
         [else (ui w)]
   )
)

(define (drawSprite w sprite)
  
   (cond [(equal? debug #t)
            (writeln (string-append "Count: " (number->string count)))
            (writeln (string-append "Frame: " (number->string w)))
         ]
   )

   (cond [(equal? (sprite-name sprite) "Empty") empty-image]
         [else (set-sprite-path! sprite (spritePath sprite))
               (cond [(= count (sprite-frames sprite)) (setZeroCount)])
               (cond [(and
                       (< count (sprite-frames sprite))
                       (string? (sprite-path sprite)) (not (equal? (sprite-path sprite) "")))
                      (addOneCount)
                      (bitmap/file
                       (string-append (sprite-path sprite) (number->string count) (sprite-ext sprite))
                       )
                      ]
                     )
         ]
   )
)

(define (render w gui sprite [message emptyState])

   (set! actualGUI gui)
   (set! actualSprite sprite)

   (cond [(equal? debug #t)  
                ;Img                             ;X                           ;Y
   (place-image (frame (drawGrid))               (screenCenterX)             (screenCenterY)    ; Grid Layer
   (place-image (frame (debugUI w))              (screenRightX (debugUI w))  (screenOffsetY 1)  ; Debug Layer
   (place-image (frame (drawTimeline w))         (screenCenterX)             (screenOffsetY 8)  ; Timeline Layer
   (place-image (frame (drawGui w (gui-ui gui))) (gui-x gui)                 (gui-y gui)        ; GUI Layer
   (place-image (frame (drawSprite w message))   (sprite-x message)          (sprite-y message) ; Notification Layer
   (place-image (frame (drawSprite w sprite))    (sprite-x sprite)           (sprite-y sprite)  ; Sprite Layer
                                                 (drawBackground w background)))))))            ; Background Layer
         ][(equal? debug #f)
   (place-image (drawGui w (gui-ui gui))         (gui-x gui)                 (gui-y gui)        ; GUI Layer
   (place-image (drawSprite w message)           (sprite-x message)          (sprite-y message) ; Notification Layer
   (place-image (drawSprite w sprite)            (sprite-x sprite)           (sprite-y sprite)  ; Sprite Layer 
                                                 (drawBackground w background))))
   ])
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Gameplay ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gameplay w)
  (cond
    [(= w 0)  (play-sound "C:/Users/alluv/tamagotchi/src/assets/mp3/epic intro.mp3" #t)])
    (cond 
          [(timelapse w intro)   (render w intro emptyState)]
          [(timelapse w title)     (render w title emptyState)]
          [(timelapse w menu)      (render w menu emptyState)]
          [(timelapse w rename)    (render w rename emptyState)]
          [(timelapse w actions)   (render w actions idleState)]
          [else (render w actions idleState)]
    )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Mouse Event Handlers ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (isInside? x y button)
  (cond [(or (and
             (>= x (button-x button))
             (<= x (+ (button-x button)(button-width button)))
         )   (and
             (>= y (button-y button))
             (<= y (+ (button-y button)(button-height button)))
             )
         )
         #t]
        [else #f]
   )
)

(define (mouse w x y me)
 
  (cond [(equal? debug #t) (writeln x) (writeln y)]) 
  
  (cond [(and (equal? actualGUI "Menu")
              (equal? me "button-down")) 621]
        [else w]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Keyboard Event Handlers ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (keyboard w key)

  (cond [(equal? debug #t) (writeln (string-append "Key: " key))])

  (cond [(key-event? key)

         (cond
           [(key=? key "left") (gui-start actualGUI)]
           [(key=? key "right") (gui-end actualGUI)]
    
           [(key=? key "f8") (onOffDebug) w]
           [(key=? key "f5") 0]

           [(and (key=? key "\r")(isGUI? w menu)) (goTo w rename)]
    
           [(isGUI? w rename)
            (cond
              
              [(and (and  (key=? key "\b")) (not (equal? petName "")))
               (set! petName (substring petName 0 (sub1 (string-length petName))))
               (cond [(equal? debug #t)
                      (writeln (string-append "Key: " key))
                      (writeln (string-append "String: " (string-titlecase petName)))
                      ])
               w
               ]
              [(and (not (key=? key "shift")) (not (key=? key "\b")))
               (set! petName (string-append petName key))
               (cond [(equal? debug #t)
                      (writeln (string-append "Key: " key))
                      (writeln (string-append "String: " (string-titlecase petName)))
                      ])
               w
               ]
              [(key=? key "\r") (goto w ) 
            ]
           [else w]
           )
         ]
        [else w]
        )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Engine ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (engine w)

   (define (start w)
      (add1 w)
   )
  
   (define (pause)
      w
   )

   (start w)

   (cond [(isGUI? w menu) (pause)]
         [(isGUI? w rename)(pause)]
         [else (start w)]
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Main ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(big-bang 0
  (on-tick engine (framerate)) ; Framelimit
  (to-draw gameplay screenWidth screenHeight)
  (on-mouse mouse)
  ;(state #f)
  (on-key keyboard)
  (name "PandaSushi")
)
