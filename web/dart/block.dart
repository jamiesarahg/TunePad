/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2016, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
part of TunePad;

const BLOCK_WIDTH = 75;


abstract class TuneBlock extends Touchable {

  // size and position of the block
  num centerX, centerY, radius;

  TuneBlock(this.centerX, this.centerY);

  void draw(CanvasRenderingContext2D ctx);

  bool animate(int millis);

  bool containsTouch(Contact c) { return false; }

  Touchable touchDown(Contact c) { return this; }

  void touchUp(Contact c) { }

  void touchDrag(Contact c) { }
   
  void touchSlide(Contact c) { }
}
