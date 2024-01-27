;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-beginner-reader.ss" "lang")((modname Snake) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;;; Snake game -- 2/3 done

(require 2htdp/image)
(require 2htdp/universe)

;;; Constants

(define BOARD-HEIGHT 30) ; in cell units
(define BOARD-WIDTH  30) ; in cell units
(define PIXELS/CELL  20)

(define SNAKE-COLOR   'red)
(define FOOD-COLOR    'green)
(define SEGMENT-IMAGE (circle (/ PIXELS/CELL 2) 'solid SNAKE-COLOR))
(define FOOD-IMAGE    (circle (/ PIXELS/CELL 2) 'solid FOOD-COLOR))
(define BOARD   (empty-scene (* BOARD-WIDTH  PIXELS/CELL)
                             (* BOARD-HEIGHT PIXELS/CELL)))
(define TICK-RATE 0.2) ; seconds

;;; Decision: Let's *not* work with annoying pixel-based, upside-down
;;; "computer graphic" coordinate system.
;;; 
;;; Board coord system is *cell* units, with (0,0) at lower/left corner,
;;; where one grid cell is a square big enough for one snake segment or 
;;; food item.

;;; Data definitions
;;;
;;; Seg = (make-posn Integer Integer)
;;; 
;;; An LOS is one of:
;;; - '()
;;; - (cons Seg LOS)
;;;
;;; Dir = 'up | 'down | 'left | 'right
;;;
;;; Snake = (make-snake LOS Dir)
;;; The head of the snake is the first segment of the segment list.
;;;
;;; Food = (make-posn Natural Natural)
;;;
;;; World = (make-world Snake Food)

(define-struct snake [segs dir])
(define-struct world [snake food])

#;
(define (los-template segs)
  (cond [(empty? segs) ...]
        [else ... (seg-template (first segs)) ... (los-template (rest segs)) ...]))
#;
(define (dir-template d)
  (cond [(symbol=? d 'right) ...]
        [(symbol=? d 'left) ...]
        [(symbol=? d 'up) ...]
        [else ...])) ; down case

#;
(define (snake-template s)
  ... (los-template (snake-segs s)) ...  (dir-template (snake-dir s)) ...)

#;
(define (posn-template p)
  ... (posn-x p) ... (posn-y p) ...)

#;
(define (world-template w)
  ... (snake-template (world-snake w))
  ... (posn-template (world-food w)) ...)

;;; TEST / EXAMPLE DATA

(define food0 (make-posn 25 25))
(define food1 (make-posn 2 5))
(define segs0 (list (make-posn 5 5)))
(define segs1 (list (make-posn 2 6)))   ; one-segment snake
(define segs2 (list (make-posn 2 5) (make-posn 3 5))) ; two-segment snake
(define segs3 (list (make-posn -1 0)))
(define segs4 (list (make-posn 0 31)))
(define segs5 (list (make-posn -1 -1)))
(define segs6 (list (make-posn 1 1) (make-posn 2 1)
                    (make-posn 2 2) (make-posn 1 2)
                    (make-posn 1 1)))
(define snake0 (make-snake segs0 'up))
(define snake1 (make-snake segs1 'up))
(define snake2 (make-snake segs2 'up))
(define snake3 (make-snake segs3 'down))
(define snake4 (make-snake segs4 'left))
(define snake5 (make-snake segs5 'right))
(define snake6 (make-snake segs6 'up))
(define world0 (make-world snake0 food0))
(define world1 (make-world snake1 food1))
(define world2 (make-world snake2 food1))   ; snake is eating
  

;;; Wish list design
;;; - What do we know we *have* to write? (Because, say, we know we're
;;;   going to be using the BIG-BANG system?)
;;; - What would be handy to have? (Helper functions that will make it
;;;   easier to write the have-to-have code?)
;;;
;;; Our wish list may grow as we write other functions and discover new
;;; needs. No problem! Just make up a function -- "wishful thinking" --
;;; add it to the to-do list, then use it.
;;;
;;; Once we have our wish list... we know the way forward: just write each
;;; function, one at a time, until the wish list is done. We know how to
;;; write functions -- just use the Design Recipe!

;;; Wish list
;;;
;;; Big-bang requirements
;;; - next-world   : World -> World
;;; - world->scene : World -> Image
;;; - key-handler   : World KE -> World
;;;
;;; Rendering functions
;;; - place-image/cell : Image Number Number Image -> Image
;;;   PLACE-IMAGE but with cell coordinates, not pixel coordinates
;;; - segs+scene : LOS Image -> Image
;;;   Add all the segments in the list to the scene.
;;; - seg+scene : Seg Image -> Image
;;;   Add the segment to the scene.
;;; - food+scene : Food Image -> Image
;;;   Add the food to the scene.
;;;
;;; Snake mechanics
;;; - grow-snake : Snake -> Snake
;;;   Grow the snake one segment.
;;; - slither-snake : Snake -> Snake
;;;   Slither the snake one cell in its current direction.
;;;
;;; Other
;;; - new-random-food : World -> World
;;;
;;; Collision detection
;;; - eating?       : World -> Boolean
;;; - wall-collide? : Snake -> Boolean
;;; - self-collide? : Snake -> Boolean
;;; - snake-death?  : World -> Boolean
;;;
;;; Constant: initial world

;;; place-image/cell : Image Number Number Image -> Image
;;; PLACE-IMAGE but with cell coordinates, not pixel coordinates
(define (place-image/cell i1 x y i2)
  (place-image i1
               (* PIXELS/CELL (+ 1/2 x))
               (* PIXELS/CELL (- BOARD-HEIGHT (+ 1/2 y)))
               i2))

(check-expect (place-image/cell FOOD-IMAGE 15 20 BOARD)
              (place-image FOOD-IMAGE
                           (* (+ 1/2 15) PIXELS/CELL)
                           (* PIXELS/CELL (- BOARD-HEIGHT (+ 1/2 20)))
                           BOARD))

;;; seg+scene : Seg Image -> Image
;;; Add the segment to the scene.
(define (seg+scene seg scene)
  (place-image/cell SEGMENT-IMAGE (posn-x seg) (posn-y seg) scene))

(check-expect (seg+scene (make-posn 3 7) BOARD)
              (place-image/cell SEGMENT-IMAGE 3 7 BOARD))

;;; segs+scene : LOS Image -> Image
;;; Add all the segments in the list to the scene.
(define (segs+scene segs scene)
  (cond [(empty? segs) scene]
        [else (seg+scene (first segs)
                         (segs+scene (rest segs) scene))]))

(check-expect (segs+scene (list (make-posn 2 5) (make-posn 3 5)) BOARD)
              (seg+scene (make-posn 2 5)
                         (seg+scene (make-posn 3 5)
                                    BOARD)))

;;; Food Image -> Image
;;; Render an image of the food onto the given image.
(define (food+scene f scene)
  (place-image/cell FOOD-IMAGE (posn-x f) (posn-y f) scene))


;;; world->scene : World -> Image
;;; Render the given world into an image
(define (world->scene w)
  (food+scene (world-food w)
              (segs+scene (snake-segs (world-snake w))
                          BOARD)))

;;; TODO: We need tests for the two functions above.

;;; Snake motion
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;; move-seg : Seg Dir -> Seg
;;; Move the segment one cell unit in the given direction.
(define (move-seg s d)
  (cond [(symbol=? d 'right) (make-posn (+ (posn-x s) 1) (posn-y s))]
        [(symbol=? d 'left)  (make-posn (- (posn-x s) 1) (posn-y s))]
        [(symbol=? d 'up)    (make-posn (posn-x s)       (+ (posn-y s) 1))]
        [else                (make-posn (posn-x s)       (- (posn-y s) 1))])) ; down case

(check-expect (move-seg (make-posn 7 22) 'right) (make-posn 8 22))
(check-expect (move-seg (make-posn 7 22) 'left)  (make-posn 6 22))
(check-expect (move-seg (make-posn 7 22) 'up)    (make-posn 7 23))
(check-expect (move-seg (make-posn 7 22) 'down)  (make-posn 7 21))

;;; A NELOS (non-empty list of segments) is one of:
;;; - (cons Seg '())
;;; - (cons Seg NELOS)
;;; Note: Every NELOS is a LOS.
#;
(define (nelos-template nelos)
  (cond [(empty? (rest nelos)) ... (seg-template (first nelos)) ...]
        [else ... (seg-template (first nelos))
              ... (nelos-template (rest nelos)) ...]))
  
;;; drop-last : NELOS -> LOS
;;; Drop the last segment of the list.
(define (drop-last nelos)
  (cond [(empty? (rest nelos)) '()]
        [else (cons (first nelos)
                    (drop-last (rest nelos)))]))

(check-expect (drop-last (list (make-posn 3 1) (make-posn 4 1) (make-posn 4 2)))
              (list (make-posn 3 1) (make-posn 4 1)))
(check-expect (drop-last (list (make-posn 3 1))) '()) ; Base case! (NOT '())

;;; slither-snake : Snake -> Snake
;;; Slither the snake one cell in its current direction.
;;; How: (1) Drop the last segment and (2) add a new head.
(define (slither-snake s)
  (make-snake (cons (move-seg (first (snake-segs s)) (snake-dir s))
                    (drop-last (snake-segs s)))
              (snake-dir s)))

(check-expect (slither-snake (make-snake (list (make-posn 3 1)
                                               (make-posn 4 1)
                                               (make-posn 4 2))
                                         'left))
              (make-snake (list (make-posn 2 1) (make-posn 3 1) (make-posn 4 1))
                          'left))

;;; grow-snake : Snake -> Snake
;;; Grow the snake one segment
;;; How: slither the snake, but don't drop the last segment.
(define (grow-snake s)
  (make-snake (cons (move-seg (first (snake-segs s)) (snake-dir s))
                    (snake-segs s))
              (snake-dir s)))

;;; Still to do:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; - Extend key handler to restart the game if we type "n"
;;;   Reset to a defined-constant initial world?
;;; - Wall collision
;;;   The snake collides with a wall if its head is ever off the board.
;;; - Self collision
;;;   The snake collides with itself if its head ever matches one of
;;;   the *other* segments of its body.
;;; - Eating detection
;;; - A (POSN= p1 p2) equality function could be handy...
;;; - Extend NEXT-WORLD so that
;;;   - Reset to initial world if snake is in a fatal state
;;;   - Snake grows & food is moved if eating
;;; - Plus... anything else that strikes your fancy.
;;;   Because it's your code & you now know how to program: you da boss.


;;; Wall collision => hit-wall? : Snake -> Boolean
;;; Did the snake's head go past the wall?

(check-expect (hit-wall? snake0) #f)
(check-expect (hit-wall? snake1) #f)
(check-expect (hit-wall? snake3) #t)
(check-expect (hit-wall? snake4) #t)
(check-expect (hit-wall? snake5) #t)

(define (hit-wall? s)
  (or (or (< (posn-x (first (snake-segs s))) 0)
          (> (posn-x (first (snake-segs s))) BOARD-WIDTH))
      (or (< (posn-y (first (snake-segs s))) 0)
          (> (posn-y (first (snake-segs s))) BOARD-HEIGHT))))


;;; posn=? : Posn Posn -> Boolean
;;; Are the two posns the same?

(check-expect (posn=? (make-posn 0 0) (make-posn 0 0)) #t)
(check-expect (posn=? (make-posn 1 0) (make-posn 0 0)) #f)
(check-expect (posn=? (make-posn 0 1) (make-posn 0 0)) #f)
(check-expect (posn=? (make-posn 1 1) (make-posn 0 0)) #f)

(define (posn=? posn1 posn2)
  (and (= (posn-x posn1) (posn-x posn2))
       (= (posn-y posn1) (posn-y posn2))))


;;; segs=? : Seg LOS -> Boolean
;;; Is the segment at the same position as any other on the list?

(check-expect (segs=? (first segs6)          '()) #f)
(check-expect (segs=? (first segs6) (rest segs6)) #t)
(check-expect (segs=? (first segs0) (rest segs0)) #f)
(check-expect (segs=? (first segs2) (rest segs2)) #f)

(define (segs=? seg los)
  (and (not (empty? los))
       (or (posn=? seg (first los))
           (segs=? seg (rest los)))))


;;; Self collision => hit-self? : Snake -> Boolean
;;; Did the snake run into itself?

(check-expect (hit-self? snake0) #f)
(check-expect (hit-self? snake2) #f)
(check-expect (hit-self? snake6) #t)

(define (hit-self? s)
  (segs=? (first (snake-segs s)) (rest (snake-segs s))))


;;; Eating detection => eating? : World -> Boolean
;;; Is the snake eating?

(check-expect (eating? world1) #f)
(check-expect (eating? world2) #t)

(define (eating? w)
  (posn=? (world-food w) (first (snake-segs (world-snake w)))))

;;; TODO: We didn't use grow-snake in class, so we never wrote tests...

;;; new-food : Food Snake -> Food
;;; Make new food if
(define (new-food f s)
  (if (segs=? f (snake-segs s)) (make-posn (random 30) (random 30)) f))

;;; World -> World
;;; Move the snake one cell in the current direction
;;; This version: Just slither. No collision & death; no eating & growth. 
(define (next-world w)
  (cond [(or (hit-self? (world-snake w)) (hit-wall? (world-snake w)))
         world0]
        [(eating? w)
         (make-world (grow-snake (world-snake w))
                     (new-food (make-posn (random 30) (random 30))
                               (world-snake w)))]
        [else (make-world (slither-snake (world-snake w))
                          (world-food w))]))

;;; TODO:
;;; - We need tests for NEXT-WORLD above for various situations
;;; - We need tests for the key handler below for various situations.

;;; World KeyEvent Symbol -> World
;;; Go in the key's direction unless it's opposite the snake's direction
(define (direct w ke dir)
  (cond [(or (and (key=?    "up" ke) (symbol=?  'down dir))
             (and (key=?  "down" ke) (symbol=?    'up dir))
             (and (key=?  "left" ke) (symbol=? 'right dir))
             (and (key=? "right" ke) (symbol=?  'left dir))) w]
        [else (make-world (make-snake (snake-segs (world-snake w))
                                      (string->symbol ke))
                          (world-food w))]))

;;; World KE -> World
(define (key-handler w ke)
  (cond [(or (key=? "up" ke)
             (key=? "down" ke)
             (key=? "left" ke)
             (key=? "right" ke))
         (direct w ke (snake-dir (world-snake w)))]
        [(key=? "n" ke) world0]
        [else w]))

;;; Quick & dirty big-bang kickoff to try things out.
(big-bang world0
  [on-tick next-world TICK-RATE]
  [to-draw world->scene]
  [on-key key-handler])


