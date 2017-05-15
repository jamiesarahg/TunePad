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


// block workspace definitions (can also go in an external JSON file)
var BLOCKS = {

  "name" : "Pucks",
  "canvasId" : "blocks-canvas",
  "touchElement" : "blocks-canvas",
  //"anchor" : "left", (top | bottom | right)
  "color" : "rgba(0, 0, 0, 0.6)",
  "defaultProgram" : "pulse();rest();",
  "fastForwardButton" : false,
  "stepForwardButton" : false,

  "blocks" : [
    {
      "name" : "pulse",
      "instances" : 3,
      "params" : [
        {
          "type" : "range",
          "min" : 0,
          "max" : 10,
          "step" : 1,
          "default" : 4,
          "random" : true,
          "label" : "velocity"
        }
      ]
    },
    {
      "name" : "rest",
      "instances" : 3
    },
    {
      "name" : "turn",
      "instances" : 3,
      "params" : [
        {
          "type" : "range",
          "min" : 0,
          "max" : 90,
          "step" : 1,
          "default" : 45,
          "random" : true,
          "label" : "degrees"
        }
      ]
    },
    {
      "instances" : 2,
      "name" : "chance",
      "type" : "chance"
    },
    {
      "name" : "send to",
      "instances" : 3,
      "params" : [
        {
          "type" : "range",
          "min" : 0,
          "max" : 2,
          "step" : 1,
          "default" : 0,
          "random" : true,
          "label" : "puck number"
        }
      ]
    }
  ]
};


