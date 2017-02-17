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
 * A link with one socket and two plugs
 */
class SplitLink extends TuneLink {

  Joint get lplug => joints[2];
  Joint get rplug => joints[3];
  Joint get anchor => joints[4];
  LogicSocket get logicSocket => (socket as LogicSocket);


  SplitLink(num cx, num cy) : super(cx, cy) {
    joints.clear();
    num l = _width * 1.75;
    num h = l * tan(PI / 6);

    // socket
    joints.add(new LogicSocket(this, cx, cy, _width * -0.75, 0));

    // center drag handle
    joints.add(new Joint(this, cx, cy, 0, 0));

    // plugs
    joints.add(new Plug(this, cx, cy, _width * 0.9, -h));
    joints.add(new Plug(this, cx, cy, _width * 0.9, h));

    // invisible counter weight for dragging
    joints.add(new Joint(this, cx, cy, _width, 0) .. invisible = true);
  }


  TuneBlock clone(num cx, num cy) {
    return new SplitLink(cx, cy);
  }


  Socket advance(PlayHead player) {
    if (logicSocket.goRight(player)) {
      return rplug.isConnected ? rplug.connections[0] : null;
    } else {
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
      num srad = socket.radius * 0.85;
      ctx.translate(centerX, centerY);
      ctx.rotate(-rotation);
      ctx.beginPath();
      ctx.arc(rplug.offX, rplug.offY, rplug.radius * 0.5, 0, PI * 2, true);
      ctx.arc(socket.offX, socket.offY, srad, PI * 0.33, PI * 1.66, false);
      ctx.quadraticCurveTo(0, 0, lplug.offX - lplug.radius, lplug.offY);
      ctx.arc(lplug.offX, lplug.offY, lplug.radius, PI, PI * 0.43, false);
      ctx.quadraticCurveTo(0, 0, 
                           rplug.offX + rplug.radius * cos(PI * 1.66),
                           rplug.offY + rplug.radius * sin(PI * 1.66));
      ctx.arc(rplug.offX, rplug.offY, rplug.radius, PI * 1.66, PI, false);
      ctx.quadraticCurveTo(0, 0, 
                           socket.offX + srad * cos(PI * 0.33), 
                           socket.offY + srad * sin(PI * 0.33));
      ctx.closePath();
      ctx.arc(lplug.offX, lplug.offY, lplug.radius * 0.5, 0, PI * 2, true);
    }
    ctx.restore();
  }
}

