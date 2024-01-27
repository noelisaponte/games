import java.util.ArrayList;
import java.util.Arrays;
import java.util.Random;
import javalib.impworld.World;
import javalib.impworld.WorldScene;
import tester.Tester;
import java.awt.Color;
import javalib.worldimages.*;

// Represents an individual tile
class Tile {
  // Constants for world/game window dimensions
  static int WORLD_WIDTH = 200;
  static int WORLD_HEIGHT = 200;

  // The number on the tile. Use 0 to represent the space
  int value;
  int x;
  int y;

  // convenience constructor
  Tile(int value, int x, int y) {
    this.value = value;
    this.x = x;
    this.y = y;
  }

  // starting constructor
  Tile(int x, int y) {
    this.x = x;
    this.y = y;
  }

  // Draws this Tile at the given column and row on the background
  WorldScene drawAt(int col, int row, WorldScene background) {
    // Represents the blank tile
    if (value == 0) {
      return background;
    }

    Color tileColor = Color.black;
    int expectedValue = (this.x - 1) + (this.y - 1) * 4 + 1;

    // Changes the color of the tile if in the correct position
    if (value == expectedValue) {
      tileColor = Color.GREEN;
    }

    background.placeImageXY(new OverlayImage(new TextImage(this.value + "", 30, tileColor),
        new RectangleImage(WORLD_WIDTH / 4, WORLD_HEIGHT / 4, "outline", tileColor)), col, row);
    return background;
  }

  // Checks to see if this is the same as the given Object
  public boolean equals(Object o) {
    if (o instanceof Tile) {
      Tile that = (Tile) o;
      return that.value == this.value && that.x == this.x && that.y == this.y;
    }
    return false;
  }

  // Returns the hash code of this Tile
  public int hashCode() {
    return this.value * this.x * this.y * 37;
  }
}

// Represents the game
class FifteenGame extends World {
  static int WORLD_WIDTH = 200;
  static int WORLD_HEIGHT = 200;

  // represents the tiles
  ArrayList<ArrayList<Tile>> tiles;
  String prevKey;
  Random r;

  // convenience constructor
  FifteenGame(ArrayList<ArrayList<Tile>> tiles) {
    this.tiles = tiles;
  }

  // starting constructor
  FifteenGame() {
    this(new Random());
  }

  // constructor for testing
  FifteenGame(Random r) {
    this.r = r;
    this.blankArray();
    this.numberArray();
  }

  // EFFECT: Creates a 4x4 grid with empty tiles
  void blankArray() {
    tiles = new ArrayList<>();
    for (int col = 1; col < 5; col++) {
      ArrayList<Tile> arrTile = new ArrayList<>();
      for (int row = 1; row < 5; row++) {
        Tile t = new Tile(col, row);
        arrTile.add(t);
      }
      tiles.add(arrTile);
    }
  }

  // EFFECT: Creates a 4x4 grid with numbered tiles
  void numberArray() {
    ArrayList<Integer> arrInt = new ArrayList<Integer>(
        Arrays.asList(0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15));
    for (ArrayList<Tile> arrTile : tiles) {
      for (Tile t : arrTile) {
        int randIndex = r.nextInt(arrInt.size());
        t.value = arrInt.get(randIndex);
        arrInt.remove(randIndex);
      }
    }
  }

  // draws the game
  public WorldScene makeScene() {
    WorldScene w = new WorldScene(WORLD_WIDTH, WORLD_HEIGHT);
    for (ArrayList<Tile> arr : tiles) {
      for (Tile t : arr) {
        t.drawAt(t.x * (WORLD_WIDTH / 8) + (WORLD_WIDTH / 8) * (t.x - 1),
            t.y * (WORLD_HEIGHT / 8) + (WORLD_HEIGHT / 8) * (t.y - 1), w);
      }
    }
    return w;
  }

