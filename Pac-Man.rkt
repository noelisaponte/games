;; The first three lines of this file were inserted by DrRacket. They record metadata
;; about the language level of this file in a form that our tools can easily process.
#reader(lib "htdp-intermediate-lambda-reader.ss" "lang")((modname Pac-Man) (read-case-sensitive #t) (teachpacks ()) (htdp-settings #(#t constructor repeating-decimal #f #t none #f () #f)))
;;; PAC-MAN REMAKE
;;; Start: 6/1/23
;;; Finish: 9/1/23

(require 2htdp/image)
(require 2htdp/universe)

;;; A Dir (direction) is one of:
;;; - 'up
;;; - 'down
;;; - 'left
;;; - 'right

;;; An ES (eating state) is one of:
;;; - 'normal
;;; - 'ghost

;;; PM (Pac-Man) = (make-pm Posn Dir ES Number)
(define-struct pm [posn dir es gc])
;;; - posn is Pac-Man's position in the maze.
;;; - dir is the direction in which Pac-Man travels.
;;; - es is the eating state Pac-Man is in based on food eaten.
;;; - gc is the ghost counter (how many ticks Pac-Man has been in a 'ghost ES.
;;; Interpretation: Pac-Man's direction is controlled by the player with
;;; arrow keys and he will automatically consume any food in his path.
;;; If Pac-Man eats "'super" food, his eating state changes temporarily.

;;; An FType (food type) is one of:
;;; - 'normal
;;; - 'fruit
;;; - 'super
;;; Interpretation: "'normal" food is required for consumption in order to
;;; pass the level. "'fruit" increases the player's score. "'super" food
;;; allows Pac-Man to eat ghosts.

;;; Food = (make-food Posn FType)
(define-struct food [posn ftype])
;;; - posn is the position of the food in the maze.
;;; - ftype is the FType.
;;; Interpretation: Food is placed at every block in the maze, and eating a
;;; piece of normal food is 10 points while super food is 50 points. Fruit
;;; is 100 points.

;;; Ghost = (make-ghost Posn Dir Symbol Number Number)
(define-struct ghost [posn dir color time releases])
;;; - posn is the position of the ghost in the maze.
;;; - dir is the direction in which the ghost travels.
;;; - color is the ghost's color (such as pink, red, blue, etc)
;;; - moves is the number of moves the ghost has made since starting.
;;; - time is the amount of time the ghost has gone without being eaten.
;;; - release is the number of times the ghost has left the cage.
;;; Interpretation: Ghosts are released into the maze from a starting cage
;;; one at a time and change color to blue when Pac-Man eats "'super" food.
;;; They are sent back to their starting cage, and the player's score
;;; doubles from 200 points per ghost eaten.

;;; World = (make-world PM [ListOf Food] [ListOf Ghost] Number Number Number)
(define-struct world [pm lof log score lives ticks])
;;; - pm is Pac-Man
;;; - lof is the list of all the food on the maze in the current game.
;;; - log is the group of ghosts in the current game.
;;; - score is the player's score in the current game.
;;; - lives is the number of lives the player has left.
;;; - ticks is the number of ticks that have passed since the game's start.

;;; CONSTANTS
(define TICK-RATE 0.2)
(define PIXELS/BLOCK 18)
(define MAZE-WIDTH 28)
(define MAZE-HEIGHT 34)
(define MAZE-BASE (rectangle (* MAZE-WIDTH PIXELS/BLOCK)
                             (* MAZE-HEIGHT PIXELS/BLOCK)
                             "solid"
                             "black"))
(define NON-FOOD-MAZE-POSNS (list (make-posn 0 17) (make-posn 1 17)
                                  (make-posn 2 17) (make-posn 3 17)
                                  (make-posn 4 17) (make-posn 5 17)
                                  (make-posn 7 17) (make-posn 8 17)
                                  (make-posn 9 20) (make-posn 9 19)
                                  (make-posn 9 18) (make-posn 9 17)
                                  (make-posn 9 16) (make-posn 9 15)
                                  (make-posn 9 14)
                                  (make-posn 9 13)
                                  (make-posn 9 12)
                                  (make-posn 10 20)
                                  (make-posn 10 14)
                                  (make-posn 11 20)
                                  (make-posn 11 14)
                                  (make-posn 12 22)
                                  (make-posn 12 21)
                                  (make-posn 12 20)
                                  (make-posn 12 14)
                                  (make-posn 13 20)
                                  (make-posn 13 14)
                                  (make-posn 27 17)
                                  (make-posn 26 17)
                                  (make-posn 25 17)
                                  (make-posn 24 17)
                                  (make-posn 23 17)
                                  (make-posn 22 17)
                                  (make-posn 20 17)
                                  (make-posn 19 17)
                                  (make-posn 18 20)
                                  (make-posn 18 19)
                                  (make-posn 18 18)
                                  (make-posn 18 17)
                                  (make-posn 18 16)
                                  (make-posn 18 15)
                                  (make-posn 18 14)
                                  (make-posn 18 13)
                                  (make-posn 18 12)
                                  (make-posn 17 20)
                                  (make-posn 17 14)
                                  (make-posn 16 20)
                                  (make-posn 16 14)
                                  (make-posn 15 22)
                                  (make-posn 15 21)
                                  (make-posn 15 20)
                                  (make-posn 15 14)
                                  (make-posn 14 20)
                                  (make-posn 14 14)))
(define BARRIER (square PIXELS/BLOCK "solid" "blue"))
(define WHITE-BARRIER (square PIXELS/BLOCK "solid" "white"))
(define BARRIER-POSNS (list (make-posn 0 31)
                            (make-posn 0 30)
                            (make-posn 0 29)
                            (make-posn 0 28)
                            (make-posn 0 27)
                            (make-posn 0 26)
                            (make-posn 0 25)
                            (make-posn 0 24)
                            (make-posn 0 23)
                            (make-posn 0 22)
                            (make-posn 0 18)
                            (make-posn 0 16)
                            (make-posn 0 12)
                            (make-posn 0 11)
                            (make-posn 0 10)
                            (make-posn 0 9)
                            (make-posn 0 8)
                            (make-posn 0 7)
                            (make-posn 0 6)
                            (make-posn 0 5)
                            (make-posn 0 4)
                            (make-posn 0 3)
                            (make-posn 0 2)
                            (make-posn 0 1)
                            (make-posn 1 31)
                            (make-posn 1 22)
                            (make-posn 1 18)
                            (make-posn 1 16)
                            (make-posn 1 12)
                            (make-posn 1 7)
                            (make-posn 1 6)
                            (make-posn 1 1)
                            (make-posn 2 31)
                            (make-posn 2 29)
                            (make-posn 2 28)
                            (make-posn 2 27)
                            (make-posn 2 25)
                            (make-posn 2 24)
                            (make-posn 2 22)
                            (make-posn 2 18)
                            (make-posn 2 16)
                            (make-posn 2 12)
                            (make-posn 2 10)
                            (make-posn 2 9)
                            (make-posn 2 7)
                            (make-posn 2 6)
                            (make-posn 2 4)
                            (make-posn 2 3)
                            (make-posn 2 1)
                            (make-posn 3 31)
                            (make-posn 3 29)
                            (make-posn 3 28)
                            (make-posn 3 27)
                            (make-posn 3 25)
                            (make-posn 3 24)
                            (make-posn 3 22)
                            (make-posn 3 18)
                            (make-posn 3 16)
                            (make-posn 3 12)
                            (make-posn 3 10)
                            (make-posn 3 9)
                            (make-posn 3 4)
                            (make-posn 3 3)
                            (make-posn 3 1)
                            (make-posn 4 31)
                            (make-posn 4 29)
                            (make-posn 4 28)
                            (make-posn 4 27)
                            (make-posn 4 25)
                            (make-posn 4 24)
                            (make-posn 4 22)
                            (make-posn 4 18)
                            (make-posn 4 16)
                            (make-posn 4 12)
                            (make-posn 4 10)
                            (make-posn 4 9)
                            (make-posn 4 8)
                            (make-posn 4 7)
                            (make-posn 4 6)
                            (make-posn 4 4)
                            (make-posn 4 3)
                            (make-posn 4 1)
                            (make-posn 5 31)
                            (make-posn 5 29)
                            (make-posn 5 28)
                            (make-posn 5 27)
                            (make-posn 5 25)
                            (make-posn 5 24)
                            (make-posn 5 22)
                            (make-posn 5 21)
                            (make-posn 5 20)
                            (make-posn 5 19)
                            (make-posn 5 18)
                            (make-posn 5 16)
                            (make-posn 5 15)
                            (make-posn 5 14)
                            (make-posn 5 13)
                            (make-posn 5 12)
                            (make-posn 5 10)
                            (make-posn 5 9)
                            (make-posn 5 8)
                            (make-posn 5 7)
                            (make-posn 5 6)
                            (make-posn 5 4)
                            (make-posn 5 3)
                            (make-posn 5 1)
                            (make-posn 6 31)
                            (make-posn 6 4)
                            (make-posn 6 3)
                            (make-posn 6 1)
                            (make-posn 7 31)
                            (make-posn 7 29)
                            (make-posn 7 28)
                            (make-posn 7 27)
                            (make-posn 7 25)
                            (make-posn 7 24)
                            (make-posn 7 23)
                            (make-posn 7 22)
                            (make-posn 7 21)
                            (make-posn 7 20)
                            (make-posn 7 19)
                            (make-posn 7 18)
                            (make-posn 7 16)
                            (make-posn 7 15)
                            (make-posn 7 14)
                            (make-posn 7 13)
                            (make-posn 7 12)
                            (make-posn 7 10)
                            (make-posn 7 9)
                            (make-posn 7 7)
                            (make-posn 7 6)
                            (make-posn 7 5)
                            (make-posn 7 4)
                            (make-posn 7 3)
                            (make-posn 7 1)
                            (make-posn 8 31)
                            (make-posn 8 29)
                            (make-posn 8 28)
                            (make-posn 8 27)
                            (make-posn 8 25)
                            (make-posn 8 24)
                            (make-posn 8 23)
                            (make-posn 8 22)
                            (make-posn 8 21)
                            (make-posn 8 20)
                            (make-posn 8 19)
                            (make-posn 8 18)
                            (make-posn 8 16)
                            (make-posn 8 15)
                            (make-posn 8 14)
                            (make-posn 8 13)
                            (make-posn 8 12)
                            (make-posn 8 10)
                            (make-posn 8 9)
                            (make-posn 8 7)
                            (make-posn 8 6)
                            (make-posn 8 5)
                            (make-posn 8 4)
                            (make-posn 8 3)
                            (make-posn 8 1)
                            (make-posn 9 31)
                            (make-posn 9 29)
                            (make-posn 9 28)
                            (make-posn 9 27)
                            (make-posn 9 22)
                            (make-posn 9 21)
                            (make-posn 9 10)
                            (make-posn 9 9)
                            (make-posn 9 4)
                            (make-posn 9 3)
                            (make-posn 9 1)
                            (make-posn 10 31)
                            (make-posn 10 29)
                            (make-posn 10 28)
                            (make-posn 10 27)
                            (make-posn 10 25)
                            (make-posn 10 24)
                            (make-posn 10 22)
                            (make-posn 10 21)
                            (make-posn 10 19)
                            (make-posn 10 18)
                            (make-posn 10 17)
                            (make-posn 10 16)
                            (make-posn 10 15)
                            (make-posn 10 13)
                            (make-posn 10 12)
                            (make-posn 10 10)
                            (make-posn 10 9)
                            (make-posn 10 7)
                            (make-posn 10 6)
                            (make-posn 10 4)
                            (make-posn 10 3)
                            (make-posn 10 1)
                            (make-posn 11 31)
                            (make-posn 11 29)
                            (make-posn 11 28)
                            (make-posn 11 27)
                            (make-posn 11 25)
                            (make-posn 11 24)
                            (make-posn 11 22)
                            (make-posn 11 21)
                            (make-posn 11 19)
                            (make-posn 11 15)
                            (make-posn 11 13)
                            (make-posn 11 12)
                            (make-posn 11 10)
                            (make-posn 11 9)
                            (make-posn 11 7)
                            (make-posn 11 6)
                            (make-posn 11 4)
                            (make-posn 11 3)
                            (make-posn 11 1)
                            (make-posn 12 31)
                            (make-posn 12 25)
                            (make-posn 12 24)
                            (make-posn 12 19)
                            (make-posn 12 15)
                            (make-posn 12 13)
                            (make-posn 12 12)
                            (make-posn 12 7)
                            (make-posn 12 6)
                            (make-posn 12 1)
                            (make-posn 13 31)
                            (make-posn 13 30)
                            (make-posn 13 29)
                            (make-posn 13 28)
                            (make-posn 13 27)
                            (make-posn 13 25)
                            (make-posn 13 24)
                            (make-posn 13 23)
                            (make-posn 13 22)
                            (make-posn 13 21)
                            (make-posn 13 15)
                            (make-posn 13 13)
                            (make-posn 13 12)
                            (make-posn 13 11)
                            (make-posn 13 10)
                            (make-posn 13 9)
                            (make-posn 13 7)
                            (make-posn 13 6)
                            (make-posn 13 5)
                            (make-posn 13 4)
                            (make-posn 13 3)
                            (make-posn 13 1)
                            (make-posn 27 31)
                            (make-posn 27 30)
                            (make-posn 27 29)
                            (make-posn 27 28)
                            (make-posn 27 27)
                            (make-posn 27 26)
                            (make-posn 27 25)
                            (make-posn 27 24)
                            (make-posn 27 23)
                            (make-posn 27 22)
                            (make-posn 27 18)
                            (make-posn 27 16)
                            (make-posn 27 12)
                            (make-posn 27 11)
                            (make-posn 27 10)
                            (make-posn 27 9)
                            (make-posn 27 8)
                            (make-posn 27 7)
                            (make-posn 27 6)
                            (make-posn 27 5)
                            (make-posn 27 4)
                            (make-posn 27 3)
                            (make-posn 27 2)
                            (make-posn 27 1)
                            (make-posn 26 31)
                            (make-posn 26 22)
                            (make-posn 26 18)
                            (make-posn 26 16)
                            (make-posn 26 12)
                            (make-posn 26 7)
                            (make-posn 26 6)
                            (make-posn 26 1)
                            (make-posn 25 31)
                            (make-posn 25 29)
                            (make-posn 25 28)
                            (make-posn 25 27)
                            (make-posn 25 25)
                            (make-posn 25 24)
                            (make-posn 25 22)
                            (make-posn 25 18)
                            (make-posn 25 16)
                            (make-posn 25 12)
                            (make-posn 25 10)
                            (make-posn 25 9)
                            (make-posn 25 7)
                            (make-posn 25 6)
                            (make-posn 25 4)
                            (make-posn 25 3)
                            (make-posn 25 1)
                            (make-posn 24 31)
                            (make-posn 24 29)
                            (make-posn 24 28)
                            (make-posn 24 27)
                            (make-posn 24 25)
                            (make-posn 24 24)
                            (make-posn 24 22)
                            (make-posn 24 18)
                            (make-posn 24 16)
                            (make-posn 24 12)
                            (make-posn 24 10)
                            (make-posn 24 9)
                            (make-posn 24 4)
                            (make-posn 24 3)
                            (make-posn 24 1)
                            (make-posn 23 31)
                            (make-posn 23 29)
                            (make-posn 23 28)
                            (make-posn 23 27)
                            (make-posn 23 25)
                            (make-posn 23 24)
                            (make-posn 23 22)
                            (make-posn 23 18)
                            (make-posn 23 16)
                            (make-posn 23 12)
                            (make-posn 23 10)
                            (make-posn 23 9)
                            (make-posn 23 8)
                            (make-posn 23 7)
                            (make-posn 23 6)
                            (make-posn 23 4)
                            (make-posn 23 3)
                            (make-posn 23 1)
                            (make-posn 22 31)
                            (make-posn 22 29)
                            (make-posn 22 28)
                            (make-posn 22 27)
                            (make-posn 22 25)
                            (make-posn 22 24)
                            (make-posn 22 22)
                            (make-posn 22 21)
                            (make-posn 22 20)
                            (make-posn 22 19)
                            (make-posn 22 18)
                            (make-posn 22 16)
                            (make-posn 22 15)
                            (make-posn 22 14)
                            (make-posn 22 13)
                            (make-posn 22 12)
                            (make-posn 22 10)
                            (make-posn 22 9)
                            (make-posn 22 8)
                            (make-posn 22 7)
                            (make-posn 22 6)
                            (make-posn 22 4)
                            (make-posn 22 3)
                            (make-posn 22 1)
                            (make-posn 21 31)
                            (make-posn 21 4)
                            (make-posn 21 3)
                            (make-posn 21 1)
                            (make-posn 20 31)
                            (make-posn 20 29)
                            (make-posn 20 28)
                            (make-posn 20 27)
                            (make-posn 20 25)
                            (make-posn 20 24)
                            (make-posn 20 23)
                            (make-posn 20 22)
                            (make-posn 20 21)
                            (make-posn 20 20)
                            (make-posn 20 19)
                            (make-posn 20 18)
                            (make-posn 20 16)
                            (make-posn 20 15)
                            (make-posn 20 14)
                            (make-posn 20 13)
                            (make-posn 20 12)
                            (make-posn 20 10)
                            (make-posn 20 9)
                            (make-posn 20 7)
                            (make-posn 20 6)
                            (make-posn 20 5)
                            (make-posn 20 4)
                            (make-posn 20 3)
                            (make-posn 20 1)
                            (make-posn 19 31)
                            (make-posn 19 29)
                            (make-posn 19 28)
                            (make-posn 19 27)
                            (make-posn 19 25)
                            (make-posn 19 24)
                            (make-posn 19 23)
                            (make-posn 19 22)
                            (make-posn 19 21)
                            (make-posn 19 20)
                            (make-posn 19 19)
                            (make-posn 19 18)
                            (make-posn 19 16)
                            (make-posn 19 15)
                            (make-posn 19 14)
                            (make-posn 19 13)
                            (make-posn 19 12)
                            (make-posn 19 10)
                            (make-posn 19 9)
                            (make-posn 19 7)
                            (make-posn 19 6)
                            (make-posn 19 5)
                            (make-posn 19 4)
                            (make-posn 19 3)
                            (make-posn 19 1)
                            (make-posn 18 31)
                            (make-posn 18 29)
                            (make-posn 18 28)
                            (make-posn 18 27)
                            (make-posn 18 22)
                            (make-posn 18 21)
                            (make-posn 18 10)
                            (make-posn 18 9)
                            (make-posn 18 4)
                            (make-posn 18 3)
                            (make-posn 18 1)
                            (make-posn 17 31)
                            (make-posn 17 29)
                            (make-posn 17 28)
                            (make-posn 17 27)
                            (make-posn 17 25)
                            (make-posn 17 24)
                            (make-posn 17 22)
                            (make-posn 17 21)
                            (make-posn 17 19)
                            (make-posn 17 18)
                            (make-posn 17 17)
                            (make-posn 17 16)
                            (make-posn 17 15)
                            (make-posn 17 13)
                            (make-posn 17 12)
                            (make-posn 17 10)
                            (make-posn 17 9)
                            (make-posn 17 7)
                            (make-posn 17 6)
                            (make-posn 17 4)
                            (make-posn 17 3)
                            (make-posn 17 1)
                            (make-posn 16 31)
                            (make-posn 16 29)
                            (make-posn 16 28)
                            (make-posn 16 27)
                            (make-posn 16 25)
                            (make-posn 16 24)
                            (make-posn 16 22)
                            (make-posn 16 21)
                            (make-posn 16 19)
                            (make-posn 16 15)
                            (make-posn 16 13)
                            (make-posn 16 12)
                            (make-posn 16 10)
                            (make-posn 16 9)
                            (make-posn 16 7)
                            (make-posn 16 6)
                            (make-posn 16 4)
                            (make-posn 16 3)
                            (make-posn 16 1)
                            (make-posn 15 31)
                            (make-posn 15 25)
                            (make-posn 15 24)
                            (make-posn 15 19)
                            (make-posn 15 15)
                            (make-posn 15 13)
                            (make-posn 15 12)
                            (make-posn 15 7)
                            (make-posn 15 6)
                            (make-posn 15 1)
                            (make-posn 14 31)
                            (make-posn 14 30)
                            (make-posn 14 29)
                            (make-posn 14 28)
                            (make-posn 14 27)
                            (make-posn 14 25)
                            (make-posn 14 24)
                            (make-posn 14 23)
                            (make-posn 14 22)
                            (make-posn 14 21)
                            (make-posn 14 15)
                            (make-posn 14 13)
                            (make-posn 14 12)
                            (make-posn 14 11)
                            (make-posn 14 10)
                            (make-posn 14 9)
                            (make-posn 14 7)
                            (make-posn 14 6)
                            (make-posn 14 5)
                            (make-posn 14 4)
                            (make-posn 14 3)
                            (make-posn 14 1)))
(define CAGE-POSNS (list (make-posn 11 16)
                         (make-posn 11 17)
                         (make-posn 11 18)
                         (make-posn 12 16)
                         (make-posn 12 17)
                         (make-posn 12 18)
                         (make-posn 13 16)
                         (make-posn 13 17)
                         (make-posn 13 18)
                         (make-posn 13 19)
                         (make-posn 14 16)
                         (make-posn 14 17)
                         (make-posn 14 18)
                         (make-posn 14 19)
                         (make-posn 15 16)
                         (make-posn 15 17)
                         (make-posn 15 18)
                         (make-posn 16 16)
                         (make-posn 16 17)
                         (make-posn 16 18)))
(define CAGE+BARRIERS (foldr (λ (p done) (cons p done)) BARRIER-POSNS CAGE-POSNS))
(define PAC-MAN (circle (/ PIXELS/BLOCK 2) "solid" "yellow"))
(define END-GC 40)
(define PM0 (make-pm (make-posn 14 8) 'left 'normal 0))
(define PM1 (make-pm (make-posn 14 9) 'up 'normal 0))
(define PM2 (make-pm (make-posn 14 7) 'down 'normal 0))
(define PM3 (make-pm (make-posn 14 9) 'left 'normal 0))
(define PM4 (make-pm (make-posn 16 9) 'right 'normal 0))
(define PM5 (make-pm (make-posn 15 8) 'up 'normal 0))
(define PM6 (make-pm (make-posn 2 2) 'right 'normal 0))
(define PM7 (make-pm (make-posn 27 17) 'right 'ghost 5))
(define PM8 (make-pm (make-posn -1 17) 'left 'ghost 19))
(define PM9 (make-pm (make-posn 2 2) 'left 'normal 0))
(define PM10 (make-pm (make-posn 1 3) 'down 'normal 0))
(define PM11 (make-pm (make-posn 1 2) 'left 'normal 0))
(define PM12 (make-pm (make-posn 4 6) 'left 'ghost 1))
(define PM13 (make-pm (make-posn 8 29) 'right 'ghost 17))
(define PM14 (make-pm (make-posn 1 29) 'down 'normal 0))
(define PM15 (make-pm (make-posn 1 28) 'up 'normal 0))
(define NORM-FOOD (circle (/ PIXELS/BLOCK 10) "solid" "light goldenrod"))
(define SUPER-FOOD (circle (/ PIXELS/BLOCK 2.5) "solid" "light goldenrod"))
(define CHERRY (triangle PIXELS/BLOCK "solid" "red"))
(define CHERRY-IN 100)
(define FOOD-POSNS (list (make-posn 25 0) ;cherry
                         (make-posn 1 30)
                         (make-posn 1 29)
                         (make-posn 1 28)
                         (make-posn 1 27)
                         (make-posn 1 26)
                         (make-posn 1 25)
                         (make-posn 1 24)
                         (make-posn 1 23)
                         (make-posn 1 11)
                         (make-posn 1 10)
                         (make-posn 1 9)
                         (make-posn 1 8)
                         (make-posn 1 5)
                         (make-posn 1 4)
                         (make-posn 1 3)
                         (make-posn 1 2)
                         (make-posn 2 30)
                         (make-posn 2 26)
                         (make-posn 2 23)
                         (make-posn 2 11)
                         (make-posn 2 8)
                         (make-posn 2 5)
                         (make-posn 2 2)
                         (make-posn 3 30)
                         (make-posn 3 26)
                         (make-posn 3 23)
                         (make-posn 3 11)
                         (make-posn 3 8)
                         (make-posn 3 7)
                         (make-posn 3 6)
                         (make-posn 3 5)
                         (make-posn 3 2)
                         (make-posn 4 30)
                         (make-posn 4 26)
                         (make-posn 4 23)
                         (make-posn 4 11)
                         (make-posn 4 5)
                         (make-posn 4 2)
                         (make-posn 5 30)
                         (make-posn 5 26)
                         (make-posn 5 23)
                         (make-posn 5 11)
                         (make-posn 5 5)
                         (make-posn 5 2)
                         (make-posn 6 30)
                         (make-posn 6 29)
                         (make-posn 6 28)
                         (make-posn 6 27)
                         (make-posn 6 26)
                         (make-posn 6 25)
                         (make-posn 6 24)
                         (make-posn 6 23)
                         (make-posn 6 22)
                         (make-posn 6 21)
                         (make-posn 6 20)
                         (make-posn 6 19)
                         (make-posn 6 18)
                         (make-posn 6 17)
                         (make-posn 6 16)
                         (make-posn 6 15)
                         (make-posn 6 14)
                         (make-posn 6 13)
                         (make-posn 6 12)
                         (make-posn 6 11)
                         (make-posn 6 10)
                         (make-posn 6 9)
                         (make-posn 6 8)
                         (make-posn 6 7)
                         (make-posn 6 6)
                         (make-posn 6 5)
                         (make-posn 6 2)
                         (make-posn 7 30)
                         (make-posn 7 26)
                         (make-posn 7 11)
                         (make-posn 7 8)
                         (make-posn 7 2)
                         (make-posn 8 30)
                         (make-posn 8 26)
                         (make-posn 8 11)
                         (make-posn 8 8)
                         (make-posn 8 2)
                         (make-posn 9 30)
                         (make-posn 9 26)
                         (make-posn 9 25)
                         (make-posn 9 24)
                         (make-posn 9 23)
                         (make-posn 9 11)
                         (make-posn 9 8)
                         (make-posn 9 7)
                         (make-posn 9 6)
                         (make-posn 9 5)
                         (make-posn 9 2)
                         (make-posn 10 30)
                         (make-posn 10 26)
                         (make-posn 10 23)
                         (make-posn 10 11)
                         (make-posn 10 8)
                         (make-posn 10 5)
                         (make-posn 10 2)
                         (make-posn 11 30)
                         (make-posn 11 26)
                         (make-posn 11 23)
                         (make-posn 11 11)
                         (make-posn 11 8)
                         (make-posn 11 5)
                         (make-posn 11 2)
                         (make-posn 12 30)
                         (make-posn 12 29)
                         (make-posn 12 28)
                         (make-posn 12 27)
                         (make-posn 12 26)
                         (make-posn 12 23)
                         (make-posn 12 11)
                         (make-posn 12 10)
                         (make-posn 12 9)
                         (make-posn 12 8)
                         (make-posn 12 5)
                         (make-posn 12 4)
                         (make-posn 12 3)
                         (make-posn 12 2)
                         (make-posn 13 26)
                         (make-posn 13 8)
                         (make-posn 13 2)
                         (make-posn 14 26)
                         (make-posn 14 8)
                         (make-posn 14 2)
                         (make-posn 15 30)
                         (make-posn 15 29)
                         (make-posn 15 28)
                         (make-posn 15 27)
                         (make-posn 15 26)
                         (make-posn 15 23)
                         (make-posn 15 11)
                         (make-posn 15 10)
                         (make-posn 15 9)
                         (make-posn 15 8)
                         (make-posn 15 5)
                         (make-posn 15 4)
                         (make-posn 15 3)
                         (make-posn 15 2)
                         (make-posn 16 30)
                         (make-posn 16 26)
                         (make-posn 16 23)
                         (make-posn 16 11)
                         (make-posn 16 8)
                         (make-posn 16 5)
                         (make-posn 16 2)
                         (make-posn 17 30)
                         (make-posn 17 26)
                         (make-posn 17 23)
                         (make-posn 17 11)
                         (make-posn 17 8)
                         (make-posn 17 5)
                         (make-posn 17 2)
                         (make-posn 18 30)
                         (make-posn 18 26)
                         (make-posn 18 25)
                         (make-posn 18 24)
                         (make-posn 18 23)
                         (make-posn 18 11)
                         (make-posn 18 8)
                         (make-posn 18 7)
                         (make-posn 18 6)
                         (make-posn 18 5)
                         (make-posn 18 2)
                         (make-posn 19 30)
                         (make-posn 19 26)
                         (make-posn 19 11)
                         (make-posn 19 8)
                         (make-posn 19 2)
                         (make-posn 20 30)
                         (make-posn 20 26)
                         (make-posn 20 11)
                         (make-posn 20 8)
                         (make-posn 20 2)
                         (make-posn 21 30)
                         (make-posn 21 29)
                         (make-posn 21 28)
                         (make-posn 21 27)
                         (make-posn 21 26)
                         (make-posn 21 25)
                         (make-posn 21 24)
                         (make-posn 21 23)
                         (make-posn 21 22)
                         (make-posn 21 21)
                         (make-posn 21 20)
                         (make-posn 21 19)
                         (make-posn 21 18)
                         (make-posn 21 17)
                         (make-posn 21 16)
                         (make-posn 21 15)
                         (make-posn 21 14)
                         (make-posn 21 13)
                         (make-posn 21 12)
                         (make-posn 21 11)
                         (make-posn 21 10)
                         (make-posn 21 9)
                         (make-posn 21 8)
                         (make-posn 21 7)
                         (make-posn 21 6)
                         (make-posn 21 5)
                         (make-posn 21 2)
                         (make-posn 22 30)
                         (make-posn 22 26)
                         (make-posn 22 23)
                         (make-posn 22 11)
                         (make-posn 22 5)
                         (make-posn 22 2)
                         (make-posn 23 30)
                         (make-posn 23 26)
                         (make-posn 23 23)
                         (make-posn 23 11)
                         (make-posn 23 5)
                         (make-posn 23 2)
                         (make-posn 24 30)
                         (make-posn 24 26)
                         (make-posn 24 23)
                         (make-posn 24 11)
                         (make-posn 24 8)
                         (make-posn 24 7)
                         (make-posn 24 6)
                         (make-posn 24 5)
                         (make-posn 24 2)
                         (make-posn 25 30)
                         (make-posn 25 26)
                         (make-posn 25 23)
                         (make-posn 25 11)
                         (make-posn 25 8)
                         (make-posn 25 5)
                         (make-posn 25 2)
                         (make-posn 26 30)
                         (make-posn 26 29)
                         (make-posn 26 28)
                         (make-posn 26 27)
                         (make-posn 26 26)
                         (make-posn 26 25)
                         (make-posn 26 24)
                         (make-posn 26 23)
                         (make-posn 26 11)
                         (make-posn 26 10)
                         (make-posn 26 9)
                         (make-posn 26 8)
                         (make-posn 26 5)
                         (make-posn 26 4)
                         (make-posn 26 3)
                         (make-posn 26 2)))
(define FOOD1 (make-food (make-posn 1 4) 'normal))
(define FOOD2 (make-food (make-posn 1 8) 'super))
(define LOF1 (list FOOD1 FOOD2))
(define LOF2 (list (make-food (make-posn 14 8) 'normal)
                   (make-food (make-posn 15 8) 'normal)))
(define LOF3 (list (make-food (make-posn 14 8) 'normal)))
(define RED-GHOST (circle (/ PIXELS/BLOCK 2) "solid" "red"))
(define PINK-GHOST (circle (/ PIXELS/BLOCK 2) "solid" "medium pink"))
(define CYAN-GHOST (circle (/ PIXELS/BLOCK 2) "solid" "medium cyan"))
(define ORANGE-GHOST (circle (/ PIXELS/BLOCK 2) "solid" "medium orange"))
(define BLUE-GHOST (circle (/ PIXELS/BLOCK 2) "solid" "blue"))
(define RED-START1 (make-posn 14 20))
(define RED-START2 (make-posn 13 18))
(define PINK-START (make-posn 14 18))
(define CYAN-START (make-posn 14 17))
(define ORANGE-START (make-posn 13 17))
(define RELEASE2 8)
(define GHOST-START-POSNS (list RED-START1 PINK-START CYAN-START ORANGE-START))
(define GHOST1 (make-ghost (make-posn 1 29) 'down 'mediumpink 38 2))
(define GHOST2 (make-ghost (make-posn 24 29) 'right 'mediumcyan 14 21))
(define GHOST3 (make-ghost (make-posn 4 6) 'left 'mediumcyan 29 1))
(define GHOST4 (make-ghost (make-posn 4 6) 'up 'mediumorange 40 1))
(define GHOST5 (make-ghost (make-posn 8 29) 'left 'red 309 2))
(define GHOST6 (make-ghost (make-posn 0 16) 'down 'red 230 2))
(define GHOST7 (make-ghost RED-START2 'left 'red RELEASE2 1))
(define GHOST8 (make-ghost (make-posn 22 31) 'up 'mediumcyan 82 1))
(define LOG1 (list GHOST1 GHOST2))
(define LOG2 (list (make-ghost (make-posn 2 2) 'left 'red 100 1)
                   (make-ghost (make-posn 2 30) 'left 'mediumpink 100 1)
                   (make-ghost (make-posn 4 30) 'left 'mediumcyan 100 1)
                   (make-ghost (make-posn 5 30) 'left 'mediumorange 100 1)))
(define 2LIVES (list (make-posn 3 0) (make-posn 5 0)))
;(define WORLD1 (make-world PM0 LOF LOG 20 2 0))
;(define WORLD2 (make-world PM5 LOF LOG1 600 2 200))
(define WORLD3 (make-world PM6 LOF1 LOG2 400 3 20))
(define WORLD4 (make-world PM7 LOF1 LOG2 400 3 1))
(define WORLD5 (make-world PM8 LOF1 LOG2 400 3 2))


;;; place-image/block : Image Number Number Image -> Image
;;; Place image on the scene according to block coordinates

(check-expect (place-image/block BARRIER 0 0 MAZE-BASE)
              (place-image BARRIER (* PIXELS/BLOCK (+ 1/2 0))
                           (* PIXELS/BLOCK (- MAZE-HEIGHT (+ 1/2 0)))
                           MAZE-BASE))
(check-expect (place-image/block BARRIER 1 32 MAZE-BASE)
              (place-image BARRIER (* PIXELS/BLOCK (+ 1/2 1))
                           (* PIXELS/BLOCK (- MAZE-HEIGHT (+ 1/2 32)))
                           MAZE-BASE))
(check-expect (place-image/block BARRIER 27 33 MAZE-BASE)
              (place-image BARRIER (* PIXELS/BLOCK (+ 1/2 27))
                           (* PIXELS/BLOCK (- MAZE-HEIGHT (+ 1/2 33)))
                           MAZE-BASE))

(define (place-image/block i1 x y s)
  (place-image i1 (* PIXELS/BLOCK (+ 1/2 x))
               (* PIXELS/BLOCK (- MAZE-HEIGHT (+ 1/2 y))) s))

(define ALL-BARRIERS
  (foldr (λ (p img-done)
           (place-image/block BARRIER (posn-x p) (posn-y p) img-done))
         MAZE-BASE
         BARRIER-POSNS))
(define ALL-BARRIERS-WHITE
  (foldr (λ (p img-done)
           (place-image/block WHITE-BARRIER (posn-x p) (posn-y p) img-done))
         MAZE-BASE
         BARRIER-POSNS))

;;; posn=? : Posn Posn -> Boolean
;;; Are the posns the same?

(check-expect (posn=? (make-posn 7 6) (make-posn 7 6)) #t)
(check-expect (posn=? (make-posn 6 6) (make-posn 7 6)) #f)
(check-expect (posn=? (make-posn 7 5) (make-posn 7 6)) #f)
(check-expect (posn=? (make-posn 9 2) (make-posn 7 6)) #f)

(define (posn=? p1 p2)
  (and (= (posn-x p1) (posn-x p2))
       (= (posn-y p1) (posn-y p2))))

(define LOF (map (λ (p) (cond [(posn=? p (make-posn 25 0))
                               (make-food p 'fruit)]
                              [(or (posn=? p (make-posn 1 28))
                                   (posn=? p (make-posn 26 28))
                                   (posn=? p (make-posn 1 8))
                                   (posn=? p (make-posn 26 8)))
                               (make-food p 'super)]
                              [else (make-food p 'normal)]))
                 FOOD-POSNS))
(define LOG (map
             (λ (p) (make-ghost p 'left
                                (cond [(posn=? p (make-posn 14 20)) 'red]
                                      [(posn=? p (make-posn 14 18)) 'mediumpink]
                                      [(posn=? p (make-posn 14 17)) 'mediumcyan]
                                      [else 'mediumorange]) 0 0)) GHOST-START-POSNS))

;;; pm->scene : PM Image -> Image
;;; Place Pac-Man onto the given scene

(check-expect (pm->scene PM0 MAZE-BASE)
              (place-image/block PAC-MAN 14 8 MAZE-BASE))
(check-expect (pm->scene PM5 MAZE-BASE)
              (place-image/block PAC-MAN 15 8 MAZE-BASE))

(define (pm->scene pm img)
  (place-image/block PAC-MAN
                     (posn-x (pm-posn pm))
                     (posn-y (pm-posn pm)) img))

;;; food->scene : Food Image -> Image
;;; Place the food onto the given scene

(check-expect (food->scene FOOD1 MAZE-BASE)
              (place-image/block NORM-FOOD 1 4 MAZE-BASE))
(check-expect (food->scene FOOD2 MAZE-BASE)
              (place-image/block SUPER-FOOD 1 8 MAZE-BASE))

(define (food->scene f img)
  (place-image/block (cond [(symbol=? (food-ftype f) 'normal) NORM-FOOD]
                           [(symbol=? (food-ftype f) 'super) SUPER-FOOD]
                           [else CHERRY])
                     (posn-x (food-posn f))
                     (posn-y (food-posn f)) img))

;;; lof->scene : [ListOf Food] Image -> Image
;;; Place the lof onto the given scene

(check-expect (lof->scene LOF MAZE-BASE)
              (foldr (λ (f img-done) (food->scene f img-done)) MAZE-BASE LOF))
(check-expect (lof->scene LOF1 MAZE-BASE)
              (foldr (λ (f img-done) (food->scene f img-done)) MAZE-BASE LOF1))

(define (lof->scene lof img)
  (foldr (λ (f img-done) (food->scene f img-done)) img lof))

;;; ghost->scene : PM Ghost Image -> Image
;;; Place the ghost onto the given scene
#|
(check-expect (ghost->scene PM0 GHOST1 MAZE-BASE)
              (place-image/block PINK-GHOST 1 29 MAZE-BASE))
(check-expect (ghost->scene PM7 GHOST2 MAZE-BASE)
              (place-image/block BLUE-GHOST 24 29 MAZE-BASE))
|#
(define (ghost->scene pm gh img)
  (place-image/block (if (symbol=? (pm-es pm) 'ghost)
                         (cond [(and (in-cage? gh) (= (ghost-releases gh) 0)) BLUE-GHOST]
                               [(and (in-cage? gh) (>= (ghost-releases gh) 1))
                                (circle (/ PIXELS/BLOCK 2) "solid" (ghost-color gh))]
                               [else (if (or (= (pm-gc pm) (- END-GC 8))
                                 (= (pm-gc pm) (- END-GC 6))
                                 (= (pm-gc pm) (- END-GC 4))
                                 (= (pm-gc pm) (- END-GC 2))
                                 (= (pm-gc pm) END-GC))
                             (circle (/ PIXELS/BLOCK 2) "solid" "white")
                             BLUE-GHOST)])
                         (circle (/ PIXELS/BLOCK 2) "solid" (ghost-color gh)))
                     (posn-x (ghost-posn gh))
                     (posn-y (ghost-posn gh)) img))

;;; log->scene : PM [ListOf Ghost] Image -> Image
;;; Place the log onto the given scene

(check-expect (log->scene PM7 LOG1 MAZE-BASE)
              (foldr (λ (g img-done) (ghost->scene PM7 g img-done))
                     MAZE-BASE LOG1))

(define (log->scene pm log img)
  (foldr (λ (g img-done) (ghost->scene pm g img-done)) img log))

;;; score->scene : Number Image -> Image
;;; Place the score onto the given scene

(define ALL-FOOD (foldr (λ (f img-done) (food->scene f img-done)) MAZE-BASE LOF))
(define BARRIERS+FOOD
  (foldr
   (λ (bp img-done)
     (place-image/block BARRIER (posn-x bp) (posn-y bp) img-done))
   ALL-FOOD BARRIER-POSNS))

(check-expect (score->scene 20 BARRIERS+FOOD)
              (place-image/block (text "20" PIXELS/BLOCK "white") 2 32 BARRIERS+FOOD))
(check-expect (score->scene 2334 BARRIERS+FOOD)
              (place-image/block (text "2334" PIXELS/BLOCK "white") 2 32 BARRIERS+FOOD))

(define (score->scene s img)
  (place-image/block (text (number->string s) PIXELS/BLOCK "white") 2 32 img))

;;; lives->scene : Number Image -> Image
;;; Place the images representing the number of lives onto the given scene

(check-expect (lives->scene 2 BARRIERS+FOOD)
              (foldr (λ (p img-done)
                       (place-image/block
                        PAC-MAN
                        (posn-x p)
                        (posn-y p)
                        img-done)) BARRIERS+FOOD 2LIVES))
(check-expect (lives->scene 1 BARRIERS+FOOD) (place-image/block PAC-MAN
                                                                5 0
                                                                BARRIERS+FOOD))
(check-expect (lives->scene 0 BARRIERS+FOOD) BARRIERS+FOOD)

(define (lives->scene l img)
  (cond [(= l 2) (foldr (λ (p img-done) (place-image/block
                                         PAC-MAN
                                         (posn-x p)
                                         (posn-y p)
                                         img-done)) img 2LIVES)]
        [(= l 1) (place-image/block PAC-MAN 5 0 img)]
        [else img]))

;;; world->scene : World -> Image
;;; Place images representing each aspect of the world on the maze
;;; Ghosts go on top of Pac-Man, Pac-Man on top of food

(define WORLD2 (make-world PM5 LOF LOG1 600 2 200))

(check-expect (world->scene WORLD2) (log->scene
                                     PM5 LOG1
                                     (pm->scene
                                      PM5
                                      (lof->scene
                                       LOF
                                       (score->scene
                                        600
                                        (lives->scene
                                         2 ALL-BARRIERS))))))

(define (world->scene w)
  (log->scene
   (world-pm w) (world-log w)
   (pm->scene
    (world-pm w)
    (lof->scene
     (world-lof w)
     (score->scene
      (world-score w)
      (lives->scene
       (world-lives w)
       ALL-BARRIERS))))))

;;; ghost-eating? : Ghost PM -> Boolean
;;; Is the ghost eating Pac-Man?

(check-expect (ghost-eating? GHOST1 PM14) #t)
(check-expect (ghost-eating? GHOST1  PM4) #f)
(check-expect (ghost-eating? GHOST1  PM7) #f)

(define (ghost-eating? gh pm)
  (and (posn=? (ghost-posn gh) (pm-posn pm))
       (symbol=? (pm-es pm) 'normal)))

;;; log-eating? : [ListOf Ghost] PM -> Boolean
;;; Is at least one ghost eating Pac-Man?

(check-expect (log-eating? LOG1 PM14) #t)
(check-expect (log-eating? LOG1 PM4)  #f)
(check-expect (log-eating?  '() PM4)  #f)

(define (log-eating? log pm)
  (ormap (λ (g) (ghost-eating? g pm)) log))

;;; maybe-move-pm : PM [ListOf Posn] -> PM
;;; If Pac-man is not in an appropriate spot, move him one
;;; space in the opposite direction

(check-expect (maybe-move-pm PM1 BARRIER-POSNS)
              (make-pm (make-posn 14 8) 'up 'normal 0))
(check-expect (maybe-move-pm PM2 BARRIER-POSNS)
              (make-pm (make-posn 14 8) 'down 'normal 0))
(check-expect (maybe-move-pm PM3 BARRIER-POSNS)
              (make-pm (make-posn 15 9) 'left 'normal 0))
(check-expect (maybe-move-pm PM4 BARRIER-POSNS)
              (make-pm (make-posn 15 9) 'right 'normal 0))

(define (maybe-move-pm pm lop)
  (local [(define X (posn-x (pm-posn pm)))
          (define Y (posn-y (pm-posn pm)))
          (define DIR (pm-dir pm))]
    (if (ormap (λ (p) (posn=? (pm-posn pm) p)) lop)
        (make-pm (cond [(symbol=? 'left DIR) (make-posn (+ X 1) Y)]
                       [(symbol=? 'right DIR) (make-posn (- X 1) Y)]
                       [(symbol=? 'down DIR) (make-posn X (+ Y 1))]
                       [else (make-posn X (- Y 1))])
                 DIR (pm-es pm) (pm-gc pm))
        pm)))

;;; dead? : World -> Boolean
;;; Are there no more lives left?

(define (dead? w)
  (= (world-lives w) -1))

;;; food-eaten? : World -> Boolean
;;; Has all maze food been eaten?

(define (food-eaten? w)
  (= (length (world-lof w)) 1))

;;; new-game : World -> World
;;; Start a new game with one less life

(define (new-game w)
  (make-world PM0
              (world-lof w)
              LOG
              (world-score w)
              (- (world-lives w) 1) 0))

;;; pm-eating-super? : PM [ListOf Food] -> Boolean
;;; Is Pac-Man eating (or in the same posn as) super food?

(check-expect (pm-eating-super? PM15 LOF) #t)
(check-expect (pm-eating-super? PM14 LOF) #f)

(define (pm-eating-super? pm lof)
  (ormap (λ (f) (and (symbol=? (food-ftype f) 'super)
                     (posn=? (pm-posn pm) (food-posn f)))) lof))

;;; change-es-help : PM [ListOf Food] -> PM
;;;

(define (change-es-help pm lof)
  (local [(define POSN (pm-posn pm))
          (define DIR (pm-dir pm))
          (define GC (pm-gc pm))]
    (if (= GC END-GC)
        (make-pm POSN DIR 'normal 0)
        (make-pm POSN
                 DIR
                 (pm-es pm)
                 (if (pm-eating-super? pm lof) 0 (+ GC 1))))))


;;; change-es? : PM [ListOf Food] -> PM
;;; If Pac-Man eats super food, change his es

(check-expect (change-es? PM15 LOF)
              (make-pm (make-posn 1 28) 'up 'ghost 0))
(check-expect (change-es? PM14 LOF) PM14)

(define (change-es? pm lof)
  (if (pm-eating-super? pm lof)
      (make-pm (pm-posn pm) (pm-dir pm) 'ghost 0)
      pm))

;;; move : PM -> PM
;;; Move Pac-Man one block according to his direction

(check-expect (move PM7) (make-pm (make-posn 0 17) 'right 'ghost 5))
(check-expect (move PM8) (make-pm (make-posn 27 17) 'left 'ghost 19))
(check-expect (move PM5) (make-pm (make-posn 15 9) 'up 'normal 0))
(check-expect (move PM6) (make-pm (make-posn 3 2) 'right 'normal 0))
(check-expect (move PM9) PM11)
(check-expect (move PM10) (make-pm (make-posn 1 2) 'down 'normal 0))
(check-expect (move PM11) PM11)

(define (move pm)
  (local [(define POSN (pm-posn pm))
          (define DIR (pm-dir pm))
          (define ES (pm-es pm))
          (define GC (pm-gc pm))
          (define X (posn-x (pm-posn pm)))
          (define Y (posn-y (pm-posn pm)))]
    (cond [(and (posn=? POSN (make-posn 27 17)) (symbol=? DIR 'right))
           (make-pm (make-posn 0 17) 'right ES GC)]
          [(and (posn=? POSN (make-posn -1 17)) (symbol=? DIR 'left))
           (make-pm (make-posn 27 17) 'left ES GC)]
          [else (maybe-move-pm (make-pm (cond [(symbol=? DIR 'left) (make-posn (- X 1) Y)]
                                              [(symbol=? DIR 'right) (make-posn (+ X 1) Y)]
                                              [(symbol=? DIR 'down) (make-posn X (- Y 1))]
                                              [else (make-posn X (+ Y 1))]) DIR ES GC)
                               CAGE+BARRIERS)])))

;;; eat-check : PM [ListOf Food] -> [ListOf Food]
;;; If Pac-Man is eating food, remove it from the maze

(check-expect (eat-check PM0 LOF2)
              (filter (λ (f) (not (posn=? (make-posn 14 8)
                                          (food-posn f)))) LOF2))
(check-expect (eat-check PM7 LOF1) LOF1)

(define (eat-check pm lof)
  (if (ormap (λ (f) (posn=? (pm-posn pm) (food-posn f))) lof)
      (filter (λ (f) (not (posn=? (pm-posn pm) (food-posn f)))) lof)
      lof))

;;; in-cage? : Ghost -> Boolean
;;; Is the ghost in the cage?
;;; (Only for ghosts ready to be taken out)

(check-expect (in-cage? GHOST1) (ormap (λ (p) (posn=? p (ghost-posn GHOST1)))
                                       CAGE-POSNS))
(check-expect (in-cage? GHOST7) #t)

(define (in-cage? gh)
  (ormap (λ (p) (posn=? p (ghost-posn gh))) CAGE-POSNS))

;;; pm-eating-ghost? : PM Ghost -> Boolean
;;; Is Pac-Man eating a ghost?

(check-expect (pm-eating-ghost? PM12 GHOST3) #t)
(check-expect (pm-eating-ghost? PM13 GHOST5) #t)
(check-expect (pm-eating-ghost? PM0 GHOST5) #f)
(check-expect (pm-eating-ghost? PM13 GHOST3) #f)

(define (pm-eating-ghost? pm gh)
  (and (posn=? (pm-posn pm) (ghost-posn gh))
       (symbol=? (pm-es pm) 'ghost)))

;;; restart-ghost : Ghost -> Ghost
;;; Bring the ghost back to its starting cage position

(check-expect (restart-ghost GHOST5) (make-ghost RED-START2 'left 'red 0 2))
(check-expect (restart-ghost GHOST1) (make-ghost PINK-START 'down 'mediumpink 0 2))
(check-expect (restart-ghost GHOST3) (make-ghost CYAN-START 'left 'mediumcyan 0 1))
(check-expect (restart-ghost GHOST4) (make-ghost ORANGE-START 'up 'mediumorange 0 1))

(define (restart-ghost gh)
  (make-ghost (cond [(symbol=? (ghost-color gh) 'red) RED-START2]
                    [(symbol=? (ghost-color gh) 'mediumpink) PINK-START]
                    [(symbol=? (ghost-color gh) 'mediumorange) ORANGE-START]
                    [else CYAN-START])
              (ghost-dir gh)
              (ghost-color gh) 0 (ghost-releases gh)))

;;; new-posn : Ghost -> Posn
;;; Give the ghost a new posn based on its current direction

(check-expect (new-posn GHOST1) (make-posn 1 28))
(check-expect (new-posn GHOST2) (make-posn 25 29))
(check-expect (new-posn GHOST3) (make-posn 3 6))
(check-expect (new-posn GHOST4) (make-posn 4 7))

(define (new-posn gh)
  (local [(define X (posn-x (ghost-posn gh)))
          (define Y (posn-y (ghost-posn gh)))]
  (cond [(symbol=? (ghost-dir gh) 'left) (make-posn (- X 1) Y)]
        [(symbol=? (ghost-dir gh) 'right) (make-posn (+ X 1) Y)]
        [(symbol=? (ghost-dir gh) 'up) (make-posn X (+ Y 1))]
        [else (make-posn X (- Y 1))])))

#|
;;; rand-dir : Number -> Dir
;;; Generate a random direction based on given number

(check-expect (rand-dir 1) 'left)
(check-expect (rand-dir 2) 'right)
(check-expect (rand-dir 3) 'up)
(check-expect (rand-dir 4) 'down)

(define (rand-dir n)
  (cond [(= n 1) 'left]
        [(= n 2) 'right]
        [(= n 3) 'up]
        [else 'down]))
|#

;;; new-rand-dir : Dir Number -> Dir
;;; A direction different from the one given based on a random number (1-3)

(check-expect (new-rand-dir 'left  1) 'right)
(check-expect (new-rand-dir 'left  2) 'up)
(check-expect (new-rand-dir 'left  3) 'down)
(check-expect (new-rand-dir 'right 1) 'up)
(check-expect (new-rand-dir 'right 2) 'down)
(check-expect (new-rand-dir 'right 3) 'left)
(check-expect (new-rand-dir 'up    1) 'down)
(check-expect (new-rand-dir 'up    2) 'left)
(check-expect (new-rand-dir 'up    3) 'right)
(check-expect (new-rand-dir 'down  1) 'left)
(check-expect (new-rand-dir 'down  2) 'right)
(check-expect (new-rand-dir 'down  3) 'up)

(define (new-rand-dir dir n)
  (cond [(symbol=? 'left dir)  (cond [(= n 1) 'right]
                                     [(= n 2) 'up]
                                     [else    'down])]
        [(symbol=? 'right dir) (cond [(= n 1) 'up]
                                     [(= n 2) 'down]
                                     [else    'left])]
        [(symbol=? 'up dir)    (cond [(= n 1) 'down]
                                     [(= n 2) 'left]
                                     [else    'right])]
        [else                  (cond [(= n 1) 'left]
                                     [(= n 2) 'right]
                                     [else    'up])]))

;;; maybe-move-ghost : Ghost [ListOf Posn] -> Ghost
;;; Move the ghost unless the new position is inappropriate

(check-expect (maybe-move-ghost GHOST1 CAGE+BARRIERS)
              (make-ghost (make-posn 1 29)
                          'down
                          'mediumpink 38 2))
(check-random (maybe-move-ghost GHOST3 CAGE+BARRIERS)
              (maybe-move-ghost (make-ghost (make-posn 5 6)
                                            (new-rand-dir 'left
                                                          (+ 1 (random 3)))
                                            'mediumcyan 29 1) CAGE+BARRIERS))
(check-random (maybe-move-ghost GHOST2 CAGE+BARRIERS)
              (maybe-move-ghost (make-ghost (make-posn 23 29)
                                            (new-rand-dir 'right
                                                          (+ 1 (random 3)))
                                            'mediumcyan 14 21) CAGE+BARRIERS))
(check-random (maybe-move-ghost GHOST6 CAGE+BARRIERS)
              (maybe-move-ghost (make-ghost (make-posn 0 17)
                                            (new-rand-dir 'down
                                                          (+ 1 (random 3)))
                                            'red 230 2) CAGE+BARRIERS))
(check-random (maybe-move-ghost GHOST8 CAGE+BARRIERS)
              (maybe-move-ghost (make-ghost (make-posn 22 30)
                                            (new-rand-dir 'up
                                                          (+ 1 (random 3)))
                                            'mediumcyan 82 1) CAGE+BARRIERS))
(check-expect (maybe-move-ghost GHOST7 CAGE+BARRIERS) GHOST7)

(define (maybe-move-ghost gh lop)
  (local [(define X (posn-x (ghost-posn gh)))
          (define Y (posn-y (ghost-posn gh)))
          (define POSN (ghost-posn gh))
          (define DIR (ghost-dir gh))
          (define COLOR (ghost-color gh))
          (define TIME (ghost-time gh))
          (define RELEASES (ghost-releases gh))]
    (cond [(in-cage? gh) gh]
          [(ormap (λ (p) (posn=? POSN p)) lop)
           (maybe-move-ghost
            (make-ghost (cond [(symbol=? 'left DIR) (make-posn (+ X 1) Y)]
                              [(symbol=? 'right DIR) (make-posn (- X 1) Y)]
                              [(symbol=? 'down DIR) (make-posn X (+ Y 1))]
                              [else (make-posn X (- Y 1))])
                        (new-rand-dir DIR (+ 1 (random 3))) COLOR TIME RELEASES)
            lop)]
          [else (make-ghost POSN DIR COLOR TIME RELEASES)])))

;;; release? : Ghost -> Boolean
;;; Has the ghost spent enough time in the cage to be released?

(define PINK-RELEASE1 15)
(define CYAN-RELEASE1 30)
(define ORANGE-RELEASE1 45)

(define (release? gh)
  ;;; color= : Symbol -> Boolean
  ;;; Is the ghost's color the given symbol?
  (local [(define (color= c) (symbol=? (ghost-color gh) c))
          (define TIME (ghost-time gh))
          (define RELEASES (ghost-releases gh))]
       (or (and (color= 'red)
                (= TIME RELEASE2))
           (and (color= 'mediumpink)
                (or (and (= TIME PINK-RELEASE1)
                         (= RELEASES 0))
                    (and (= TIME RELEASE2)
                         (>= RELEASES 1))))
           (and (color= 'mediumcyan)
                (or (and (= TIME CYAN-RELEASE1)
                         (= RELEASES 0))
                    (and (= TIME RELEASE2)
                         (>= RELEASES 1))))
           (and (color= 'mediumorange)
                (or (and (= TIME ORANGE-RELEASE1)
                         (= RELEASES 0))
                    (and (= TIME RELEASE2)
                         (>= RELEASES 1)))))))

;;; release : Ghost -> Ghost
;;; Release the ghost from the cage

(define (release gh)
  (make-ghost (make-posn 14 20)
              (ghost-dir gh)
              (ghost-color gh)
              (add1 (ghost-time gh))
              (add1 (ghost-releases gh))))

;;; move-ghost : PM Ghost -> Ghost
;;; Move the ghost according to its current position

(check-random (move-ghost PM0 GHOST1) (maybe-move-ghost
                                           (make-ghost (new-posn GHOST1)
                                                       (ghost-dir GHOST1)
                                                       (ghost-color GHOST1)
                                                       39 2)
                                                       CAGE+BARRIERS))
(check-expect (move-ghost PM0 GHOST7) (make-ghost (make-posn 14 20)
                                                  'left
                                                  'red
                                                  9 2))
(check-expect (move-ghost PM12 GHOST3) (restart-ghost GHOST3))

(define (move-ghost pm gh)
  (local [(define POSN (ghost-posn gh))
          (define DIR (ghost-dir gh))
          (define COLOR (ghost-color gh))
          (define TIME (ghost-time gh))
          (define RELEASES (ghost-releases gh))]
    (cond [(in-cage? gh) (if (release? gh)
                             (release gh)
                             (make-ghost POSN DIR COLOR (add1 TIME) RELEASES))]
          [(pm-eating-ghost? pm gh) (restart-ghost gh)]
          [(posn=? POSN (make-posn -1 17))
           (make-ghost (make-posn 27 17) 'left COLOR (add1 TIME) RELEASES)]
          [(posn=? POSN (make-posn 28 17))
           (make-ghost (make-posn 0 17) 'right COLOR (add1 TIME) RELEASES)]
          [else (maybe-move-ghost (make-ghost (new-posn gh)
                                              DIR
                                              COLOR
                                              (add1 TIME)
                                              RELEASES)
                                  CAGE+BARRIERS)])))

;;; move-log : PM [ListOf Ghost] -> [ListOf Ghost]
;;; Move the log in its current direction unless they aren't ready
#|
(check-expect (move-log PM0 LOG1) '())
(check-random (move-log PM0 LOG2)
              (map (λ (g) (move-ghost PM0 g))
                   (list (make-ghost (make-posn 2 2) 'left 'red)
                         (make-ghost (make-posn 2 30) 'left 'mediumpink))))
(check-random (move-log PM0 LOG2)
              (map (λ (g) (move-ghost PM0 g))
                   (list (make-ghost (make-posn 2 2) 'left 'red)
                         (make-ghost (make-posn 2 30) 'left 'mediumpink)
                         (make-ghost (make-posn 4 30) 'left 'mediumcyan))))
(check-random (move-log PM0 LOG2) (map (λ (g) (move-ghost PM0 g)) LOG2))
|#
(define (move-log pm log)
  (map (λ (g) (move-ghost pm g)) log))

;;; change-score : Number [ListOf Food] [ListOf Food] -> Number
;;; Change the score by adding 10 for each piece of food missing
;;; from the previous list.

(check-expect (change-score 10 LOF2 LOF3) 20)
(check-expect (change-score 10 LOF2  '()) 30)
(check-expect (change-score 10  '()  '()) 10)

(define (change-score s lof ne)
  (+ s
     (- (foldr (λ (f done) (cond [(symbol=? (food-ftype f) 'super) (+ 50 done)]
                                 [(symbol=? (food-ftype f) 'fruit) (+ 100 done)]
                                 [else (+ 10 done)])) 0 lof)
        (foldr (λ (f done) (cond [(symbol=? (food-ftype f) 'super) (+ 50 done)]
                                 [(symbol=? (food-ftype f) 'fruit) (+ 100 done)]
                                 [else (+ 10 done)])) 0 ne))))

;;; next-world : World -> World

(define WORLD1 (make-world PM0 LOF LOG 20 2 0))

(define (next-world w)
  (local [(define NOT-EATEN (eat-check (world-pm w) (world-lof w)))
          (define PM (world-pm w))
          (define LOF (world-lof w))
          (define LOG (world-log w))
          (define TICKS (world-ticks w))]
    (if (log-eating? LOG PM)
        (new-game w)
        (make-world
         (move (if (symbol=? (pm-es PM) 'ghost)
                   (change-es-help PM LOF)
                   (change-es? PM LOF)))
         (if (= (world-ticks w) CHERRY-IN)
             (cons (make-food (make-posn 14 14) 'fruit) NOT-EATEN)
             NOT-EATEN)
         (move-log PM LOG)
         (change-score (world-score w) LOF NOT-EATEN)
         (world-lives w)
         (add1 TICKS)))))

;;; player-move : World KeyEvent -> World
;;; Change Pac-Man's direction with the arrow keys

(check-expect (player-move WORLD1 "left")
              (make-world (make-pm (make-posn 14 8) 'left 'normal 0)
                          LOF LOG 20 2 0))
(check-expect (player-move WORLD1 "right")
              (make-world (make-pm (make-posn 14 8) 'right 'normal 0)
                          LOF LOG 20 2 0))
(check-expect (player-move WORLD1 "up")
              (make-world (make-pm (make-posn 14 8) 'up 'normal 0)
                          LOF LOG 20 2 0))
(check-expect (player-move WORLD1 "down")
              (make-world (make-pm (make-posn 14 8) 'down 'normal 0)
                          LOF LOG 20 2 0))
(check-expect (player-move WORLD1 "e") WORLD1)

(define (player-move w ke)
  (local [(define PM (world-pm w))
          (define (key dir) (key=? ke dir))]
    (make-world
     (make-pm (pm-posn (world-pm w))
              (if (or (key "left")
                      (key "right")
                      (key "up")
                      (key "down"))
                  (string->symbol ke)
                  (pm-dir (world-pm w)))
              (pm-es (world-pm w))
              (pm-gc (world-pm w)))
     (world-lof w)
     (world-log w)
     (world-score w)
     (world-lives w)
     (world-ticks w))))

;;; finished? : World -> Boolean
;;; Is Pac-Man dead or has all food been eaten?

(define (finished? w)
  (or (dead? w) (food-eaten? w)))

;;; end-world->scene : World -> Image
(define (end-world->scene w)
  (lof->scene
   (world-lof w)
   (score->scene
    (world-score w)
    (lives->scene
     (world-lives w)
     ALL-BARRIERS))))

;;; final-screen : World -> Image
;;; The result screen

(define (final-screen w)
  (if (dead? w)
      (place-image/block (text "GAME      OVER" PIXELS/BLOCK "red") 13.5 14
                         (end-world->scene w))
      (log->scene
       (world-pm w) (world-log w)
       (pm->scene
        (world-pm w)
        (lof->scene
         (world-lof w)
         (score->scene
          (world-score w)
          (lives->scene
           (world-lives w)
           ALL-BARRIERS-WHITE)))))))

;;; play-pacman : World -> World
;;; Play Pac-Man
(big-bang WORLD1
  [to-draw world->scene]
  [on-tick next-world TICK-RATE]
  [on-key  player-move]
  [stop-when finished? final-screen])