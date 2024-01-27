import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.Stack;
import tester.*;
import javalib.impworld.*;
import java.awt.Color;
import javalib.worldimages.*;

// Represents constant values in the game
interface IConstants {
  // Represents the side length of each cell (square)
  static int CELL_DIM = 50;
  // Represents player one's cell color
  static Color P1_COLOR = Color.blue;
  // Represents player two's cell color
  static Color P2_COLOR = Color.green;
}

// Represents a singular cell on the game board
class Cell implements IConstants {
  Color color;    // color of cell
  int x;          // x-coordinate of cell
  int y;          // y-coordinate of cell
  Cell top;       // cell directly above this
  Cell bot;       // cell directly below this
  Cell left;      // cell directly left of this
  Cell right;     // cell directly right of this
  boolean isEdge; // represents whether or not an edge cell
  
  // starting constructor
  Cell(int x, int y) {
    this.x = x;
    this.y = y;
    this.isEdge = false;
  }

  // testing constructor
  Cell(Color c, int x, int y) {
    this.color = c;
    this.x = x;
    this.y = y;
    this.isEdge = false;
  }

  // Draws this Cell at the given x- and y-coordinates onto the given WorldScene
  public WorldScene drawAt(int x, int y, WorldScene background) {
    background.placeImageXY(new RectangleImage(CELL_DIM, CELL_DIM, "solid", this.color), x, y);
    return background;
  }
  
  // Determines if this is the same as the given object
  public boolean equals(Object o) {
    if (o instanceof Cell) {
      Cell that = (Cell)o;
      return this.color == that.color
          && this.x == that.x
          && this.y == that.y
          && this.isEdge == that.isEdge;
    }
    return false;
  }
  
  // Returns the hashCode of this
  public int hashCode() {
    return this.x * this.y * 37;
  }
}

// Represents aspects of the BridgIt game
class BridgItGame extends World implements IConstants {
  int n; // board dimensions n x n
  ArrayList<Cell> cells; // board cells
  boolean turn; // true for player one, false for player two
  
  // main constructor
  BridgItGame(int n) {
    BridgItUtils u = new BridgItUtils();
    this.n = u.checkOdd(n, "n must be odd and at least 3");
    this.cells = this.makeCells();
    this.turn = true; // begins on player one
  }
  
  // convenience constructor
  BridgItGame(int n, boolean turn) {
    BridgItUtils u = new BridgItUtils();
    this.n = u.checkOdd(n, "n must be odd and at least 3");
    this.cells = this.makeCells(); 
    this.turn = turn;
  }
  
  // convenience constructor
  BridgItGame(int n, ArrayList<Cell> cells, boolean turn) {
    BridgItUtils u = new BridgItUtils();
    this.n = u.checkOdd(n, "n must be odd and at least 3");
    this.cells = cells;
    this.turn = turn;
  }
  
  // Creates the starting cells of the game
  public ArrayList<Cell> makeCells() {
    // List of cells to be added to
    ArrayList<Cell> newCells = new ArrayList<Cell>();
    for (int x = 0; x < this.n; x++) {
      for (int y = 0; y < this.n; y++) {
        
        // Creates a new, colored cell at the current coordinates
        Cell c = new Cell(x,y);
        this.giveColorTo(c,x,y);
        
        // Makes the cell an edge cell based on the given coordinates
        if (this.isEdgeCell(x,y)) {
          c.isEdge = true;
        }
        
        // Makes links between cells
        this.linkCells(newCells, c);
        // Adds the created cell to the end of the already generated list
        newCells.add(c);
      }
    }
    return newCells;
  }
  
  // Gives color to the given Cell based on its given x- and y-coordinates
  public void giveColorTo(Cell c, int x, int y) {
    if ((y % 2) != 0 && (x % 2) == 0) { //even x, odd y
      c.color = P1_COLOR;
    }
    else if ((y % 2) == 0 && (x % 2) != 0) { //odd x, even y
      c.color = P2_COLOR;
    }
    else {
      c.color = Color.white;
    }
  }
  
  // Determines whether or not the given cell is on the edge of the board
  public boolean isEdgeCell(int x, int y) {
    return x == 0 
        || x == this.n - 1 
        || y == 0 
        || y == this.n - 1;
  }
  
