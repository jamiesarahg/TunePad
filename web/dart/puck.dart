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

  // font face
  String font = "tune-pad"; // "32px FontAwesome";

  // font size
  int fontSize = 32;

  // foreground color of the block
  String color = "rgba(255, 255, 255, 0.9)";

  // color of the block
  String background = "rgb(0, 160, 227)";

  // hint message
  String hint;

  // puck context menu
  PieMenu menu;

  // variables for touch interaction
  bool _dragging = false;
  num _touchX, _touchY, _lastX, _lastY;

  // animates sounds playing
  num _pop = 0.0;


  TunePuck(this.centerX, this.centerY, this.background, this.hint) {
    this.radius = PUCK_WIDTH / 2;
    menu = new PieMenu(this);
  }


  TuneBlock clone(num cx, num cy);

  bool get isDragging => _dragging;

  bool get isConnected => socket != null;

/** 
 * As the playhead moves through a chain, it calls eval on sockets 
 * and pucks
 */
  void eval(PlayHead) { }


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


  void menuSelection(PuckMenuItem item) { }


  void _drawIcon(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      if (socket != null) {
        ctx.rotate(socket.parent.rotation * -1);
      }
      ctx.fillStyle = color; 
      int size = fontSize + (_pop * 60).toInt();
      ctx.font = "${size}px $font";
      ctx.textBaseline = "middle";
      ctx.textAlign = "center";
      ctx.fillText("$icon", 0, 0);
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
            ctx.fillStyle = background; 
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
    bool refresh = false;
    if (_dragging) {
      centerX += (_touchX - _lastX);
      centerY += (_touchY - _lastY);
      _lastX = _touchX;
      _lastY = _touchY;
      highlight = workspace.findMatchingSocket(this);
      refresh = true;
    } 
    else if (socket != null) {
      centerX = socket.cx;
      centerY = socket.cy;
    }
    if (_pop > 0.05) {
      _pop *= 0.9;
      refresh = true;
    } else {
      _pop = 0.0;
    }
    return refresh;
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


  AudioPuck(num cx, num cy, String background, this.sound) : 
  super(cx, cy, background, null) {
    if (!Sounds.hasSound(sound)) {
      Sounds.loadSound(sound, sound);
    }
    icon = "d"; // eight note
    duration = millisPerMeasure / 8;
    menu.addItem("a", 1/2);  // half note
    menu.addItem("c", 1/4); // dotted quarter
    menu.addItem("d", 1/8, true); // 8th note
    menu.addItem("e", 1/16); // 16th note
  }


  TuneBlock clone(num cx, num cy) {
    return new AudioPuck(cx, cy, background, sound) .. icon = icon;
  }


  void menuSelection(PuckMenuItem item) { 
    duration = millisPerMeasure * item.data;
  }


  void eval(PlayHead player) {
    Sounds.playSound(sound, 
      volume : player.gain, 
      playback : player.playback,
      convolve : player.convolve);
    _pop = 1.0;
    score.addNote(0, player.lastbeat, duration * player.tempo, background);
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
 * Changes the master tempo of a play head
 */
class TempoPuck extends TunePuck {

  num tempo = 2;


  TempoPuck(num cx, num cy, String hint) : super(cx, cy, "#e2e7ed", hint) {
    fontSize = 28;
    color = "#666";
    icon = "6";  // tempo 2 fd

    menu.addItem("7", 4); // quadruple time
    menu.addItem("6", 2, true); // double time
    menu.addItem("5", 1/2); // slow down by half
    menu.addItem("4", 1/4);  // slow down by 1/4
  }


  void menuSelection(PuckMenuItem item) { 
    tempo = item.data;
  }


  TuneBlock clone(num cx, num cy) {
    return new TempoPuck(cx, cy, hint);
  }


  void eval(PlayHead player) {
    player.tempo = 1.0 / tempo; // min(32, player.tempo * 2);
  }
}




/**
 * Increases the volume of a play head
 */
class GainPuck extends TunePuck {

  num gain = 0.66;

  GainPuck(num cx, num cy, String hint) : super(cx, cy, "#e2e7ed", hint) {
    fontSize = 28;
    icon = "2";
    color = "#666";
    menu.addItem("3", 1.0); // high
    menu.addItem("2", 0.66, true); // medium
    menu.addItem("1", 0.33); // low
    menu.addItem("0", 0.0);   // mute
  }

  TuneBlock clone(num cx, num cy) {
    return new GainPuck(cx, cy, hint);
  }


  void menuSelection(PuckMenuItem item) { 
    gain = item.data;
  }


  void eval(PlayHead player) {
    player.gain = gain;
  }
}


/**
 * Increases the pitch of a play head
 */
class PitchPuck extends TunePuck {

  num pitch = 2.0;


  PitchPuck(num cx, num cy, String hint) : super(cx, cy, "#e2e7ed", hint) {
    fontSize = 36;
    icon = "h";
    color = "#666";
    menu.addItem("h", 2.0, true); // pitch up
    menu.addItem("g", 0.5);   // pitch down
  }


  TuneBlock clone(num cx, num cy) {
    return new PitchPuck(cx, cy, hint);
  }


  void menuSelection(PuckMenuItem item) { 
    pitch = item.data;
  }


  void eval(PlayHead player) {
    player.playback = pitch;
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
    fontSize = 36;
    color = "#666";
    icon = "y";
  }


  TuneBlock clone(num cx, num cy) {
    return new DistortPuck(cx, cy, impulse, hint);
  }


  void eval(PlayHead player) {
    player.convolve = impulse;
  }
}


/**
 * Jumps to a subroutine
 */
class JumpPuck extends TunePuck {

  String target = null;

  JumpPuck(num cx, num cy, String hint) : super(cx, cy, "#c12", hint) {
    color = "white";
    font = "sans-serif";
    icon = "A";
    menu.addItem("E", "E"); 
    menu.addItem("D", "D"); 
    menu.addItem("C", "C"); 
    menu.addItem("B", "B");
    menu.addItem("A", "A", true);
    menu.setFont("30px sans-serif");
  }


  TuneBlock clone(num cx, num cy) {
    return new JumpPuck(cx, cy, hint);
  }


  void eval(PlayHead player) {
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
            ctx.fillStyle = background; 
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
    fontSize = 40;
    icon = "J";
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
    icon = "m";
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
 * Loop puck
 */
class LoopPuck extends LogicPuck {

  int count = 2;

  int id = 0;

  static int LOOP_ID = 0;

  String get key => "loop-${id}";


  LoopPuck(num cx, num cy, String hint) : super(cx, cy, hint) {
    id = LOOP_ID++;
    icon = "t";
    fontSize = 38;
    menu.addItem("w", 5); 
    menu.addItem("v", 4); 
    menu.addItem("u", 3); 
    menu.addItem("t", 2, true); 
  }

  TuneBlock clone(num cx, num cy) {
    return new LoopPuck(cx, cy, hint);
  }


  void menuSelection(PuckMenuItem item) { 
    count = item.data;
  }


  void eval(PlayHead player) {
    if (player[key] == null) {
      player[key] = count;
    } else {
      player[key]--;
    }
  }

  bool goLeft(PlayHead player) {
    if (player.containsKey(key) && player[key] <= 0) {
      player.removeKey(key);
      return true;
    } else {
      return false;
    }
  }

  bool goRight(PlayHead player) {
    return !goLeft(player);
  }
}
