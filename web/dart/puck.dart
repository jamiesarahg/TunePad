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


abstract class TunePuck extends TuneBlock {

  // size and position of the puck
  num centerX, centerY, radius;

  // duration of the puck (-1 means auto-advance)
  int duration = -1; 

  // matching socket highlight
  Socket highlight = null;

  // socket that this puck is connected to
  Socket socket = null;

  // icon to draw on the puck
  String icon = "\uf0e7";

  // font face / size to draw in
  String font = "32px FontAwesome";

  // color of the block
  String color = "rgb(0, 160, 227)";

  // hint message
  String hint;

  // puck context menu options
  List<PuckMenuItem> menu = new List<PuckMenuItem>();

  // variables for touch interaction
  bool _dragging = false;
  num _touchX, _touchY, _lastX, _lastY;



  TunePuck(this.centerX, this.centerY, this.color, this.hint) {
    this.radius = PUCK_WIDTH / 2;
  }


  TuneBlock clone(num cx, num cy);

  bool get isDragging => _dragging;

  bool get isConnected => socket != null;

/** 
 * As the playhead moves through a chain, it calls eval on sockets 
 * and pucks
 */
  void eval(PlayHead) { }


/**
 * Callback for when a menu option is changed
 */
  void menuSelection(int index) {
    if (index >= 0 && index < menu.length) {
      for (PuckMenuItem m in menu) {
        m.selected = false;  // clear existing selection
      }
      icon = menu[index].icon;
      menu[index].selected = true;
      _menuSelectionChanged(index);
    }
  }

  void _menuSelectionChanged(int index) { }


  void connect(Socket s) {
    if (s.puck != null) {
      s.puck.trash = true;
      s.puck.socket = null;
    }
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


  void _drawIcon(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      if (socket != null) {
        ctx.rotate(socket.parent.rotation * -1);
      }
      ctx.fillStyle = "rgba(255, 255, 255, 0.9)";
      ctx.font = font;
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
      ctx.fillText("$icon", -1, 0);
    }
    ctx.restore();
  }


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


  void drawMenu(CanvasRenderingContext2D ctx, num touchX, num touchY) {
    if (menu == null || menu.isEmpty) return;
    ctx.save();
    {
      ctx.translate(centerX, centerY);

      // figure out the highlighted menu slice
      int target = screenToMenuIndex(touchX, touchY);

      // menu background
      ctx.fillStyle = "#ddd";
      ctx.strokeStyle = "#777";
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.arc(0, 0, radius * 4, 0, PI * 2, true);
      ctx.fill();

      // menu segments
      ctx.rotate(PI * 0.5);
      int segments = menu.length;
      num arc = PI * 2 / segments;
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";

      for (int i=0; i<segments; i++) {
        if (i == target) {
          ctx.fillStyle = "white";
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(0, radius * -4);
          ctx.arc(0, 0, radius * 4, -PI/2, -PI/2 - arc, true);
          ctx.closePath();
          ctx.fill();
          ctx.fillStyle = "#777";
        }
        else if (menu[i].selected) {
          ctx.fillStyle = "rgba(0, 0, 0, 0.3)";
          ctx.beginPath();
          ctx.moveTo(0, 0);
          ctx.lineTo(0, radius * -4);
          ctx.arc(0, 0, radius * 4, -PI/2, -PI/2 - arc, true);
          ctx.closePath();
          ctx.fill();
          ctx.fillStyle = "#eee";
        } else {
          ctx.fillStyle = "#777";
        }

        ctx.beginPath();
        ctx.moveTo(0, 0);
        ctx.lineTo(0, radius * -4);
        ctx.stroke();

        ctx.rotate(arc * -0.5);
        ctx.font = menu[i].font;
        ctx.fillText("${menu[i].icon}", 0, radius * -2.6); 
        ctx.rotate(arc * -0.5);
      }

      ctx.beginPath();
      ctx.arc(0, 0, radius * 4, 0, PI * 2, true);
      ctx.stroke();
    }
    ctx.restore();
  }