  // Link each Cell in the given list as needed to the given Cell
  public void linkCells(ArrayList<Cell> cells, Cell c) {
    for (Cell cell : cells) {
      if (c.x - cell.x == 1 && c.y == cell.y) { //is c to the right of the cell?
        c.left = cell;
        cell.right = c;
      }
      else if (cell.x - c.x == 1 && c.y == cell.y) { // is c to the left of the cell?
        cell.left = c;
        c.right = cell;
      }
      else if (c.y - cell.y == 1 && c.x == cell.x) { // is c above the cell?
        c.top = cell;
        cell.bot = c;
      }
      else if (cell.y - c.y == 1 && c.x == cell.x) { // is c below the cell?
        cell.top = c;
        c.bot = cell;
      }
    }
  }

  @Override
  // Draws each cell of this game onto a blank scene
  public WorldScene makeScene() {
    int worldWidth = this.n * CELL_DIM; // width of the game screen
    int worldHeight = this.n * CELL_DIM; // height of the game screen
    WorldScene w = new WorldScene(worldWidth, worldHeight);
    for (Cell cell : this.cells) {
      cell.drawAt(this.scaleCoord(cell.x), this.scaleCoord(cell.y), w);
    }
    return w;
  }
  
  // Scales the given coordinate based on the dimensions of this BridgItGame
  public int scaleCoord(int coord) {
    return (CELL_DIM / 2) * (coord * 2 + 1);
  }
  
  // Handles changes in the game
  public void onTick() {
    // If there is a path from the left to the right edge of the board,
    // then end the game and declare that player one has won
    if (this.hasPathLeftToRight()) {
      this.endOfWorld("Player one has won!");
    }
    // If there is a path from the top to the bottom edge of the board,
    // then end the game and declare that player two has won
    if (this.hasPathTopToBottom()) {
      this.endOfWorld("Player two has won!");
    }
  }
  
  // Handles mouse clicks
  public void onMouseClicked(Posn p) {
    // Represents the assignment of the game's cells to posns
    HashMap<Posn, Cell> posnCells = new HashMap<Posn, Cell>();

    // Assigns each game cell to a posn and puts it into the hashmap
    int index = 0;
    for (int x = 0; x < this.n; x++) {
      for (int y = 0; y < this.n; y++) {
        Posn posn = new Posn(x, y);
        posnCells.put(posn, this.cells.get(index));
        index++;
      }
    }
    // Converts the posn of a mouse click to be in the correct cell range
    Posn convertedPosn = new Posn(p.x / CELL_DIM, p.y / CELL_DIM);
    
    // Gets the cell at the converted posn to change its color
    Cell clickedCell = posnCells.get(convertedPosn);
    Color clickedColor1 = clickedCell.color;
    this.changeCellColor(clickedCell);
    
    // Can still be the same after clicking an unchangeable cell
    Color clickedColor2 = clickedCell.color;
    this.changeTurn(clickedColor1, clickedColor2);

  }
  
  // Changes the color of a clicked changeable cell
  public void changeCellColor(Cell clickedCell) {
    if (!clickedCell.isEdge && clickedCell.color.equals(Color.white)) {
      if (this.turn) {
        clickedCell.color = P1_COLOR;
      }
      else if (!this.turn) {
        clickedCell.color = P2_COLOR;
      }
    }
  }
  
  // Changes which player's turn it is, if a cell's color has been changed
  public void changeTurn(Color before, Color after) {
    if (this.turn && !before.equals(after)) {
      this.turn = false; // -> player two
    }
    else if (!this.turn && !before.equals(after)) {
      this.turn = true; // -> player one
    }
  }
  
  // Checks if player one has a path from the left to the right edge of the board
  public boolean hasPathLeftToRight() {
    Stack<Cell> leftEdge = new Stack<Cell>();
    this.makeCellCollection(leftEdge, 0, P1_COLOR);
    ArrayList<Cell> rightEdge = new ArrayList<Cell>();
    this.makeCellCollection(rightEdge, this.n * (this.n - 1), P1_COLOR);
    return this.hasPathFromTo(P1_COLOR, leftEdge, rightEdge);
  }
  
