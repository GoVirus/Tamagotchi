#lang racket

(require 2htdp/universe)
(require 2htdp/image)
;(require test-engine/racket-tests)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Global Variables ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define screenHeight 432) ;True 16:9
(define screenWidth 768) ;True 16:9
(define fps 60)
(define totalFrames 30000)
(define assets "assets/")
(define actualState "Main")
(define startFrame 0)
(define endFrame 0)
(define count 0)

(define debug #t)
(define showFrames #t)
(define showFPS #t)
(define showActualState #t)
(define showTimeline #t)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; Structs ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define-struct gui (name frames ui) #:transparent)
(define-struct sprite (name [path #:mutable] frames ext) #:transparent)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;; States ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define idleState (make-sprite "idle" "" 120 ".png"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Debugging Tools ;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

(define (debugTools w)
  
  (above (if showFrames
             (text (string-append "Frame: " (number->string w)) 12 "black")
                (text "" 10 "black"))
         (if showActualState
             (text (string-append "State: " actualState) 12 "black")
                (text "" 10 "black"))
         (if showFPS
             (text (string-append "FPS: " (number->string fps)) 12 "black")
                (text "" 10 "black"))
         (text (string-append "Count: " (number->string count)) 12 "black")
         (text (string-append "StartFrame: " (number->string startFrame)) 12 "black")
         (text (string-append "EndFrame: " (number->string endFrame)) 12 "black")
  )         
)


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

(define (timelapse w a b)
  (cond [(and (and (>= w a) (<= w b))) #t]
        [else #f]
  )
)

(define (addOneCount)
  (set! count (+ 1 count))
)

(define (setZeroCount)
  (set! count 0)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Interface ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (background w)
  (cond
     [(equal? debug #t)
        (underlay/xy
        (underlay/xy
        (underlay/xy
        (rectangle screenWidth screenHeight "solid" "white") 620 10 (debugTools w))
        0 408
     (rectangle 756 20 "outline" "black"))
     (+ w 1) 395
     (isosceles-triangle 15 -30 "solid" "red"))]
     
  [else (rectangle screenWidth screenHeight "solid" "white")]
  )
)

(define (introUI)
  (above (text "Valentina" 40 "purple")
         (text "Santiago" 40 "purple")
         (text "Daniel" 40 "purple")
  )
)

(define (titleUI)
  (above (text "Tamagotchi" 100 "purple")
         (text "Play" 40 "purple")
  )
)

(define (menuUI)
  (above (underlay/xy (rectangle 100 80 "outline" "black") 0 0 (text "New Game" 20 "black"))
         (underlay/xy (rectangle 100 80 "outline" "black") 0 0 (text "Continue" 20 "black"))
  )
)

(define intro (make-gui "intro" 120 (introUI)))
(define title (make-gui "title" 120 (titleUI)))
(define menu (make-gui "menu" 120 (menuUI)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions GUI ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (startEndFrames w ui)
  (define f w)
  (set! startFrame f)
  (cond [(gui? ui)(set! endFrame (+ f (gui-frames ui)))]
        [(gui? ui)(set! endFrame (+ f (sprite-frames ui)))]
  )
)

(define (render w ui)
  (cond [(gui? ui)
           (set! actualState "GUI")
           (underlay/xy (background w) 100 100 (gui-ui ui))
        ]
        [(sprite? ui)
          (set-sprite-path! ui (spritePath ui))
          (set! actualState (string-append "SPRITE "(sprite-name ui)))
          (underlay/xy (background w) 100 100 (spriteDraw w ui))
        ]
  )
)

(define (spritePath sprite)
  (cond [(sprite? sprite)
            (string-append assets "sprites/" (sprite-name sprite) "/")]
  )
)

(define (spriteDraw w sprite)

   (addOneCount)

   (cond [(equal? debug #t)
            (writeln (string-append "Count: " (number->string count)))
            (writeln (string-append "W: " (number->string w)))
         ])
   
   (cond [(= count (sprite-frames sprite)) (setZeroCount)])
   
   (cond [(and (string? (sprite-path sprite)) (not (equal? (sprite-path sprite) "")))
         (bitmap/file (string-append (sprite-path sprite) (number->string count) (sprite-ext sprite)))
         ]
   )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Event Handlers ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (interactions w x y me)
  (cond [(and (timelapse w 600 700) (equal? me "button-down")) 700]
        ;[(equal? me "leave") 0]
        [else w]
))

(define (change w keypress)
  (cond
    [(key=? keypress "left") startFrame]
    [(key=? keypress "right") endFrame]
    [else w]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Gameplay ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gameplay w)
   (cond [(timelapse w 0 120)(render w intro)]
         [(timelapse w 121 240)(render w idleState)]
         [else (render w menu)]
   )
)       

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Engine ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (engine w)
  
   (define (goto w a)
      (- w (- w a))
   )

   (define (start w)
      (+ w 1)
   )
  
   (define (pause)
      w
   )
  
   (start w)
  
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;; Main ;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(big-bang 0
  (on-tick engine (framerate) 241)
  (to-draw gameplay screenWidth screenHeight)
  ;(on-mouse interactions)
  (on-key change)
  ;(stop-when stop)
  (state #f)
  (name "PandaSushi")
)
