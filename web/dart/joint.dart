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

/**
* A joint is control point touch handel that allows 
* for the rotation and connection of links. Lots 
* of the complicated logic for the physics-like
* interactions get hidden in here.
*/
class Joint extends Touchable {

  TuneLink parent;

  Joint highlight = null;

  // links connected to this one 
  List<Joint> connections = new List<Joint>();

  // maximum number of connections allowed
  int maxConnections = 0;

  // position and size 
  num cx, cy, cw = JOINT_WIDTH;

  // offset from the center of the parent
  num offX = 0, offY = 0, offR = 0;

  // simulates magnetic force connections
  num forceX = 0, forceY = 0;

  // used for touch interaction
  bool _dragging = false;
  num _lastX, _lastY;
  num _touchX, _touchY;


  Joint(this.parent, this.cx, this.cy, this.offX, this.offY) {
    cx += offX;
    cy += offY;
    if (offX != 0 || offY != 0) offR = atan2(-offY, offX);
  }

  bool get isOpen => (connections.length < maxConnections);

  bool get isConnected => connections.isNotEmpty;

  num get radius => cw / 2;

  bool isNear(Joint o) => distance(o) < (radius + o.radius);

  bool isConnection(Joint o) => false;

  num distance(Joint o) => sqrt((o.cx - cx) * (o.cx - cx) + (o.cy - cy) * (o.cy - cy));

  num angle(Joint o) => atan2(o.cy - cy, cx - o.cx);

  num separation(Joint o) => sqrt((o.offX - offX) * (o.offX - offX) + (o.offY - offY) * (o.offY - offY));


  void draw(CanvasRenderingContext2D ctx) {
    if (highlight != null) {
      ctx.fillStyle = "rgba(255, 255, 255, 0.5)";
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, PI*2, true);
      ctx.fill();
    }
  }


  void drawCap(CanvasRenderingContext2D ctx) { }


  void disconnect() {
    for (Joint c in connections) {
      c.connections.remove(this);
    }
    connections.clear();
  }


  void dragChain() {
    _dragCenter();
    _dragLink();
  }


  void _dragCenter() {
    // drag opposite joint    
    Joint c = _getOppositeJoint(); //parent.center;
    num dist = distance(c) - separation(c);
    num theta = angle(c);
    c.cx += dist * cos(theta);
    c.cy -= dist * sin(theta);
    num alpha = atan2(offY - c.offY, c.offX - offX);
    theta = c.angle(this);

    // move center point to the correct location
    c = parent.center;
    dist = separation(c);
    c.cx = cx + dist * cos(theta);
    c.cy = cy - dist * sin(theta);
  }


  void _dragLink() {
    Joint c = parent.center;
    num theta = (this == c) ? parent.rotation : c.angle(this) - offR - PI;

    for (Joint j in parent.joints) {
      if (j != this && j != c) {
        num alpha = j.offR + theta;
        num dist = j.separation(c);
        j.cx = c.cx + dist * cos(alpha);
        j.cy = c.cy - dist * sin(alpha);
      }
    }
  }


  Joint _getOppositeJoint() {
    if (parent.joints.length > 3) {
      return parent.center;
    }
    else if (this is Plug) {
      return parent.socket;
    }
    else if (this is Socket) {
      return parent.plug;
    }
    else {
      return parent.center;
    }
  }


  bool animate() {
    highlight = null;

    if (_dragging) {
      cx += (_touchX - _lastX);
      cy += (_touchY - _lastY);
      _lastX = _touchX;
      _lastY = _touchY;
      highlight = parent.findOpenConnector(this);
      return true;
    } 
    else if (parent.isDragging) {
      highlight = parent.findOpenConnector(this);
      return true;
    }
    else {
      forceX = 0;
      forceY = 0;
      for (Joint c in connections) {
        forceX += (c.cx - cx);
        forceY += (c.cy - cy);
      }
      return (forceX.abs() > 0.1 || forceY.abs() > 0.1);
    }
  }


  void relax() {
    if (forceX.abs() > 0.1 || forceY.abs() > 0.1) {
      cx += forceX * 0.3;
      cy += forceY * 0.3;
      dragChain();
    }
    forceX = 0;
    forceY = 0;
  }


  bool containsTouch(Contact c) {
    num a2 = (c.touchX - cx) * (c.touchX - cx);
    num b2 = (c.touchY - cy) * (c.touchY - cy);
    num c2 = radius * radius;
    return a2 + b2 <= c2;
  }
 

  bool touchDown(Contact c) {
    _dragging = true;
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    return true;
  }


  void touchUp(Contact event) { 
    _dragging = false;
  }
 

  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;
  }
   
  void touchSlide(Contact event) {  }

}


class Socket extends Joint {

  int _flasher = 0;

  TunePuck puck = null;

  Socket(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 2;
    cw = SOCKET_WIDTH;
  }


  bool canAcceptPuck(TunePuck p) {
    return puck != null;
  }


  bool animate() {
    _flasher += 5;
    return super.animate();
  }


  void eval(PlayHead player) {
    if (puck != null) {
      puck.eval(player);
    }
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


  void flash(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      num alpha = sin(PI * _flasher / 180) * 0.5 + 0.5;
      ctx.fillStyle = "rgba(255, 255, 240, $alpha)";
      ctx.beginPath();
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 0;
      ctx.shadowBlur = 20;
      ctx.shadowColor = "rgba(255, 255, 240, $alpha)";
      ctx.arc(cx, cy, PUCK_WIDTH / 2 - 10, 0, PI * 2, true);
      ctx.fill();
    }
    ctx.restore();
  }

  bool isConnection(Joint o) => (o is Plug && isOpen && o.isOpen && isNear(o));
}


class Plug extends Joint {
  Plug(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 1;
    cw = PLUG_WIDTH;
  }

  bool isConnection(Joint o) => (o is Socket && isOpen && o.isOpen && isNear(o));
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