  // Checks if player two has a path from the top to the bottom edge of the board
  public boolean hasPathTopToBottom() {
    Stack<Cell> topEdge = new Stack<Cell>();
    this.makeCellCollection(topEdge, this.n, P2_COLOR);
    ArrayList<Cell> botEdge = new ArrayList<Cell>();
    this.makeCellCollection(botEdge, 2 * this.n - 1, P2_COLOR);
    return this.hasPathFromTo(P2_COLOR, topEdge, botEdge);
  }
  
  // Makes a collection of cells of the given color from one column or row
  public Collection<Cell> makeCellCollection(Collection<Cell> collection, 
      int convert, Color color) {
    for (int index = 0; index < this.n; index++) {
      if (color.equals(P1_COLOR)) {
        Cell c = this.cells.get(index + convert);
        if (c.color.equals(P1_COLOR)) {
          collection.add(c);
        }
      }
      if (color.equals(P2_COLOR)) {
        Cell c = this.cells.get(index * this.n + (convert - this.n));
        if (c.color.equals(P2_COLOR)) {
          collection.add(c);
        }
      }
    }
    return collection;
  }
  
  // Checks if a player has a created a path from one side of the board to the opposite
  public boolean hasPathFromTo(Color color, Stack<Cell> worklist, ArrayList<Cell> endEdge) {
    // Represents the cells already seen
    ArrayList<Cell> alreadySeen = new ArrayList<Cell>();

    while (worklist.size() > 0) {
      Cell next = worklist.pop();
      if (endEdge.contains(next)) {
        return true;
      }
      else {
        alreadySeen.add(next);
        // neighbors of the current cell
        ArrayList<Cell> neighbors = new ArrayList<Cell>(
            Arrays.asList(next.top, next.bot, next.left, next.right));
        for (Cell neighbor : neighbors) {
          // Doesn't add to worklist if null, already checked, or the wrong color
          if (neighbor != null && !alreadySeen.contains(neighbor) 
              && neighbor.color.equals(color)) {
            worklist.add(neighbor);
          }
        }
      }
    }
    return false;
  }
  
  // Renders the winning scene
  public WorldScene lastScene(String msg) {
    WorldScene w = this.makeScene();
    int worldWidth = this.n * CELL_DIM; // width of the game screen
    int worldHeight = this.n * CELL_DIM; // height of the game screen
    w.placeImageXY(new TextImage(msg, CELL_DIM / 2, FontStyle.REGULAR, Color.BLACK),
        (worldWidth / 2), (worldHeight / 2));
    return w;
  }
}

// Sets restrictions on constructors
class BridgItUtils {
  // Checks if the given number is odd and at least 3, and throws an exception if not
  int checkOdd(int n, String msg) {
    if ((n % 2) != 0 && n >= 3) {
      return n;
    }
    throw new IllegalArgumentException(msg);
  }
}

// Represents examples of game data and tests for their methods
class ExamplesBridgIt implements IConstants {
  // Cell examples
  Cell c1;
  Cell c2;
  Cell c3;
  Cell c4;
  
  // BridgItGame examples
  BridgItGame bIG1;
  BridgItGame bIG2;
  BridgItGame bIG3;
  
  // WorldScene examples
  WorldScene scn1;
  WorldScene scn2;
  
  // Initializes examples of data
  void initData() {
    this.c1 = new Cell(Color.white,0,0);
    this.c2 = new Cell(P1_COLOR,7,10);
    this.c3 = new Cell(P2_COLOR,4,4);
    this.c4 = new Cell(P1_COLOR,10,7);
    
    this.bIG1 = new BridgItGame(11);
    this.bIG2 = new BridgItGame(5);
    this.bIG3 = new BridgItGame(3,true);
    
    this.scn1 = new WorldScene(11 * CELL_DIM,11 * CELL_DIM);
    this.scn2 = new WorldScene(5 * CELL_DIM,5 * CELL_DIM);
  }
  
