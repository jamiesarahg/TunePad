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


class BlockButton extends Touchable {

  // location of the button relative to its parent block
  num x = -20, y = -20;

  num _lastX = 0, _lastY = 0;

  // width and height of the block
  num width = 40, height = 40;

  // button name and image
  String name;

  // is the button down
  bool down = false;

  // block that owns this button
  TuneBlock parent;

  // button image (svg)
  ImageElement image = new ImageElement();


  BlockButton(this.parent, this.name) {
    image.src = "images/buttons/$name.svg";
  }


  num get centerX => x + width/2;
      set centerX(num value) => x = value - width/2;
  num get centerY => y + height/2;
      set centerY(num value) => y = value - height/2;


  void draw(CanvasRenderingContext2D ctx) {
    if (down && isOver()) {
      ctx.drawImage(image, x + 3, y + 3);
    } else {
      ctx.drawImage(image, x, y);
    }
  }


  bool animate(int millis) { 
    return false;
  }


  bool isOver() {
    return (_lastX >= x && _lastX <= x + width && _lastY >= y && _lastY <= y + height);
  }


  bool containsTouch(Contact c) {
    num cx = c.touchX - parent.cx;
    num cy = c.touchY - parent.cy;
    return (cx >= x && cx <= x + width && cy >= y && cy <= y + height);
  }


  bool touchDown(Contact c) {
    down = true;
    _lastX = c.touchX - parent.cx;
    _lastY = c.touchY - parent.cy;
    return true;
  }


  void touchUp(Contact c) {
    down = false;
    _lastX = c.touchX - parent.cx;
    _lastY = c.touchY - parent.cy;
    if (isOver()) { parent.buttonCallback(this); }
  }


  void touchDrag(Contact c) {
    _lastX = c.touchX - parent.cx;
    _lastY = c.touchY - parent.cy;
  }
   
  void touchSlide(Contact c) {  }
}