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



class TuneLink extends TuneBlock {

  // size of the block
  num _width = BLOCK_WIDTH;

  // color of the block
  String color = "rgb(0, 160, 227)";

  List<Joint> joints = new List<Joint>();

  Joint _target;


  TuneLink(num cx, num cy) {
    _width = BLOCK_WIDTH;

    // socket
    joints.add(new Socket(this, cx, cy, _width * -0.75, 0));

    // center drag handle
    joints.add(new Joint(this, cx, cy, 0, 0));

    // plug
    joints.add(new Plug(this, cx, cy, _width * 0.75, 0));
  }


  TuneBlock clone(num cx, num cy) {
    return new TuneLink(cx, cy);
  }


  num get rotation => center.angle(socket);
  num get centerX => center.cx;
  num get centerY => center.cy;
  Joint get socket => joints[0];
  Joint get center => joints[1];
  Joint get plug => joints[2];
  bool get isDragging => _target != null;
  bool get isSocketDragging => _target is Socket;
  bool get isPlugDragging => _target is Plug;


  bool get isConnected {
    for (Joint j in joints) if (j.isConnected) return true;
    return false;
  }

/**
 * Return true if there's a direct connection (1 degree of separation) to the
 * other link
 */
  bool isDirectConnection(TuneLink other) {
    for (Joint j in joints) {
      if (j.isConnectedTo(other)) return true;
    }
    return false;
  }


/**
 * Detects a special case where two links are directly connected across 
 * a split link fork.
 */
  bool isShortCircuit(TuneLink other) {
    for (Joint j in joints) {
      for (Joint k in j.connections) {
        if (k.parent is SplitLink) {
          if (other.isDirectConnection(k.parent)) {
            return true;
          }
        }
        else if (other is SplitLink) {
          if (k.parent.isDirectConnection(other)) {
            return true;
          }
        }
      }
    }
    return false;
  }


  bool get isOverMenu {
    for (Joint j in joints) {
      if (workspace.isOverMenu(j.cx, j.cy)) return true;
    }
    return false;
  }


/**
 * When the playhead arrives at a new socket, it starts by calling 
 * eval to do things like make sounds or add effects. Mostly this 
 * gets handled by the socket and the puck, but for things like 
 * split links, some logic needs to happen here.
 */
  void eval(PlayHead player) { }


/**
 * Advance the playhead to the next link in the chain.
 */
  Socket advance(PlayHead player) {
    if (plug.isConnected) {
      return plug.connections[0];
    }
    return null;
  }


  Joint getOppositeJoint(Joint j) {
    if (j is Plug) {
      return socket;
    }
    else if (j is Socket) {
      return plug;
    }
    else {
      return center;
    }
  }


  void draw(CanvasRenderingContext2D ctx, [layer = 0]) {
    num theta = rotation;
    num cx = centerX;
    num cy = centerY;

    ctx.save();
    {
      switch (layer) {
      case 0:

        //----------------------------------------------
        // link outline
        //----------------------------------------------
        _outlineBlock(ctx);
        ctx.shadowColor = "rgba(0, 0, 0, 0.3)";
        ctx.shadowOffsetX = 2 * workspace.zoom;
        ctx.shadowOffsetY = 2 * workspace.zoom;
        ctx.shadowBlur = 5 * workspace.zoom;
        ctx.fillStyle = "#d2d7dd"; //"#e2e7ed";
        ctx.fill();

        //----------------------------------------------
        // slightly darker shadow on joints
        //----------------------------------------------
        /*
        ctx.fillStyle = "rgba(255, 255, 255, 0.15)"; //rgba(0, 0, 0, 0.05)";
        for (Joint j in joints) {
          if (j is Plug) {
            ctx.beginPath();
            ctx.arc(j.cx, j.cy, j.radius, 0, PI * 2, true);
            ctx.fill();
          }
        }
        */

        _drawIcon(ctx);

        break;

      case 1:
        //----------------------------------------------
        // joint caps
        //----------------------------------------------
        for (Joint j in joints) j.drawCap(ctx);
        break;


      case 2:
        //----------------------------------------------
        // highlight
        //----------------------------------------------
        ctx.fillStyle = "rgba(255, 255, 240, 0.9)";
        for (Joint j in joints) {
          if (j.highlight != null) {
            Joint h = (j is Socket) ? j.highlight : j;
            ctx.beginPath();
            ctx.arc(h.cx, h.cy, h.radius, 0, PI * 2, false);
            ctx.fill();
          }
          if (j is Socket && workspace.isPuckDragging) {
            j.flash(ctx);
          }
        }
        break;
      }
    }
    ctx.restore();
  }