  // tests the drawAt method in Cell
  void testDrawAt(Tester t) {
    this.initData();
    // Empty WorldScene representing the initial scene (11 x 11)
    WorldScene bg1 = new WorldScene(11 * CELL_DIM, 11 * CELL_DIM);
    t.checkExpect(this.scn1, new WorldScene(11 * CELL_DIM, 11 * CELL_DIM));
    
    // Draws a cell onto the blank scene
    this.c2.drawAt(375,525,this.scn1);
    WorldImage sqr1 = new RectangleImage(CELL_DIM,CELL_DIM,"solid",P1_COLOR);
    bg1.placeImageXY(sqr1,375,525);
    
    // Tests that the scene is no longer empty
    t.checkExpect(this.scn1, bg1);
    
    // Empty WorldScene representing the initial scene (5 x 5)
    WorldScene bg2 = new WorldScene(5 * CELL_DIM, 5 * CELL_DIM);
    t.checkExpect(this.scn2, new WorldScene(5 * CELL_DIM, 5 * CELL_DIM));
    
    // Draws a cell onto the blank scene
    this.c3.drawAt(225, 225, this.scn2);
    WorldImage sqr2 = new RectangleImage(CELL_DIM,CELL_DIM,"solid",P2_COLOR);
    bg2.placeImageXY(sqr2,225,225);
    
    // Tests that the scene is no longer empty
    t.checkExpect(this.scn2, bg2);
  }
  
  // tests the equals method in Cell
  void testEquals(Tester t) {
    this.initData();
    Cell c1 = new Cell(Color.white,0,0);
    Cell c2 = new Cell(P1_COLOR,7,10);
    Cell c3 = new Cell(P2_COLOR,2,2);
    // tests two of the same edge cells
    this.c1.isEdge = true;
    c1.isEdge = true;
    t.checkExpect(this.c1.equals(c1), true);
    // tests two of the same non-edge cells
    t.checkExpect(this.c2.equals(c2), true);
    // tests two different edge cells
    c2.isEdge = true;
    t.checkExpect(this.c1.equals(this.c2), false);
    // tests an two different non-edge cells
    t.checkExpect(this.c3.equals(c3), false);
  }
  
  // tests the hashCode method in Cell
  void testHashCode(Tester t) {
    this.initData();
    t.checkExpect(this.c1.hashCode(), 0);
    t.checkExpect(this.c2.hashCode(), 2590);
    t.checkExpect(this.c3.hashCode(), 592);
  }
  
  // tests the makeCells method in BridgItGame
  void testMakeCells(Tester t) {
    this.initData();
    
    // Creates new cells and gives them colors
    Cell cell1 = new Cell(0,0);
    cell1.color = Color.white;
    Cell cell2 = new Cell(0,1);
    cell2.color = P1_COLOR;
    Cell cell3 = new Cell(0,2);
    cell3.color = Color.white;
    Cell cell4 = new Cell(1,0);
    cell4.color = P2_COLOR;
    Cell cell5 = new Cell(1,1);
    cell5.color = Color.white;
    Cell cell6 = new Cell(1,2);
    cell6.color = P2_COLOR;
    Cell cell7 = new Cell(2,0);
    cell7.color = Color.white;
    Cell cell8 = new Cell(2,1);
    cell8.color = P1_COLOR;
    Cell cell9 = new Cell(2,2);
    cell9.color = Color.white;
    
    // Declares them as edge cells if necessary
    cell1.isEdge = true;
    cell2.isEdge = true;
    cell3.isEdge = true;
    cell4.isEdge = true;
    cell6.isEdge = true;
    cell7.isEdge = true;
    cell8.isEdge = true;
    cell9.isEdge = true;
    
    // Links cells
    cell1.right = cell4;
    cell4.left = cell1;
    cell1.bot = cell2;
    cell2.top = cell1;
    cell2.right = cell5;
    cell5.left = cell2;
    cell2.bot = cell3;
    cell3.top = cell2;
    cell3.right = cell6;
    cell6.left = cell3;
    cell4.right = cell7;
    cell7.left = cell4;
    cell4.bot = cell5;
    cell5.top = cell4;
    cell5.right = cell8;
    cell8.left = cell5;
    cell5.bot = cell6;
    cell6.top = cell5;
    cell6.right = cell9;
    cell9.left = cell6;
    cell7.bot = cell8;
    cell8.top = cell7;
    cell8.bot = cell9;
    cell9.top = cell8;
    
    // List of cells in the game
    ArrayList<Cell> arrCell = 
        new ArrayList<Cell>(
            Arrays.asList(cell1, cell2, cell3, cell4, cell5, cell6, cell7, cell8, cell9));
    
    t.checkExpect(this.bIG3.makeCells(), arrCell);
  }
  