  // determines if this game's tiles are in order
  public boolean tilesInOrder() {
    Tile t1 = new Tile(1, 1, 1);
    Tile t2 = new Tile(5, 1, 2);
    Tile t3 = new Tile(9, 1, 3);
    Tile t4 = new Tile(13, 1, 4);
    Tile t5 = new Tile(2, 2, 1);
    Tile t6 = new Tile(6, 2, 2);
    Tile t7 = new Tile(10, 2, 3);
    Tile t8 = new Tile(14, 2, 4);
    Tile t9 = new Tile(3, 3, 1);
    Tile t10 = new Tile(7, 3, 2);
    Tile t11 = new Tile(11, 3, 3);
    Tile t12 = new Tile(15, 3, 4);
    Tile t13 = new Tile(4, 4, 1);
    Tile t14 = new Tile(8, 4, 2);
    Tile t15 = new Tile(12, 4, 3);
    Tile t16 = new Tile(0, 4, 4);

    ArrayList<Tile> arrTile1 = new ArrayList<Tile>(Arrays.asList(t1, t2, t3, t4));
    ArrayList<Tile> arrTile2 = new ArrayList<Tile>(Arrays.asList(t5, t6, t7, t8));
    ArrayList<Tile> arrTile3 = new ArrayList<Tile>(Arrays.asList(t9, t10, t11, t12));
    ArrayList<Tile> arrTile4 = new ArrayList<Tile>(Arrays.asList(t13, t14, t15, t16));

    ArrayList<ArrayList<Tile>> arr = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile1, arrTile2, arrTile3, arrTile4));

    for (int outerIdx = 0; outerIdx < arr.size(); outerIdx++) {
      boolean result = true;
      for (int innerIdx = 0; innerIdx < arr.size(); innerIdx++) {
        if (!this.tiles.get(outerIdx).get(innerIdx).equals(arr.get(outerIdx).get(innerIdx))) {
          result = false;
        }
      }
      if (result) {
        return true;
      }
    }
    return false;
  }

  // Swaps the values of the given Tiles
  public void swapTiles(Tile t1, Tile t2) {
    int oldVal = t1.value;
    t1.value = t2.value;
    t2.value = oldVal;
  }

  // handles keystrokes
  public void onKeyEvent(String k) {
    if (this.tilesInOrder()) {
      this.endOfWorld("OK...");
    }
    int zeroTileIdx = 0;
    int zeroTileIdy = 0;
    Tile zeroTile = null;
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        if (tiles.get(i).get(j).value == 0) {
          zeroTile = tiles.get(i).get(j);
          zeroTileIdx = i;
          zeroTileIdy = j;
        }
      }
    }

    if (!k.equals("u")) {
      this.prevKey = k;
    }

    if (k.equals("up") && zeroTileIdy > 0) {
      this.swapTiles(zeroTile, tiles.get(zeroTileIdx).get(zeroTileIdy - 1));
    }
    else if (k.equals("down") && zeroTileIdy < 3) {
      this.swapTiles(zeroTile, tiles.get(zeroTileIdx).get(zeroTileIdy + 1));
    }
    else if (k.equals("left") && zeroTileIdx > 0) {
      this.swapTiles(zeroTile, tiles.get(zeroTileIdx - 1).get(zeroTileIdy));
    }
    else if (k.equals("right") && zeroTileIdx < 3) {
      this.swapTiles(zeroTile, tiles.get(zeroTileIdx + 1).get(zeroTileIdy));
    }
    // undo the previous swap
    else if (k.equals("u")) {
      if (this.prevKey.equals("up")) {
        this.onKeyEvent("down");
      }
      if (this.prevKey.equals("down")) {
        this.onKeyEvent("up");
      }
      if (this.prevKey.equals("left")) {
        this.onKeyEvent("right");
      }
      if (this.prevKey.equals("right")) {
        this.onKeyEvent("left");
      }

    }
  }

  // displays the winning screen
  public WorldScene lastScene(String msg) {
    WorldScene w = this.makeScene();
    w.placeImageXY(new TextImage(msg, 40, FontStyle.BOLD, Color.GREEN), (WORLD_WIDTH / 2),
        (WORLD_HEIGHT / 2));
    return w;
  }
}

