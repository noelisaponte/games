;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname Tetris) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
(require 2htdp/image)
(require 2htdp/universe)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; Data definitions:

;;; A Brick is a (make-brick Number Number Symbol)
;;; - x is the x-coordinate of the brick's position
;;; - y is the y-coordinate of the brick's position
;;; - color is the color of the brick
(define-struct brick [x y color])

;;; A Pt (2D point) is a (make-posn Integer Integer)
;;; - x is the x-coordinate of the point
;;; - y is the y-coordinate of the point
;;; (define-struct posn [x y])
;;; The coordinates are Cartesian plane, first quadrant
;;; coordinates, with x increasing to the right and y to the top.

;;; A Tetra is a (make-tetra Pt SOB)
;;; The center point is the point around which the tetra
;;; rotates when it spins.
;;; - sob is the set of bricks that makes up the tetra
(define-struct tetra [center sob])

;;; A SOB (Set of Bricks) is one of:
;;; - empty
;;; - (cons Brick SOB)
;;; Order does not matter.

;;; A World is a (make-world Tetra SOB Number)
;;; - The tetra is the random set of 4 bricks
;;; that spawns from above the grid.
;;; - The SOB represents the pile of bricks at the bottom of the screen.
;;; - The score is the number of blocks that have been fit into the grid.
;;; (4 is added when a tetra lands on the pile or the ground.)
(define-struct world [tetra pile score])


;;; Constants/examples:

;;; Big-bang scene:
(define PIXELS/BLOCK 20)
(define GRID-WIDTH  10)
(define GRID-HEIGHT 20)
(define GRID (empty-scene (* PIXELS/BLOCK GRID-WIDTH)
                          (* PIXELS/BLOCK GRID-HEIGHT)))
(define FALL-RATE 0.3)

;;; The 7 main tetras:
(define O-CENTER (make-posn 5 21))
(define I-CENTER (make-posn 5 20))
(define L-CENTER (make-posn 5 21))
(define J-CENTER (make-posn 3 21))
(define T-CENTER (make-posn 4 21))
(define Z-CENTER (make-posn 4 21))
(define S-CENTER (make-posn 4 21))

