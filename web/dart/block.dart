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

  bool inMenu = false;

  TuneBlock();

  TuneBlock clone(num cx, num cy);

  void draw(CanvasRenderingContext2D ctx, [layer = 0]);

  bool animate(int millis);

  bool containsTouch(Contact c) { return false; }

  bool touchDown(Contact c) { return false; }

  void touchUp(Contact c) { }

  void touchDrag(Contact c) { }
   
  void touchSlide(Contact c) { }
}