// examples and tests for methods of the game
class ExampleFifteenGame {
  static int WORLD_WIDTH = 200;
  static int WORLD_HEIGHT = 200;

  // Tile examples
  Tile t1;
  Tile t2;
  Tile t3;
  Tile t4;
  Tile t5;
  Tile t6;
  Tile t7;
  Tile t8;
  Tile t9;
  Tile t10;
  Tile t11;
  Tile t12;
  Tile t13;
  Tile t14;
  Tile t15;

  // WorldScene examples
  WorldScene scene1;
  WorldScene scene2;

  // ArrayList<Tile> examples
  ArrayList<Tile> arr0;
  ArrayList<Tile> arr1;
  ArrayList<Tile> arr2;

  // ArrayList<ArrayList<Tile>> examples
  ArrayList<ArrayList<Tile>> rr1;
  ArrayList<ArrayList<Tile>> rr2;
  ArrayList<ArrayList<Tile>> rr3;

  // FifteenGame examples
  FifteenGame game1;
  FifteenGame game2;
  FifteenGame game3;
  FifteenGame game4;
  FifteenGame game5;

  // Initial game data
  void initData() {
    // Tiles
    this.t1 = new Tile(1, 4, 4);
    this.t2 = new Tile(2, 3, 3);
    this.t3 = new Tile(3, 2, 2);
    this.t4 = new Tile(4, 2, 1);
    this.t5 = new Tile(5, 1, 3);
    this.t6 = new Tile(6, 4, 1);
    this.t7 = new Tile(7, 2, 3);
    this.t8 = new Tile(8, 1, 4);
    this.t9 = new Tile(9, 3, 1);
    this.t10 = new Tile(10, 3, 4);
    this.t11 = new Tile(11, 4, 2);
    this.t12 = new Tile(12, 2, 4);
    this.t13 = new Tile(13, 4, 3);
    this.t14 = new Tile(14, 3, 2);
    this.t15 = new Tile(15, 1, 2);

    // WorldScenes
    this.scene1 = new WorldScene(WORLD_WIDTH, WORLD_HEIGHT);
    this.scene2 = new WorldScene(300, 300);

    // ArrayList<Tile>
    this.arr0 = new ArrayList<Tile>();
    this.arr1 = new ArrayList<Tile>(Arrays.asList(t3, t4, t5));
    this.arr2 = new ArrayList<Tile>(
        Arrays.asList(t1, t2, t3, t4, t5, t6, t7, t8, t9, t10, t11, t12, t13, t14, t15));

    // ArrayList<ArrayList<Tile>>
    this.rr1 = new ArrayList<ArrayList<Tile>>(Arrays.asList(arr0));
    this.rr2 = new ArrayList<ArrayList<Tile>>(Arrays.asList(arr0, arr1));
    this.rr3 = new ArrayList<ArrayList<Tile>>(Arrays.asList(arr2));

    // FifteenGame
    this.game1 = new FifteenGame(this.rr1);
    this.game2 = new FifteenGame(this.rr2);
    this.game3 = new FifteenGame(this.rr3);
    this.game4 = new FifteenGame(new Random(4));
    this.game5 = new FifteenGame(new Random(5));
  }