(define O-COLOR 'green)
(define I-COLOR 'blue)
(define L-COLOR 'purple)
(define J-COLOR 'turquoise)
(define T-COLOR 'orange)
(define Z-COLOR 'pink)
(define S-COLOR 'red)

(define O-SOB (list (make-brick 4 21 O-COLOR)
                    (make-brick 5 21 O-COLOR)
                    (make-brick 4 20 O-COLOR)
                    (make-brick 5 20 O-COLOR)))
(define I-SOB (list (make-brick 3 20 I-COLOR)
                    (make-brick 4 20 I-COLOR)
                    (make-brick 5 20 I-COLOR)
                    (make-brick 6 20 I-COLOR)))
(define L-SOB (list (make-brick 5 21 L-COLOR)
                    (make-brick 3 20 L-COLOR)
                    (make-brick 4 20 L-COLOR)
                    (make-brick 5 20 L-COLOR)))
(define J-SOB (list (make-brick 3 21 J-COLOR)
                    (make-brick 3 20 J-COLOR)
                    (make-brick 4 20 J-COLOR)
                    (make-brick 5 20 J-COLOR)))
(define T-SOB (list (make-brick 4 21 T-COLOR)
                    (make-brick 3 20 T-COLOR)
                    (make-brick 4 20 T-COLOR)
                    (make-brick 5 20 T-COLOR)))
(define Z-SOB (list (make-brick 3 21 Z-COLOR)
                    (make-brick 4 21 Z-COLOR)
                    (make-brick 4 20 Z-COLOR)
                    (make-brick 5 20 Z-COLOR)))
(define S-SOB (list (make-brick 4 21 S-COLOR)
                    (make-brick 5 21 S-COLOR)
                    (make-brick 3 20 S-COLOR)
                    (make-brick 4 20 S-COLOR)))

(define O (make-tetra O-CENTER O-SOB))
(define I (make-tetra I-CENTER I-SOB))
(define L (make-tetra L-CENTER L-SOB))
(define J (make-tetra J-CENTER J-SOB))
(define T (make-tetra T-CENTER T-SOB))
(define Z (make-tetra Z-CENTER Z-SOB))
(define S (make-tetra S-CENTER S-SOB))

;;; SOB examples:
(define O-SOB-FALL (list (make-brick 4 20 O-COLOR)
                         (make-brick 5 20 O-COLOR)
                         (make-brick 4 19 O-COLOR)
                         (make-brick 5 19 O-COLOR)))
(define I-SOB-FALL (list (make-brick 3 19 I-COLOR)
                         (make-brick 4 19 I-COLOR)
                         (make-brick 5 19 I-COLOR)
                         (make-brick 6 19 I-COLOR)))

(define EXSOB1     (list (make-brick 4 7 'red)))
(define EXSOB2     (list (make-brick 4 7 'red) (make-brick 0 17 'red)))
#|
(define EXSOB1-L   (list (brick-left (make-brick 4 7 'red))))
(define EXSOB2-L   (list (make-brick 3 7 'red) (make-brick -1 17 'red)))
(define EXSOB1-R   (list (brick-right (make-brick 4 7 'red))))
(define EXSOB2-R   (list (brick-right (make-brick 4 7 'red))
                         (brick-right (make-brick 0 17 'red))))
|#
(define EXSOB3     (list (make-brick 7 19 'red) (make-brick 7 20 'red)))
(define EXSOB4     (list (make-brick 1 4 'red)))
(define EXSOB5     (list (make-brick 4 7 'red) (make-brick 1 4 'red)))
#|
(define EXSOB4-CW  (list (brick-rotate-cw (make-brick 1 4 'red)
                                          (make-posn 5 5))))
(define EXSOB5-CW  (list (brick-rotate-cw (make-brick 4 7 'red)
                                          (make-posn 5 5))
                         (brick-rotate-cw (make-brick 1 4 'red)
                                          (make-posn 5 5))))

(define EXSOB4-CCW (list (brick-rotate-ccw (make-brick 1 4 'red)
                                           (make-posn 5 5))))
(define EXSOB5-CCW (list (brick-rotate-ccw (make-brick 4 7 'red)
                                           (make-posn 5 5))
                         (brick-rotate-ccw (make-brick 1 4 'red)
                                           (make-posn 5 5))))
|#
(define EXSOB6  (list (make-brick 2 1 'red) (make-brick 1 1 'red)))
(define EXSOB7  (list (make-brick 2 0 'red) (make-brick 1 0 'red)))
(define EXSOB8  (list (make-brick 7 19 'red) (make-brick 7 20 'red)))
(define EXSOB9  (list (make-brick 2 1 'red) (make-brick 2 2 'red)))
(define EXSOB10 (list (make-brick 0 18 'red) (make-brick 1 18 'red)))
(define EXSOB11 (list (make-brick 9 10 'red) (make-brick 9 11 'red)))
(define EXSOB11-R (list (make-brick 10 10 'red) (make-brick 10 11 'red)))
(define EXSOB12 (list (make-brick 4 2 'red) (make-brick 9 11 'red)))
(define EXSOB13 (list (make-brick 2 2 'red) (make-brick 3 2 'red)))
(define EXSOB14 (list (make-brick 1 1 'red)))
(define EXSOB15 (list (make-brick 4 3 'red)
                      (make-brick 4 4 'red)
                      (make-brick 4 5 'red)
                      (make-brick 4 6 'red)))
(define EXSOB16 (list (make-brick 4 6 'red) (make-brick -1 3 'red)))

;;; Tetra examples:
(define TETRA1 (make-tetra (make-posn 1 1)
                           (cons (make-brick 1 1 'red)
                                 (cons (make-brick 2 1 'red) '()))))
(define TETRA2 (make-tetra (make-posn 1 0)
                           (cons (make-brick 1 0 'red)
                                 (cons (make-brick 1 1 'red) '()))))
(define OLD-TETRA3 (make-tetra (make-posn 3 4)
                               (list (make-brick 3 4 'red)
                                     (make-brick 3 5 'red)
                                     (make-brick 3 6 'red)
                                     (make-brick 3 7 'red))))
;(define NEW-TETRA3 (tetra-rotate-cw OLD-TETRA3 (make-posn 3 4)))

;;; Pile (SOB) examples:
(define PILE1 (list (make-brick 2 0 'red)
                    (make-brick 3 0 'red)
                    (make-brick 4 0 'red)
                    (make-brick 5 0 'red)))
(define PILE2  (list (make-brick 0 0 'green)
                     (make-brick 0 1 'green)
                     (make-brick 9 0 'green)
                     (make-brick 9 1 'green)))
(define PILE3 (list (make-brick 30 100 'red)
                    (make-brick 0 1 'red)))
(define ONSCRN-PILE3 (list (make-brick 0 1 'red)))
(define PILE4 (list (make-brick 1 0 'red)
                    (make-brick 2 0 'red)
                    (make-brick 3 0 'red)
                    (make-brick 4 0 'red)
                    (make-brick 5 0 'red)
                    (make-brick 6 0 'red)
                    (make-brick 7 0 'red)
                    (make-brick 8 0 'red)
                    (make-brick 9 0 'red)
                    (make-brick 0 0 'red)))
(define PILE5 (list (make-brick 1 0 'red)
                    (make-brick 2 0 'red)
                    (make-brick 3 0 'red)
                    (make-brick 4 0 'red)
                    (make-brick 5 0 'red)
                    (make-brick 6 0 'red)
                    (make-brick 7 0 'red)
                    (make-brick 8 0 'red)
                    (make-brick 9 0 'red)
                    (make-brick 0 0 'red)
                    (make-brick 0 1 'red)
                    (make-brick 2 1 'red)))

;;; World examples:
;(define WORLD0 (make-world (new-tetra 1 7) '() 0))
(define WORLD1 (make-world      O PILE1 0))
(define WORLD2 (make-world      J PILE2 0))
(define WORLD3 (make-world      T PILE1 0))
(define WORLD4 (make-world TETRA1 PILE1 0))
(define WORLD5 (make-world      Z PILE3 0))
(define WORLD6 (make-world      L PILE4 0))
(define WORLD7 (make-world      L PILE5 0))


;;; place-image/block : Image Number Number Image -> Image
;;; Place the given image onto the given scene in block coordinates

(check-expect (place-image/block (circle 1 'solid 'blue) 0 0 GRID)
              (place-image (circle 1 'solid 'blue) 10 390 GRID))
(check-expect (place-image/block (square 1 'solid 'blue) 19 19 GRID)
              (place-image (square 1 'solid 'blue)
                           (* PIXELS/BLOCK (+ 1/2 19))
                           (* PIXELS/BLOCK (- GRID-HEIGHT (+ 1/2 19)))
                           GRID))
(check-expect (place-image/block (circle 1 'solid 'blue) 4 9 GRID)
              (place-image (circle 1 'solid 'blue) 90 210 GRID))

(define (place-image/block i x y s)
  (place-image i (* PIXELS/BLOCK (+ 1/2 x))
               (* PIXELS/BLOCK (- GRID-HEIGHT (+ 1/2 y)))
               s))

;;; brick->scene : Brick Image -> Image (helper for sob->scene)
;;; Draw the given brick onto the given scene

(check-expect (brick->scene (make-brick 3 4 'red) GRID)
              (place-image/block
               (frame (square (* PIXELS/BLOCK 1) 'solid 'red)) 3 4 GRID))
(check-expect (brick->scene (make-brick 1 7 'red) GRID)
              (place-image/block
               (frame (square (* PIXELS/BLOCK 1) 'solid 'red)) 1 7 GRID))

(define (brick->scene b s)
  (place-image/block
   (frame (square (* PIXELS/BLOCK 1) 'solid (brick-color b)))
   (brick-x b)
   (brick-y b) s))

;;; sob->scene : SOB Image -> Image (helper for tetra->scene)
;;; Draw the given list of bricks

(define O-SOB->GRID (brick->scene
                     (make-brick 4 21 O-COLOR)
                     (brick->scene
                      (make-brick 5 21 O-COLOR)
                      (brick->scene
                       (make-brick 4 20 O-COLOR)
                       (brick->scene
                        (make-brick 5 20 O-COLOR) GRID)))))
(define S-SOB->GRID (brick->scene
                     (make-brick 4 21 S-COLOR)
                     (brick->scene
                      (make-brick 5 21 S-COLOR)
                      (brick->scene
                       (make-brick 3 20 S-COLOR)
                       (brick->scene
                        (make-brick 4 20 S-COLOR) GRID)))))

(check-expect (sob->scene   '() GRID)        GRID)
(check-expect (sob->scene O-SOB GRID) O-SOB->GRID)
(check-expect (sob->scene S-SOB GRID) S-SOB->GRID)

(define (sob->scene sob s)
  (foldr (λ (b scn-done) (brick->scene b scn-done)) s sob))

;;; tetra->scene : Tetra Image -> Image (helper for world->scene)
;;; Draw the given tetra onto the given image

(check-expect (tetra->scene O GRID) (sob->scene O-SOB GRID))
(check-expect (tetra->scene S GRID) (sob->scene S-SOB GRID))

(define (tetra->scene t s)
  (sob->scene (tetra-sob t) s))

;;; world->scene : World -> Image (to-draw)
;;; Draw an image of the current world on the given scene

(check-expect (world->scene WORLD1)
              (sob->scene PILE1 (tetra->scene O GRID)))
(check-expect (world->scene WORLD2)
              (sob->scene PILE2 (tetra->scene J GRID)))
(check-expect (world->scene WORLD3)
              (sob->scene PILE1 (tetra->scene T GRID)))

(define (world->scene w)
  (sob->scene (world-pile w) (tetra->scene (world-tetra w) GRID)))


;;; brick-on-ground? : Brick -> Boolean (helper for brick-landed?)
;;; Is the brick on the ground?

(check-expect (brick-on-ground? (make-brick 1  0 'red)) #t)
(check-expect (brick-on-ground? (make-brick 1 10 'red)) #f)

(define (brick-on-ground? b) (= (brick-y b) 0))

;;; brick-landed? : Brick SOB -> Boolean (helper for sob-landed?)
;;; Has the brick landed on the ground or on the pile?

(check-expect (brick-landed? (make-brick 2  1 'red)   '()) #f)
(check-expect (brick-landed? (make-brick 2  1 'red) PILE1) #t)
(check-expect (brick-landed? (make-brick 1  5 'red) PILE1) #f)
(check-expect (brick-landed? (make-brick 1  0 'red) PILE2) #t)
(check-expect (brick-landed? (make-brick 1 10 'red) PILE2) #f)

(define (brick-landed? b1 sob)
  ;;; landed-on-pile? : Brick -> Boolean
  ;;; Did the brick land on the given pile brick?
  (local [(define (landed-on-pile? b2)
            (and (= (brick-x b1) (brick-x b2))
                 (= (brick-y b1) (+ 1 (brick-y b2)))))]
    (or (brick-on-ground? b1) (ormap landed-on-pile? sob))))

;;; sob-on-ground? : SOB -> Boolean (helper for sob-landed?)
;;; Is the SOB on the ground?

(check-expect (sob-on-ground?   '()) #f)
(check-expect (sob-on-ground? PILE1) #t)
(check-expect (sob-on-ground? PILE2) #t)
(check-expect (sob-on-ground? PILE3) #f)

(define (sob-on-ground? sob)
  (ormap brick-on-ground? sob))

;;; sob-landed? : SOB SOB -> Boolean (helper for tetra-landed?)
;;; Has the SOB landed on the ground or on the pile?

(check-expect (sob-landed? '() '())       #f)
(check-expect (sob-landed? EXSOB6 '())    #f)
(check-expect (sob-landed? EXSOB7 '())    #t)
(check-expect (sob-landed? EXSOB6 EXSOB7) #t)
(check-expect (sob-landed? EXSOB8 EXSOB7) #f)
(check-expect (sob-landed? EXSOB9 EXSOB7) #t)

(define (sob-landed? sob1 sob2)
  (cond [(empty? sob1) #f]
        [(empty? sob2) (sob-on-ground? sob1)]
        [else (ormap (λ (b) (brick-landed? b sob2)) sob1)]))

;;; tetra-landed? : Tetra SOB -> Boolean (helper for next-world)
;;; Has the tetra landed on the ground or on the pile?

(check-expect (tetra-landed? TETRA1    '()) #f)
(check-expect (tetra-landed? O         '()) #f)
(check-expect (tetra-landed? O      EXSOB1) #f)
(check-expect (tetra-landed? TETRA1 EXSOB7) #t)
(check-expect (tetra-landed? TETRA2 EXSOB4) #t)

(define (tetra-landed? t sob)
  (sob-landed? (tetra-sob t) sob))

;;; rand-tetra : Number -> Tetra (helper for new-tetra)
;;; A random tetra from seven possible tetras

(check-expect (rand-tetra 1) O)
(check-expect (rand-tetra 2) I)
(check-expect (rand-tetra 3) L)
(check-expect (rand-tetra 4) J)
(check-expect (rand-tetra 5) T)
(check-expect (rand-tetra 6) Z)
(check-expect (rand-tetra 7) S)

(define (rand-tetra x)
  (cond [(= x 1) O]
        [(= x 2) I]
        [(= x 3) L]
        [(= x 4) J]
        [(= x 5) T]
        [(= x 6) Z]
        [else    S]))

;;; new-tetra : Number Number -> Tetra (helper for next-world)
;;; A new tetra for the next world

(check-random (new-tetra 1 7) (rand-tetra (+ 1 (random 6))))
(check-random (new-tetra 2 5) (rand-tetra (+ 2 (random 3))))

(define (new-tetra min max) (rand-tetra (+ min (random (- max min)))))

;;; brick-fall : Brick -> Brick (helper for sob-fall)
;;; The given brick down one block

(check-expect (brick-fall (make-brick 5 19 'red)) (make-brick 5 18 'red))
(check-expect (brick-fall (make-brick 8 12 'red)) (make-brick 8 11 'red))
(check-expect (brick-fall (make-brick 0 19 'red)) (make-brick 0 18 'red))

(define (brick-fall b)
  (make-brick (brick-x b) (- (brick-y b) 1) (brick-color b)))

;;; sob-fall : SOB -> SOB (helper for tetra-fall)
;;; Each brick in the given SOB down one block

(check-expect (sob-fall '()) '())
(check-expect (sob-fall O-SOB) O-SOB-FALL)
(check-expect (sob-fall I-SOB) I-SOB-FALL)

(define (sob-fall sob)
  (map brick-fall sob))

;;; tetra-fall : Tetra -> Tetra (helper for next-world)
;;; The falling tetra down one block

(check-expect (tetra-fall O)
              (make-tetra
               (make-posn (posn-x O-CENTER)
                          (- (posn-y O-CENTER) 1))
               (sob-fall O-SOB)))
(check-expect (tetra-fall I)
              (make-tetra
               (make-posn (posn-x I-CENTER)
                          (- (posn-y I-CENTER) 1))
               (sob-fall I-SOB)))

(define (tetra-fall t)
  (make-tetra (make-posn (posn-x (tetra-center t))
                         (- (posn-y (tetra-center t)) 1))
              (sob-fall (tetra-sob t))))

;;; sob+pile : SOB SOB -> SOB (helper for new-pile)
;;; Adds the SOB to the pile

(check-expect (sob+pile    '() '()) '())
(check-expect (sob+pile EXSOB1 '()) EXSOB1)
(check-expect (sob+pile '() EXSOB2) EXSOB2)
(check-expect (sob+pile EXSOB1 EXSOB2)
              (cons (first EXSOB1) (sob+pile (rest EXSOB1) EXSOB2)))

(define (sob+pile sob1 sob2)
  (cond [(empty? sob1) sob2]
        [(empty? sob2) sob1]
        [else (append sob1 sob2)]))

;;; new-pile : Tetra SOB -> SOB (helper for next-world)
;;; Adds the tetra to the pile

(check-expect (new-pile O    '()) (sob+pile O-SOB    '()))
(check-expect (new-pile J EXSOB1) (sob+pile J-SOB EXSOB1))

(define (new-pile t sob)
  (sob+pile (tetra-sob t) sob))

;;; full-block? : Brick Number -> Boolean (helper for full-row?)
;;; Does the brick occupy a block at a y-coordinate on the grid?

(check-expect (full-block? (make-brick 1 10 'red) 10) #t)
(check-expect (full-block? (make-brick 1 10 'red) 9) #f)
(check-expect (full-block? (make-brick 4 27 'red) 27) #f)

(define (full-block? br y)
  (and (not (brick-above-grid? br))
       (= (brick-y br) y)))

;;; full-row? : SOB Number -> Boolean (helper for clear-row)
;;; Does the any part of the pile occupy an entire row of the grid?

(check-expect (full-row? PILE4 0) #t)
(check-expect (full-row? PILE1 0) #f)
(check-expect (full-row? PILE5 0) #t)

(define (full-row? sob y)
  (= (length (filter (λ (b) (full-block? b y)) sob)) 10))

;;; pile-fall : SOB Number -> SOB (helper for clear-row)
;;; All bricks above cleared pile rows shifted down one block

(check-expect (pile-fall PILE1 -1) (list (make-brick 2 -1 'red)
                                         (make-brick 3 -1 'red)
                                         (make-brick 4 -1 'red)
                                         (make-brick 5 -1 'red)))
(check-expect (pile-fall PILE1 2) PILE1)
; bricks stay put since the row number is
; greater than the y values of the bricks

(define (pile-fall pile row-num)
  (map (λ (b) (if (> row-num (brick-y b)) b (brick-fall b)))
       pile))

;;; clear-row : Pile Number -> Pile (helper for check-rows)
;;; Clear the full rows from the given pile

(check-expect (clear-row PILE1 0) PILE1)
(check-expect (clear-row PILE4 0) '())
(check-expect (clear-row PILE5 0) (list (make-brick 0 0 'red)
                                        (make-brick 2 0 'red)))

(define (clear-row pile y)
  (if (full-row? pile y)
      (pile-fall (filter (λ (b) (not (= (brick-y b) y))) pile) y)
      pile))

;;; check-rows : SOB -> SOB (helper for next-world)
;;; Return the given pile unless any rows are full and need to be cleared

(define Y-COORDS (list 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19))

(check-expect (check-rows PILE1) PILE1)
(check-expect (check-rows PILE4) '())

(define (check-rows pile)
  (foldr (λ (y checked) (clear-row checked y)) pile Y-COORDS))

;;; new-score : Tetra Number -> Number (helper for next-world)
;;; Add the number of on-screen bricks in the landed tetra to the score

(check-expect (new-score O 12) 12)
(check-expect (new-score TETRA1 30) 32)

(define (new-score t s)
  (+ (length (on-screen-pile (tetra-sob t)))
     s))

;;; next-world : World -> World (on-tick)
;;; The next world (the tetra falls down one unit)

(check-expect (next-world WORLD1)
              (make-world (tetra-fall O) PILE1 0))
(check-expect (next-world WORLD2)
              (make-world (tetra-fall J) PILE2 0))
(check-random (next-world WORLD4)
              (make-world (new-tetra 1 7)
                          (check-rows (new-pile TETRA1 PILE1)) 2))

(define (next-world w)
  (local [(define TETRA (world-tetra w))
          (define PILE (world-pile w))
          (define SCORE (world-score w))]
    (if (tetra-landed? TETRA PILE)
        (make-world (new-tetra 1 7)
                    (check-rows (new-pile TETRA PILE))
                    (new-score TETRA SCORE))
        (make-world (tetra-fall TETRA) PILE SCORE))))


;;; brick-above-grid? : Brick -> Boolean (helper for sob-above-grid?)
;;; Is the brick above the grid?

(check-expect (brick-above-grid? (make-brick 4  5 'red)) #f)
(check-expect (brick-above-grid? (make-brick 4 20 'red)) #t)
(check-expect (brick-above-grid? (make-brick 3 19 'red)) #f)
(check-expect (brick-above-grid? (make-brick 6 21 'red)) #t)

(define (brick-above-grid? b) (> (brick-y b) 19))

;;; sob-above-grid? : SOB -> Boolean (helper for extends?)
;;; Is the SOB above the grid (by at least one brick)?

(check-expect (sob-above-grid?    '()) #f)
(check-expect (sob-above-grid? EXSOB1) #f)
(check-expect (sob-above-grid? EXSOB2) #f)
(check-expect (sob-above-grid? EXSOB3) #t)

(define (sob-above-grid? sob)
  (ormap brick-above-grid? sob))

;;; brick-left : Brick -> Brick (helper for sob-left)
;;; Move the given tetra one unit left

(check-expect (brick-left (make-brick 0 18 'red)) (make-brick -1 18 'red))
(check-expect (brick-left (make-brick 9 25 'red)) (make-brick 9 25 'red))
(check-expect (brick-left (make-brick 8 18 'red)) (make-brick 7 18 'red))
(check-expect (brick-left (make-brick 5 10 'red)) (make-brick 4 10 'red))
(check-expect (brick-left (make-brick 3  7 'red)) (make-brick 2  7 'red))

(define (brick-left b)
  (if (brick-above-grid? b) b
      (make-brick (- (brick-x b) 1) (brick-y b) (brick-color b))))

;;; brick-right : Brick -> Brick (helper for sob-right)
;;; Move the given tetra one unit right

(check-expect (brick-right (make-brick 9  1 'red)) (make-brick 10 1 'red))
(check-expect (brick-right (make-brick 9 25 'red)) (make-brick 9 25 'red))
(check-expect (brick-right (make-brick 8 18 'red)) (make-brick 9 18 'red))
(check-expect (brick-right (make-brick 5 10 'red)) (make-brick 6 10 'red))
(check-expect (brick-right (make-brick 3  7 'red)) (make-brick 4  7 'red))

(define (brick-right b)
  (if (brick-above-grid? b) b
      (make-brick (+ (brick-x b) 1) (brick-y b) (brick-color b))))

;;; sob-left : SOB -> SOB (helper for tetra-left)
;;; Move the given tetra one unit left

(define EXSOB1-L   (list (brick-left (make-brick 4 7 'red))))
(define EXSOB2-L   (list (make-brick 3 7 'red) (make-brick -1 17 'red)))

(check-expect (sob-left    '())      '())
(check-expect (sob-left EXSOB1) EXSOB1-L)
(check-expect (sob-left EXSOB2) EXSOB2-L)
(check-expect (sob-left O-SOB) O-SOB)

(define (sob-left sob)
  (if (sob-above-grid? sob) sob
      (map brick-left sob)))

;;; sob-right : SOB -> SOB (helper for tetra-right)
;;; Move the given tetra one unit right

(define EXSOB1-R   (list (brick-right (make-brick 4 7 'red))))
(define EXSOB2-R   (list (brick-right (make-brick 4 7 'red))
                         (brick-right (make-brick 0 17 'red))))

(check-expect (sob-right    '())      '())
(check-expect (sob-right EXSOB1) EXSOB1-R)
(check-expect (sob-right EXSOB2) EXSOB2-R)
(check-expect (sob-right EXSOB11) EXSOB11-R)
(check-expect (sob-right O-SOB) O-SOB)

(define (sob-right sob)
  (if (sob-above-grid? sob) sob
      (map brick-right sob)))

;;; tetra-left : Tetra -> Tetra (helper for move)
;;; Move the given tetra one unit left

(check-expect (tetra-left O)
              (make-tetra
               (make-posn (- (posn-x O-CENTER) 1)
                          (posn-y O-CENTER))
               (sob-left O-SOB)))
(check-expect (tetra-left J)
              (make-tetra
               (make-posn (- (posn-x J-CENTER) 1)
                          (posn-y J-CENTER))
               (sob-left J-SOB)))

(define (tetra-left t)
  (make-tetra
   (make-posn (- (posn-x (tetra-center t)) 1)
              (posn-y (tetra-center t)))
   (sob-left (tetra-sob t))))

;;; tetra-right : Tetra -> Tetra (helper for move)
;;; Move the given tetra one unit right

(check-expect (tetra-right O)
              (make-tetra
               (make-posn (+ 1 (posn-x O-CENTER))
                          (posn-y O-CENTER))
               (sob-right O-SOB)))
(check-expect (tetra-right J)
              (make-tetra
               (make-posn (+ 1 (posn-x J-CENTER))
                          (posn-y J-CENTER))
               (sob-right J-SOB)))

(define (tetra-right t)
  (make-tetra
   (make-posn (+ 1 (posn-x (tetra-center t)))
              (posn-y (tetra-center t)))
   (sob-right (tetra-sob t))))

;;; brick-rotate-cw : Brick Pt -> Brick (helper for sob-rotate-cw)
;;; Rotate the brick 90 degrees clockwise around the posn.

(check-expect (brick-rotate-cw (make-brick 4 5 'red) (make-posn 5 5))
              (make-brick 5 6 'red))
(check-expect (brick-rotate-cw (make-brick 2 3 'red) (make-posn 5 5))
              (make-brick 3 8 'red))
(check-expect (brick-rotate-cw (make-brick 1 4 'red) (make-posn 5 5))
              (make-brick 4 9 'red))
(check-expect (brick-rotate-cw (make-brick 1 25 'red) (make-posn 5 5))
              (make-brick 1 25 'red))

(define (brick-rotate-cw br c)
  (if (brick-above-grid? br) br
      (brick-rotate-ccw (brick-rotate-ccw (brick-rotate-ccw br c) c) c)))

;;; brick-rotate-ccw : Brick Pt -> Brick (helper for sob-rotate-ccw)
;;; Rotate the brick 90 degrees counterclockwise around the posn.

(check-expect (brick-rotate-ccw (make-brick 4 5 'red) (make-posn 5 5))
              (make-brick 5 4 'red))
(check-expect (brick-rotate-ccw (make-brick 2 3 'red) (make-posn 5 5))
              (make-brick 7 2 'red))
(check-expect (brick-rotate-ccw (make-brick 1 4 'red) (make-posn 5 5))
              (make-brick 6 1 'red))
(check-expect (brick-rotate-ccw (make-brick 1 25 'red) (make-posn 5 5))
              (make-brick 1 25 'red))

(define (brick-rotate-ccw br c)
  (if (brick-above-grid? br) br
      (make-brick (+ (posn-x c) (- (posn-y c) (brick-y br)))
                  (+ (posn-y c) (- (brick-x br) (posn-x c)))
                  (brick-color br))))

;;; sob-rotate-cw : SOB Pt -> SOB (helper for tetra-rotate-cw)
;;; Rotate the SOB 90 degrees clockwise around the posn.

(define EXSOB4-CW  (list (brick-rotate-cw (make-brick 1 4 'red)
                                          (make-posn 5 5))))
(define EXSOB5-CW  (list (brick-rotate-cw (make-brick 4 7 'red)
                                          (make-posn 5 5))
                         (brick-rotate-cw (make-brick 1 4 'red)
                                          (make-posn 5 5))))


(check-expect (sob-rotate-cw    '() (make-posn 5 5))       '())
(check-expect (sob-rotate-cw EXSOB4 (make-posn 5 5)) EXSOB4-CW)
(check-expect (sob-rotate-cw EXSOB5 (make-posn 5 5)) EXSOB5-CW)
(check-expect (sob-rotate-cw O-SOB (make-posn 5 5)) O-SOB)

(define (sob-rotate-cw sob pt)
  (if (sob-above-grid? sob) sob
      (map (λ (b) (brick-rotate-cw b pt)) sob)))

;;; sob-rotate-ccw : SOB Pt -> SOB (helper for tetra-rotate-ccw)
;;; Rotate the SOB 90 degrees counterclockwise around the posn.

(define EXSOB4-CCW (list (brick-rotate-ccw (make-brick 1 4 'red)
                                           (make-posn 5 5))))
(define EXSOB5-CCW (list (brick-rotate-ccw (make-brick 4 7 'red)
                                           (make-posn 5 5))
                         (brick-rotate-ccw (make-brick 1 4 'red)
                                           (make-posn 5 5))))

(check-expect (sob-rotate-ccw    '() (make-posn 5 5))        '())
(check-expect (sob-rotate-ccw EXSOB4 (make-posn 5 5)) EXSOB4-CCW)
(check-expect (sob-rotate-ccw EXSOB5 (make-posn 5 5)) EXSOB5-CCW)
(check-expect (sob-rotate-ccw O-SOB (make-posn 5 5)) O-SOB)

(define (sob-rotate-ccw sob pt)
  (if (sob-above-grid? sob) sob
      (map (λ (b) (brick-rotate-ccw b pt)) sob)))

;;; tetra-rotate-cw : Tetra Pt -> Tetra (helper for move)
;;; Rotate the given tetra clockwise 90 degrees around its center

(check-expect (tetra-rotate-cw O O-CENTER) O)
(check-expect (tetra-rotate-cw T T-CENTER) T)
(check-expect (tetra-rotate-cw TETRA1 (make-posn 1 1))
              (make-tetra (make-posn 1 1)
                          (sob-rotate-cw (tetra-sob TETRA1)
                                         (make-posn 1 1))))

(define (tetra-rotate-cw t pt)
  (make-tetra (tetra-center t)
              (sob-rotate-cw (tetra-sob t) (tetra-center t))))

;;; tetra-rotate-ccw : Tetra -> Tetra (helper for move)
;;; Rotate the given tetra counterclockwise 90 degrees around its center

(check-expect (tetra-rotate-ccw O O-CENTER) O)
(check-expect (tetra-rotate-ccw T T-CENTER) T)
(check-expect (tetra-rotate-ccw TETRA1 (make-posn 1 1))
              (make-tetra (make-posn 1 1)
                          (sob-rotate-ccw (tetra-sob TETRA1)
                                          (make-posn 1 1))))

(define (tetra-rotate-ccw t pt)
  (make-tetra (tetra-center t)
              (sob-rotate-ccw (tetra-sob t) (tetra-center t))))

;;; brick-leaves? : Brick -> Boolean (helper for sob-leaves?)
;;; Does the brick leave the screen?

(check-expect (brick-leaves? (make-brick -1  3 'red)) #t)
(check-expect (brick-leaves? (make-brick  1 20 'red)) #t)
(check-expect (brick-leaves? (make-brick  3  4 'red)) #f)
(check-expect (brick-leaves? (make-brick 10  3 'red)) #t)

(define (brick-leaves? b)
  (or (or (< (brick-x b) 0) (> (brick-x b) 9))
      (or (< (brick-y b) 0) (> (brick-y b) 19))))

;;; sob-leaves? : SOB -> Boolean (helper for tetra-leaves?)
;;; Does the SOB leave the screen?

(check-expect (sob-leaves?     '()) #f)
(check-expect (sob-leaves? EXSOB16) #t)
(check-expect (sob-leaves? EXSOB13) #f)

(define (sob-leaves? sob)
  (ormap brick-leaves? sob))

;;; tetra-leaves? : Tetra -> Boolean (helper for maybe-move-tetra)
;;; Does the tetra leave the screen?

(check-expect (tetra-leaves?      O) #t)
(check-expect (tetra-leaves? TETRA1) #f)

(define (tetra-leaves? t) (sob-leaves? (tetra-sob t)))

;;; brick-overlaps? : Brick SOB -> Boolean (helper for sob-overlaps?)
;;; Does the brick overlap the pile?

(check-expect (brick-overlaps? (make-brick 1 2 'red)     '()) #f)
(check-expect (brick-overlaps? (make-brick 1 2 'red) EXSOB13) #f)
(check-expect (brick-overlaps? (make-brick 2 2 'red) EXSOB13) #t)

(define (brick-overlaps? b sob)
  ;;; same-posn? : Brick -> Boolean
  ;;; Is the pile brick at the same position as the second brick?
  (local [(define (same-posn? sob-b)
            (and (= (brick-x sob-b) (brick-x b))
                 (= (brick-y sob-b) (brick-y b))))]
    (ormap same-posn? sob)))

;;; sob-overlaps? : SOB SOB -> Boolean (helper for tetra-overlaps?)
;;; Does any brick in the SOB overlap the pile?

(check-expect (sob-overlaps?                '()     '()) #f)
(check-expect (sob-overlaps?                '()  EXSOB1) #f)
(check-expect (sob-overlaps?            EXSOB13     '()) #f)
(check-expect (sob-overlaps? (tetra-sob TETRA1) EXSOB13) #f)
(check-expect (sob-overlaps? (tetra-sob TETRA1) EXSOB14) #t)

(define (sob-overlaps? sob1 sob2)
  (ormap (λ (b) (brick-overlaps? b sob2)) sob1))

;;; tetra-overlaps? : Tetra SOB -> Boolean (helper for maybe-move-tetra)
;;; Does any brick of the tetra overlap the pile?

(check-expect (tetra-overlaps? TETRA1     '()) #f)
(check-expect (tetra-overlaps?      O   PILE1) #f)
(check-expect (tetra-overlaps? TETRA1 EXSOB12) #f)
(check-expect (tetra-overlaps? TETRA1 EXSOB14) #t)

(define (tetra-overlaps? t sob) (sob-overlaps? (tetra-sob t) sob))

;;; maybe-move-tetra : Tetra Tetra SOB -> Tetra (helper for move)
;;; Move the tetra unless doing so leads to overlap

(define NEW-TETRA3 (tetra-rotate-cw OLD-TETRA3 (make-posn 3 4)))

(check-expect (maybe-move-tetra OLD-TETRA3 NEW-TETRA3 EXSOB15)
              OLD-TETRA3)
(check-expect (maybe-move-tetra TETRA1
                                (tetra-rotate-ccw TETRA1 (make-posn 1 1))
                                PILE1)
              (tetra-rotate-ccw TETRA1 (make-posn 1 1)))

(define (maybe-move-tetra old new sob)
  (if (or (tetra-leaves? new) (tetra-overlaps? new sob)) old new))

;;; move : World KeyEvent -> World (on-key)
;;; Move the given world's tetra "left," "right," 90 degrees cw or ccw

(check-expect (move WORLD1 "right") WORLD1)
(check-expect (move WORLD2 "left")  WORLD2)
(check-expect (move WORLD2 "up")                                WORLD2)
(check-expect (move WORLD1 "s") (make-world (tetra-rotate-cw O O-CENTER)
                                            PILE1 0))
(check-expect (move WORLD3 "a") (make-world (tetra-rotate-ccw T T-CENTER)
                                            PILE1 0))

(define (move w k)
  (local [(define (maybe-move event)
            (maybe-move-tetra (world-tetra w) event (world-pile w)))
          (define TETRA (world-tetra w))]
    (make-world (cond [(key=? k "left")
                       (maybe-move (tetra-left TETRA))]
                      [(key=? k "right")
                       (maybe-move (tetra-right TETRA))]
                      [(key=? k "s")
                       (maybe-move (tetra-rotate-cw
                                    TETRA
                                    (tetra-center TETRA)))]
                      [(key=? k "a")
                       (maybe-move (tetra-rotate-ccw
                                    TETRA
                                    (tetra-center TETRA)))]
                      [else TETRA])
                (world-pile w)
                (world-score w))))


;;; extends? : World -> Boolean (stop-when)
;;; Does the world pile extend above the grid?

(check-expect (extends? WORLD0) #f)
(check-expect (extends? WORLD5) #t)
(check-expect (extends? WORLD1) #f)

(define (extends? w)
  (sob-above-grid? (world-pile w)))

;;; brick-on-screen? : Brick -> Boolean (helper for on-screen-pile)
;;; Is the brick on the screen?

(check-expect (brick-on-screen? (make-brick -1  2 'red)) #f)
(check-expect (brick-on-screen? (make-brick  4 22 'red)) #f)
(check-expect (brick-on-screen? (make-brick  4  6 'red)) #t)

(define (brick-on-screen? b)
  (not (brick-leaves? b)))

;;; on-screen-pile : SOB -> SOB (helper for new-score)
;;; Removes bricks from the pile not on the screen

(check-expect (on-screen-pile   '())          '())
(check-expect (on-screen-pile PILE1)        PILE1)
(check-expect (on-screen-pile PILE3) ONSCRN-PILE3)

(define (on-screen-pile sob)
  (filter brick-on-screen? sob))

;;; final-score : Number -> Image (helper for score->scene)
;;; The final score in text form

(check-expect (final-score 20)
              (text (string-append "FINAL SCORE:\n " "20") 20 'black))
(check-expect (final-score 40)
              (text (string-append "FINAL SCORE:\n " "40") 20 'black))

(define (final-score s)
  (text (string-append "FINAL SCORE:\n " (number->string s)) 20 'black))

;;; score->scene : World -> Image (stop-when end-screen)
;;; Add the final score to the world scene

(check-expect (score->scene WORLD0)
              (place-image (final-score 0)
                           100 50 (world->scene WORLD0)))
(check-expect (score->scene WORLD1)
              (place-image (final-score 0)
                           100 50 (world->scene WORLD1)))

(define (score->scene w)
  (place-image (final-score (world-score w))
               100 50 (world->scene w)))

(define WORLD0 (make-world (new-tetra 1 7) '() 0))

(big-bang WORLD0
  [to-draw world->scene]
  [on-tick next-world FALL-RATE]
  [on-key  move]
  [stop-when extends? score->scene])