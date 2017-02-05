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



/**
 * Increases the tempo of a play head
 */
class TempoPuck extends TunePuck {

  bool up = true;

  TempoPuck(num cx, num cy, this.up) : super(cx, cy, "#e2e7ed");


  TuneBlock clone(num cx, num cy) {
    return new TempoPuck(cx, cy, up);
  }


  void eval(PlayHead player) {
    if (up) {
      player.tempo = min(32, player.tempo * 2);
    } else {
      player.tempo = max(1, player.tempo ~/ 2);
    }
  }


  bool skipAhead(PlayHead player) {
    return true;
  }


  void _drawIcon(CanvasRenderingContext2D ctx) { 
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      if (socket != null) {
        ctx.rotate(socket.parent.rotation * -1);
      }
      ctx.fillStyle = "rgba(0, 0, 0, 0.5)";
      ctx.font = "40px FontAwesome";
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
    //ctx.fillText("\uf001", centerX, centerY); // music
      ctx.fillText(up ? "\uf04e" : "\uf04a", 0, 0); // lightning

    //ctx.fillText("\uf04b \uf04e \uf04c \uf0e7 \uf074 \uf00d", centerX, centerY);
    //ctx.fillText("\uf026 \uf027 \uf028 \uf0e7 \uf074 \uf00d", centerX, centerY + 100);
    //ctx.font = "30px sans-serif";
    //ctx.fillText("\u221e", centerX + 30, centerY + 30);
    }
    ctx.restore();
  }
}

/**
 * Puck that represents an audio sample
 */
class AudioPuck extends TunePuck {

  // sound file for this puck
  String sound;

  // animates sounds playing
  num _pop = 0.0;


  AudioPuck(num cx, num cy, String color, this.sound) : super(cx, cy, color) {
    if (!Sounds.hasSound(sound)) {
      Sounds.loadSound(sound, sound);
    }
  }


  TuneBlock clone(num cx, num cy) {
    return new AudioPuck(cx, cy, color, sound);
  }

  bool animate(int millis) { 
    bool refresh = super.animate(millis);
    if (_pop > 0.05) {
      _pop *= 0.9;
      refresh = true;
    } else {
      _pop = 0.0;
    }
    return refresh;
  }


  void eval(PlayHead player) {
    Sounds.playSound(sound);
    _pop = 1.0;
  }


  void _drawIcon(CanvasRenderingContext2D ctx) { 
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      if (socket != null) {
        ctx.rotate(socket.parent.rotation * -1);
      }
      ctx.fillStyle = "rgba(255, 255, 255, 0.9)";
      int size = 30 + (_pop * 60).toInt();
      ctx.font = "${size}px FontAwesome";
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
    //ctx.fillText("\uf001", centerX, centerY); // music
      ctx.fillText("\uf0e7", 0, 0); // lightning

    //ctx.fillText("\uf04b \uf04e \uf04c \uf0e7 \uf074 \uf00d", centerX, centerY);
    //ctx.fillText("\uf026 \uf027 \uf028 \uf0e7 \uf074 \uf00d", centerX, centerY + 100);
    //ctx.font = "30px sans-serif";
    //ctx.fillText("\u221e", centerX + 30, centerY + 30);
    }
    ctx.restore();
  }


  Touchable touchDown(Contact c) {
    if (!isConnected) {
      Sounds.playSound(sound);
      _pop = 1.0;
    }
    return super.touchDown(c);
  }
}





abstract class TunePuck extends TuneBlock {

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


  TunePuck(this.centerX, this.centerY, this.color) {
    this.radius = PUCK_WIDTH / 2;
  }


  TuneBlock clone(num cx, num cy);

  bool get isDragging => _dragging;

  bool get isConnected => socket != null;


  void eval(PlayHead) { }

  bool skipAhead(PlayHead player) {
    return false;
  }


  void connect(Socket s) {
    socket = s;
    socket.puck = this;
    centerX = socket.cx;
    centerY = socket.cy;
    Sounds.playSound("click");
  }


  void disconnect() {
    if (socket != null) {
      socket.puck = null;
      socket = null;
    }
  }


  void _drawIcon(CanvasRenderingContext2D ctx);


  void draw(CanvasRenderingContext2D ctx, [layer = 0]) {
    ctx.save();
    {
      switch (layer) {

        case 2:
  
          // highlight socket
          if (highlight != null) {
            ctx.fillStyle = "#aaeeff";
            ctx.beginPath();
            ctx.arc(highlight.cx, highlight.cy, highlight.radius, 0, PI * 2, false);
            ctx.fill();
          }
          break;

        case 3: 
          ctx.save();
          {
            ctx.fillStyle = color; 
            ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
            ctx.lineWidth = 2;
            ctx.beginPath();
            ctx.arc(centerX, centerY, radius, 0, PI * 2, true);
            ctx.stroke();
            ctx.shadowOffsetX = 2; // * workspace.zoom;
            ctx.shadowOffsetY = 2; // * workspace.zoom;
            ctx.shadowBlur = 4; // * workspace.zoom;
            ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
            ctx.fill();
          }
          ctx.restore();
          _drawIcon(ctx);
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


  num distance(num tx, num ty) {
    num a2 = (tx - centerX) * (tx - centerX);
    num b2 = (ty - centerY) * (ty - centerY);
    return sqrt(a2 + b2);
  }


  bool containsTouch(Contact c) {
    if (isConnected) {
      return false;
    } else {
      return distance(c.touchX, c.touchY) <= radius;
    }
  }


  Touchable touchDown(Contact c) {
    _dragging = true;
    disconnect();
    workspace.moveToTop(this);
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    return this;
  }    


  void touchUp(Contact c) {
    _dragging = false;
    if (highlight != null) {
      connect(highlight);
    }
    highlight = null;
    if (isOverMenu) trash = true;
    inMenu = false;
    workspace.draw();
  }


  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;    
  }
   
  void touchSlide(Contact c) {  }
}
