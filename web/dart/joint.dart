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

  // invisible joints just act as non-touchable counterweights
  bool invisible = false;

  // used for touch interaction
  bool _dragging = false;
  bool _dragged = false;
  num _lastX, _lastY;
  num _touchX, _touchY;
  num _startX, _startY;


  Joint(this.parent, this.cx, this.cy, this.offX, this.offY) {
    cx += offX;
    cy += offY;
    if (offX != 0 || offY != 0) offR = atan2(-offY, offX);
  }

  bool get isOpen => (connections.length < maxConnections);

  bool get isConnected => connections.isNotEmpty;

  bool isConnectedTo(TuneLink other) {
    for (Joint j in connections) {
      if (j.parent == other) return true;
    }
    return false;
  }

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


  void flash(CanvasRenderingContext2D ctx) {
    if (parent.inMenu) return;
    int flasher = clock.elapsedMilliseconds ~/ 3;
    ctx.save();
    {
      num alpha = sin(PI * flasher / 180) * 0.5 + 0.5;
      ctx.fillStyle = "rgba(255, 255, 240, $alpha)";
      ctx.beginPath();
      ctx.shadowOffsetX = 0;
      ctx.shadowOffsetY = 0;
      ctx.shadowBlur = 20 * workspace.zoom;
      ctx.shadowColor = "rgba(255, 255, 240, $alpha)";
      ctx.arc(cx, cy, radius * 0.65, 0, PI * 2, true);
      ctx.fill();
    }
    ctx.restore();
  }


  void drawCap(CanvasRenderingContext2D ctx) { }


  void disconnect() {
    for (Joint c in connections) {
      c.connections.remove(this);
    }
    connections.clear();
  }


  void translateBlock(num dx, num dy) {
    for (Joint j in parent.joints) {
      j.cx += dx;
      j.cy += dy;
    }
  }


  void dragChain() {
    _dragCenter();
    _dragLink();
  }


  void _dragCenter() {
    // drag opposite joint    
    Joint c = parent.getOppositeJoint(this); //parent.center;
    num dist = distance(c) - separation(c);
    num theta = angle(c);
    c.cx += dist * cos(theta);
    c.cy -= dist * sin(theta);
    theta = c.angle(this);

    // move center point to the correct location
    num a1 = atan2(offY - c.offY, c.offX - offX);
    num a2 = atan2(offY, -offX);
    num delta = a2 - a1;
    c = parent.center;
    dist = separation(c);
    c.cx = cx + dist * cos(theta + delta);
    c.cy = cy - dist * sin(theta + delta);
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


  bool animate() {
    highlight = null;

    if (_dragging) {
      if (_dragged || dist(_touchX, _touchY, _startX, _startY) >= radius * 0.75) {
        cx += (_touchX - _lastX);
        cy += (_touchY - _lastY);
        _lastX = _touchX;
        _lastY = _touchY;
        _dragged = true;
      }
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
    if (invisible) return false;
    num a2 = (c.touchX - cx) * (c.touchX - cx);
    num b2 = (c.touchY - cy) * (c.touchY - cy);
    num c2 = radius * radius;
    return a2 + b2 <= c2;
  }
 

  Touchable touchDown(Contact c) {
    _dragging = true;
    _dragged = false;
    _touchX = c.touchX;
    _touchY = c.touchY;
    _lastX = c.touchX;
    _lastY = c.touchY;
    _startX = c.touchX;
    _startY = c.touchY;
    return this;
  }


  void touchUp(Contact event) { 
    _dragging = false;
    _dragged = false;
  }
 

  void touchDrag(Contact c) {
    _touchX = c.touchX;
    _touchY = c.touchY;
  }
   
  void touchSlide(Contact event) {  }

}


class Plug extends Joint {
  Plug(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 1;
    cw = PLUG_WIDTH;
  }


  bool containsTouch(Contact c) {
    if (isConnected) {
      return false;
    } else {
      return super.containsTouch(c);
    }
  }


  bool isConnection(Joint o) => (o is Socket && isOpen && o.isOpen && isNear(o));
}
