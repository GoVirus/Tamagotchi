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
(define lastAction empty)
(define life 0)
(define countGUI 0)
(define count 0)
(define search 0)
(define play 0)
(define musicPlayer #f)
(define pixelate #t)

(define debug #f)
(define showFrames #t)
(define showFPS #t)
(define showSpriteName #t)
(define showGUIName #t)
(define showTimeline #t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;; Game Variables ;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define petname "Panda")

(define-struct pet ([name #:mutable] stats))

(define eating    #f)
(define washing   #f)
(define gaming    #f)
(define healing   #f)
(define listening #f)
(define sleeping  #f)

(define totalEat    0)
(define totalWash   0)
(define totalGame   0)
(define totalHeal   0)
(define totalListen 0)

(define statEat    0)
(define statWash   0)
(define statGame   0)
(define statHeal   0)
(define statListen 0)
(define statHappy  0)

(define stats (vector statEat statWash statGame statHeal statListen statHappy))

(define panda (make-pet petname stats))

(define introSong
  (string->path (string-append (path->string (current-directory)) "assets/mp3/epic.mp3"))
)

(define listenSong
  (string->path (string-append (path->string (current-directory)) "assets/mp3/panda.mp3"))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Structs ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct posn (x y))
(define-struct button (name img x y width height) #:transparent)
(define-struct gui (name x y state [frames #:mutable] time ui) #:transparent)
(define-struct sprite (name x y [path   #:mutable] [frames #:mutable] state ext) #:transparent)

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
;;;;;;;;;;;;;; Buttons ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (getButtonImage buttonName)
       (bitmap/file (string-append assets "img/ui/" buttonName ".png"))
)

(define eatButton    (button "Eat"    (getButtonImage "eat")     0 0 75 75))
(define gameButton   (button "Game"   (getButtonImage "game")    0 0 75 75))
(define listenButton (button "Listen" (getButtonImage "listen")  0 0 75 75))
(define healButton   (button "Heal"   (getButtonImage "heal")    0 0 75 75))
(define washButton   (button "Wash"   (getButtonImage "wash")    0 0 75 75))
(define sleepButton  (button "Sleep"  (getButtonImage "sleep")   0 0 75 75))

(define newGameButton  (button "New Game"
                               (underlay/xy (text "New Game" 15 "black") 0 0
                                            (rectangle 100 50 "outline" "black")) 0 0 100 50))

(define continueButton (button "Continue"
                               (underlay/xy (text "Continue" 15 "black") 0 0
                                            (rectangle 100 50 "outline" "black")) 0 0 100 50))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;; Interface ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (debugUI w)
  
  (above (if showGUIName
             (text (string-append "GUI: "     (gui-name actualGUI))       12 "black")
                (text "" 10 "black"))
         (if showSpriteName
             (text (string-append "Sprite: "  (sprite-name actualSprite)) 12 "black")
                (text "" 10 "black"))
         (if showFPS
             (text (string-append "FPS: "     (number->string fps))       12 "black")
                (text "" 10 "black"))
         (if showFrames
             (text (string-append "State: "   (number->string w))         12 "black")
                (text "" 10 "black"))
         (if musicPlayer
             (text "Music: On" 12 "black")
                (text "Music: Off" 12 "black"))
         (text (string-append "CountSprite: " (number->string count))       12 "black")
         (text (string-append "CountGUI: "    (number->string countGUI))    12 "black")
         (text (string-append "Lifetime: "    (number->string life))        12 "black")
         (text (string-append "TotalEat: "    (number->string totalEat))   12 "black")
         (text (string-append "TotalWash: "   (number->string totalWash))   12 "black")
         (text (string-append "TotalGame: "   (number->string totalGame))   12 "black")
         (text (string-append "TotalHeal: "   (number->string totalHeal))   12 "black")
         (text (string-append "TotalListen: " (number->string totalListen)) 12 "black")
         (if (not (empty? lastAction))
              (text (string-append "LastAction: " (sprite-name lastAction)) 12 "black")
                (text "" 10 "black"))
        
  )         
)

(define (introUI w)
  (above (text "Valentina" 40 "purple")
         (text "Santiago"  40 "purple")
         (text "Daniel"    40 "purple")
  )
)

(define (titleUI w)
  (set! background (rectangle 768 432 "solid" "white"))
  (cond [(equal? pixelate #t)
            (bitmap/file (string-append assets "/img/background/title-pixel.png"))]
           [else (bitmap/file (string-append assets "/img/background/title.png"))]
  )
)

(define (menuUI w)
  (set! background (rectangle 768 432 "solid" "white"))
  (overlay/offset
     (cond [(equal? pixelate #t)
            (scale 0.75 (bitmap/file (string-append assets "/img/background/title-pixel.png")))]
           [else (scale 0.75 (bitmap/file (string-append assets "/img/background/title.png"))) ]
     )
     0 150
     (overlay/offset
         (button-img newGameButton)
         0 75
         (button-img continueButton)
     )
  )
)

(define (birthUI w)
  (set! background (rectangle 768 432 "solid" "white"))
  (overlay/offset
     (button-img continueButton) 0 -200 (rectangle 0 0 "outline" "white")
  )
)

(define (sleepUI w)
  (set! background (rectangle 768 432 "solid" "black"))
  (scale 2 (button-img sleepButton))
)

(define (renameUI w)
  (above (text "Ingresa el nombre de tu mascota: " 16 'black)
         (text (pet-name panda) 24 'black)
  )
)

(define (buttonsUI w)
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
               (button-img sleepButton)
   )
)

(define (barsUI w)
  (overlay/xy
   (overlay/xy
    (overlay/xy
     (overlay/xy
      (overlay/xy
       (overlay/xy
        (text
         (string-append "Eat "
                        (number->string (vector-ref (pet-stats panda) 0)) "/5")
         12 "black") -25 0
                     (overlay/xy
                      (rectangle (* 20  (vector-ref  (pet-stats panda) 0))  20 "solid" "red")
                      0 0
                      (rectangle 100  20 "outline" "black"))
                     )
       110 0
       (overlay/xy
        (text
         (string-append "Clean "
                        (number->string (vector-ref (pet-stats panda) 1)) "/5")
         12 "black") -25 0
                     (overlay/xy
                      (rectangle (* 20 (vector-ref (pet-stats panda) 1))  20 "solid" "red")
                      0 0
                      (rectangle 100  20 "outline" "black"))
                     )
       )
      220 0
      (overlay/xy
       (text
        (string-append "Game "
                       (number->string (vector-ref (pet-stats panda) 2)) "/5")
        12 "black") -25 0
                    (overlay/xy
                     (rectangle (* 20 (vector-ref (pet-stats panda) 2))  20 "solid" "red")
                     0 0
                     (rectangle 100  20 "outline" "black"))
                    )
     )
     330 0
     (overlay/xy
      (text
       (string-append "Heal "
                      (number->string (vector-ref (pet-stats panda) 3)) "/5")
       12 "black") -25 0
                   (overlay/xy
                    (rectangle (* 20 (vector-ref (pet-stats panda) 3))  20 "solid" "red")
                    0 0
                    (rectangle 100  20 "outline" "black"))
                   )
      )
     
    440 0
    (overlay/xy
     (text
      (string-append "Listen "
         (number->string (vector-ref (pet-stats panda) 4)) "/5") 12 "black") -25 0
            (overlay/xy
               (rectangle (* 20 (vector-ref (pet-stats panda) 4))  20 "solid" "red")
                   0 0
                (rectangle 100  20 "outline" "black"))
    )
    )
   550 0
   (overlay/xy
    (text
     (string-append "Happy "
                    (number->string (vector-ref (pet-stats panda) 5)) "/10")
     12 "black") -25 0
                 (overlay/xy
                  (rectangle (* 10 (vector-ref (pet-stats panda) 5))  20 "solid" "red")
                  0 0
                  (rectangle 100  20 "outline" "black"))
                 )
   )
)

(define (backUI w)
   (underlay/xy (text "Back to Menu" 15 "black") 0 0
                (rectangle 100 50 "outline" "black")
   ) 
)

(define (actionsUI w)
   (set! background (rectangle 768 432 "solid" "white"))
   (overlay/offset (barsUI w) 0 320 (buttonsUI w))
)

(define (gameoverUI w)
   (set! background (rectangle 768 432 "solid" "white"))
   (overlay/offset (barsUI w) 0 320 (backUI w))
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;; GUIs ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define intro    (gui "Intro"    (screenCenterX) (screenCenterY)    0   680 "next"   introUI))
(define title    (gui "Title"    (screenCenterX) (screenCenterY)    1   680 "next"   titleUI))
(define menu     (gui "Menu"     (screenCenterX) (screenCenterY)    2   120 "pause"  menuUI))
(define rename   (gui "Rename"   (screenCenterX) (screenCenterY)    3   120 "pause"  renameUI))
(define birth    (gui "Birth"    (screenCenterX) (screenCenterY)    4   120 "pause"  birthUI))
(define sleep    (gui "Sleep"    (screenCenterX) (screenCenterY)    12  600 "pause"  sleepUI))
(define bars     (gui "Bars"     (screenCenterX) (screenOffsetY 1)  5   420 "idle"   barsUI))
(define actions  (gui "Actions"  (screenCenterX) (screenCenterY)    5   420 "pause"  actionsUI))
(define gameover (gui "GameOver" (screenCenterX) (screenCenterY)    11  120 "pause"  gameoverUI))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; States ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define eggState    (sprite "Egg"    (screenCenterX) (screenCenterY) "" 120 4  ".png"))
(define idleState   (sprite "Idle"   (screenCenterX) (screenCenterY) "" 120 5  ".png"))
(define eatState    (sprite "Eat"    (screenCenterX) (screenCenterY) "" 120 6  ".png"))
(define listenState (sprite "Listen" (screenCenterX) (screenCenterY) "" 420 7  ".png"))
(define healState   (sprite "Heal"   (screenCenterX) (screenCenterY) "" 120 8  ".png"))
(define gameState   (sprite "Game"   (screenCenterX) (screenCenterY) "" 180 9  ".png"))
(define washState   (sprite "Wash"   (screenCenterX) (screenCenterY) "" 240 10 ".png"))
(define deadState   (sprite "Dead"   (screenCenterX) (screenCenterY) "" 120 11 ".png"))
(define emptyState  (sprite "Empty"  (screenCenterX) (screenCenterY) "" 1   0 ".png"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;; Messages ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define sadMessage    (sprite "SadCloud"    (screenCenterX) (screenCenterY) "" 1   0 ".png"))
(define happyMessage  (sprite "HappyCloud"  (screenCenterX) (screenCenterY) "" 120 0 ".png"))
(define hungryMessage (sprite "HungryCloud" (screenCenterX) (screenCenterY) "" 120 0 ".png"))
(define sickMessage   (sprite "SickCloud"   (screenCenterX) (screenCenterY) "" 120 0 ".png"))
(define dirtyMessage  (sprite "DirtyCloud"  (screenCenterX) (screenCenterY) "" 120 0 ".png"))

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

(define (addOneCountGUI)
  (set! countGUI (+ 1 countGUI))
)

(define (setZeroCount)
  (set! count 0)
)

(define (setZeroCountGUI)
  (set! countGUI 0)
)

(define (goTo x)
  (cond [(gui? x) (gui-state x)])
)

(define (isSprite? w sprite)
  (cond [(= w (sprite-state sprite)) #t]
        [else #f])
)

(define (isGUI? w gui)
  (cond [(= w (gui-state gui)) #t]
        [else #f])
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions GUI ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (onOffPixelate)
   (cond [(equal? pixelate #t) (set! pixelate #f)]
         [else (set! pixelate #t)]
   )
)

(define (spritePath sprite)
  (cond [(and (sprite? sprite) (equal? pixelate #f))
            (string-append assets "sprites/" (string-downcase (sprite-name sprite)) "/")]
        [else (string-append assets "sprites/" (string-downcase (sprite-name sprite)) "/pixelart/")]
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

(define (drawGUI w gui)
   (addOneCountGUI)
   (cond [(empty? gui) empty-image]
         [else (gui w)]
   )
)

(define (drawSprite w sprite)
        
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
   (place-image
    (frame (drawGrid))               (screenCenterX)             (screenCenterY)    ; Grid Layer
   (place-image
    (frame (debugUI w))              (screenRightX (debugUI w))  (screenOffsetY 3)  ; Debug Layer
   (place-image
    (frame (drawTimeline w))         (screenCenterX)             (screenOffsetY 8)  ; Timeline
   (place-image
    (frame (drawGUI w (gui-ui gui))) (gui-x gui)                 (gui-y gui)        ; GUI Layer
   (place-image
    (frame (drawSprite w sprite))    (sprite-x sprite)           (sprite-y sprite)  ; Sprite Layer
                                     (drawBackground w background))))))]           ; Background

   [(equal? debug #f)
   (place-image
      (drawGUI w (gui-ui gui)) (gui-x gui) (gui-y gui) ; GUI Layer
   (place-image
      (drawSprite w sprite) (sprite-x sprite) (sprite-y sprite) ; Sprite Layer 
         (drawBackground w background)))]
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Gameplay Helper ;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (restart)
   (setZeroCount)
   (setZeroCountGUI)
)

(define (onMusicPlayer)
   (cond [(equal? musicPlayer #f) (set! musicPlayer #t)])
)

(define (offMusicPlayer)
   (cond [(equal? musicPlayer #t) (set! musicPlayer #f)])
)

(define (onOffMusicPlayer)
   (cond [(equal? musicPlayer #f) (set! musicPlayer #t)]
         [else (set! musicPlayer #f)]
   )
)

(define (addStat pos x)
  (cond [(and (>= pos 0) (< pos 5) (= x 2) (<= (vector-ref (pet-stats panda) pos) 3))
         (vector-set! (pet-stats panda) pos (+ (vector-ref (pet-stats panda) pos) x))]
        
        [(and (>= pos 0) (< pos 5) (= x 1) (<= (vector-ref (pet-stats panda) pos) 4))
         (vector-set! (pet-stats panda) pos (+ (vector-ref (pet-stats panda) pos) x))]
        
        [(and (= pos  5) (= x 1) (<= (vector-ref (pet-stats panda) pos) 9))
         (vector-set! (pet-stats panda) pos (+ (vector-ref (pet-stats panda) pos) x))]
        
        [(and (= pos  5) (= x 2) (<= (vector-ref (pet-stats panda) pos) 8))
         (vector-set! (pet-stats panda) pos (+ (vector-ref (pet-stats panda) pos) x))]
        
        [(and (= pos  5) (= (vector-ref (pet-stats panda) pos) 10))
         (vector-set! (pet-stats panda) pos 10)]
        )
)

(define (subStat pos x)
  (cond [(and (>= pos 0) (< pos 5) (= x 2) (>= (vector-ref (pet-stats panda) pos) 1))
         (vector-set! (pet-stats panda) pos (- (vector-ref (pet-stats panda) pos) x))]
        
        [(and (>= pos 0) (< pos 5) (= x 1) (>= (vector-ref (pet-stats panda) pos) 1))
         (vector-set! (pet-stats panda) pos (- (vector-ref (pet-stats panda) pos) x))]
        
        [(and (= pos  5) (= x 1) (>= (vector-ref (pet-stats panda) pos) 4))
         (vector-set! (pet-stats panda) pos (- (vector-ref (pet-stats panda) 5) x))]
        
        [(and (= pos  5) (= x 2) (>= (vector-ref (pet-stats panda) pos) 5))
         (vector-set! (pet-stats panda) pos (- (vector-ref (pet-stats panda) pos) x))]
        
        [(and (= pos  5) (= (vector-ref (pet-stats panda) pos) 3))
         (vector-set! (pet-stats panda) pos 3)]
        )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Gameplay ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gameplay w)
  
  (define (eatStats)
    (addStat 0 1) ;Eat +1
    (addStat 5 1) ;Happy +1
    (subStat 1 1) ;Wash  -1
    (subStat 3 1) ;Heal  -1
    (cond [(<= totalEat 3)
           (set! totalEat (+ totalEat 1))
           (set! totalWash   0)
           (set! totalGame   0)
           (set! totalListen 0)
           (set! totalHeal   0)
           ]
     )
  )
  
  (define (washStats)
     (addStat 1 2) ;Wash  +2
     (cond [(<= totalWash 3)
            (set! totalWash (+ totalWash 1))
            (set! totalEat    0)
            (set! totalGame   0)
            (set! totalListen 0)
            (set! totalHeal   0)]
     )
  )

  (define (gameStats)
    
    (addStat 2 1) ;Game  +1
    (addStat 3 1) ;Heal  +1
    (addStat 5 1) ;Happy +1
    (subStat 1 1) ;Wash  -1
    (cond [(<= totalGame 3)
           (set! totalGame (+ totalGame 1))
           (set! totalEat    0)
           (set! totalWash   0)
           (set! totalListen 0)
           (set! totalHeal   0)
           ]
          )
    )
     
  (define (healStats)
    (addStat 3 1) ;Heal  +1
    (subStat 5 1) ;Happy -1
    (cond [(<= totalHeal 3)
           (set! totalHeal (+ totalHeal 1))
           (set! totalEat    0)
           (set! totalWash   0)
           (set! totalListen 0)
           (set! totalGame   0)
           ])
    )

  (define (listenStats)
     (addStat 4 1) ;Listen +1
     (addStat 5 2) ;Happy  +2
     (subStat 3 1) ;Heal   -1
     (cond [(<= totalListen 3)
            (set! totalListen (+ totalListen 1))
            (set! totalEat    0)
            (set! totalWash   0)
            (set! totalHeal   0)
            (set! totalGame   0)
            
           ]
     )
  )

  ;;;Intro and Music;;;
  (define (introScene)
     (cond [(equal? musicPlayer #f)
            (onMusicPlayer) 
            ;(play-sound introSong #t)
        ]
     )
     (render w intro emptyState)
  )

  ;;;Title;;;
  (define (titleScene)
     (render w title emptyState)
  )

  ;;;Menu;;;
  (define (menuScene)
     (cond [(equal? musicPlayer #t)
            (offMusicPlayer)
           ]
     )
     (render w menu emptyState)
  )

  ;;;Rename;;;
  (define (renameScene)
     (render w rename emptyState)
  )

  ;;;EggState;;;
  (define (eggScene)
     (vector-set! (pet-stats panda) 0 3)
     (vector-set! (pet-stats panda) 1 3)
     (vector-set! (pet-stats panda) 2 3)
     (vector-set! (pet-stats panda) 3 3)
     (vector-set! (pet-stats panda) 4 3)
     (vector-set! (pet-stats panda) 5 6)
     (render w birth eggState)
  )

  ;;;IdleState and Lifetime;;;
  (define (idleScene)
     (set! eating    #f)
     (set! gaming    #f)
     (set! washing   #f)
     (set! healing   #f)
     (set! listening #f)
     (set! sleeping  #f)
     (set-gui-frames! bars 120)
     (set-gui-frames! actions 120)
     (offMusicPlayer)
     (lifetime)
     (render w actions idleState)
  )

  ;;;EatState;;;
  (define (eatScene)
    (set-gui-frames! bars 240)
    (cond [(equal? eating #f) (eatStats) (set! eating #t)])
    
    (cond [(= totalEat 4) (render w gameover deadState)]
          [else (lifetime) (render w bars eatState)]
    )
  )

  ;;;WashState;;;
  (define (washScene)
    (set-gui-frames! bars 420)
    (cond [(equal? washing #f) (washStats) (set! washing #t)])
    
    (cond [(= totalWash 4) (render w gameover deadState)]
          [else (lifetime) (render w bars washState)]
    )
  )

  ;;;ListenState;;;
  (define (listenScene)
    (set-gui-frames! bars 420)

    (cond [(and (equal? eating #f) (equal? musicPlayer #f)) 
           (listenStats)
           (set-gui-frames! bars 900)
           (set! eating #t)
           (onMusicPlayer)
           ;(play-sound listenSong #t)
          ]
    )
    
    (cond [(= totalListen 4) (render w gameover deadState)]
          [else (lifetime)(render w bars listenState)]            
    ) 
  )

  ;;;GameState;;;
  (define (gameScene)
    (set-gui-frames! bars 420)
    (cond [(equal? gaming #f) (gameStats) (set! gaming #t)])
    
    (cond [(= totalGame 4) (render w gameover deadState)]
          [else (lifetime) (render w bars gameState)]
    )
  )

  ;;;HealState;;;
  (define (healScene)
    (set-gui-frames! bars 240)
    (cond [(equal? healing #f) (healStats) (set! healing #t)])
    
    (cond [(= totalHeal 4) (render w gameover deadState)]
          [else (lifetime) (render w bars healState)]
    )
  )

  ;;;SleepState;;;
  (define (sleepScene)
    (cond [(equal? sleeping #f) (set! sleeping #t)])
    (lifetime)
    (render w sleep emptyState)
  )

  ;;;DeadState;;;
  (define (deadScene)
    (set-gui-frames! gameover 120)
    (render w gameover deadState)
  )

  ;;;Stats;;;
  (define (lifetime)
     (set! life (+ life 1))
  )
  
  ;;;Logic;;;
  (cond [(= w (gui-state    intro))       (introScene)]  ;0
        [(= w (gui-state    title))       (titleScene)]  ;1
        [(= w (gui-state    menu))        (menuScene)]   ;2
        [(= w (gui-state    rename))      (renameScene)] ;3
        [(= w (gui-state    birth))       (eggScene)]    ;4
        [(= w (sprite-state idleState))   (idleScene)]   ;5
        [(= w (sprite-state eatState))    (eatScene)]    ;6
        [(= w (sprite-state listenState)) (listenScene)] ;7
        [(= w (sprite-state healState))   (healScene)]   ;8
        [(= w (sprite-state washState))   (washScene)]   ;9
        [(= w (sprite-state gameState))   (gameScene)]   ;10
        [(= w (sprite-state deadState))   (deadScene)]   ;11
        [(= w (gui-state    sleep))       (sleepScene)]  ;12
  )
)
  
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Mouse Event Handlers ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (click me)
  
   (cond [(equal? me "button-down") #t]
         [else #t]
   )
)

(define (mouse w x y me)

  (cond [(equal? debug #t)
         (writeln (string-append  "ME:" me))
         (writeln (string-append  "X:" (number->string x) " Y:" (number->string y)))
        ]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Keyboard Event Handlers ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (keyboard w key)

  (cond [(equal? debug #t) (writeln (string-append "Key: " key))])

  (cond [(isGUI? w rename)
         (cond [(and  (key=? key "\b")) (not (equal? (pet-name panda) ""))
            (set-pet-name! panda
                           (substring (pet-name panda) 0 (sub1 (string-length (pet-name panda)))))]
        [(and (not (key=? key "shift"))
              (not (key=? key "\b"))
              (not (key=? key "left"))
              (not (key=? key "right")))
            (set-pet-name! panda
                           (string-append (pet-name panda) key))]
        [else w]
  )])           


  (cond [(and (equal? debug #t) (not (isGUI? w intro)) (key=? key "left" )) (restart) (- w 1)]
        [(and (equal? debug #t) (not (isGUI? w sleep)) (key=? key "right")) (restart) (+ w 1)]

        [(and (isGUI? w actions) (not (isGUI? w rename)) (key=? key "z"))
            (restart) (sprite-state eatState)]
        
        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "x"))
            (restart) (sprite-state washState)]

        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "c"))
            (restart) (sprite-state gameState)]

        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "v"))
            (restart) (sprite-state healState)]

        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "b"))
            (restart) (sprite-state listenState)]

        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "n"))
            (restart) (gui-state sleep)]

        [(and (isGUI? w sleep) (not (isGUI? w rename))  (key=? key "n"))
            (restart) (sprite-state idleState)]

        [(and (isGUI? w actions) (not (isGUI? w rename))  (key=? key "escape"))
            (restart) (sprite-state idleState)]

        [(key=? key "f5") 0]
        [(key=? key "f8") (onOffDebug) w]
        [(and (not (isGUI? w rename)) (key=? key "p")) (onOffPixelate) w]

        [(and (isGUI? w rename) (key=? key "\r")) (+ w 1)]
        [else w]
  )    
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Engine ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (engine w)
  
   (define (next w)
     (+ w 1)
   )

   (define (pause w)
     w
   )

   (define (goto sprite)
     (sprite-state sprite)
   )

   (cond [(= (gui-frames actualGUI) countGUI)
          (cond [(equal? (gui-time actualGUI) "idle")  (restart) (goto idleState)]
                [(equal? (gui-time actualGUI) "next")  (restart) (next w)]
                [(equal? (gui-time actualGUI) "pause") (pause w)])
         ] [else w]
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Main ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(big-bang 0
  (on-tick engine (framerate)) ; Framelimit
  (to-draw gameplay screenWidth screenHeight)
  ;(on-mouse mouse)
  ;(state #f)
  (on-key keyboard)
  (name "PandaSushi")
)

