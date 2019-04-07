#lang racket

(require 2htdp/universe)
(require 2htdp/image)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Global Variables ;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define screenHeight 432) ;True 16:9
(define screenWidth 768) ;True 16:9

(define-struct gui    (name
                       x y
                      [start  #:mutable]                   
                      [end    #:mutable]
                       ui)    #:transparent)

(define (menuUI w)
  (overlay/offset
         (button-img newGameButton)
         0 50
         (button-img continueButton)
  )
)

(define (screenCenterX)
  (/ screenWidth 2)
)

(define (screenCenterY)
  (/ screenHeight 2)
)

(define menu    (gui "Menu"    0 0 0 1000 menuUI))

(define-struct button (name img x y width height) #:transparent)

(define newGameButton  (button "New Game"
                               (underlay/xy (text "New Game" 15 "black") 0 0
                                            (rectangle 100 50 "outline" "black")) 0 0 100 50))

(define continueButton (button "Continue"
                               (underlay/xy (text "Continue" 15 "black") 0 0
                                            (rectangle 100 50 "outline" "black"))  0 0 100 50))

(define (isGUI? w x)
  (cond [(and (>= w (gui-start x)) (< w (gui-end x)))  #t]  
        [else #f])
)

(define (drawGui w ui)
   (cond [(empty? ui) empty-image]
         [else (ui w)]
   )
)

(define (render w gui)
   (place-image (drawGui w (gui-ui gui)) (gui-x gui)(gui-y gui)  (rectangle screenWidth screenHeight "solid" "white"))
)

(define (isInside? x y button)
              
  (cond [(and (and
             (>= x (- (pinhole-x (center-pinhole (button-img button))) (/ (button-width button) 2)))
             (<= x (+ (- (pinhole-x (center-pinhole (button-img button))) (/ (button-width button) 2)) (button-width button)))
         )   (and
             (>= y (- (pinhole-y (center-pinhole (button-img button))) (/ (button-height button) 2)))
             (<= y (+ (- (pinhole-y (center-pinhole (button-img button))) (/ (button-height button) 2)) (button-height button)))
             )
         )
        (writeln "Inside") #t]
        [else #f]
   )
)

(define (getPinhole button)
   (pinhole-x (center-pinhole (button-img button)))
)

(define (click me)
   (cond [(equal? me "button-down") #t]
         [else #t])
)

(define (mouse w x y me)

  (writeln (string-append  "ME:" me))
  (writeln (string-append  "X:" (number->string x) " Y:" (number->string y)))

  (cond [(isGUI? w menu) (writeln (getPinhole newGameButton))])

  (cond [(and (isGUI? w menu) (isInside? x y newGameButton) (click me)) (writeln "Hello")] [else w])

)

(define (engine w)

   (define (start w)
      (+ w 1)
   )
  
   (define (pause)
      w
   )

   (start w)

   (cond [(isGUI? w menu) (pause)]
         [else (start w)]
   )
)

(define (gameplay w)
   (render w menu)
)

(big-bang 0
  (on-tick engine) ; Framelimit
  (to-draw gameplay screenWidth screenHeight)
  (on-mouse mouse)
  ;(state #f)
  ;(on-key keyboard)
  (name "PandaSushi")
)