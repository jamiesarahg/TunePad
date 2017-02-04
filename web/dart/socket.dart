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
 * A socket is control point that allows joint connections and puck attachments
 */
class Socket extends Joint {

  TunePuck puck = null;

  Socket(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 2;
    cw = SOCKET_WIDTH;
  }


  bool canAcceptPuck(TunePuck p) {
    return puck == null;
  }


  bool animate() {
    return super.animate();
  }


/**
 * As the playhead moves through a chain, it calls advance to move on to 
 * the next socket.
 */
  Socket advance(PlayHead player) {
    return parent.advance(player);
  }


/**
 * When the playhead arrives at a new socket, it starts by calling 
 * eval to do things like make sounds or add effects
 */
  void eval(PlayHead player) {
    if (puck != null) puck.eval(player);
    parent.eval(player);
  }


/**
 * Certain types of pucks should get evaluated instantly and then 
 * advance the playhead
 */
  bool skipAhead(PlayHead player) {
    return (puck != null && puck.skipAhead(player));
  }


  void drawCap(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = "white";
      ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
      ctx.shadowOffsetX = 2 * workspace.zoom;
      ctx.shadowOffsetY = 2 * workspace.zoom;
      ctx.shadowBlur = 5 * workspace.zoom;
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, PI * 2, false);
      ctx.fill();

      ctx.shadowOffsetX = -1 * workspace.zoom;
      ctx.shadowOffsetY = -1 * workspace.zoom;
      ctx.shadowBlur = 2 * workspace.zoom;
      ctx.fillStyle = "#e2e7ed";//"#d2d7dd";
      ctx.beginPath();
      ctx.arc(cx + 1, cy + 1, PUCK_WIDTH / 2, 0, PI * 2, false);
      ctx.fill();
    }
    ctx.restore();
  }

  bool isConnection(Joint o) => (o is Plug && isOpen && o.isOpen && isNear(o));
}


class ButtonJoint extends Socket {

  bool _down = false;

  bool playing = false;

  num _startX, _startY;

  Function action = null;

  ButtonJoint(TuneLink parent, num cx, num cy, num offX, num offY) : 
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


  bool touchDown(Contact c) {
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


