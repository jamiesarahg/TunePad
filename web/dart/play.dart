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
 * Playheads move along chains from play links. As they pass through audio blocks,
 * they initiate sounds.
 */
class PlayHead {
  
  // The first socket for this playhead (socket for the play link)
  Socket start = null;

  // Current socket in the chain
  Socket current = null;

  // 1, 2, 4, 8, 16, or 32 (higher means faster)
  int tempo = 8; // 8th notes

  // volume
  num gain = 0.6;  

  // this changes pitch (but only as a side effect of changing the play)
  num playback = 1.0;   // playback rate

  // covolution impulse to play with sounds
  String convolve = null;

  
  PlayLink get parent => start.parent;



  PlayHead(this.start) {
    current = start;
  }


  PlayHead.copy(PlayHead other) {
    start = other.start;
    current = other.current;
    tempo = other.tempo;
    gain = other.gain;
    playback = other.playback;
    convolve = other.convolve;
  }


  void reset() {
    tempo = 8;
    gain = 0.6;
    playback = 1.0;
    convolve = null;
  }


  bool get isDone => current == null;


  void restart() {
    current = start;
    reset();
  }


  void stop() {
    current = null;
  }


  void stepProgram(int millis) {

    if (current == null) return;

    // advance on the next matching beat
    if (millis % (millisPerMeasure ~/ tempo) == 0) {
      Socket source = null;
      while (current != null && current != source) {

        // this prevents short circuits and stack overflows
        if (source == null && current != start) source = current;

        // move to the next socket in the chain
        current = current.advance(this);
        if (current != null) {

          // call eval on the current socket 
          current.eval(this);
          if (!current.skipAhead(this)) break;
        }
      }
    }
  }


  bool animate(int millis) { }
}


/**
 * Play / pause button link 
 */
class PlayLink extends TuneLink {

  // list of playheads originating from this link
  // usually this is only one unless there's a split
  List<PlayHead> players = new List<PlayHead>();

  // play / pause button
  PlaySocket get button => joints[0];


  PlayLink(num cx, num cy) : super(cx, cy) {
    joints.clear();

    // play button socket
    joints.add(
      new PlaySocket(this, cx, cy, _width * -0.75, 0)
      .. action = onClick);

    // center drag handle
    joints.add(new Joint(this, cx, cy, 0, 0));

    // plug
    joints.add(new Plug(this, cx, cy, _width * 0.75, 0));
  }


  TuneBlock clone(num cx, num cy) {
    return new PlayLink(cx, cy);
  }


  void stepProgram(int millis) {
    bool running = false;

    for (int i=0; i < players.length; i++) {
      players[i].stepProgram(millis);
      if (!players[i].isDone) running = true;
    }

    for (int i=players.length - 1; i >= 0; i--) {
      if (players[i].isDone) players.removeAt(i);
    }

    if (!running && button.playing) {
      button.playing = false;
      workspace.draw();
    }
  }


  void play() {
    if (players.isEmpty) players.add(new PlayHead(button));
  }


  void pause() {
    for (PlayHead player in players) player.stop();
    players.clear();
  }


  PlayHead split(PlayHead player) {
    PlayHead clone = new PlayHead.copy(player);
    players.add(clone);
    return clone;
  }


  void onClick(PlaySocket button) {
    if (button.playing) {
      play();
    } else {
      pause();
    }
  }
}


/**
 * Play / pause button socket
 */
class PlaySocket extends Socket {

  bool _down = false;

  bool playing = false;

  num _startX, _startY;

  Function action = null;

  PlaySocket(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 0;
    cw = SOCKET_WIDTH;
  }


  bool canAcceptPuck(TunePuck p) {
    return false;
  }


  void drawCap(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(cx, cy);
      ctx.rotate(-parent.rotation);
      ctx.fillStyle = _down ? "#aaeeff" : "white";
      ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
      ctx.shadowOffsetX = 2 * workspace.zoom;
      ctx.shadowOffsetY = 2 * workspace.zoom;
      ctx.shadowBlur = 5 * workspace.zoom;
      ctx.beginPath();
      ctx.arc(0, 0, radius, 0, PI * 2, false);
      ctx.fill();

      ctx.font = "64px FontAwesome";
      ctx.fillStyle = "#5f6972";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
      ctx.shadowOffsetX = 2 * workspace.zoom;
      ctx.shadowOffsetY = 2 * workspace.zoom;
      ctx.shadowBlur = 3 * workspace.zoom;
      // pause \uf04c
      // stop \uf04d
      // fforward \uf04e
      // play \uf04b
      num delta = _down ? 2 * workspace.zoom : 0;
      ctx.fillText(playing ? "\uf28b" : "\uf144", delta, delta); // f28b pause-circle
    }
    ctx.restore();
  }

  void flash(CanvasRenderingContext2D ctx) { }

  bool isConnection(Joint o) => false;


  Touchable touchDown(Contact c) {
    _down = !parent.inMenu;
    return super.touchDown(c);
  }


  void touchUp(Contact c) { 
    if (_down) {
      playing = !playing;
      if (action != null) {
        Function.apply(action, [ this ]);
      }
    }
    _down = false;
    super.touchUp(c);
  }
 

  void touchDrag(Contact c) {
    if (!_down || !containsTouch(c)) {
      _down = false;
      super.touchDrag(c);
    }
  }
}