  int screenToMenuIndex(num tx, num ty) {
    tx -= centerX;
    ty -= centerY;
    int segments = menu.length;
    num arc = PI * 2 / segments;
    num alpha = atan2(-ty, tx);
    if (alpha < 0) alpha += 2 * PI;
    int target = alpha ~/= arc;
    num d = dist(tx, ty, 0, 0);
    if (d >= radius && d <= radius * 4) {
      return target;
    } else {
      return -1;
    }
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
    return dist(tx, ty, centerX, centerY);
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
    if (inMenu && hint != null) {
      workspace.showHint(hint);
    }
    return this;
  }    


  void touchUp(Contact c) {
    _dragging = false;
    if (highlight != null) {
      connect(highlight);
    }
    highlight = null;
    if (isOverMenu) trash = true;
    if (inMenu) workspace.clearHint();
    inMenu = false;
    workspace.draw();
  }


  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;    
  }
   
  void touchSlide(Contact c) {  }
}



/**
 * Puck that represents an audio sample
 */
class AudioPuck extends TunePuck {

  // sound file for this puck
  String sound;

  // animates sounds playing
  num _pop = 0.0;


  AudioPuck(num cx, num cy, String color, this.sound) : super(cx, cy, color, null) {
    if (!Sounds.hasSound(sound)) {
      Sounds.loadSound(sound, sound);
    }
    font = "40px tune-pad";
    icon = "d"; // eight note
    duration = millisPerMeasure / 8;
    menu.add(new PuckMenuItem("a", 1/2));  // half note
    menu.add(new PuckMenuItem("b", 3/4)); // dotted quarter
    menu.add(new PuckMenuItem("c", 1/4)); // quarter note
    menu.add(new PuckMenuItem("d", 1/8)..selected = true); // 8th note
    menu.add(new PuckMenuItem("e", 1/16)); // 16th note
  }


  TuneBlock clone(num cx, num cy) {
    return new AudioPuck(cx, cy, color, sound) .. icon = icon;
  }


  void _menuSelectionChanged(int index) { 
    duration = millisPerMeasure * menu[index].data;
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
    Sounds.playSound(sound, 
      volume : player.gain, 
      playback : player.playback,
      convolve : player.convolve);
    _pop = 1.0;
  }


  void _drawIcon(CanvasRenderingContext2D ctx) { 
    int size = 40 + (_pop * 60).toInt();
    font = "${size}px tune-pad";
    super._drawIcon(ctx);
  }


  Touchable touchDown(Contact c) {
    if (!isConnected) {
      Sounds.playSound(sound);
      _pop = 1.0;
    }
    return super.touchDown(c);
  }
}


/**
 * Increases the tempo of a play head
 */
class TempoPuck extends TunePuck {

  bool up = true;

  TempoPuck(num cx, num cy, bool up, String hint) : super(cx, cy, "#e2e7ed", hint) {
    this.up = up;
    icon = up ? "\uf04e" : "\uf04a";
  }


  TuneBlock clone(num cx, num cy) {
    return new TempoPuck(cx, cy, up, hint);
  }


  void eval(PlayHead player) {
    if (up) {
      player.tempo = min(32, player.tempo * 2);
    } else {
      player.tempo = max(1, player.tempo ~/ 2);
    }
  }
}




/**
 * Increases the volume of a play head
 */
class GainPuck extends TunePuck {

  bool up = true;

  GainPuck(num cx, num cy, this.up, String hint) : super(cx, cy, "#e2e7ed", hint) {
    icon = up? "\uf028" : "\uf027";
  }


  TuneBlock clone(num cx, num cy) {
    return new GainPuck(cx, cy, up, hint);
  }


  void eval(PlayHead player) {
    if (up) {
      player.gain = min(1.0, player.gain + 0.2);
    } else {
      player.gain = max(0.05, player.gain - 0.2);
    }
  }
}




/**
 * Increases the pitch of a play head
 */
class PitchPuck extends TunePuck {

  bool up = true;

  PitchPuck(num cx, num cy, this.up, String hint) : super(cx, cy, "#e2e7ed", hint) {
    icon = up ? "\uf062" : "\uf063";
  }


  TuneBlock clone(num cx, num cy) {
    return new PitchPuck(cx, cy, up, hint);
  }


