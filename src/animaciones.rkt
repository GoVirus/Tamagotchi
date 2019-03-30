#lang racket
(define-struct tamagotchi (nombre image estadisticas)) 

(define nombre 0)

(define imagen 0)

(define (eat)  
  (set! image (animacion-eat)) ;cada vez que el usuario presione la tecla destinada para comer, mostrara esta animacion
)

(define (shower)
  (set! image (animacion-shower)) ;cada vez que el usuario presione la tecla destinada para ir al baño, mostrara esta animacion
)

(define (play)
  (set! image (animacion-play)) ;cada vez que el usuario presione la tecla destinada para jugar, mostrara esta animacion
)

(define (music)
  (set! image (animacion-music)) ;cada vez que el usuario presione la tecla destinada para escuchar musica, mostrara esta animacion
)

(define (heal)
  (set! image (animacion-heal)) ;cada vez que el usuario presione la tecla destinada para curar, mostrara esta animacion
)
  
(define (stateSick)
  (set! image (animacion-sick)) ;cada vez que el estado del tamago llegue a enfermo, mostrara esta animacion
)

(define (stateDed)
  (set! image (animacion-ded)) ; ;cada vez que el estado del tamago llegue a muerto, mostrara esta animacion
 )
    