  void _drawIcon(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      ctx.shadowColor = "transparent";
      ctx.font = "28px FontAwesome";
      ctx.fillStyle = "white";
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      ctx.fillText("\uf178", 2, 0);
    }
    ctx.restore();
  }


  void _outlineBlock(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      ctx.beginPath();
      ctx.arc(socket.offX, socket.offY, socket.radius, PI * 0.33, PI * 1.66, false);
      ctx.quadraticCurveTo(0, 0, 
                           plug.offX + plug.radius * cos(PI * 1.33), 
                           plug.offY + plug.radius * sin(PI * 1.33));
      ctx.arc(plug.offX, plug.offY, plug.radius, PI * 1.33, PI * 0.66, false);
      ctx.quadraticCurveTo(0, 0, 
                           socket.offX + socket.radius * cos(PI * 0.33), 
                           socket.offY + socket.radius * sin(PI * 0.33));
      ctx.closePath();
      ctx.arc(plug.offX, plug.offY, plug.radius * 0.5, 0, PI * 2, true);
    }
    ctx.restore();
  }


  bool animate(int millis) { 
    bool refresh = false;
    for (Joint j in joints) {
      if (j.animate()) refresh = true;
      if (j._dragging) j.dragChain();
    }
    return refresh;
  }


  void relax() {
    for (Joint j in joints) {
      j.relax();
    }
  }


  void connect() {
    for (Joint j in joints) {
      if (j.highlight != null) {
        if (!isDirectConnection(j.highlight.parent)) {
          j.highlight.connections.add(j);
          j.connections.add(j.highlight);
          j.cx = j.highlight.cx;
          j.cy = j.highlight.cy;
          j.dragChain();
          Sounds.playSound("click");
        }
        j.highlight = null;
      }
    }
  }


  void disconnect() {
    for (Joint j in joints) j.disconnect();
  }


  Joint findOpenConnector(Joint j) {
    for (TuneLink other in workspace.links) {
      if (other != this && !isDirectConnection(other)) {
        for (Joint joint in other.joints) {
          if (joint.isConnection(j)) {
            if (!isShortCircuit(other)) {
              return joint;
            }
          }
        }
      }
    }
    return null;
  }


/** 
 * Recursively delete an entire chain of links 
 */
  void _trashChain() {
    trash = true;

    // 1. throw away pucks
    for (Joint j in joints) {
      if (j is Socket) {
        Socket s = j;
        if (s.puck != null) {
          s.puck.trash = true;
          s.puck.disconnect();
        }
      }
    }

    // 2. recursively throw away connected links
    for (Joint j in joints) {
      for (int k = j.connections.length - 1; k >= 0; k--) {
        Joint c = j.connections[k];
        if (!c.parent.trash) {  // prevent infinite recursion
          c.parent._trashChain();
        }
      }
      j.disconnect();
    }
  }


  bool containsTouch(Contact c) {
    for (Joint j in joints) {
      if (j.containsTouch(c)) return true;
    }
    return false;
  }


  Touchable touchDown(Contact c) {
    _target = null;
    for (Joint j in joints) {
      if (j.containsTouch(c)) {
        _target = j;
        _target.touchDown(c);
        _target.disconnect();
        if (inMenu) {
          _target.cx -= 20;
          _target.cy += 20;
        }
        return this;
      }
    }
    return null;
  }


  void touchUp(Contact c) {
    if (_target != null) {
      _target.touchUp(c);
      connect();
    }
    _target = null;
    if (isOverMenu) {
      _trashChain();
    }
    inMenu = false;
    workspace.draw();
  }


  void touchDrag(Contact c) {
    if (_target != null) {
      _target.touchDrag(c);
    }
  }
   
  void touchSlide(Contact c) {  }
}


/**
 * A link with one socket and two plugs
 */
class SplitLink extends TuneLink {

  Joint get lplug => joints[2];
  Joint get rplug => joints[3];
  Joint get anchor => joints[4];


  SplitLink(num cx, num cy) : super(cx, cy) {
    joints.removeLast();
    num l = _width * 1.8;
    num h = l * tan(PI / 6);
    joints.add(new Plug(this, cx, cy, _width * 0.9, -h));
    joints.add(new Plug(this, cx, cy, _width * 0.9, h));
    joints.add(new Joint(this, cx, cy, _width, 0) .. invisible = true);
  }


  TuneBlock clone(num cx, num cy) {
    return new SplitLink(cx, cy);
  }


  void eval(PlayHead player) { 
    _clone = player.parent.split(player);
  }
  PlayHead _clone = null;


  Socket advance(PlayHead player) {
    if (player == _clone) {
      _clone = null;
      return rplug.isConnected ? rplug.connections[0] : null;
    }
    else {
      return lplug.isConnected ? lplug.connections[0] : null;
    }
  }


  Joint getOppositeJoint(Joint j) {
    if (j is Plug) {
      return socket;
    }
    else if (j is Socket) {
      return anchor;
    }
    else {
      return center;
    }
  }