  // tests the giveColorTo method in BridgItGame
  void testGiveColorTo(Tester t) {
    this.initData();
    // Tests a cell with even coordinates (top left corner)
    this.bIG1.giveColorTo(this.c1, this.c1.x, this.c1.y);
    t.checkExpect(this.c1.color, Color.white);
    // Tests a cell with odd x, even y
    this.bIG1.giveColorTo(this.c2, this.c2.x, this.c2.y);
    t.checkExpect(this.c2.color, P2_COLOR);
    // Tests a cell with even coordinates (bottom right corner)
    this.bIG1.giveColorTo(this.c3, this.c3.x, this.c3.y);
    t.checkExpect(this.c3.color, Color.white);
    // Tests a cell with even x, odd y
    this.bIG1.giveColorTo(this.c4, this.c4.x, this.c4.y);
    t.checkExpect(this.c4.color, P1_COLOR);
  }
  
  // tests the isEdgeCell method in BridgItGame
  void testIsEdgeCell(Tester t) {
    this.initData();
    // Tests for a cell in a corner (any game)
    t.checkExpect(this.bIG1.isEdgeCell(0,0), true);
    // Tests for a cell in a corner (5 x 5)
    t.checkExpect(this.bIG2.isEdgeCell(4,4), true);
    // Tests for a cell in a corner (11 x 11)
    t.checkExpect(this.bIG1.isEdgeCell(10,10), true);
    // Tests for a cell in the middle of the board
    t.checkExpect(this.bIG2.isEdgeCell(3,3), false);
    // Tests for a cell with one edge coordinate (x)
    t.checkExpect(this.bIG1.isEdgeCell(10,1), true);
    // Tests for a cell with one edge coordinate (y)
    t.checkExpect(this.bIG1.isEdgeCell(1,10), true);
    // Tests for a cell with two inequivalent edge coordinates
    t.checkExpect(this.bIG1.isEdgeCell(0,4), true);
  }
  
  // tests the linkCells method in BridgItGame
  void testLinkCells(Tester t) {
    this.initData();
    Cell cell1 = new Cell(0,1);
    Cell cell2 = new Cell(1,0);
    Cell cell3 = new Cell(2,4);
    ArrayList<Cell> arrCell = new ArrayList<Cell>(Arrays.asList(cell1,cell2,cell3));
    
    // Before links
    t.checkExpect(this.c1.bot, null);
    t.checkExpect(cell1.top, null);
    t.checkExpect(this.c1.right, null);
    t.checkExpect(cell2.left, null);
    
    // Game partially made, linking a new cell to the cells so far
    BridgItGame game = new BridgItGame(5,arrCell,true);
    game.linkCells(arrCell, this.c1);
    
    // After links
    t.checkExpect(this.c1.bot, cell1);
    t.checkExpect(cell1.top, this.c1);
    t.checkExpect(this.c1.right, cell2);
    t.checkExpect(cell2.left, this.c1);
  }
  
  // tests the makeScene method in BridgItGame
  void testMakeScene(Tester t) {
    this.initData();
    
    // Draws each cell onto a blank WorldScene
    WorldScene w = new WorldScene(this.bIG3.n * CELL_DIM, this.bIG3.n * CELL_DIM);
    this.bIG3.cells.get(0).drawAt(25, 25, w);
    this.bIG3.cells.get(1).drawAt(25, 75, w);
    this.bIG3.cells.get(2).drawAt(25, 125, w);
    this.bIG3.cells.get(3).drawAt(75, 25, w);
    this.bIG3.cells.get(4).drawAt(75, 75, w);
    this.bIG3.cells.get(5).drawAt(75, 125, w);
    this.bIG3.cells.get(6).drawAt(125, 25, w);
    this.bIG3.cells.get(7).drawAt(125, 75, w);
    this.bIG3.cells.get(8).drawAt(125, 125, w);
    
    // Tests on a 3x3 board
    t.checkExpect(this.bIG3.makeScene(), w);
  }
  