  void eval(PlayHead player) {
    if (up) {
      player.playback = min(4.0, player.playback * 2);
    } else {
      player.playback = max(0.25, player.playback * 0.5);
    }
  }
}




/**
 * Increases the pitch of a play head
 */
class DistortPuck extends TunePuck {

  String impulse = null;

  DistortPuck(num cx, num cy, this.impulse, String hint) : super(cx, cy, "#e2e7ed", hint) {
    if (!Sounds.hasSound(impulse)) {
      Sounds.loadSound(impulse, impulse);
    }
    icon = "\uf0d0";
  }


  TuneBlock clone(num cx, num cy) {
    return new DistortPuck(cx, cy, impulse, hint);
  }


  void eval(PlayHead player) {
    player.convolve = impulse;
  }
}


/**
 * Resets the play head to its default state
 */
class ResetPuck extends TunePuck {

  String impulse = null;

  ResetPuck(num cx, num cy, String hint) : super(cx, cy, "#e2e7ed", hint) {
    icon = "\uf05e";
  }


  TuneBlock clone(num cx, num cy) {
    return new ResetPuck(cx, cy, hint);
  }


  void eval(PlayHead player) {
    player.reset();
  }
}




/**
 * Hexagonal logic puck abstract base class
 */
abstract class LogicPuck extends TunePuck {

  LogicPuck(num cx, num cy, String hint) : super(cx, cy, "#5f6972", hint) {
    radius = PUCK_WIDTH * 0.5 * 1.15;
  }


  bool goLeft(PlayHead player) { return false;  }

  bool goRight(PlayHead player) { return false; }


  void eval(PlayHead player) {
  }


  void draw(CanvasRenderingContext2D ctx, [layer = 0]) {
    ctx.save();
    {
      switch (layer) {

        case 2:
  
          // highlight socket
          if (highlight != null) {
            ctx.fillStyle = "#aaeeff";
            ctx.beginPath();
            ctx.arc(highlight.cx, highlight.cy, highlight.radius * 0.85, 0, PI * 2, false);
            ctx.fill();
          }
          break;

        case 3: 
          ctx.save();
          {
            ctx.fillStyle = color; 
            ctx.strokeStyle = "rgba(255, 255, 255, 0.5)";
            ctx.lineWidth = 2;

            ctx.translate(centerX, centerY);
            if (socket != null) {
              ctx.rotate(socket.parent.rotation * -1);
            }
            ctx.rotate(PI / 6);
            ctx.beginPath();
            ctx.moveTo(0, -radius);
            for (int i=0; i<6; i++) {
              ctx.rotate(PI / 3);
              ctx.lineTo(0, PUCK_WIDTH * -0.575);
            }
            ctx.closePath();
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
}


/**
 * Random puck
 */
class RandomPuck extends LogicPuck {

  bool _goLeft = false;

  Random _rand = new Random();

  RandomPuck(num cx, num cy, String hint) : super(cx, cy, hint) {
    icon = "\uf074";
  }

  TuneBlock clone(num cx, num cy) {
    return new RandomPuck(cx, cy, hint);
  }

  void eval(PlayHead) { 
    _goLeft = _rand.nextBool();
  }

  bool goLeft(PlayHead player) { return _goLeft;  }

  bool goRight(PlayHead player) { return !_goLeft; }

}


/**
 * Split puck
 */
class SplitPuck extends LogicPuck {

  PlayHead _clone  = null;


  SplitPuck(num cx, num cy, String hint) : super(cx, cy, hint) {
    icon = "\uf1e0";
  }

  TuneBlock clone(num cx, num cy) {
    return new SplitPuck(cx, cy, hint);
  }

  void eval(PlayHead player) {
    _clone = player.parent.split(player);
  }

  bool goLeft(PlayHead player) => (player == _clone);

  bool goRight(PlayHead player) => (player != _clone);
}


/**
 * Each item in the menu knows how to draw itself
 */
class PuckMenuItem {

  String icon = "";
  var data;
  String font = "40px tune-pad";

  bool selected = false;

  bool highlight = false;


  PuckMenuItem(this.icon, this.data);

  void draw(CanvasRenderingContext2D ctx, num dx, num dy) {
  }
}



