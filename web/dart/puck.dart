/*
 * TunePad
 *
 * Michael S. Horn
 * Northwestern University
 * michael-horn@northwestern.edu
 * Copyright 2017, Michael S. Horn
 *
 * This project was funded by the National Science Foundation (grant DRL-1612619).
 * Any opinions, findings and conclusions or recommendations expressed in this
 * material are those of the author(s) and do not necessarily reflect the views
 * of the National Science Foundation (NSF).
 */
part of TunePad;


class TunePuck extends TuneBlock {

  // size and position of the puck
  num centerX, centerY, radius;

  // matching socket highlight
  Socket highlight = null;

  // socket that this puck is connected to
  Socket socket = null;

  // variables for touch interaction
  bool _dragging = false;
  num _touchX, _touchY, _lastX, _lastY;

  // color of the block
  String color = "rgb(0, 160, 227)";

  // puck sound
  String sound;


  TunePuck(this.centerX, this.centerY) {
    this.radius = PUCK_WIDTH / 2;
  }


  TuneBlock clone(num cx, num cy) {
    return new TunePuck(cx, cy) 
      .. color = color
      .. sound = sound;
  }


  bool get isDragging => _dragging;


  void connect(Socket s) {
    socket = s;
    socket.puck = this;
    centerX = socket.cx;
    centerY = socket.cy;
  }


  void disconnect() {
    if (socket != null) {
      socket.puck = null;
      socket = null;
    }
  }


  void draw(CanvasRenderingContext2D ctx, [layer = 0]) {
    ctx.save();
    {
      switch (layer) {

        case 2:
  
          // highlight puck
          if (highlight != null) {
            ctx.fillStyle = "rgba(255, 255, 240, 0.9)";
            ctx.beginPath();
            ctx.arc(highlight.cx, highlight.cy, highlight.radius, 0, PI * 2, false);
            ctx.fill();
          }
          break;

        case 3: 
          ctx.fillStyle = color; 
          ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
          ctx.lineWidth = 2;
          ctx.beginPath();
          ctx.arc(centerX, centerY, radius, 0, PI * 2, true);
          ctx.shadowOffsetX = 2;
          ctx.shadowOffsetY = 2;
          ctx.shadowBlur = 3;
          ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
          ctx.fill();
          ctx.stroke();
        break;
      }
    }
    ctx.restore();
  }


  bool animate(int millis) { 
    if (_dragging) {
      centerX += (_touchX - _lastX);
      centerY += (_touchY - _lastY);
      _lastX = _touchX;
      _lastY = _touchY;
      highlight = workspace.findMatchingSocket(this);
      return true;
    } 
    else if (socket != null) {
      centerX = socket.cx;
      centerY = socket.cy;
    }
    return false;
  }


  bool containsTouch(Contact c) {
    num a2 = (c.touchX - centerX) * (c.touchX - centerX);
    num b2 = (c.touchY - centerY) * (c.touchY - centerY);
    num c2 = radius * radius;
    return a2 + b2 <= c2;
  }


  bool touchDown(Contact c) {
    _dragging = true;
    Sounds.playSound(sound);
    disconnect();
    workspace.moveToTop(this);
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    return true;
  }    


  void touchUp(Contact c) {
    _dragging = false;
    if (highlight != null) {
      connect(highlight);
    }
    workspace.draw();
  }


  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;    
  }
   
  void touchSlide(Contact c) {  }
}
