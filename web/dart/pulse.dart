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


const PULSE_RADIUS = 7;

const PULSE_GRAVITY = 0;


class TunePulse {

  // don't collide with your own parent
  TunePuck parent;

  // location center point and size
  num cx, cy, radius;

  // velocity vector
  num vx, vy;

  // fade out over time
  num energy = 1.0;

  // if dead it will get removed from the game
  bool dead = false;


  TunePulse(this.parent, this.cx, this.cy, this.vx, this.vy) {
    radius = PULSE_RADIUS;
  }


/**
 * Just draw as a two colored pointn
 */
  void draw(CanvasRenderingContext2D ctx) {
    ctx.save();
    {
      ctx.fillStyle = "rgba(255, 0, 80, ${0.7 * energy})";
      if (dead) ctx.fillStyle = "black";
      ctx.beginPath();
      ctx.arc(cx, cy, radius, 0, PI * 2, true);
      ctx.fill();
      ctx.fillStyle = "rgba(255, 200, 80, $energy)";
      ctx.beginPath();
      ctx.arc(cx, cy, radius - 3, 0, PI * 2, true);
      ctx.fill();
    }
    ctx.restore();
  }


  bool animate(int millis) { 
    num cx = 300;
    num vx = 2;
    num vy = 2;

    cx += vx;
    cy += vy;
    vy += PULSE_GRAVITY;

    if (energy < 0.01) {
      dead = true;
      energy = 0.0;
    }
    else {
      energy *= 0.99;
    }

    TunePuck collision = workspace.collisionCheck(this);
    if (collision != null) {
      collision.hit();
      dead = true;
    }
    return true;
  }
}