  // tests the scaleCoord method in BridgItGame
  void testScaleCoord(Tester t) {
    this.initData();
    t.checkExpect(this.bIG1.scaleCoord(7), 375);
    t.checkExpect(this.bIG1.scaleCoord(10), 525);
    t.checkExpect(this.bIG1.scaleCoord(0), 25);
  }
  
  // tests the onMouseClicked method in BridgItGame
  void testOnMouseClicked(Tester t) {
    // Does not change color of cell
    Posn p = new Posn(1,1);
    HashMap<Posn,Cell> posnCells = new HashMap<Posn,Cell>();
    
    // Assigns each game cell to a posn and puts it into the hashmap
    int index = 0;
    for (int x = 0; x < this.bIG3.n; x++) {
      for (int y = 0; y < this.bIG3.n; y++) {
        Posn posn = new Posn(x, y);
        posnCells.put(posn, this.bIG3.cells.get(index));
        index++;
      }
    }
    
    // Converts the posn of a mouse click to be in the correct cell range
    Posn convertedPosn = new Posn(p.x / CELL_DIM, p.y / CELL_DIM);
    t.checkExpect(convertedPosn, new Posn(1 / 50, 1 / 50));
    
    // Gets the cell at the converted posn to change its color
    Cell clickedCell = posnCells.get(convertedPosn);
    
    Color clickedColor1 = clickedCell.color;
    t.checkExpect(clickedColor1, Color.white);
    this.bIG3.changeCellColor(clickedCell);
    // Can still be the same after clicking an unchangeable cell
    Color clickedColor2 = clickedCell.color;
    t.checkExpect(clickedColor2, Color.white);
    
    t.checkExpect(this.bIG3.turn, true);
    this.bIG3.changeTurn(clickedColor1, clickedColor2);
    t.checkExpect(this.bIG3.turn, true);
    
    // Changes a cell's color to player one's color
    Posn p2 = new Posn(51,51);
    HashMap<Posn,Cell> posnCells2 = new HashMap<Posn,Cell>();
    
    // Assigns each game cell to a posn and puts it into the hashmap
    int index2 = 0;
    for (int x = 0; x < this.bIG3.n; x++) {
      for (int y = 0; y < this.bIG3.n; y++) {
        Posn posn = new Posn(x, y);
        posnCells2.put(posn, this.bIG3.cells.get(index2));
        index2++;
      }
    }
    // Converts the posn of a mouse click to be in the correct cell range
    Posn convertedPosn2 = new Posn(p2.x / CELL_DIM, p2.y / CELL_DIM);
    t.checkExpect(convertedPosn2, new Posn(51 / 50, 51 / 50));
    
    // Gets the cell at the converted posn to change its color
    Cell clickedCell2 = posnCells2.get(convertedPosn2);
    
    Color clickedColor3 = clickedCell2.color;
    t.checkExpect(clickedColor3, Color.white);
    this.bIG3.changeCellColor(clickedCell2);
    // Can still be the same after clicking an unchangeable cell
    Color clickedColor4 = clickedCell2.color;
    t.checkExpect(clickedColor4, P1_COLOR);
    
    t.checkExpect(this.bIG3.turn, true);
    this.bIG3.changeTurn(clickedColor3, clickedColor4);
    t.checkExpect(this.bIG3.turn, false);
  }
  
  // tests the changeCellColor method in BridgItGame
  void testChangeCellColor(Tester t) {
    this.initData();
    // tests on an edge cell
    c1.isEdge = true;
    t.checkExpect(this.c1.color, Color.white);
    this.bIG1.changeCellColor(this.c1);
    t.checkExpect(this.c1.color, Color.white);
    
    // tests on a non-edge, white cell
    Cell changeableCell = new Cell(Color.white,4,4);
    t.checkExpect(changeableCell.color, Color.white);
    this.bIG1.changeCellColor(changeableCell);
    t.checkExpect(changeableCell.color, P1_COLOR);
    
    // tests on a colored cell
    Cell coloredCell = new Cell(P2_COLOR,3,4);
    t.checkExpect(coloredCell.color, P2_COLOR);
    this.bIG1.changeCellColor(coloredCell);
    t.checkExpect(coloredCell.color, P2_COLOR);
  }
  
