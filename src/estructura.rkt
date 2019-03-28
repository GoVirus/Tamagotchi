#lang racket


(require 2htdp/universe)
(require 2htdp/image)
(require racket/local)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Global Variables ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define-struct tamagotchi (nombre imagen estadisticas))  ;cree la estructura tamagotchi, que estara cambiando de acuerdo
                                                         ; a las imagenes y a las estadisticas

(define nombre 0) ;este nombre se cambia con set! cuando el usuario ingrese el nombre

(define imagen 0) ; este seria el cambio de imagenes de acuerdo al estado del tamago

(define estadisticas (vector 5 0))

(define nivelComida 0)
(define nivelBano 1)
(define nivelJuego 2)
(define nivelSalud 3)
(define nivelMusica 4)


(define-struct size (height width))

(define screen (make-size 720 720))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Helper Functions Interface ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (background w)
  (underlay/xy (rectangle 720 720 "solid" "white") 650 10 (framerate w))
)

(define (framerate w)
   (above (text (string-append "Frame " (number->string w)) 10 "black")
          (text "FPS 60" 10 "black")
   )
)

(define (render w gui)
  (underlay/xy (background w) 100 100 (gui))
)

(define (mouse-x me)
  (me)
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Timer Functions ;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (waitSeconds x)
  (* x 28)
)

(define (waitMinutes x)
  (* 28 (* x 60))
)

(define (waitHours x)
  (* 24 (* 28 (* x 60)))
)

(define (fps x)
  (/ 1 x)
)

(define (timelapse w a b)
  (cond [(and (and (>= w a) (<= w b))) #t]
        [else #f]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; GUI ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (intro)
  (above (text "Valentina" 40 "purple")
         (text "Santiago" 40 "purple")
         (text "Daniel" 40 "purple")
  )
)

(define (title)
  (above (text "Tamagotchi" 100 "purple")
         (text "Play" 40 "purple")
         ;(bitmap "img/panda.jpg")
  )
)

(define (menu)
  (above (underlay/xy (rectangle 100 80 "outline" "black") 0 0 (text "New Game" 20 "black"))
         (underlay/xy (rectangle 100 80 "outline" "black") 0 0 (text "Continue" 20 "black"))
  )
)

(define (ponNombre)                                              
  (begin
         (above(printf "Digite nombre de su mascota: ")
         (set! nombre (read))
         ;(set! imagen (bitmap "img/panda.jpg"))
         )

   )
)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Engine ;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (engine w)
  
  (define (start w)
    (+ w 1)
  )
  
  (define (stop w)
    (- w 1)
  )
  
  (define (goto w a)
    (- w (- w a))
  )
  
  (cond [(= w 700) (goto w 0)]
        [(timelapse w 600 700) (stop w)]
        [else (start w)]
  )
)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Gameplay ;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (gameplay w)
  (cond [(timelapse w 0 300) (render w intro) ]
        [(timelapse w 300 590) (render w title) ]
        [(timelapse w 590 600) (render w menu) ]
        [else (render w ponNombre) ] ;la idea es que despues de que pase el menu y el usuario de click salga
                                     ;la ventana para poner el nombre 
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;; Main ;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(big-bang 0
  (on-tick engine (fps 60))
  (to-draw gameplay (size-width screen) (size-height screen))
  (on-mouse interactions)
  ;(stop-when stop)
  (state #f)
  (name "PandaSushi")
)
      