  void _outlineBlock(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      ctx.beginPath();
      ctx.arc(rplug.offX, rplug.offY, rplug.radius * 0.5, 0, PI * 2, true);
      ctx.arc(socket.offX, socket.offY, socket.radius, PI * 0.33, PI * 1.66, false);
      ctx.quadraticCurveTo(0, 0, lplug.offX - lplug.radius, lplug.offY);
      ctx.arc(lplug.offX, lplug.offY, lplug.radius, PI, PI * 0.43, false);
      ctx.quadraticCurveTo(0, 0, 
                           rplug.offX + rplug.radius * cos(PI * 1.66),
                           rplug.offY + rplug.radius * sin(PI * 1.66));
      ctx.arc(rplug.offX, rplug.offY, rplug.radius, PI * 1.66, PI, false);
      ctx.quadraticCurveTo(0, 0, 
                           socket.offX + socket.radius * cos(PI * 0.33), 
                           socket.offY + socket.radius * sin(PI * 0.33));
      ctx.closePath();
      ctx.arc(lplug.offX, lplug.offY, lplug.radius * 0.5, 0, PI * 2, true);
    }
    ctx.restore();
  }
}


/**
 * A link with two sockets and one plug
 */
class JoinLink extends TuneLink {

  Joint get lsocket => joints[0];
  Joint get rsocket => joints[3];
  num get rotation => plug.angle(center);


  JoinLink(num cx, num cy) : super(cx, cy) {
    num l = _width * 1.5;
    num h = l * tan(PI / 6);

    joints.clear();

    // left socket
    joints.add(new Socket(this, cx, cy, _width * -0.75, -h));

    // center drag handle
    joints.add(new Joint(this, cx, cy, 0, 0));

    // plug
    joints.add(new Plug(this, cx, cy, _width * 0.75, 0));

    // right socket
    joints.add(new Socket(this, cx, cy, _width * -0.75, h));
  }


  TuneBlock clone(num cx, num cy) {
    return new JoinLink(cx, cy);
  }

  void _outlineBlock(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      ctx.beginPath();
      ctx.arc(lsocket.offX, lsocket.offY, lsocket.radius, PI * 0.66, PI * 0, false);
      ctx.quadraticCurveTo(
        -15, 0, 
        plug.offX + plug.radius * cos(PI * 1.33),
        plug.offY + plug.radius * sin(PI * 1.33));
      ctx.arc(plug.offX, plug.offY, plug.radius, PI * 1.33, PI * 0.66, false);
      ctx.quadraticCurveTo(
        -15, 0, 
        rsocket.offX + rsocket.radius * cos(PI * 0),
        rsocket.offY + rsocket.radius * sin(PI * 0));
      ctx.arc(rsocket.offX, rsocket.offY, rsocket.radius, PI * 0, PI * 1.33, false);
      ctx.quadraticCurveTo(
        0, 0, 
        lsocket.offX + lsocket.radius * cos(PI * 0.66), 
        lsocket.offY + lsocket.radius * sin(PI * 0.66));
      ctx.closePath();
      ctx.arc(plug.offX, plug.offY, plug.radius * 0.5, 0, PI * 2, true);
    }
    ctx.restore();
  }
}



/**
 * Adds a playhead to the chain
 */
class PlayLink extends TuneLink {

  List<PlayHead> players = new List<PlayHead>();

  ButtonJoint get button => joints[0];


  PlayLink(num cx, num cy) : super(cx, cy) {
    joints.clear();

    // play button
    joints.add(
      new ButtonJoint(this, cx, cy, _width * -0.75, 0)
      .. action = onClick);

    // center drag handle
    joints.add(new Joint(this, cx, cy, 0, 0));

    // plug
    joints.add(new Plug(this, cx, cy, _width * 0.75, 0));

  }


  void stepProgram(int millis) {
    bool running = false;
    for (int i=players.length - 1; i >= 0; i--) {
      players[i].stepProgram(millis);
      if (players[i].isDone) {
        players.removeAt(i);
      } else {
        running = true;
      }
    }

    if (!running && button.playing) {
      button.playing = false;
      workspace.draw();
    }
/*
    if (player.isDone) {
      button.playing = false;
      player.restart();
      player.pause();
      workspace.draw();
    }
*/
  }


  void resume() {
    if (players.isEmpty) players.add(new PlayHead(button, this));
    for (PlayHead player in players) player.resume();
  }


  void pause() {
    for (PlayHead player in players) player.pause();
    players.clear();
  }


  PlayHead split(PlayHead player) {
    PlayHead clone = new PlayHead.copy(player);
    players.add(clone);
    return clone;
  }


  void onClick(ButtonJoint button) {
    if (button.playing) {
      resume();
    } else {
      pause();
    }
  }


  TuneBlock clone(num cx, num cy) {
    return new PlayLink(cx, cy);
  }
}