  // tests the changeTurn method in BridgItGame
  void testChangeTurn(Tester t) {
    this.initData();
    // Starts on player one's turn
    t.checkExpect(this.bIG1.turn, true);
    // Clicked cell doesn't change color
    this.bIG1.changeTurn(P1_COLOR,P1_COLOR);
    // Still player one's turn
    t.checkExpect(this.bIG1.turn, true);
    // Clicked cell changes color
    this.bIG1.changeTurn(Color.white, P2_COLOR);
    // Changes to player two's turn
    t.checkExpect(this.bIG1.turn, false);
  }
  
  // tests the makeCellCollection method in BridgItGame
  void testMakeCellCollection(Tester t) {
    this.initData();
    // Makes a collection of colored cells from the first column
    Cell c1 = this.bIG2.cells.get(1);
    Cell c2 = this.bIG2.cells.get(3);
    Stack<Cell> columnOne = new Stack<Cell>();
    columnOne.add(c1);
    columnOne.add(c2);
    t.checkExpect(this.bIG2.makeCellCollection(new Stack<Cell>(), 0, P1_COLOR), columnOne);
    
    // Makes a collection of colored cells from the last column
    Cell c3 = this.bIG2.cells.get(21);
    Cell c4 = this.bIG2.cells.get(23);
    ArrayList<Cell> lastColumn5 = new ArrayList<Cell>(Arrays.asList(c3,c4));
    t.checkExpect(this.bIG2.makeCellCollection(new ArrayList<Cell>(), 20, P1_COLOR), lastColumn5);
    
    // Makes a collection of colored cells from the last column
    Cell c5 = this.bIG1.cells.get(111);
    Cell c6 = this.bIG1.cells.get(113);
    Cell c7 = this.bIG1.cells.get(115);
    Cell c8 = this.bIG1.cells.get(117);
    Cell c9 = this.bIG1.cells.get(119);
    ArrayList<Cell> lastColumn11 = new ArrayList<Cell>(Arrays.asList(c5,c6,c7,c8,c9));
    t.checkExpect(
        this.bIG1.makeCellCollection(new ArrayList<Cell>(), 110, P1_COLOR), lastColumn11);
    
    // Makes a collection of colored cells from the last row
    Cell c10 = this.bIG3.cells.get(5);
    ArrayList<Cell> lastRow3 = new ArrayList<Cell>(Arrays.asList(c10));
    t.checkExpect(
        this.bIG3.makeCellCollection(new ArrayList<Cell>(), 5, P2_COLOR), lastRow3);
    
    // Makes a collection of colored cells from the first row
    Cell c11 = this.bIG2.cells.get(5);
    Cell c12 = this.bIG2.cells.get(15);
    Stack<Cell> rowOne = new Stack<Cell>();
    rowOne.add(c11);
    rowOne.add(c12);
    t.checkExpect(
        this.bIG2.makeCellCollection(new Stack<Cell>(), 5, P2_COLOR), rowOne);
  }
  
