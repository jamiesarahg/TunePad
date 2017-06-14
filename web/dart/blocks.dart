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
  "defaultProgram" : "send to pucks();",
  "fastForwardButton" : false,
  "stepForwardButton" : false,

  "startBlocks" : [
    {
       "name" : "while 'play'",
       "color" : "black",
       "position" : 20
    },
    {
       "name" : "when mangenta hit",
       "color" : "rgb(229, 66, 244)",
       "position" : 170
    },
    {
       "name" : "when cyan hit",
       "color" : "rgb(66, 212, 244)",
       "position" : 380
    },
    {
       "name" : "when yellow hit",
       "color" : "rgb(244, 235, 66)",
       "position" : 550
    }
  ],

  "blocks" : [
    {
      "name" : "rest",
      "instances" : 5
    },
    {
      "instances" : 5,
      "name" : "chance",
      "type" : "chance"
    },
    {
      "name" : "send to pucks",
      "instances" : 10
    },
    {
      "name" : "if the puck distance is:",
      "instances" : 5,
      "type" : "if",
      "params" : [
        {
          "type" : "dropdown",
          "values" : ["less than", "equal to", "greater than"]
        },
        {
          "type" : "range",
          "min" : 0,
          "max" : 600,
          "step" : 1,
          "default" : 200,
          "label" : "pixels",

        }
      ]
    },
    {
      "name" : "if the puck color is:",
      "instances" : 5,
      "type" : "if",
      "params" : [
        {
          "type" : "dropdown",
          "values" : ["Magenta", "Cyan", "Yellow"]
        },
      ]
    },
    {
      "name" : "if the puck shape is:",
      "instances" : 5,
      "type" : "if",
      "params" : [
        {
          "type" : "dropdown",
          "values" : ["Bolt", "Heart", "Star"]
        },
      ]
    }
  ]
};


