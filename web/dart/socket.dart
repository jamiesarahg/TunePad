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
    return !(p is LogicPuck);
  }


  bool get hasPuck => (puck != null);


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
  int get duration {
    return (puck == null)? millisPerMeasure / 8 : puck.duration;
  }


  void drawCap(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      if (_showMenu && hasPuck) {
        puck.drawMenu(ctx, _menuX, _menuY);
      }

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


  Touchable touchDown(Contact c) {
    _showMenu = false;
    _menuX = c.touchX;
    _menuY = c.touchY;
    new Timer(const Duration(milliseconds : 850), _launchMenu);
    return super.touchDown(c);
  }


  void touchUp(Contact event) { 
    if (_showMenu && hasPuck) {
      puck.menuSelection(puck.screenToMenuIndex(_menuX, _menuY));
    }
    _showMenu = false;
    super.touchUp(event);
  }
 
  num _menuX, _menuY;
  void touchDrag(Contact c) {
    _menuX = c.touchX;
    _menuY = c.touchY;
    if (!_showMenu) {
      super.touchDrag(c);
    }
  }
   
  bool _showMenu = false;

  void _launchMenu() {
    if (!_dragged && hasPuck) {
      _showMenu = true;
    }
  }
}



/**
 * A logic socket takes hexagonal logic pucks
 */
class LogicSocket extends Socket {

  // hidden split puck
  SplitPuck _spuck = null;


  LogicSocket(TuneLink parent, num cx, num cy, num offX, num offY) : 
    super(parent, cx, cy, offX, offY) {
    maxConnections = 2;
    cw = SOCKET_WIDTH;
    _spuck = new SplitPuck(cx, cy, "Split");
  }


  LogicPuck get logicPuck => (puck == null) ? _spuck : (puck as LogicPuck);


  void eval(PlayHead player) {
    logicPuck.eval(player);
    parent.eval(player);
  }


  bool goLeft(PlayHead player) => logicPuck.goLeft(player);

  bool goRight(PlayHead player) => logicPuck.goRight(player);

  int get duration => -1;

  bool canAcceptPuck(TunePuck p) {
    return p is LogicPuck;
  }


  void drawCap(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = "white";
      ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
      ctx.shadowOffsetX = 2 * workspace.zoom;
      ctx.shadowOffsetY = 2 * workspace.zoom;
      ctx.shadowBlur = 5 * workspace.zoom;
      ctx.translate(cx, cy);
      ctx.rotate(PI / 6 - parent.rotation);
      ctx.beginPath();
      ctx.moveTo(0, -radius * 1.15);
      for (int i=0; i<6; i++) {
        ctx.rotate(PI / 3);
        ctx.lineTo(0, -radius * 1.15);
      }
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();

    ctx.save();
    {
      ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
      ctx.shadowOffsetX = -1 * workspace.zoom;
      ctx.shadowOffsetY = -1 * workspace.zoom;
      ctx.shadowBlur = 2 * workspace.zoom;
      ctx.fillStyle = "#e2e7ed";//"#d2d7dd";
      ctx.translate(cx + 1, cy + 1);
      ctx.rotate(PI / 6 - parent.rotation);
      ctx.beginPath();
      ctx.moveTo(0, PUCK_WIDTH * -0.575);
      for (int i=0; i<6; i++) {
        ctx.rotate(PI / 3);
        ctx.lineTo(0, PUCK_WIDTH * -0.575);
      }
      ctx.closePath();
      ctx.fill();
    }
    ctx.restore();
  }
}