  // tests the blankArray method in FifteenGame
  void testBlankArray(Tester t) {
    this.initData();

    // Tiles to be added to the game board initially for gameplay
    Tile t1 = new Tile(11, 1, 1);
    Tile t2 = new Tile(7, 1, 2);
    Tile t3 = new Tile(1, 1, 3);
    Tile t4 = new Tile(12, 1, 4);
    Tile t5 = new Tile(4, 2, 1);
    Tile t6 = new Tile(6, 2, 2);
    Tile t7 = new Tile(2, 2, 3);
    Tile t8 = new Tile(3, 2, 4);
    Tile t9 = new Tile(0, 3, 1);
    Tile t10 = new Tile(8, 3, 2);
    Tile t11 = new Tile(10, 3, 3);
    Tile t12 = new Tile(14, 3, 4);
    Tile t13 = new Tile(13, 4, 1);
    Tile t14 = new Tile(15, 4, 2);
    Tile t15 = new Tile(9, 4, 3);
    Tile t16 = new Tile(5, 4, 4);

    // Creates one column at a time
    ArrayList<Tile> arrTile1 = new ArrayList<>(Arrays.asList(t1, t2, t3, t4));
    ArrayList<Tile> arrTile2 = new ArrayList<>(Arrays.asList(t5, t6, t7, t8));
    ArrayList<Tile> arrTile3 = new ArrayList<>(Arrays.asList(t9, t10, t11, t12));
    ArrayList<Tile> arrTile4 = new ArrayList<>(Arrays.asList(t13, t14, t15, t16));

    // Adds each column to the game board
    ArrayList<ArrayList<Tile>> arrArr1 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile1, arrTile2, arrTile3, arrTile4));

    // Returns what will happen during gameplay
    t.checkExpect(game4.tiles, arrArr1);

    // Reinitializes the game's tiles to be blank
    game4.blankArray();

    // Empty Tiles to be added to the board
    Tile t01 = new Tile(0, 1, 1);
    Tile t02 = new Tile(0, 1, 2);
    Tile t03 = new Tile(0, 1, 3);
    Tile t04 = new Tile(0, 1, 4);
    Tile t05 = new Tile(0, 2, 1);
    Tile t06 = new Tile(0, 2, 2);
    Tile t07 = new Tile(0, 2, 3);
    Tile t08 = new Tile(0, 2, 4);
    Tile t09 = new Tile(0, 3, 1);
    Tile t010 = new Tile(0, 3, 2);
    Tile t011 = new Tile(0, 3, 3);
    Tile t012 = new Tile(0, 3, 4);
    Tile t013 = new Tile(0, 4, 1);
    Tile t014 = new Tile(0, 4, 2);
    Tile t015 = new Tile(0, 4, 3);
    Tile t016 = new Tile(0, 4, 4);

    // Creates one column of empty Tiles at a time
    ArrayList<Tile> arrTile01 = new ArrayList<>(Arrays.asList(t01, t02, t03, t04));
    ArrayList<Tile> arrTile02 = new ArrayList<>(Arrays.asList(t05, t06, t07, t08));
    ArrayList<Tile> arrTile03 = new ArrayList<>(Arrays.asList(t09, t010, t011, t012));
    ArrayList<Tile> arrTile04 = new ArrayList<>(Arrays.asList(t013, t014, t015, t016));

    // Adds each column of empty Tiles to the game board
    ArrayList<ArrayList<Tile>> arrArr2 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile01, arrTile02, arrTile03, arrTile04));

    // Return an 4x4 grid of empty Tiles
    t.checkExpect(game4.tiles, arrArr2);
  }

  // tests the numberArray method in FifteenGame
  void testNumberArray(Tester t) {
    this.initData();

    // Tiles to be added to the game board initially for gameplay
    Tile t1 = new Tile(11, 1, 1);
    Tile t2 = new Tile(7, 1, 2);
    Tile t3 = new Tile(4, 1, 3);
    Tile t4 = new Tile(13, 1, 4);
    Tile t5 = new Tile(8, 2, 1);
    Tile t6 = new Tile(10, 2, 2);
    Tile t7 = new Tile(5, 2, 3);
    Tile t8 = new Tile(15, 2, 4);
    Tile t9 = new Tile(3, 3, 1);
    Tile t10 = new Tile(12, 3, 2);
    Tile t11 = new Tile(14, 3, 3);
    Tile t12 = new Tile(6, 3, 4);
    Tile t13 = new Tile(1, 4, 1);
    Tile t14 = new Tile(0, 4, 2);
    Tile t15 = new Tile(9, 4, 3);
    Tile t16 = new Tile(2, 4, 4);

    // Creates one column at a time
    ArrayList<Tile> arrTile1 = new ArrayList<>(Arrays.asList(t1, t2, t3, t4));
    ArrayList<Tile> arrTile2 = new ArrayList<>(Arrays.asList(t5, t6, t7, t8));
    ArrayList<Tile> arrTile3 = new ArrayList<>(Arrays.asList(t9, t10, t11, t12));
    ArrayList<Tile> arrTile4 = new ArrayList<>(Arrays.asList(t13, t14, t15, t16));

    // Adds each column to the game board
    ArrayList<ArrayList<Tile>> arrArr1 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile1, arrTile2, arrTile3, arrTile4));

    // Returns what will happen during gameplay
    t.checkExpect(game5.tiles, arrArr1);

    // Reinitializes the game's tiles to be different unique values
    game5.numberArray();

    // Numbered Tiles to be added to the board
    Tile t01 = new Tile(3, 1, 1);
    Tile t02 = new Tile(11, 1, 2);
    Tile t03 = new Tile(6, 1, 3);
    Tile t04 = new Tile(2, 1, 4);
    Tile t05 = new Tile(0, 2, 1);
    Tile t06 = new Tile(9, 2, 2);
    Tile t07 = new Tile(14, 2, 3);
    Tile t08 = new Tile(10, 2, 4);
    Tile t09 = new Tile(15, 3, 1);
    Tile t010 = new Tile(7, 3, 2);
    Tile t011 = new Tile(5, 3, 3);
    Tile t012 = new Tile(8, 3, 4);
    Tile t013 = new Tile(4, 4, 1);
    Tile t014 = new Tile(13, 4, 2);
    Tile t015 = new Tile(12, 4, 3);
    Tile t016 = new Tile(1, 4, 4);

    // Creates one column of numbered Tiles at a time
    ArrayList<Tile> arrTile01 = new ArrayList<>(Arrays.asList(t01, t02, t03, t04));
    ArrayList<Tile> arrTile02 = new ArrayList<>(Arrays.asList(t05, t06, t07, t08));
    ArrayList<Tile> arrTile03 = new ArrayList<>(Arrays.asList(t09, t010, t011, t012));
    ArrayList<Tile> arrTile04 = new ArrayList<>(Arrays.asList(t013, t014, t015, t016));

    // Adds each column of numbered Tiles to the game board
    ArrayList<ArrayList<Tile>> arrArr2 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile01, arrTile02, arrTile03, arrTile04));

    // Return an 4x4 grid of numbered Tiles
    t.checkExpect(game5.tiles, arrArr2);
  }

  // tests the drawAt method in Tile
  void testDrawAt(Tester t) {
    // Initializes game data examples
    this.initData();
    // Checks what a WorldScene contains initially
    t.checkExpect(scene1, new WorldScene(WORLD_WIDTH, WORLD_HEIGHT));

    // Draws a tile onto a WorldScene
    t1.drawAt(175, 175, scene1);
    WorldScene w1 = new WorldScene(WORLD_WIDTH, WORLD_HEIGHT);
    WorldImage img1 = new OverlayImage(new TextImage("1", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    w1.placeImageXY(img1, 175, 175);

    // Checks what a WorldScene contains after adding one tile
    t.checkExpect(scene1, w1);

    // Draws a second tile onto a WorldScene
    t2.drawAt(125, 125, scene1);
    WorldScene w2 = w1;
    WorldImage img2 = new OverlayImage(new TextImage("2", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    w2.placeImageXY(img2, 125, 125);

    // Checks what a WorldScene contains after adding two tiles
    t.checkExpect(scene1, w2);
  }

  // tests the equals (and hashCode) method in Tile
  void testEquals(Tester t) {
    this.initData();
    Tile tile = new Tile(1, 4, 4);
    t.checkExpect(tile.equals(t1), true);
    t.checkExpect(tile.equals(t9), false);
    t.checkExpect(tile.hashCode(), 592);
    t.checkExpect(t1.hashCode(), 592);
    t.checkExpect(t9.hashCode(), 999);
  }

  // tests the makeScene method in FifteenGame
  void testMakeScene(Tester t) {
    this.initData();

    // empty WorldScene
    WorldScene w1 = new WorldScene(WORLD_WIDTH, WORLD_WIDTH);

    // tests on a game with no tiles
    t.checkExpect(this.game1.makeScene(), w1);

    // images of Tiles
    WorldImage img1 = new OverlayImage(new TextImage("3", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img2 = new OverlayImage(new TextImage("4", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img3 = new OverlayImage(new TextImage("5", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));

    // images of Tiles placed onto an empty WorldScene
    w1.placeImageXY(img1, 75, 75);
    w1.placeImageXY(img2, 75, 25);
    w1.placeImageXY(img3, 25, 125);

    // tests on a game with tiles in different rows and columns
    t.checkExpect(this.game2.makeScene(), w1);

    WorldScene w2 = new WorldScene(WORLD_WIDTH, WORLD_HEIGHT);
    // images of Tiles
    WorldImage img01 = new OverlayImage(new TextImage("1", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img02 = new OverlayImage(new TextImage("2", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img03 = new OverlayImage(new TextImage("3", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img04 = new OverlayImage(new TextImage("4", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img05 = new OverlayImage(new TextImage("5", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img06 = new OverlayImage(new TextImage("6", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img07 = new OverlayImage(new TextImage("7", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img08 = new OverlayImage(new TextImage("8", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img09 = new OverlayImage(new TextImage("9", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img010 = new OverlayImage(new TextImage("10", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img011 = new OverlayImage(new TextImage("11", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img012 = new OverlayImage(new TextImage("12", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img013 = new OverlayImage(new TextImage("13", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img014 = new OverlayImage(new TextImage("14", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));
    WorldImage img015 = new OverlayImage(new TextImage("15", 30, Color.black),
        new RectangleImage(50, 50, "outline", Color.black));

    // images of Tiles placed onto an empty WorldScene
    w2.placeImageXY(img01, 175, 175);
    w2.placeImageXY(img02, 125, 125);
    w2.placeImageXY(img03, 75, 75);
    w2.placeImageXY(img04, 75, 25);
    w2.placeImageXY(img05, 25, 125);
    w2.placeImageXY(img06, 175, 25);
    w2.placeImageXY(img07, 75, 125);
    w2.placeImageXY(img08, 25, 175);
    w2.placeImageXY(img09, 125, 25);
    w2.placeImageXY(img010, 125, 175);
    w2.placeImageXY(img011, 175, 75);
    w2.placeImageXY(img012, 75, 175);
    w2.placeImageXY(img013, 175, 125);
    w2.placeImageXY(img014, 125, 75);
    w2.placeImageXY(img015, 25, 75);

    // makes a full WorldScene out of 15 Tiles
    t.checkExpect(this.game3.makeScene(), w2);
  }

  // tests the tilesInOrder method in FifteenGame
  void testTilesInOrder(Tester t) {
    
    Tile t1 = new Tile(1, 1, 1);
    Tile t2 = new Tile(9, 1, 2);
    Tile t3 = new Tile(5, 1, 3);
    Tile t4 = new Tile(13, 1, 4);
    Tile t5 = new Tile(2, 2, 1);
    Tile t6 = new Tile(6, 2, 2);
    Tile t7 = new Tile(10, 2, 3);
    Tile t8 = new Tile(14, 2, 4);
    Tile t9 = new Tile(3, 3, 1);
    Tile t10 = new Tile(7, 3, 2);
    Tile t11 = new Tile(11, 3, 3);
    Tile t12 = new Tile(15, 3, 4);
    Tile t13 = new Tile(4, 4, 1);
    Tile t14 = new Tile(8, 4, 2);
    Tile t15 = new Tile(12, 4, 3);
    Tile t16 = new Tile(0, 4, 4);

    ArrayList<Tile> arrTile1 = new ArrayList<Tile>(Arrays.asList(t1, t2, t3, t4));
    ArrayList<Tile> arrTile2 = new ArrayList<Tile>(Arrays.asList(t5, t6, t7, t8));
    ArrayList<Tile> arrTile3 = new ArrayList<Tile>(Arrays.asList(t9, t10, t11, t12));
    ArrayList<Tile> arrTile4 = new ArrayList<Tile>(Arrays.asList(t13, t14, t15, t16));

    ArrayList<ArrayList<Tile>> arr1 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile1, arrTile2, arrTile3, arrTile4));
    
    FifteenGame game6 = new FifteenGame(arr1);
    
    Tile t01 = new Tile(1, 1, 1);
    Tile t02 = new Tile(5, 1, 2);
    Tile t03 = new Tile(9, 1, 3);
    Tile t04 = new Tile(13, 1, 4);
    Tile t05 = new Tile(2, 2, 1);
    Tile t06 = new Tile(6, 2, 2);
    Tile t07 = new Tile(10, 2, 3);
    Tile t08 = new Tile(14, 2, 4);
    Tile t09 = new Tile(3, 3, 1);
    Tile t010 = new Tile(7, 3, 2);
    Tile t011 = new Tile(11, 3, 3);
    Tile t012 = new Tile(15, 3, 4);
    Tile t013 = new Tile(4, 4, 1);
    Tile t014 = new Tile(8, 4, 2);
    Tile t015 = new Tile(12, 4, 3);
    Tile t016 = new Tile(0, 4, 4);

    ArrayList<Tile> arrTile01 = new ArrayList<Tile>(Arrays.asList(t01, t02, t03, t04));
    ArrayList<Tile> arrTile02 = new ArrayList<Tile>(Arrays.asList(t05, t06, t07, t08));
    ArrayList<Tile> arrTile03 = new ArrayList<Tile>(Arrays.asList(t09, t010, t011, t012));
    ArrayList<Tile> arrTile04 = new ArrayList<Tile>(Arrays.asList(t013, t014, t015, t016));

    ArrayList<ArrayList<Tile>> arr2 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile01, arrTile02, arrTile03, arrTile04));
    
    FifteenGame game7 = new FifteenGame(arr2);
    
    t.checkExpect(game6.tilesInOrder(), false);
    t.checkExpect(game7.tilesInOrder(), true);
    
  }
  
  // tests the swap method in FifteenGame
  void testSwap(Tester t) {
    this.initData();
    this.game2.swapTiles(game2.tiles.get(1).get(0), game2.tiles.get(1).get(1));
    // Swaps tile values
    Tile newTile1 = new Tile(3,2,1);
    Tile newTile2 = new Tile(4,2,2);
    this.arr1 = new ArrayList<Tile>(Arrays.asList(newTile2,newTile1,t5));
    ArrayList<ArrayList<Tile>> newArr = new ArrayList<ArrayList<Tile>>(Arrays.asList(arr0,arr1));
    t.checkExpect(this.game2.tiles, newArr);
    
    this.initData();
    this.game2.swapTiles(game2.tiles.get(1).get(1), game2.tiles.get(1).get(2));
    // Swaps tile values
    Tile newTile3 = new Tile(5,2,1);
    Tile newTile4 = new Tile(4,1,3);
    this.arr1 = new ArrayList<Tile>(Arrays.asList(t3,newTile3,newTile4));
    ArrayList<ArrayList<Tile>> newArr2 = new ArrayList<ArrayList<Tile>>(Arrays.asList(arr0,arr1));
    t.checkExpect(this.game2.tiles, newArr2);
  }
  
  // tests the onKeyEvent method in FifteenGame
  void testOnKeyEvent(Tester t) {
    this.initData();
    Tile t01 = new Tile(1, 1, 1);
    Tile t02 = new Tile(5, 1, 2);
    Tile t03 = new Tile(9, 1, 3);
    Tile t04 = new Tile(13, 1, 4);
    Tile t05 = new Tile(2, 2, 1);
    Tile t06 = new Tile(6, 2, 2);
    Tile t07 = new Tile(10, 2, 3);
    Tile t08 = new Tile(14, 2, 4);
    Tile t09 = new Tile(3, 3, 1);
    Tile t010 = new Tile(7, 3, 2);
    Tile t011 = new Tile(11, 3, 3);
    Tile t012 = new Tile(15, 3, 4);
    Tile t013 = new Tile(4, 4, 1);
    Tile t014 = new Tile(8, 4, 2);
    Tile t015 = new Tile(12, 4, 3);
    Tile t016 = new Tile(0, 4, 4);

    ArrayList<Tile> arrTile01 = new ArrayList<Tile>(Arrays.asList(t01, t02, t03, t04));
    ArrayList<Tile> arrTile02 = new ArrayList<Tile>(Arrays.asList(t05, t06, t07, t08));
    ArrayList<Tile> arrTile03 = new ArrayList<Tile>(Arrays.asList(t09, t010, t011, t012));
    ArrayList<Tile> arrTile04 = new ArrayList<Tile>(Arrays.asList(t013, t014, t015, t016));

    ArrayList<ArrayList<Tile>> arr2 = new ArrayList<ArrayList<Tile>>(
        Arrays.asList(arrTile01, arrTile02, arrTile03, arrTile04));
    
    FifteenGame game7 = new FifteenGame(arr2);
    
    t.checkExpect(game7.tiles.get(3).get(3), t016);
    game7.onKeyEvent("right");
    t.checkExpect(game7.tiles.get(3).get(3), t016);
    game7.onKeyEvent("up");
    t.checkExpect(game7.tiles.get(3).get(3), new Tile(12,4,4));
    
    FifteenGame game8 = new FifteenGame(arr2);
    t.checkExpect(game8.tiles.get(3).get(3), t016);
    game8.onKeyEvent("down");
    t.checkExpect(game8.tiles.get(3).get(3), t016);
    game8.onKeyEvent("left");
    t.checkExpect(game8.tiles.get(3).get(3), new Tile(15,4,4));
  }

  // tests lastScene method in FifteenGame
  void testLastScene(Tester t) {
    this.initData();
    
    WorldScene scn = this.game1.makeScene();
    scn.placeImageXY(new TextImage("ok", 40, FontStyle.BOLD, Color.GREEN), (WORLD_WIDTH / 2),
        (WORLD_HEIGHT / 2));
    t.checkExpect(this.game1.lastScene("ok"), scn);
    
    WorldScene scn2 = this.game4.makeScene();
    scn2.placeImageXY(new TextImage("ok", 40, FontStyle.BOLD, Color.GREEN), (WORLD_WIDTH / 2),
        (WORLD_HEIGHT / 2));
    t.checkExpect(this.game4.lastScene("ok"), scn2);
  }

  // tests and renders the game
  void testGame(Tester t) {
    this.initData();
    // Generates a game with 15 fixed Tiles
    FifteenGame g1 = this.game3;
    // Generates a game with 15 random Tiles
    FifteenGame g2 = new FifteenGame();
    g2.bigBang(WORLD_WIDTH, WORLD_HEIGHT);
  }

}