  // tests the hasPathFromTo (hasPathLeftToRight, hasPathTopToBottom) method in BridgItGame
  void testHasPathFromTo(Tester t) {
    this.initData();
    // 5 x 5 game, player one wins
    // left (start) edge
    Stack<Cell> worklist = new Stack<Cell>();
    Cell c1 = this.bIG2.cells.get(1);  
    Cell c2 = this.bIG2.cells.get(3);
    worklist.add(c1);
    worklist.add(c2);
    
    Cell c3 = this.bIG2.cells.get(21);
    Cell c4 = this.bIG2.cells.get(23);
    // right edge
    ArrayList<Cell> endEdge = new ArrayList<Cell>(Arrays.asList(c3,c4));
    
    // Creates a straight horizontal path from left to right edge
    Cell c1Right = this.bIG2.cells.get(6);
    c1Right.color = P1_COLOR;
    c1.right = c1Right;
    Cell c1Right2 = this.bIG2.cells.get(11);
    c1Right.right = c1Right2;
    Cell c1Right3 = this.bIG2.cells.get(16);
    c1Right3.color = P1_COLOR;
    c1Right2.right = c1Right3;
    Cell c1Right4 = this.bIG2.cells.get(21);
    c1Right3.right = c1Right4;
    
    // Checks that final linked cell is on the opposite edge
    t.checkExpect(c1Right4.equals(c3), true);
    
    // Tests on a game with a winning path for player one
    t.checkExpect(this.bIG2.hasPathLeftToRight(), true);
    t.checkExpect(this.bIG2.hasPathFromTo(P1_COLOR, worklist, endEdge), true);

    // 5 x 5 game, player two wins
    // top (start) edge
    Stack<Cell> worklist2 = new Stack<Cell>();
    Cell c5 = this.bIG2.cells.get(5);  
    Cell c6 = this.bIG2.cells.get(10);
    worklist2.add(c5);
    worklist2.add(c6);
    
    Cell c7 = this.bIG2.cells.get(9);
    Cell c8 = this.bIG2.cells.get(14);
    // bottom edge
    ArrayList<Cell> endEdge2 = new ArrayList<Cell>(Arrays.asList(c7,c8));
    
    // Creates a straight vertical path from top to bottom edge
    Cell c5Bot1 = this.bIG2.cells.get(6);
    c5Bot1.color = P2_COLOR;
    c5.bot = c5Bot1;
    Cell c5Bot2 = this.bIG2.cells.get(7);
    c5Bot1.bot = c5Bot2;
    Cell c5Bot3 = this.bIG2.cells.get(8);
    c5Bot3.color = P2_COLOR;
    c5Bot2.bot = c5Bot3;
    Cell c5Bot4 = this.bIG2.cells.get(9);
    c1Right3.bot = c5Bot4;
    
    // Checks that final linked cell is on the opposite edge
    t.checkExpect(c5Bot4.equals(c7), true);
    
    // Tests on a game with a winning path for player two
    t.checkExpect(this.bIG2.hasPathTopToBottom(), true);
    t.checkExpect(this.bIG2.hasPathFromTo(P2_COLOR, worklist2, endEdge2), true);
  }
  
  // tests the lastScene method in BridgItGame
  void testLastScene(Tester t) {
    this.initData();
    WorldScene w = this.bIG1.makeScene();
    int worldWidth = this.bIG1.n * CELL_DIM;
    int worldHeight = this.bIG1.n * CELL_DIM;
    w.placeImageXY(new TextImage("Player one wins", CELL_DIM / 2, FontStyle.REGULAR, Color.BLACK),
        (worldWidth / 2), (worldHeight / 2));
    t.checkExpect(this.bIG1.lastScene("Player one wins"), w);
    
    WorldScene w2 = this.bIG2.makeScene();
    int worldWidth2 = this.bIG2.n * CELL_DIM; 
    int worldHeight2 = this.bIG2.n * CELL_DIM; 
    w2.placeImageXY(new TextImage("Player two wins", CELL_DIM / 2, FontStyle.REGULAR, Color.BLACK),
        (worldWidth2 / 2), (worldHeight2 / 2));
    t.checkExpect(this.bIG2.lastScene("Player two wins"), w2);
  }
  
  // tests the checkOdd method in BridgItUtils
  void testCheckOdd(Tester t) {
    this.initData();
    BridgItUtils u = new BridgItUtils();
    // tests on odd numbers with values of at least 3
    t.checkExpect(u.checkOdd(3, "must be odd and at least 3"), 3);
    t.checkExpect(u.checkOdd(5, "must be odd and at least 3"), 5);
    t.checkExpect(u.checkOdd(11, "must be odd and at least 3"), 11);
    // tests an odd number less than 3
    t.checkException(new IllegalArgumentException("must be odd and at least 3"), 
        u, "checkOdd", 1, "must be odd and at least 3");
    // tests an even number less than 3
    t.checkException(new IllegalArgumentException("must be odd and at least 3"), 
        u, "checkOdd", 2, "must be odd and at least 3");
    // tests an even number greater than 3
    t.checkException(new IllegalArgumentException("must be odd and at least 3"), 
        u, "checkOdd", 4, "must be odd and at least 3");
  }
  
  // tests and renders the game
  void testGame(Tester t) {
    this.initData();
    int fiveByFive = 5 * CELL_DIM;
    int mainGameDim = 11 * CELL_DIM;
    int threeByThree = 3 * CELL_DIM;
    this.bIG1.bigBang(mainGameDim, mainGameDim, 0.001);
  }
}